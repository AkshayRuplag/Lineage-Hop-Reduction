"""
LLM-based SQL lineage extractor — fallback for files Gudu couldn't process.

Sends Oracle PL/SQL (INSERT / MERGE / UPDATE) to Azure OpenAI and extracts
column-level lineage. Output CSV matches extract_gudu_lineage.py exactly:
  SQL Object Name, Target Table, Target Column,
  Source Table, Source Column, Transformation

Usage
-----
# Auto mode: detect all failing cleaned files and process them
python llm_lineage_extractor.py

# Single source file
python llm_lineage_extractor.py --file All_Metadata/PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_MGIS.sql

# Specific output path
python llm_lineage_extractor.py -o output/llm_lineage_output.csv
"""

import os
import re
import csv
import json
import time
import argparse
import configparser
from pathlib import Path

# ── Config ───────────────────────────────────────────────────────────────────

_THIS_DIR   = os.path.dirname(os.path.abspath(__file__))
_ENV_FILE   = os.path.join(_THIS_DIR, '.env')
_ALL_META   = os.path.join(_THIS_DIR, 'All_Metadata')
_CLEANED    = os.path.join(_THIS_DIR, 'output', 'All_Metadata_cleaned')
_DEFAULT_OUT = os.path.join(_THIS_DIR, 'output', 'llm_lineage_output.csv')

# Max characters to send per LLM call.
# gpt-5-mini supports a 128K-token context window for INPUT, but output is
# capped at ~32K completion tokens.  Wide tables (100+ columns) produce
# very long JSON arrays that exhaust the output budget even at 12K input chars.
# 6 000 chars ≈ ~1.5K input tokens, producing at most ~60 lineage rows
# (~8K output tokens) — safely within the 32K output budget.
# _chunk_sql() splits at DML statement boundaries so no statement is cut.
MAX_CHUNK_CHARS = 6_000

# Gudu skips files over 10 000 chars — the LLM handles them fine.
GUDU_LIMIT = 10_000

# CSV columns (matches extract_gudu_lineage.py fieldnames)
FIELDNAMES = [
    'Object Type', 'Package', 'Procedure', 'SQL Object Name',
    'Target Table', 'Target Column',
    'Source Table', 'Source Column', 'Transformation',
]

# ── Azure OpenAI setup ───────────────────────────────────────────────────────

def load_azure_client():
    """Load credentials from .env and return an AzureOpenAI client."""
    cfg = configparser.RawConfigParser()
    # .env has no [section] header — prepend a dummy one before parsing
    with open(_ENV_FILE, encoding='utf-8') as f:
        raw = '[default]\n' + f.read()
    cfg.read_string(raw)
    sec = 'default'

    api_key         = cfg.get(sec, 'api_key').strip('"').strip("'")
    endpoint        = cfg.get(sec, 'endpoint').strip('"').strip("'")
    deployment_name = cfg.get(sec, 'deployment_name').strip('"').strip("'")
    api_version     = cfg.get(sec, 'api_version').strip('"').strip("'")

    try:
        from openai import AzureOpenAI
    except ImportError:
        raise ImportError("openai package not installed. Run: pip install openai")

    client = AzureOpenAI(
        api_key=api_key,
        azure_endpoint=endpoint,
        api_version=api_version,
    )
    return client, deployment_name


# ── Helpers ──────────────────────────────────────────────────────────────────

def _strip_comments(sql: str) -> str:
    """Remove single-line and block comments to reduce token count."""
    sql = re.sub(r'--[^\n]*', '', sql)
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
    return re.sub(r'\n{3,}', '\n\n', sql).strip()


def _object_name_from_file(filename: str) -> str:
    """Derive SQL object name from a cleaned SQL filename."""
    name = os.path.splitext(filename)[0]
    # Strip _cleaned suffix
    name = re.sub(r'_cleaned$', '', name, flags=re.IGNORECASE)
    # Strip _partN suffix  
    name = re.sub(r'_part\d+$', '', name, flags=re.IGNORECASE)
    return name


def _classify(sql_object_name: str):
    """Return (object_type, package, procedure) for a SQL object name."""
    upper = sql_object_name.upper()
    base  = re.sub(r'_PART\d+$', '', upper)

    if base.startswith('PKG_'):
        idx = sql_object_name.upper().rfind('_PRC_')
        if idx != -1:
            pkg  = sql_object_name[:idx]
            proc = sql_object_name[idx + 1:]
        else:
            pkg  = sql_object_name
            proc = ''
        return 'PKG Procedure', pkg, proc

    if base.startswith(('PRC_', 'PROC_')):
        return 'Standalone Procedure', '', sql_object_name

    if any(base.startswith(p) for p in ('DIM_', 'FCT_', 'MVW_', 'RPT_')):
        return 'Materialized View', '', sql_object_name

    if base.startswith('VW_'):
        return 'View', '', sql_object_name

    return 'SQL Object', '', sql_object_name


def _chunk_sql(sql: str, max_chars: int = MAX_CHUNK_CHARS) -> list[str]:
    """
    Split SQL into chunks at DML statement boundaries so each chunk
    sent to the LLM is complete.  Falls back to hard split if no
    boundaries found.
    """
    if len(sql) <= max_chars:
        return [sql]

    # Try to split at clean INSERT / MERGE / UPDATE statement starts
    pattern = re.compile(
        r'(?=\b(?:INSERT\s+(?:\/\*[^*]*\*\/\s*)?INTO|MERGE\s+INTO|UPDATE\s+)\b)',
        re.IGNORECASE,
    )
    parts = pattern.split(sql)
    # Reassemble greedily
    chunks, buf = [], ''
    for part in parts:
        if buf and len(buf) + len(part) > max_chars:
            chunks.append(buf.strip())
            buf = part
        else:
            buf += part
    if buf.strip():
        chunks.append(buf.strip())

    if not chunks:
        # Hard split as last resort
        chunks = [sql[i:i + max_chars] for i in range(0, len(sql), max_chars)]

    return [c for c in chunks if c.strip()]


