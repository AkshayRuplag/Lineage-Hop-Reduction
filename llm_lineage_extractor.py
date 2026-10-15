"""
LLM-based SQL lineage extractor — fallback for files Gudu couldn't process.

Sends Oracle PL/SQL (INSERT / MERGE / UPDATE) to Azure OpenAI and extracts
column-level lineage. Output CSV matches extract_gudu_lineage.py exactly:
  SQL Object Name, Target Table, Target Column,
  Source Table, Source Column, Transformation, Actual Transformation

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
_CLEANED    = os.path.join(_THIS_DIR, 'output', 'All_Metadata_cleaned_new')
_DEFAULT_OUT = os.path.join(_THIS_DIR, 'output', 'llm_lineage_output.csv')
_DEFAULT_GUDU_CSV = os.path.join(_THIS_DIR, 'output', 'gudu_lineage_output.csv')

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
    'Actual Transformation',
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


# ── AWS Bedrock (Claude Sonnet 4) setup ─────────────────────────────────────

BEDROCK_MODEL_ID = "us.anthropic.claude-sonnet-4-20250514-v1:0"


class _BedrockMessage:
    def __init__(self, content):
        self.content = content


class _BedrockChoice:
    def __init__(self, content, finish_reason):
        self.message = _BedrockMessage(content)
        self.finish_reason = finish_reason


class _BedrockResponse:
    def __init__(self, content, finish_reason):
        self.choices = [_BedrockChoice(content, finish_reason)]


class _BedrockChatCompletions:
    """Mimics OpenAI's client.chat.completions.create() on top of Bedrock Converse."""

    def __init__(self, brt_client, default_model_id):
        self._brt = brt_client
        self._default_model = default_model_id

    def create(self, model=None, messages=None, max_completion_tokens=32000, **_ignored):
        model_id = model or self._default_model
        system_blocks = []
        conv_messages = []
        for m in messages or []:
            role, text = m.get('role'), m.get('content', '')
            if role == 'system':
                system_blocks.append({'text': text})
            else:
                conv_messages.append({'role': role, 'content': [{'text': text}]})

        kwargs = {'system': system_blocks} if system_blocks else {}
        response = self._brt.converse(
            modelId=model_id,
            messages=conv_messages,
            inferenceConfig={'maxTokens': max_completion_tokens},
            **kwargs,
        )
        content_blocks = response.get('output', {}).get('message', {}).get('content', [])
        text = ''.join(b.get('text', '') for b in content_blocks if 'text' in b)
        finish_reason = response.get('stopReason', 'stop')
        return _BedrockResponse(text, finish_reason)


class BedrockChatClient:
    """Thin adapter so call_llm() can use Bedrock via the same `.chat.completions.create()` API."""

    def __init__(self, brt_client, default_model_id):
        self.chat = type('_Chat', (), {})()
        self.chat.completions = _BedrockChatCompletions(brt_client, default_model_id)


def load_bedrock_client():
    """Load an AWS Bedrock (Claude Sonnet 4) client using local AWS CLI credentials."""
    import boto3
    from botocore.config import Config as BotoConfig

    model_id = os.environ.get('BEDROCK_MODEL_ID', BEDROCK_MODEL_ID)
    region = (os.environ.get('AWS_REGION') or os.environ.get('AWS_DEFAULT_REGION')
              or 'us-east-1')
    bedrock_config = BotoConfig(
        retries={'max_attempts': 5, 'mode': 'adaptive'},
        max_pool_connections=10,   # Lower for Bedrock (rate limiting)
        read_timeout=300,          # Longer for LLM responses
    )
    brt = boto3.client('bedrock-runtime', region_name=region, config=bedrock_config)
    # Cheap credentials check so we fail fast (and fall back to Azure) if AWS CLI isn't configured
    boto3.client('sts', region_name=region).get_caller_identity()
    return BedrockChatClient(brt, model_id), model_id