# ── LLM prompt ───────────────────────────────────────────────────────────────

_SYSTEM = """\
You are an expert Oracle SQL data lineage analyst.
Given Oracle PL/SQL code, extract column-level data flow from every DML statement
(INSERT INTO...SELECT, MERGE INTO, UPDATE...SET) AND from every
CREATE TABLE ... AS SELECT (CTAS) statement — including those inside
EXECUTE IMMEDIATE '...' string literals.

For cursor-based UPDATE patterns (common in Oracle PL/SQL), the cleaner may
replace the original cursor loop with a comment like:
  -- Lineage: Cursor CUR_NAME -> UPDATE TARGET_TABLE
  -- Source query:
  SELECT col1 AS TARGET_COL1, col2 AS TARGET_COL2, ... FROM SOURCE_TABLE ...
In these cases: TARGET_TABLE is the UPDATE target, each SELECT alias (e.g.
TARGET_COL1) is the target column, and the expression before AS is the source.
Emit one lineage row per (TARGET_TABLE, alias) pair.

Return ONLY valid JSON — no markdown, no explanation, just the JSON object.
The JSON must have exactly one top-level key "lineage" whose value is an array.
Each array element is a FLAT object with EXACTLY these 5 string keys:

  "target_table"   : table/MV being written to (UPPER CASE)
  "target_column"  : column being populated (UPPER CASE)
  "source_table"   : table/view read from (UPPER CASE, or "" for constants)
  "source_column"  : source column (UPPER CASE, or "" for constants/expressions)
  "transformation" : one of: "Direct" | "CASE" | "NVL" | "DECODE" | "TO_DATE"
                     or any function name, or "Constant / Expression"

Example output:
{"lineage": [
  {"target_table": "ORDERS", "target_column": "STATUS", "source_table": "STAGING", "source_column": "STATUS_CD", "transformation": "Direct"},
  {"target_table": "ORDERS", "target_column": "CREATED_AT", "source_table": "", "source_column": "", "transformation": "Constant / Expression"}
]}

Rules:
- One row per (target_table, target_column, source_table, source_column) combination.
- CRITICAL — Resolve ALL aliases to actual table/view names:
  * Table aliases in FROM/JOIN: e.g. "FROM DIM_GRP_CLAIM_DIR_R A" → source_table="DIM_GRP_CLAIM_DIR_R", never "A".
  * Inline view aliases: e.g. "(SELECT ... FROM RPT_FCT_RPT_CLAIM_SUMMARY_R ...) TAB1" → resolve TAB1 to the real base table(s) inside the subquery; never emit "TAB1" or "TAB2" as a table name.
  * CTE aliases: e.g. "WITH CLAIM_DATA AS (SELECT ... FROM DIM_GRP_CLAIM_DIR_R)" → when CLAIM_DATA is used, trace back to DIM_GRP_CLAIM_DIR_R.
  * Never emit a single letter (A, B, C …), a short abbreviation (RS, BE, LF, MCV …), or a TABn alias as source_table or target_table — always resolve to the real Oracle table or view name.
- For MERGE: WHEN NOT MATCHED = INSERT rows, WHEN MATCHED = UPDATE rows.
- For SELECT *: emit one row per source table with target_column="*" and source_column="*".
- Constants/literals/SYSDATE/ROWNUM: source_table="", source_column="", transformation="Constant / Expression".
- Direct column copy (no function): transformation="Direct".
- CASE WHEN expression: transformation="CASE".
- Function call (NVL, DECODE, etc.): transformation = the function name.
- EXECUTE IMMEDIATE: extract the SQL inside the string literal and treat it as
  normal SQL. For EXECUTE IMMEDIATE 'CREATE TABLE T AS SELECT ...' — T is the
  target table; emit one row per selected column with the source table/column.
- Do NOT include internal pseudo-names (RS-1, CTE aliases as final tables, etc.).
- If no DML or CTAS found, return {"lineage": []}.
"""

_USER_TMPL = """\
Extract data lineage from the following Oracle SQL snippet.
SQL Object: {obj_name}

```sql
{sql}
```
"""


_JSON_RE = re.compile(r'\{.*\}', re.DOTALL)


def _extract_json(text: str) -> dict:
    """Extract the first JSON object from text, tolerating surrounding prose."""
    if not text or not text.strip():
        raise ValueError('Empty response from model')
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        m = _JSON_RE.search(text)
        if m:
            return json.loads(m.group())
        raise