def load_llm_client():
    """Load the LLM client: AWS Bedrock (Claude Sonnet 4) at priority one, falling
    back to Azure OpenAI (gpt-5-mini) if Bedrock/AWS credentials aren't available."""
    try:
        client, model_id = load_bedrock_client()
        print(f"Using AWS Bedrock ({model_id})\n")
        return client, model_id
    except Exception as e:
        print(f"  [WARN] AWS Bedrock unavailable ({e}); falling back to Azure OpenAI…")
        print("Loading Azure OpenAI client from .env …")
        client, deployment = load_azure_client()
        print(f"  Model: {deployment}\n")
        return client, deployment


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
(INSERT INTO...SELECT, MERGE INTO, UPDATE...SET) and every CREATE TABLE ... AS
SELECT (CTAS) statement, including statements inside EXECUTE IMMEDIATE strings.

For cursor-based UPDATE patterns, the cleaner may replace the original cursor
loop with comments such as:
  -- Lineage: Cursor CUR_NAME -> UPDATE TARGET_TABLE
  -- Source query:
  SELECT col1 AS TARGET_COL1, NVL(col2, 0) AS TARGET_COL2
  FROM SOURCE_TABLE

In these cases, TARGET_TABLE is the UPDATE target, each SELECT alias is the
target column, and the expression before AS is the source expression.

Return ONLY valid JSON. Do not return markdown, explanations, or code fences.
The JSON must have exactly one top-level key named "lineage" whose value is an
array. Each array element must be a FLAT object with EXACTLY these 6 string keys:

  "target_table"          : table or materialized view being written to,
                            in UPPER CASE
  "target_column"         : target column being populated, in UPPER CASE
  "source_table"          : actual table/view read from, in UPPER CASE,
                            or "" for constants and expressions with no source
  "source_column"         : actual source column, in UPPER CASE,
                            or "" for constants and expressions with no source
  "transformation"        : normalized transformation category, such as
                            "Direct", "CASE", "NVL", "DECODE", "TO_DATE",
                            "Arithmetic", a function name, or
                            "Constant / Expression"
  "actual_transformation" : exact SQL expression used to populate the target
                            column. Preserve functions, CASE logic, operators,
                            aliases, literals, predicates, and nesting. Remove
                            only the final target alias or the left side of an
                            UPDATE assignment.

Example output:
{"lineage": [
  {"target_table": "ORDERS", "target_column": "STATUS", "source_table": "STAGING", "source_column": "STATUS_CD", "transformation": "Direct", "actual_transformation": "S.STATUS_CD"},
  {"target_table": "ORDERS", "target_column": "TOTAL_AMOUNT", "source_table": "STAGING", "source_column": "BASE_AMOUNT", "transformation": "NVL", "actual_transformation": "NVL(S.BASE_AMOUNT, 0) + NVL(S.TAX_AMOUNT, 0)"},
  {"target_table": "ORDERS", "target_column": "TOTAL_AMOUNT", "source_table": "STAGING", "source_column": "TAX_AMOUNT", "transformation": "NVL", "actual_transformation": "NVL(S.BASE_AMOUNT, 0) + NVL(S.TAX_AMOUNT, 0)"},
  {"target_table": "ORDERS", "target_column": "CREATED_AT", "source_table": "", "source_column": "", "transformation": "Constant / Expression", "actual_transformation": "SYSDATE"}
]}

Rules:
- Emit one row per unique target_table, target_column, source_table,
  source_column, and actual_transformation combination.
- Resolve every FROM/JOIN alias to the real Oracle table or view name.
- Resolve inline-view and CTE aliases to their underlying base tables/views.
- Never emit single-letter aliases, short aliases, TABn aliases, CTE aliases,
  or internal result-set names as source_table or target_table.
- Preserve aliases inside actual_transformation because that field must reflect
  the SQL expression as written, while source_table must contain the resolved
  physical table/view name.
- For INSERT INTO ... SELECT, match target columns and SELECT expressions by
  ordinal position. The SELECT expression before its alias is the
  actual_transformation.
- For UPDATE SET TARGET_COL = expression, TARGET_COL is the target column and
  the complete right-hand expression is actual_transformation.
- For MERGE, extract both WHEN MATCHED UPDATE and WHEN NOT MATCHED INSERT.
  For UPDATE mappings use the right-hand assignment expression. For INSERT
  mappings match target columns to VALUES expressions by ordinal position.
- For CTAS, the created table is the target. The SELECT expression before its
  alias is actual_transformation. If no alias exists, use the selected source
  column name as the target column.