def call_llm(client, deployment: str, obj_name: str, sql_chunk: str,
             retries: int = 3, delay: float = 5.0,
             system_prompt: str = None) -> list[dict]:
    """Call Azure OpenAI and parse the returned lineage JSON array."""
    sql_clean = _strip_comments(sql_chunk)
    user_msg  = _USER_TMPL.format(obj_name=obj_name, sql=sql_clean)
    sys_msg   = system_prompt if system_prompt is not None else _SYSTEM

    for attempt in range(1, retries + 1):
        try:
            response = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": sys_msg},
                    {"role": "user",   "content": user_msg},
                ],
                # gpt-5-mini is a reasoning model: it uses internal chain-of-thought
                # tokens before producing output.  4096 is not enough — the model
                # exhausts the budget on reasoning and returns empty content.
                # 32000 gives ~8K reasoning + ~24K for the JSON output, needed for
                # wide tables (100+ columns) like RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.
                max_completion_tokens=32000,
            )
            choice  = response.choices[0]
            raw     = choice.message.content
            finish  = choice.finish_reason

            # Always show finish_reason on first pass so we can diagnose issues
            if attempt == 1:
                print(f"      finish_reason={finish!r}  content_len={len(raw or '')}")

            if not raw or not raw.strip():
                raise ValueError(f'Empty response from model (finish_reason={finish!r})')

            data = _extract_json(raw)
            rows = data.get("lineage", [])
            if not isinstance(rows, list):
                return []

            # If model returned hierarchical schema (target/sources/mappings objects),
            # flatten them into the canonical flat row format
            flat_rows = []
            for item in rows:
                if not isinstance(item, dict):
                    continue
                if 'target' in item and 'target_table' not in item:
                    flat_rows.extend(_extract_flat_rows(item))
                else:
                    flat_rows.append(item)
            return flat_rows

        except KeyboardInterrupt:
            raise  # propagate so outer handler can save partial results
        except Exception as e:
            if attempt < retries:
                print(f"      [WARN] Attempt {attempt} failed: {e}. Retrying in {delay}s…")
                time.sleep(delay)
            else:
                print(f"      [ERROR] All {retries} attempts failed: {e}")
                return []


def _extract_flat_rows(raw: dict) -> list[dict]:
    """
    The model sometimes returns an alternative hierarchical schema:
      {"lineage": [{"target": {"name": ...}, "sources": [...], "mappings": [...]}]}
    Convert it to a list of flat row dicts with the canonical keys.
    """
    flat = []
    tgt_info = raw.get('target', {})
    if not isinstance(tgt_info, dict):
        return flat
    tgt_tbl = str(tgt_info.get('name', '')).strip().upper()
    if not tgt_tbl:
        return flat

    sources = raw.get('sources', [])
    mappings = raw.get('mappings', [])

    if not mappings and sources:
        # No column-level mappings — emit a table-level row per source
        for src in sources:
            src_name = str(src.get('name', '')).strip().upper()
            if src_name:
                flat.append({
                    'target_table': tgt_tbl, 'target_column': '*',
                    'source_table': src_name, 'source_column': '*',
                    'transformation': 'Direct',
                })
        return flat

    # Try to pair mappings with source tables
    for m in mappings:
        if not isinstance(m, dict):
            continue
        src_col  = str(m.get('source', m.get('source_column', ''))).strip().upper()
        tgt_col  = str(m.get('target', m.get('target_column', ''))).strip().upper()
        transf   = str(m.get('transformation', 'Direct')).strip()

        if not tgt_col or 'CONDITION' in tgt_col.upper():
            continue  # skip JOIN conditions

        # Find which source table has this column
        src_tbl = ''
        for src in sources:
            cols = [str(c).upper() for c in src.get('columns', [])]
            alias = str(src.get('alias', '')).upper()
            bare_src_col = re.sub(r'^[A-Z]\.(.*)', r'\1', src_col)  # strip alias prefix
            if bare_src_col in cols or src_col in cols or '*' in cols:
                src_tbl = str(src.get('name', '')).strip().upper()
                src_col = bare_src_col if bare_src_col else src_col
                break

        flat.append({
            'target_table': tgt_tbl, 'target_column': tgt_col,
            'source_table': src_tbl, 'source_column': src_col,
            'transformation': transf if transf else 'Direct',
        })

    return flat


def normalise_row(raw: dict, obj_name: str) -> dict | None:
    """Convert raw LLM row to final CSV row. Returns None if clearly invalid."""
    # Detect alternative hierarchical schema and convert
    if 'target' in raw and 'lineage' not in raw:
        flat_rows = _extract_flat_rows(raw)
        if flat_rows:
            # Return only first; caller handles the list
            raw = flat_rows[0]

    tgt_tbl = str(raw.get('target_table', '')).strip().upper()
    tgt_col = str(raw.get('target_column', '')).strip().upper()
    src_tbl = str(raw.get('source_table', '')).strip().upper()
    src_col = str(raw.get('source_column', '')).strip().upper()
    transf  = str(raw.get('transformation', 'Direct')).strip()

    # Skip rows with no target
    if not tgt_tbl or not tgt_col:
        return None

    # Skip internal SQLFlow pseudo-names that sometimes leak through
    _INTERNAL = re.compile(
        r'^(RS-\d+|RESULT_OF_|INSERT-SELECT-\d+|SELECT-INTO-\d+|MERGE-INSERT-\d+|'
        r'MERGE-UPDATE-\d+|UPDATE-SET-\d+|CTE-\d+|SQL_CONSTANTS|RelationRows)$',
        re.IGNORECASE,
    )
    if _INTERNAL.match(tgt_tbl) or _INTERNAL.match(tgt_col):
        return None

    # Skip backup snapshot tables — _BKP tables are intermediate copies used for
    # rollback safety; they carry no business lineage for the RPT layer.
    if tgt_tbl.endswith('_BKP'):
        return None

    obj_type, pkg, proc = _classify(obj_name)

    return {
        'Object Type':     obj_type,
        'Package':         pkg,
        'Procedure':       proc,
        'SQL Object Name': obj_name,
        'Target Table':    tgt_tbl,
        'Target Column':   tgt_col,
        'Source Table':    src_tbl,
        'Source Column':   src_col,
        'Transformation':  transf if transf else 'Direct',
    }


# ── Core file processing ─────────────────────────────────────────────────────

def process_sql_text(client, deployment: str, obj_name: str,
                     sql: str) -> list[dict]:
    """Chunk sql, call LLM per chunk, return normalised rows."""
    chunks = _chunk_sql(sql)
    all_rows = []
    seen = set()

    for i, chunk in enumerate(chunks, 1):
        if len(chunks) > 1:
            print(f"    chunk {i}/{len(chunks)} ({len(chunk):,} chars)")
        raw_rows = call_llm(client, deployment, obj_name, chunk)
        for raw in raw_rows:
            row = normalise_row(raw, obj_name)
            if row is None:
                continue
            key = (row['Target Table'], row['Target Column'],
                   row['Source Table'],  row['Source Column'])
            if key not in seen:
                seen.add(key)
                all_rows.append(row)

    return all_rows


def process_file(client, deployment: str,
                 sql_path: str, obj_name: str | None = None) -> list[dict]:
    """Process a single SQL file and return lineage rows."""
    sql = Path(sql_path).read_text(encoding='utf-8', errors='ignore')
    if obj_name is None:
        obj_name = _object_name_from_file(os.path.basename(sql_path))
    print(f"  [{obj_name}]  ({len(sql):,} chars)")
    return process_sql_text(client, deployment, obj_name, sql)


# ── Auto-detection of failing files ─────────────────────────────────────────

# Internal Gudu construct names that are never real target tables.
# When ALL relationship targets match this pattern the JSON has no usable
# lineage (Gudu parsed the SELECT subqueries but not the outer UPDATE/INSERT).
_INTERNAL_TARGET_RE = re.compile(
    r'^(RS-\d+|RESULT_OF_\S*|INSERT-SELECT-?\d*|SELECT-INTO-?\d*'
    r'|MERGE-INSERT-?\d*|MERGE-UPDATE-?\d*|UPDATE-SET-?\d*'
    r'|CTE-\S*|SQL_CONSTANTS-?\d*|RelationRows'
    r'|NVL|DECODE|COALESCE|CAST|TO_DATE|TO_CHAR|TO_NUMBER'
    r'|max|min|sum|count|avg|nvl|decode)$',
    re.IGNORECASE,
)


def _json_has_rels(jpath: str) -> bool:
    """Return True if a lineage JSON has at least one relationship whose
    target is a real table/view column (not an internal Gudu construct).

    Gudu sometimes produces relationships that only map source → RS-N
    (result-set intermediates used for UPDATE subqueries) without ever
    connecting RS-N back to the real target table.  Such JSONs look non-empty
    but extract_lineage() returns 0 rows — we must not treat them as covered.
    """
    if not os.path.exists(jpath):
        return False
    try:
        raw = Path(jpath).read_text(encoding='utf-8').split('\nError log:')[0].strip()
        data = json.loads(raw)
        rels = data.get('relationships', [])
        if not rels:
            return False
        for r in rels:
            tgt = r.get('target', {})
            parent = str(tgt.get('parentName', '') or tgt.get('parentId', '')).strip()
            if parent and not _INTERNAL_TARGET_RE.match(parent):
                return True   # at least one real-table target found
        return False          # all targets are internal constructs
    except Exception:
        return False


# Pattern matching the Gudu assessment: file must have DML or CTAS to be worth sending to LLM.
# Also matches cursor-lineage comment annotations written by clean_and_run_gudu.py:
#   -- Lineage: Cursor CUR_X -> UPDATE RPT_Y
# These cleaned files contain only the cursor SELECT (no literal UPDATE keyword)
# but the LLM can infer source→target mappings from the comment + SELECT aliases.
_HAS_DML = re.compile(
    r'\b(INSERT\s+(?:/\*[^*]*\*/\s*)?INTO|MERGE\s+INTO|UPDATE\s+\w|DELETE\s+(FROM\s+)?\w'
    r'|CREATE\s+TABLE\b.*\bAS\s+SELECT)\b'
    r'|--\s*Lineage:\s*Cursor\s+\w+\s*->\s*(UPDATE|INSERT|MERGE|DELETE)',
    re.IGNORECASE | re.DOTALL,
)