- If an expression references multiple source columns, emit one row for each
  source column and repeat the complete actual_transformation for every row.
- Direct source-column copy: transformation="Direct" and preserve the exact
  column expression, such as A.STATUS_CD, in actual_transformation.
- CASE expression: transformation="CASE" and preserve the complete CASE logic.
- Function expression: transformation is the outermost or primary function
  name and actual_transformation is the complete expression, including nested
  functions.
- Arithmetic without a dominant function: transformation="Arithmetic" and
  preserve the complete arithmetic expression.
- Constants, literals, SYSDATE, SYSTIMESTAMP, USER, sequences, and ROWNUM use
  source_table="", source_column="", transformation="Constant / Expression",
  and preserve the exact expression in actual_transformation.
- For SELECT *, emit one row per source table with target_column="*",
  source_column="*", transformation="Direct", and actual_transformation as
  ALIAS.* when an alias is present, otherwise "*".
- EXECUTE IMMEDIATE: extract and analyze SQL inside the string literal. For
  concatenated dynamic SQL, reconstruct what can be resolved without inventing
  values.
- Do not include JOIN, WHERE, GROUP BY, ORDER BY, or filter-only columns unless
  they are part of the expression that populates the target column.
- Do not simplify, paraphrase, or invent actual_transformation. Preserve the
  supplied SQL expression as closely as possible.
- If no DML or CTAS is found, return {"lineage": []}.
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
    """Convert an alternative hierarchical response into canonical flat rows."""
    flat = []
    tgt_info = raw.get('target', {})
    if not isinstance(tgt_info, dict):
        return flat

    tgt_tbl = str(tgt_info.get('name', '') or '').strip().upper()
    if not tgt_tbl:
        return flat

    sources = raw.get('sources', [])
    mappings = raw.get('mappings', [])
    if not isinstance(sources, list):
        sources = []
    if not isinstance(mappings, list):
        mappings = []

    if not mappings and sources:
        for src in sources:
            if not isinstance(src, dict):
                continue
            src_name = str(src.get('name', '') or '').strip().upper()
            src_alias = str(src.get('alias', '') or '').strip()
            if src_name:
                flat.append({
                    'target_table': tgt_tbl,
                    'target_column': '*',
                    'source_table': src_name,
                    'source_column': '*',
                    'transformation': 'Direct',
                    'actual_transformation': f'{src_alias}.*' if src_alias else '*',
                })
        return flat

    for mapping in mappings:
        if not isinstance(mapping, dict):
            continue

        source_value = mapping.get('source', mapping.get('source_column', ''))
        target_value = mapping.get('target', mapping.get('target_column', ''))
        src_col = str(source_value or '').strip().upper()
        tgt_col = str(target_value or '').strip().upper()
        transf = str(mapping.get('transformation', 'Direct') or 'Direct').strip()
        actual = str(
            mapping.get(
                'actual_transformation',
                mapping.get(
                    'expression',
                    mapping.get('source_expression', mapping.get('logic', source_value)),
                ),
            ) or ''
        ).strip()

        if not tgt_col or 'CONDITION' in tgt_col:
            continue

        src_tbl = ''
        bare_src_col = re.sub(
            r'^[A-Z][A-Z0-9_$#]*\.(.*)$',
            r'\1',
            src_col,
            flags=re.IGNORECASE,
        )

        for src in sources:
            if not isinstance(src, dict):
                continue
            src_name = str(src.get('name', '') or '').strip().upper()
            src_alias = str(src.get('alias', '') or '').strip().upper()
            columns = [str(c or '').strip().upper() for c in src.get('columns', [])]
            if (
                (src_alias and src_col.startswith(f'{src_alias}.'))
                or bare_src_col in columns
                or src_col in columns
                or '*' in columns
            ):
                src_tbl = src_name
                src_col = bare_src_col or src_col
                break

        flat.append({
            'target_table': tgt_tbl,
            'target_column': tgt_col,
            'source_table': src_tbl,
            'source_column': src_col,
            'transformation': transf or 'Direct',
            'actual_transformation': actual or str(source_value or '').strip() or src_col,
        })

    return flat