def detect_failing_cleaned_files(cleaned_dir: str = _CLEANED) -> list[tuple[str, str, str]]:
    """
    Return list of (obj_name, combined_sql_text, display_label) for procedures
    that the LLM should process.

    Key logic:
    - Part files (_part1, _part2, ...) that belong to the SAME procedure are
      CONCATENATED into one combined SQL string before being sent to the LLM.
      This is critical: the Gudu splitter can cut mid-statement, so sending a
      part in isolation gives the LLM an incomplete picture.
    - A procedure group is included only if:
        a) At least one of its _partN_cleaned_lineage.json files has zero
           relationships (meaning Gudu failed or produced no output for that
           part), AND
        b) The combined SQL actually contains DML.
    - Single (non-part) files that have no lineage JSON and contain DML are included as-is.
    """
    cleaned_dir = os.path.abspath(cleaned_dir)
    all_cleaned = sorted(
        f for f in os.listdir(cleaned_dir) if f.endswith('_cleaned.sql')
    )

    # Separate part files from single files
    part_re = re.compile(r'^(.+?)_part(\d+)_cleaned$')
    groups: dict[str, list[tuple[int, str]]] = {}  # base_name -> [(part_num, path)]
    singles: list[str] = []

    for f in all_cleaned:
        base = os.path.splitext(f)[0]  # e.g. "PKG_..._part3_cleaned"
        m = part_re.match(base)
        if m:
            grp_name = m.group(1)
            part_num = int(m.group(2))
            groups.setdefault(grp_name, []).append((part_num, os.path.join(cleaned_dir, f)))
        else:
            singles.append(os.path.join(cleaned_dir, f))

    failing: list[tuple[str, str, str]] = []

    # ── Handle grouped part-files ──────────────────────────────────────────
    for grp_name, parts in groups.items():
        # Only skip if EVERY individual part JSON has relationships.
        # Checking the stitched JSON alone is insufficient — a stitched file
        # can exist with only trivial relationships (e.g. debug-trace table
        # writes from one part) while other parts were never parsed by Gudu.
        all_parts_covered = all(
            _json_has_rels(
                os.path.join(
                    cleaned_dir,
                    os.path.splitext(os.path.basename(ppath))[0] + '_lineage.json',
                )
            )
            for _, ppath in parts
        )
        if all_parts_covered:
            continue  # every part already has Gudu lineage

        # Sort parts in order and concatenate
        parts.sort(key=lambda x: x[0])
        combined_parts = []
        for _, ppath in parts:
            try:
                combined_parts.append(open(ppath, encoding='utf-8', errors='ignore').read())
            except OSError:
                pass

        combined_sql = '\n\n'.join(combined_parts)
        if not combined_sql.strip():
            continue

        # Only include if combined SQL has DML
        if not _HAS_DML.search(combined_sql):
            continue

        obj_name = _object_name_from_file(grp_name + '_cleaned')
        label = f'{grp_name} ({len(parts)} parts combined, {len(combined_sql):,} chars)'
        failing.append((obj_name, combined_sql, label))

    # ── Handle single files ────────────────────────────────────────────────
    for sql_path in singles:
        base = os.path.splitext(os.path.basename(sql_path))[0]
        json_path = os.path.join(cleaned_dir, base + '_lineage.json')
        if _json_has_rels(json_path):
            continue
        try:
            content = open(sql_path, encoding='utf-8', errors='ignore').read()
        except OSError:
            continue
        if not _HAS_DML.search(content):
            continue
        obj_name = _object_name_from_file(os.path.basename(sql_path))
        label = f'{os.path.basename(sql_path)} ({len(content):,} chars)'
        failing.append((obj_name, content, label))

    failing.sort(key=lambda x: x[0])
    return failing


def extract_hybrid_main_body(pkg_sql_path: str) -> str | None:
    """Extract the MAIN procedure body from a package SQL file.

    Returns the raw MAIN procedure text (from 'PROCEDURE MAIN' through
    'END MAIN;' / 'END;'), or None if MAIN is not found.

    Used for Hybrid packages where MAIN has its own DML (INSERT/MERGE/UPDATE)
    in addition to calling child procedures.  Gudu cannot parse these because
    the INSERT body is too large (>10K chars) and uses complex CASE/JOIN
    expressions that Gudu misresolves to internal constructs.
    """
    try:
        raw = Path(pkg_sql_path).read_text(encoding='utf-8', errors='ignore')
    except OSError:
        return None

    lines = raw.splitlines(keepends=True)

    # Locate PROCEDURE MAIN start
    main_start = None
    for i, line in enumerate(lines):
        if re.match(r'^\s*PROCEDURE\s+MAIN\b', line, re.IGNORECASE):
            main_start = i
            break
    if main_start is None:
        return None

    # Walk forward to find the matching END MAIN; / END;
    begin_count = 0
    found_first_begin = False
    in_block_comment = False
    end_idx = None

    for j in range(main_start, len(lines)):
        raw_line = lines[j]
        stripped = raw_line.strip().upper()
        if stripped.startswith('--'):
            continue
        if in_block_comment:
            if '*/' in stripped:
                in_block_comment = False
            continue
        if '/*' in stripped:
            if '*/' not in stripped[stripped.index('/*') + 2:]:
                in_block_comment = True
                continue
        # Exact END MAIN; wins immediately
        if re.match(r'^\s*END\s+MAIN\s*;', stripped):
            end_idx = j
            break
        if re.search(r'\bBEGIN\b', stripped):
            begin_count += 1
            found_first_begin = True
        if found_first_begin and re.match(r'^\s*END\s*;', stripped):
            begin_count -= 1
            if begin_count <= 0:
                end_idx = j
                break

    if end_idx is None:
        end_idx = len(lines) - 1

    return ''.join(lines[main_start: end_idx + 1])


def detect_hybrid_main_failing(pkg_names: list[str],
                                all_meta_dir: str = _ALL_META) -> list[tuple[str, str, str]]:
    """For each package name, extract the MAIN procedure body and return it as an
    LLM-processable task tuple: (obj_name, sql_text, display_label).

    obj_name is set to PKG_NAME_MAIN so the combined lineage lookup matches the
    combiner's dot→underscore key for the 'main' proc row
    (FULL_OBJECT = 'PKG_NAME.main' → PKG_NAME_MAIN).
    """
    tasks = []
    for pkg_name in pkg_names:
        sql_path = os.path.join(all_meta_dir, pkg_name + '.sql')
        if not os.path.exists(sql_path):
            print(f"  [WARN] Package SQL not found: {sql_path}")
            continue
        main_body = extract_hybrid_main_body(sql_path)
        if not main_body:
            print(f"  [WARN] MAIN procedure not found in {pkg_name}.sql")
            continue
        if not _HAS_DML.search(main_body):
            print(f"  [WARN] MAIN in {pkg_name} has no DML — skipping")
            continue
        obj_name = f'{pkg_name}_MAIN'
        label = f'{pkg_name}.MAIN ({len(main_body):,} chars)'
        tasks.append((obj_name, main_body, label))
    return tasks