def normalise_row(raw: dict, obj_name: str) -> dict | None:
    """Convert a raw LLM lineage row to the final CSV structure."""
    if not isinstance(raw, dict):
        return None

    if 'target' in raw and 'target_table' not in raw:
        flat_rows = _extract_flat_rows(raw)
        if not flat_rows:
            return None
        raw = flat_rows[0]

    tgt_tbl = str(raw.get('target_table', '') or '').strip().upper()
    tgt_col = str(raw.get('target_column', '') or '').strip().upper()
    src_tbl = str(raw.get('source_table', '') or '').strip().upper()
    src_col = str(raw.get('source_column', '') or '').strip().upper()
    transf = str(raw.get('transformation', 'Direct') or 'Direct').strip()
    actual = str(
        raw.get(
            'actual_transformation',
            raw.get('expression', raw.get('source_expression', raw.get('logic', ''))),
        ) or ''
    ).strip()

    if not tgt_tbl or not tgt_col:
        return None

    _INTERNAL = re.compile(
        r'^(RS-\d+|RESULT_OF_|INSERT-SELECT-\d+|SELECT-INTO-\d+|MERGE-INSERT-\d+|'
        r'MERGE-UPDATE-\d+|UPDATE-SET-\d+|CTE-\d+|SQL_CONSTANTS|RelationRows)$',
        re.IGNORECASE,
    )
    if _INTERNAL.match(tgt_tbl) or _INTERNAL.match(tgt_col):
        return None

    if tgt_tbl.endswith('_BKP'):
        return None

    # Backward-compatible fallback if a model omits the requested field.
    if not actual:
        actual = src_col if src_col else (transf if transf != 'Constant / Expression' else '')

    obj_type, pkg, proc = _classify(obj_name)
    return {
        'Object Type': obj_type,
        'Package': pkg,
        'Procedure': proc,
        'SQL Object Name': obj_name,
        'Target Table': tgt_tbl,
        'Target Column': tgt_col,
        'Source Table': src_tbl,
        'Source Column': src_col,
        'Transformation': transf or 'Direct',
        'Actual Transformation': actual,
    }

# ── Mode B: transformation-only enrichment for Gudu-resolved objects ───────
# Gudu already resolved target/source columns correctly for these objects —
# we only need the exact SQL expression per target column, not re-discovery.
# One batched call per object/chunk, never per row.

_SYSTEM_ENRICH = """\
You are an expert Oracle SQL lineage analyst.

A separate static-analysis tool already determined which target columns are
populated by DML in the supplied SQL. Your only job is to find, for each
listed target column, the exact SQL expression that computes it.

Return ONLY valid JSON, no markdown. The JSON must have one top-level key
"lineage" whose value is an array of flat objects with exactly these keys:

  "target_table"          : target table/materialized view, UPPER CASE
  "target_column"         : target column, UPPER CASE
  "actual_transformation" : exact SQL expression used to populate the column,
                            preserving functions, CASE logic, operators,
                            aliases, and nesting as written

Rules:
- Only emit rows for target columns from the supplied list that you can
  actually find evidence for in the SQL.
- Do not invent, re-derive, or second-guess source tables/columns — that is
  not part of this task.
- Do not simplify, paraphrase, or invent actual_transformation.
- If none of the listed target columns can be found, return {"lineage": []}.
"""

_USER_ENRICH_TMPL = """\
A static-analysis tool already determined that this SQL populates the
following target columns:

{target_cols}

For each one, return the exact SQL expression that computes it.

SQL Object: {obj_name}

```sql
{sql}
```
"""


def call_llm_enrich(client, deployment: str, obj_name: str, sql_chunk: str,
                    target_columns: list[tuple[str, str]],
                    retries: int = 3, delay: float = 5.0) -> list[dict]:
    """Call the LLM for transformation-only enrichment of already-resolved target columns."""
    sql_clean = _strip_comments(sql_chunk)
    cols_text = '\n'.join(f'- {t}.{c}' for t, c in target_columns)
    user_msg  = _USER_ENRICH_TMPL.format(obj_name=obj_name, sql=sql_clean, target_cols=cols_text)

    for attempt in range(1, retries + 1):
        try:
            response = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": _SYSTEM_ENRICH},
                    {"role": "user",   "content": user_msg},
                ],
                max_completion_tokens=16000,
            )
            choice = response.choices[0]
            raw    = choice.message.content
            if not raw or not raw.strip():
                raise ValueError('Empty response from model')
            data = _extract_json(raw)
            rows = data.get("lineage", [])
            return rows if isinstance(rows, list) else []
        except KeyboardInterrupt:
            raise
        except Exception as e:
            if attempt < retries:
                print(f"      [WARN] Attempt {attempt} failed: {e}. Retrying in {delay}s…")
                time.sleep(delay)
            else:
                print(f"      [ERROR] All {retries} attempts failed: {e}")
                return []