def _load_already_processed_obj_names(llm_output_path: str) -> set[str]:
    """Read the existing LLM output CSV and return a set of UPPER(SQL Object Name)
    values that already have at least one row — used to skip re-processing."""
    done = set()
    if not os.path.exists(llm_output_path):
        return done
    try:
        with open(llm_output_path, 'r', encoding='utf-8-sig') as f:
            for row in csv.DictReader(f):
                name = str(row.get('SQL Object Name', '') or '').strip().upper()
                if name:
                    done.add(name)
    except Exception:
        pass
    return done


def detect_all_hybrid_main_procs(
        all_meta_dir: str = _ALL_META,
        already_done: set[str] | None = None,
) -> list[tuple[str, str, str]]:
    """Auto-detect ALL Hybrid MAIN procedures across every package SQL in all_meta_dir.

    A Hybrid MAIN is one where:
      - The file is a package body (CREATE ... PACKAGE BODY)
      - The package has a MAIN procedure
      - MAIN has its own DML (INSERT INTO / MERGE INTO / UPDATE)
      - MAIN was NOT already processed (not in already_done)

    Returns list of (obj_name, sql_text, display_label) tasks ready for LLM.
    obj_name = PKG_NAME_MAIN  (matches the combiner's dot→underscore lookup key).
    """
    # Detect package body marker
    _PKG_BODY_RE = re.compile(
        r'\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:EDITIONABLE\s+|NONEDITIONABLE\s+)?PACKAGE\s+BODY\b',
        re.IGNORECASE,
    )

    if already_done is None:
        already_done = set()

    tasks = []
    sql_files = sorted(f for f in os.listdir(all_meta_dir) if f.endswith('.sql'))

    for fname in sql_files:
        pkg_name = os.path.splitext(fname)[0]
        obj_name = f'{pkg_name}_MAIN'

        # Skip if already in LLM output
        if obj_name.upper() in already_done:
            continue

        sql_path = os.path.join(all_meta_dir, fname)
        try:
            raw_sql = Path(sql_path).read_text(encoding='utf-8', errors='ignore')
        except OSError:
            continue

        # Only process package bodies
        if not _PKG_BODY_RE.search(raw_sql):
            continue

        # Extract MAIN body
        main_body = extract_hybrid_main_body(sql_path)
        if not main_body:
            continue   # No MAIN proc in this package

        # Only include if MAIN has DML
        if not _HAS_DML.search(main_body):
            continue

        label = f'{pkg_name}.MAIN ({len(main_body):,} chars)'
        tasks.append((obj_name, main_body, label))

    return tasks


def detect_failing_source_files(all_meta_dir: str = _ALL_META,
                                cleaned_dir: str  = _CLEANED) -> list[tuple[str, str]]:
    """
    Return list of (obj_name, sql_path) for ORIGINAL source files where
    ALL cleaned parts have no usable lineage (fully failing objects).
    Used as fallback when there are no cleaned parts at all.
    """
    all_jsons = set(
        f for f in os.listdir(cleaned_dir) if f.endswith('_lineage.json')
    )
    src_files = sorted(f for f in os.listdir(all_meta_dir) if f.endswith('.sql'))
    failing = []

    for f in src_files:
        base = os.path.splitext(f)[0]
        # Check if any cleaned file from this source exists
        related = [c for c in os.listdir(cleaned_dir)
                   if c.endswith('_cleaned.sql') and c.startswith(base)]
        if not related:
            # No cleaned file at all — Gudu had nothing to run
            obj_name = base
            failing.append((obj_name, os.path.join(all_meta_dir, f)))
            continue

        # Check if ALL cleaned parts have no rels
        any_ok = False
        for c in related:
            j = os.path.splitext(c)[0] + '_lineage.json'
            if _json_has_rels(os.path.join(cleaned_dir, j)):
                any_ok = True
                break
        # Also check stitched json
        stitch = os.path.join(cleaned_dir, base + '_lineage.json')
        if _json_has_rels(stitch):
            any_ok = True

        if not any_ok:
            obj_name = base
            failing.append((obj_name, os.path.join(all_meta_dir, f)))

    return failing


# ── Output ───────────────────────────────────────────────────────────────────

def write_csv(rows: list[dict], output_path: str, append: bool = False):
    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)
    mode = 'a' if append and os.path.exists(output_path) else 'w'
    # In append mode skip BOM and header so the file stays valid CSV
    write_header = mode == 'w'
    with open(output_path, mode, newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=FIELDNAMES, extrasaction='ignore')
        if write_header:
            writer.writeheader()
        writer.writerows(rows)
    action = 'Appended' if mode == 'a' else 'Wrote'
    print(f"\n{action} {len(rows)} rows -> {output_path}")


# ── Completeness Report (Phase 4) ─────────────────────────────────────────────

AUDIT_COLS = frozenset({
    'N_BATCH_ID_R', 'T_CREATION_DATE_R', 'T_LAST_MODIFIED_DATE_R',
    'V_CREATED_BY_R', 'V_LAST_MODIFIED_BY_R', 'V_RPT_ACTIVE_STATUS_R',
    'N_YEARMONTH_R', 'N_LOAD_RUN_ID_R', 'T_BATCH_DATE_R', 'N_SEQUENCE_NUMBER_R',
})