def process_sql_text_enrich(client, deployment: str, obj_name: str, sql: str,
                            target_columns: list[tuple[str, str]]) -> list[dict]:
    """Chunk sql, call the enrichment LLM per chunk, return one row per resolved
    target column (first non-empty match wins across chunks)."""
    chunks = _chunk_sql(sql)
    resolved: dict[tuple[str, str], str] = {}

    for i, chunk in enumerate(chunks, 1):
        if len(chunks) > 1:
            print(f"    chunk {i}/{len(chunks)} ({len(chunk):,} chars)")
        raw_rows = call_llm_enrich(client, deployment, obj_name, chunk, target_columns)
        for raw in raw_rows:
            tgt_tbl = str(raw.get('target_table', '') or '').strip().upper()
            tgt_col = str(raw.get('target_column', '') or '').strip().upper()
            actual  = str(raw.get('actual_transformation', '') or '').strip()
            if not tgt_tbl or not tgt_col or not actual:
                continue
            resolved.setdefault((tgt_tbl, tgt_col), actual)

    obj_type, pkg, proc = _classify(obj_name)
    rows = []
    for (tgt_tbl, tgt_col), actual in resolved.items():
        rows.append({
            'Object Type': obj_type, 'Package': pkg, 'Procedure': proc,
            'SQL Object Name': obj_name,
            'Target Table': tgt_tbl, 'Target Column': tgt_col,
            'Source Table': '', 'Source Column': '',
            'Transformation': '', 'Actual Transformation': actual,
        })
    return rows


_PART_SUFFIX_RE = re.compile(r'_part\d+$', re.IGNORECASE)


def load_gudu_target_columns(gudu_csv_path: str) -> dict[str, list[tuple[str, str]]]:
    """Map base obj_name (part-suffix stripped) -> sorted distinct
    (Target Table, Target Column) pairs already resolved by Gudu."""
    cols: dict[str, set[tuple[str, str]]] = {}
    if not os.path.exists(gudu_csv_path):
        return {}
    with open(gudu_csv_path, newline='', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            obj = str(row.get('SQL Object Name', '') or '').strip()
            if not obj:
                continue
            base = _PART_SUFFIX_RE.sub('', obj).upper()
            tgt_tbl = str(row.get('Target Table', '') or '').strip()
            tgt_col = str(row.get('Target Column', '') or '').strip()
            if not tgt_tbl or not tgt_col:
                continue
            cols.setdefault(base, set()).add((tgt_tbl, tgt_col))
    return {k: sorted(v) for k, v in cols.items()}


def detect_all_cleaned_objects(cleaned_dir: str = _CLEANED) -> dict[str, tuple[str, str]]:
    """Return {obj_name: (combined_sql_text, label)} for every cleaned object
    (grouped part-files combined), regardless of whether Gudu succeeded on it.
    Used to find the complement of detect_failing_cleaned_files() for Mode B."""
    cleaned_dir = os.path.abspath(cleaned_dir)
    all_cleaned = sorted(
        f for f in os.listdir(cleaned_dir) if f.endswith('_cleaned.sql')
    )

    part_re = re.compile(r'^(.+?)_part(\d+)_cleaned$')
    groups: dict[str, list[tuple[int, str]]] = {}
    singles: list[str] = []

    for f in all_cleaned:
        base = os.path.splitext(f)[0]
        m = part_re.match(base)
        if m:
            groups.setdefault(m.group(1), []).append((int(m.group(2)), os.path.join(cleaned_dir, f)))
        else:
            singles.append(os.path.join(cleaned_dir, f))

    result: dict[str, tuple[str, str]] = {}

    for grp_name, parts in groups.items():
        parts.sort(key=lambda x: x[0])
        combined_parts = []
        for _, ppath in parts:
            try:
                combined_parts.append(open(ppath, encoding='utf-8', errors='ignore').read())
            except OSError:
                pass
        combined_sql = '\n\n'.join(combined_parts)
        if not combined_sql.strip() or not _HAS_DML.search(combined_sql):
            continue
        obj_name = _object_name_from_file(grp_name + '_cleaned')
        label = f'{grp_name} ({len(parts)} parts combined, {len(combined_sql):,} chars)'
        result[obj_name] = (combined_sql, label)

    for sql_path in singles:
        try:
            content = open(sql_path, encoding='utf-8', errors='ignore').read()
        except OSError:
            continue
        if not _HAS_DML.search(content):
            continue
        obj_name = _object_name_from_file(os.path.basename(sql_path))
        label = f'{os.path.basename(sql_path)} ({len(content):,} chars)'
        result[obj_name] = (content, label)

    return result


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
            key = (
                row['Target Table'], row['Target Column'],
                row['Source Table'], row['Source Column'],
                row['Transformation'], row['Actual Transformation'],
            )
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
        # all_parts_covered = all(
        #     _json_has_rels(
        #         os.path.join(
        #             cleaned_dir,
        #             os.path.splitext(os.path.basename(ppath))[0] + '_lineage.json',
        #         )
        #     )
        #     for _, ppath in parts
        # )
        # if all_parts_covered:
        #     continue  # every part already has Gudu lineage

        all_parts_covered = all(
            _json_has_rels(
                os.path.join(
                    cleaned_dir,
                    os.path.splitext(os.path.basename(ppath))[0] + '_lineage.json',
                )
            )
            for _, ppath in parts
        )

        # Force large cleaned files through LLM even if Gudu produced
        # some lineage, because the Gudu lineage may be incomplete.
        has_large_part = any(
            os.path.getsize(ppath) > GUDU_LIMIT
            for _, ppath in parts
        )

        if all_parts_covered and not has_large_part:
            continue

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




def duplicate_exg_target_rows(rows: list[dict]) -> list[dict]:
    """
    For every lineage row whose Target Table ends with '_EXG',
    create an exact copy of the row and remove the '_EXG' suffix
    from Target Table.

    Example:
        RPT_POLICY_DTL_R_EXG -> RPT_POLICY_DTL_R

    The original _EXG row is preserved.
    """
    result = list(rows)

    for row in rows:
        target_table = str(row.get('Target Table', '') or '').strip()

        if target_table.upper().endswith('_EXG'):
            copied_row = row.copy()
            copied_row['Target Table'] = target_table[:-4]
            result.append(copied_row)

    return result

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
        '--enrich-gudu', action='store_true',
        help=(
            'Mode B: skip discovery entirely and only extract actual_transformation '
            'for objects Gudu already resolved structurally (the complement of auto mode). '
            'Requires --gudu-csv to already exist (run Stage 3 first).'
        ),
    )
    parser.add_argument(
        '--gudu-csv', metavar='CSV', default=_DEFAULT_GUDU_CSV,
        help=f'Gudu structural lineage CSV used by --enrich-gudu (default: {_DEFAULT_GUDU_CSV})',
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

    # Load LLM client — Bedrock (Claude Sonnet 4) first, Azure (gpt-5-mini) fallback
    if not args.dry_run:
        client, deployment = load_llm_client()
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
    elif args.enrich_gudu:
        # ── Mode B: enrich objects Gudu already resolved structurally ──────
        print(f"Loading Gudu-resolved target columns from:\n  {args.gudu_csv}\n")
        gudu_cols = load_gudu_target_columns(args.gudu_csv)
        if not gudu_cols:
            print("[WARN] No Gudu target columns found — did Stage 3 run first?")

        print(f"Scanning all cleaned objects in:\n  {args.cleaned_dir}\n")
        all_objects = detect_all_cleaned_objects(args.cleaned_dir)

        # Mode B targets = objects Gudu resolved (have target columns) AND are
        # not already covered by the discovery (failing) list.
        failing_names = {obj.upper() for obj, _, _ in detect_failing_cleaned_files(args.cleaned_dir)}
        enrich_tasks = []
        for obj_name, (sql_text, label) in all_objects.items():
            if obj_name.upper() in failing_names:
                continue  # covered by discovery mode instead
            target_cols = gudu_cols.get(obj_name.upper())
            if not target_cols:
                continue  # Gudu has nothing resolved for this object either
            enrich_tasks.append((obj_name, sql_text, label, target_cols))

        if args.only:
            filters = [s.strip().upper() for s in args.only.split(',') if s.strip()]
            enrich_tasks = [
                t for t in enrich_tasks if any(f in t[0].upper() for f in filters)
            ]

        print(f"Found {len(enrich_tasks)} Gudu-resolved object(s) to enrich with actual transformation.\n")
        print("-" * 70)

        if args.dry_run:
            for obj_name, sql_text, label, target_cols in enrich_tasks:
                print(f"  [{len(sql_text):>7,} chars, {len(target_cols)} target cols]  {label}")
            print(f"\n[DRY-RUN] Would enrich {len(enrich_tasks)} object(s).")
            return

        import threading
        from concurrent.futures import ThreadPoolExecutor, as_completed

        _print_lock = threading.Lock()
        _all_rows_lock = threading.Lock()
        total = len(enrich_tasks)
        workers = min(args.workers, total) if total else 1

        def _enrich_one(task):
            i, obj_name, sql_text, label, target_cols = task
            with _print_lock:
                print(f"[{i}/{total}] {label}")
            try:
                rows = process_sql_text_enrich(client, deployment, obj_name, sql_text, target_cols)
            except Exception as exc:
                with _print_lock:
                    print(f"[{i}/{total}] [ERROR] {exc}")
                rows = []
            with _print_lock:
                print(f"[{i}/{total}]   -> {len(rows)} transformation(s) resolved")
            return rows

        indexed_tasks = [
            (i, obj, sql, lbl, cols)
            for i, (obj, sql, lbl, cols) in enumerate(enrich_tasks, 1)
        ]

        try:
            with ThreadPoolExecutor(max_workers=workers) as executor:
                futures = {executor.submit(_enrich_one, t): t[0] for t in indexed_tasks}
                for future in as_completed(futures):
                    rows = future.result()
                    with _all_rows_lock:
                        all_rows.extend(rows)
        except KeyboardInterrupt:
            print(f"\n[INTERRUPTED] Saving {len(all_rows)} rows collected so far…")
    else:
        # ── Auto mode: scan cleaned dir for failing files ─────────────────
        print(f"Scanning for failing cleaned files in:\n  {args.cleaned_dir}\n")
        failing = detect_failing_cleaned_files(args.cleaned_dir)

        # ── Auto mode: also detect Hybrid MAIN procs not yet processed ────
        # Hybrid MAINs have their own DML (INSERT/MERGE/UPDATE) but are skipped
        # by clean_and_run_gudu.py because Gudu can't resolve complex JOINs in
        # large INSERT bodies.  We detect them here and append to the task list.
        # Only honour "already processed" when --append is set: a non-append run
        # overwrites args.output at the end, so skipping an object here while not
        # appending would silently delete it from the final file.
        already_done = _load_already_processed_obj_names(args.output) if args.append else set()
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

        # Create copies of _EXG target rows pointing to the corresponding
        # non-EXG target table.
        #
        # Example:
        # RPT_POLICY_DTL_R_EXG -> RPT_POLICY_DTL_R
        all_rows = duplicate_exg_target_rows(all_rows)

        # Deduplicate across files (same target/source can appear in multiple parts)
        seen = set()
        deduped = []

        for row in all_rows:
            key = (
                row['SQL Object Name'], row['Target Table'], row['Target Column'],
                row['Source Table'], row['Source Column'],
                row['Transformation'], row['Actual Transformation'],
            )
            if key not in seen:
                seen.add(key)
                deduped.append(row)

        deduped.sort(key=lambda r: (
            r['Object Type'], r['Package'], r['Procedure'],
            r['Target Table'], r['Target Column'],
            r['Source Table'], r['Source Column'],
            r['Transformation'], r['Actual Transformation'],
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