def run_completeness_report(csv_path: str) -> None:
    """
    Phase 4: print a completeness summary of remaining lineage gaps after all extraction.
    Categorises gaps as: AUDIT_COLUMN | EXCHANGE_TABLE | GENUINE_GAP.
    """
    if not os.path.exists(csv_path):
        return

    total = 0
    gap_audit = 0
    gap_exchange = 0
    gap_genuine: dict[str, list[str]] = {}  # target_table -> [columns]

    with open(csv_path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            total += 1
            if row.get('Source Table', '').strip():
                continue
            tgt_tbl = row.get('Target Table', '').strip().upper()
            tgt_col = row.get('Target Column', '').strip().upper()

            if tgt_col in AUDIT_COLS or tgt_col == '*':
                gap_audit += 1
            elif re.search(r'(_EXG|_TEMP|_INC|_TMP)$', tgt_tbl):
                gap_exchange += 1
            else:
                gap_genuine.setdefault(tgt_tbl, []).append(tgt_col)

    genuine_total = sum(len(v) for v in gap_genuine.values())

    print('\n' + '=' * 65)
    print('LINEAGE COMPLETENESS REPORT')
    print('=' * 65)
    print(f'  Total lineage rows          : {total:>6}')
    print(f'  Rows with source (complete) : {total - gap_audit - gap_exchange - genuine_total:>6}')
    print(f'  Gaps — Audit/System cols    : {gap_audit:>6}  (no data lineage by design)')
    print(f'  Gaps — Exchange/Staging tbl : {gap_exchange:>6}  (intermediate hops, not final RPT)')
    print(f'  Gaps — Genuine (unexplained): {genuine_total:>6}')

    if gap_genuine:
        print()
        print('  Genuine gaps by target table:')
        for tbl in sorted(gap_genuine):
            cols = gap_genuine[tbl]
            sample = ', '.join(sorted(cols)[:4])
            more   = f' +{len(cols)-4} more' if len(cols) > 4 else ''
            print(f'    {tbl}: {len(cols)} cols  [{sample}{more}]')
    else:
        print('\n  ✓ ZERO genuine lineage gaps — full-proof extraction complete.')
    print('=' * 65)


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='LLM-based SQL lineage extractor for files Gudu could not process'
    )
    src_grp = parser.add_mutually_exclusive_group()
    src_grp.add_argument(
        '--file', '-f', metavar='SQL_FILE',
        help='Process a single SQL file (source or cleaned)',
    )
    src_grp.add_argument(
        '--cleaned-dir', metavar='DIR', default=_CLEANED,
        help=f'Cleaned SQL dir to scan for failing files (default: {_CLEANED})',
    )
    parser.add_argument(
        '--source-dir', metavar='DIR', default=_ALL_META,
        help=f'Original source SQL dir (default: {_ALL_META})',
    )
    parser.add_argument(
        '--output', '-o', default=_DEFAULT_OUT,
        help=f'Output CSV path (default: {_DEFAULT_OUT})',
    )
    parser.add_argument(
        '--obj-name', metavar='NAME',
        help='Override SQL object name (only with --file)',
    )
    parser.add_argument(
        '--max-chunk', type=int, default=MAX_CHUNK_CHARS,
        help=f'Max chars per LLM call (default: {MAX_CHUNK_CHARS})',
    )
    parser.add_argument(
        '--workers', '-w', type=int, default=4,
        help='Parallel LLM workers for auto mode (default: 4; use 1 for sequential)',
    )
    parser.add_argument(
        '--only', metavar='SUBSTR[,SUBSTR...]',
        help='Comma-separated substrings: only process procedures whose name contains any of them (case-insensitive)',
    )
    parser.add_argument(
        '--pkg-mains', metavar='PKG[,PKG...]',
        help=(
            'Comma-separated package names whose MAIN procedure should be sent directly '
            'to LLM (bypassing Gudu). Use for Hybrid packages where MAIN has its own DML '
            'that Gudu cannot parse (INSERT body >10K chars or unresolvable complex JOINs). '
            'Example: --pkg-mains PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC,PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
        ),
    )
    parser.add_argument(
        '--append', action='store_true',
        help='Append rows to existing output CSV instead of overwriting it',
    )
    parser.add_argument(
        '--dry-run', action='store_true',
        help='List files that would be processed but do not call LLM',
    )
    parser.add_argument(
        '--skip-report', action='store_true',
        help='Skip the Phase 4 completeness report at the end',
    )
    args = parser.parse_args()

    # Allow caller to override max chunk size
    if args.max_chunk != MAX_CHUNK_CHARS:
        import sys
        sys.modules[__name__].__dict__['MAX_CHUNK_CHARS'] = args.max_chunk

    # Load LLM client
    if not args.dry_run:
        print("Loading Azure OpenAI client from .env …")
        client, deployment = load_azure_client()
        print(f"  Model: {deployment}\n")
    else:
        client, deployment = None, 'DRY-RUN'

    all_rows = []

    if args.file:
        # ── Single file mode ──────────────────────────────────────────────
        sql_path = os.path.abspath(args.file)
        obj_name = args.obj_name or _object_name_from_file(os.path.basename(sql_path))
        if args.dry_run:
            print(f"[DRY-RUN] Would process: {sql_path} as '{obj_name}'")
        else:
            rows = process_file(client, deployment, sql_path, obj_name)
            all_rows.extend(rows)
            print(f"  -> {len(rows)} lineage rows extracted")
    elif args.pkg_mains:
        # ── Hybrid-MAIN mode: bypass Gudu, send MAIN proc directly to LLM ──────
        pkg_list = [p.strip() for p in args.pkg_mains.split(',') if p.strip()]
        print(f"Extracting MAIN procedures from {len(pkg_list)} Hybrid package(s)...\n")
        tasks = detect_hybrid_main_failing(pkg_list, args.source_dir)
        print(f"Found {len(tasks)} MAIN proc(s) with DML to process.\n")
        print("-" * 70)

        if args.dry_run:
            for obj_name, sql_text, label in tasks:
                print(f"  [{len(sql_text):>7,} chars]  {label}  -> obj_name='{obj_name}'")
            print(f"\n[DRY-RUN] Would send {len(tasks)} MAIN proc(s) to LLM.")
            return

        for i, (obj_name, sql_text, label) in enumerate(tasks, 1):
            print(f"[{i}/{len(tasks)}] {label}")
            rows = process_sql_text(client, deployment, obj_name, sql_text)
            print(f"[{i}/{len(tasks)}]   -> {len(rows)} rows extracted")
            all_rows.extend(rows)
    else:
        # ── Auto mode: scan cleaned dir for failing files ─────────────────
        print(f"Scanning for failing cleaned files in:\n  {args.cleaned_dir}\n")
        failing = detect_failing_cleaned_files(args.cleaned_dir)

        # ── Auto mode: also detect Hybrid MAIN procs not yet processed ────
        # Hybrid MAINs have their own DML (INSERT/MERGE/UPDATE) but are skipped
        # by clean_and_run_gudu.py because Gudu can't resolve complex JOINs in
        # large INSERT bodies.  We detect them here and append to the task list.
        already_done = _load_already_processed_obj_names(args.output)
        hybrid_tasks = detect_all_hybrid_main_procs(args.source_dir, already_done)
        if hybrid_tasks:
            # Exclude any Hybrid MAINs already present in failing (avoid dups)
            failing_obj_names = {obj.upper() for obj, _, _ in failing}
            new_hybrids = [(obj, sql, lbl) for obj, sql, lbl in hybrid_tasks
                           if obj.upper() not in failing_obj_names]
            if new_hybrids:
                print(f"  + {len(new_hybrids)} Hybrid MAIN proc(s) detected "
                      f"(Gudu skipped, routing to LLM directly)")
                failing.extend(new_hybrids)

        # Apply --only filter if provided
        if args.only:
            filters = [s.strip().upper() for s in args.only.split(',') if s.strip()]
            failing = [
                (obj, sql, lbl) for obj, sql, lbl in failing
                if any(f in obj.upper() for f in filters)
            ]

        print(f"Found {len(failing)} procedures needing LLM processing.\n")
        print("-" * 70)

        if args.dry_run:
            for obj_name, sql_text, label in failing:
                print(f"  [{len(sql_text):>7,} chars]  {label}")
            print(f"\n[DRY-RUN] Would send {len(failing)} procedures to LLM.")
            return

        import threading
        from concurrent.futures import ThreadPoolExecutor, as_completed

        _print_lock = threading.Lock()
        _all_rows_lock = threading.Lock()
        total = len(failing)
        workers = min(args.workers, total)

        def _process_one(task):
            i, obj_name, sql_text, label = task
            with _print_lock:
                print(f"[{i}/{total}] {label}")
            try:
                rows = process_sql_text(client, deployment, obj_name, sql_text)
            except Exception as exc:
                with _print_lock:
                    print(f"[{i}/{total}] [ERROR] {exc}")
                rows = []
            with _print_lock:
                print(f"[{i}/{total}]   -> {len(rows)} rows")
            return rows

        tasks = [(i, obj, sql, lbl) for i, (obj, sql, lbl) in enumerate(failing, 1)]

        try:
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {executor.submit(_process_one, t): t[0] for t in tasks}
                for future in as_completed(futures):
                    rows = future.result()
                    with _all_rows_lock:
                        all_rows.extend(rows)
        except KeyboardInterrupt:
            print(f"\n[INTERRUPTED] Saving {len(all_rows)} rows collected so far…")

    if not args.dry_run:
        # Deduplicate across files (same target/source can appear in multiple parts)
        seen = set()
        deduped = []
        for row in all_rows:
            key = (row['SQL Object Name'], row['Target Table'], row['Target Column'],
                   row['Source Table'],    row['Source Column'])
            if key not in seen:
                seen.add(key)
                deduped.append(row)

        deduped.sort(key=lambda r: (
            r['Object Type'], r['Package'], r['Procedure'],
            r['Target Table'], r['Target Column'],
            r['Source Table'], r['Source Column'],
        ))

        write_csv(deduped, args.output, append=args.append)

        # Stats
        tgts = set(r['Target Table'] for r in deduped)
        srcs = set(r['Source Table'] for r in deduped if r['Source Table'])
        print(f"\nStats:")
        print(f"  Total rows       : {len(deduped)}")
        print(f"  Target tables    : {len(tgts)}")
        print(f"  Source tables    : {len(srcs)}")
        print(f"  Direct mappings  : {sum(1 for r in deduped if r['Transformation'] == 'Direct')}")
        print(f"  With transforms  : {sum(1 for r in deduped if r['Transformation'] not in ('Direct','Constant / Expression'))}")

        # ── Phase 4: Completeness report ──────────────────────────────────────
        if not args.skip_report:
            run_completeness_report(args.output)


if __name__ == '__main__':
    main()
