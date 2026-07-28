"""
Clean Oracle PL/SQL scripts for data lineage analysis via Gudu SQLFlow.

This script:
1. Removes single-line comments (-- ...)
2. Removes multi-line block comments (/* ... */)
3. Strips PL/SQL boilerplate that doesn't affect lineage:
   - Variable/type/cursor-type declarations
   - Logging calls (PKG_GRP_LOG_UTIL.*, FCT_PROC_EXEC_STATUS_LOG_R, etc.)
   - COMMIT / SAVEPOINT / ROLLBACK
   - EXECUTE IMMEDIATE (TRUNCATE/ALTER/GATHER STATS)
   - DBMS_STATS, DBMS_MVIEW, DBMS_OUTPUT calls
   - EXCEPTION WHEN OTHERS blocks
   - RAISE / RAISE_APPLICATION_ERROR
   - Control flow wrappers (IF/ELSIF/ELSE/END IF, LOOP/END LOOP, EXIT WHEN)
   - OPEN/FETCH/CLOSE cursor statements
   - FORALL ... wrappers (keeps the inner DML)
   - BEGIN/END blocks (outer wrappers)
4. Extracts core DML statements: INSERT...SELECT, UPDATE...SET, MERGE, DELETE...WHERE
5. For cursor-based patterns, reconstructs lineage-equivalent INSERT/UPDATE from cursor SELECT + FORALL target
6. Supports CREATE MATERIALIZED VIEW / CREATE VIEW DDL files (strips Oracle storage params, keeps AS SELECT)
7. Splits large files into <=10K char chunks for Gudu lite
8. Can process a single file, a directory, or batch all split procs

Usage:
    # Clean a single file
    python clean_and_run_gudu.py -f path/to/proc.sql

    # Clean all files in a directory (PRC + MView files, skip PKG)
    python clean_and_run_gudu.py -d path/to/Rest_Metadata_7RPT/ --exclude-prefix PKG

    # Clean + run Gudu lineage
    python clean_and_run_gudu.py -d path/to/split_procs/ -r

    # Specify output directory
    python clean_and_run_gudu.py -d path/to/split_procs/ -o path/to/output/
"""

import re
import os
import sys
import glob
import subprocess
import argparse


# ---------------------------------------------------------------------------
# Comment removal
# ---------------------------------------------------------------------------

def remove_block_comments(sql: str) -> str:
    """Remove /* ... */ block comments, handling nesting and respecting string literals."""
    result = []
    i = 0
    in_string = False
    while i < len(sql):
        if not in_string and sql[i] == "'":
            in_string = True
            result.append(sql[i])
            i += 1
        elif in_string and sql[i] == "'":
            if i + 1 < len(sql) and sql[i + 1] == "'":
                result.append(sql[i])
                result.append(sql[i + 1])
                i += 2
            else:
                in_string = False
                result.append(sql[i])
                i += 1
        elif not in_string and sql[i:i+2] == '/*':
            depth = 1
            i += 2
            while i < len(sql) and depth > 0:
                if sql[i:i+2] == '/*':
                    depth += 1
                    i += 2
                elif sql[i:i+2] == '*/':
                    depth -= 1
                    i += 2
                else:
                    i += 1
        else:
            result.append(sql[i])
            i += 1
    return ''.join(result)


def remove_line_comments(sql: str) -> str:
    """Remove single-line -- comments, preserving string literals."""
    lines = sql.split('\n')
    cleaned = []
    for line in lines:
        new_line = []
        in_string = False
        i = 0
        while i < len(line):
            if not in_string and line[i] == "'":
                in_string = True
                new_line.append(line[i])
                i += 1
            elif in_string and line[i] == "'":
                if i + 1 < len(line) and line[i + 1] == "'":
                    new_line.append(line[i])
                    new_line.append(line[i + 1])
                    i += 2
                else:
                    in_string = False
                    new_line.append(line[i])
                    i += 1
            elif not in_string and line[i:i+2] == '--':
                break
            else:
                new_line.append(line[i])
                i += 1
        cleaned.append(''.join(new_line))
    return '\n'.join(cleaned)


# ---------------------------------------------------------------------------
# Statement splitter
# ---------------------------------------------------------------------------

def split_statements(sql: str) -> list:
    """Split SQL into statements by semicolons, respecting string literals and parens."""
    statements = []
    current = []
    in_string = False
    paren_depth = 0
    i = 0
    while i < len(sql):
        ch = sql[i]
        if not in_string and ch == "'":
            in_string = True
            current.append(ch)
            i += 1
        elif in_string and ch == "'":
            if i + 1 < len(sql) and sql[i + 1] == "'":
                current.append(ch)
                current.append(sql[i + 1])
                i += 2
            else:
                in_string = False
                current.append(ch)
                i += 1
        elif not in_string and ch == '(':
            paren_depth += 1
            current.append(ch)
            i += 1
        elif not in_string and ch == ')':
            paren_depth -= 1
            current.append(ch)
            i += 1
        elif not in_string and ch == ';' and paren_depth <= 0:
            stmt = ''.join(current).strip()
            if stmt:
                statements.append(stmt)
            current = []
            paren_depth = 0
            i += 1
        else:
            current.append(ch)
            i += 1
    stmt = ''.join(current).strip()
    if stmt:
        statements.append(stmt)
    return statements


# ---------------------------------------------------------------------------
# Boilerplate detection
# ---------------------------------------------------------------------------

# Patterns that indicate a statement references logging/utility objects
BOILERPLATE_CONTENT_PATTERNS = [
    re.compile(r'\bPKG_GRP_LOG_UTIL\b', re.IGNORECASE),
    re.compile(r'\bFNC_GRP_TIME_DURATION\b', re.IGNORECASE),
    re.compile(r'\bDBMS_STATS\b', re.IGNORECASE),
    re.compile(r'\bDBMS_MVIEW\b', re.IGNORECASE),
    re.compile(r'\bDBMS_OUTPUT\b', re.IGNORECASE),
    re.compile(r'\bDBMS_UTILITY\b', re.IGNORECASE),
    re.compile(r'\bFCT_PROC_EXEC_STATUS_LOG_R\b', re.IGNORECASE),
    re.compile(r'\bPRCS_JOB_LOG_MESSAGE_R\b', re.IGNORECASE),
    re.compile(r'\bPRCS_JOB_LOG_R\b', re.IGNORECASE),
    re.compile(r'\bSEQ_FCT_PROC_EXEC_STATUS_LOG_R\b', re.IGNORECASE),
    re.compile(r'\bPKG_GRP_COMMON_UTIL\b', re.IGNORECASE),
    # Debug / audit trace tables — no business logic, skip
    re.compile(r'\b\w*DEBUG_TRC\w*\b', re.IGNORECASE),
    re.compile(r'\bPRCS_GRP_TBL_LOAD_DEBUG_TRC\b', re.IGNORECASE),
]

# Statement-level patterns to skip entirely (matched at start of statement)
SKIP_STATEMENT_START_PATTERNS = [
    # COMMIT/SAVEPOINT/ROLLBACK
    re.compile(r'^\s*COMMIT\b', re.IGNORECASE),
    re.compile(r'^\s*SAVEPOINT\s+', re.IGNORECASE),
    re.compile(r'^\s*ROLLBACK\b', re.IGNORECASE),
    # RAISE
    re.compile(r'^\s*RAISE\b', re.IGNORECASE),
    re.compile(r'^\s*RAISE_APPLICATION_ERROR\b', re.IGNORECASE),
    # Control flow
    re.compile(r'^\s*IF\s+', re.IGNORECASE),
    re.compile(r'^\s*ELSIF\s+', re.IGNORECASE),
    re.compile(r'^\s*ELSE\s*$', re.IGNORECASE),
    re.compile(r'^\s*END\s+IF\b', re.IGNORECASE),
    re.compile(r'^\s*END\s+LOOP\b', re.IGNORECASE),
    re.compile(r'^\s*LOOP\s*$', re.IGNORECASE),
    re.compile(r'^\s*EXIT\s+WHEN\b', re.IGNORECASE),
    re.compile(r'^\s*FOR\s+\w+\s+IN\s+', re.IGNORECASE),
    re.compile(r'^\s*WHILE\s+', re.IGNORECASE),
    # OPEN/FETCH/CLOSE cursor
    re.compile(r'^\s*OPEN\s+', re.IGNORECASE),
    re.compile(r'^\s*FETCH\s+', re.IGNORECASE),
    re.compile(r'^\s*CLOSE\s+', re.IGNORECASE),
    # BEGIN/END wrappers
    re.compile(r'^\s*BEGIN\s*$', re.IGNORECASE),
    re.compile(r'^\s*END\s*$', re.IGNORECASE),
    re.compile(r'^\s*END\s+\w+\s*$', re.IGNORECASE),
    # NULL statement
    re.compile(r'^\s*NULL\s*$', re.IGNORECASE),
    # EXECUTE IMMEDIATE for non-DML (DDL that has NO lineage)
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bTRUNCATE\b', re.IGNORECASE | re.DOTALL),
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bALTER\s+SESSION\b', re.IGNORECASE | re.DOTALL),
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bALTER\s+INDEX\b', re.IGNORECASE | re.DOTALL),
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bGATHER\b', re.IGNORECASE | re.DOTALL),
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bENABLE\s+PARALLEL\b', re.IGNORECASE | re.DOTALL),
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bDISABLE\s+PARALLEL\b', re.IGNORECASE | re.DOTALL),
    # DROP TABLE has no lineage
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bDROP\s+TABLE\b', re.IGNORECASE | re.DOTALL),
    # CREATE INDEX has no lineage
    re.compile(r'^\s*EXECUTE\s+IMMEDIATE\s+.*\bCREATE\s+(UNIQUE\s+)?INDEX\b', re.IGNORECASE | re.DOTALL),
    # FORALL wrapper line only (DML inside is kept separately)
    re.compile(r'^\s*FORALL\s+\w+\s+IN\s+', re.IGNORECASE),
    # PROCEDURE/FUNCTION declaration header
    re.compile(r'^\s*PROCEDURE\s+\w+', re.IGNORECASE),
    re.compile(r'^\s*FUNCTION\s+\w+', re.IGNORECASE),
    # EXCEPTION handling
    re.compile(r'^\s*EXCEPTION\s*$', re.IGNORECASE),
    re.compile(r'^\s*WHEN\s+(OTHERS|NO_DATA_FOUND|DUP_VAL_ON_INDEX|TOO_MANY_ROWS)\s+THEN', re.IGNORECASE),
    # IS/AS at procedure start
    re.compile(r'^\s*IS\s*$', re.IGNORECASE),
    re.compile(r'^\s*AS\s*$', re.IGNORECASE),
    # RETURN statements
    re.compile(r'^\s*RETURN\b', re.IGNORECASE),
]


def is_variable_declaration(stmt: str) -> bool:
    """Check if a statement is a PL/SQL variable/constant/type declaration."""
    stripped = stmt.strip()
    upper = stripped.upper()

    # Variable declarations: name TYPE := value  or  name TYPE;
    if re.match(r'^\s*\w+\s+(VARCHAR2|NUMBER|DATE|PLS_INTEGER|BOOLEAN|TIMESTAMP|CLOB|BLOB|INTEGER|CONSTANT|BINARY_INTEGER)\b',
                upper):
        return True

    # Typed variable: name TABLE_NAME.COLUMN%TYPE
    if re.match(r'^\s*\w+\s+\w+(\.\w+)?%TYPE\b', upper):
        return True
    if re.match(r'^\s*\w+\s+\w+%ROWTYPE\b', upper):
        return True

    # TYPE declarations
    if re.match(r'^\s*TYPE\s+\w+\s+IS\s+(TABLE|RECORD|REF\s+CURSOR|VARRAY)\b', upper):
        return True

    # CURSOR declarations (handled separately for lineage)
    if re.match(r'^\s*CURSOR\s+\w+', upper):
        return True

    # Simple variable assignments (not containing DML keywords)
    if re.match(r'^\s*\w+\s*:=\s*', stripped):
        if not re.search(r'\b(INSERT|UPDATE|DELETE|MERGE|SELECT)\b', upper):
            return True

    # Package constant patterns: gc_, gv_, gn_, gt_, ln_, lc_, ld_
    if re.match(r'^\s*(g[cvntd]_|l[cnvtd]_|lt_)\w+\s*(:=|CONSTANT|\w+)', stripped, re.IGNORECASE):
        if not re.search(r'\b(INSERT|UPDATE|DELETE|MERGE|SELECT)\b', upper):
            return True

    return False


def is_boilerplate(stmt: str) -> bool:
    """Check if a statement is boilerplate to remove."""
    stripped = stmt.strip()
    if not stripped:
        return True

    # Check content patterns (logging references)
    for pat in BOILERPLATE_CONTENT_PATTERNS:
        if pat.search(stripped):
            return True

    # Check statement-level skip patterns
    for pat in SKIP_STATEMENT_START_PATTERNS:
        if pat.search(stripped):
            return True

    # Variable/type declarations
    if is_variable_declaration(stripped):
        return True

    # String concatenation assignments (typically building trace messages)
    upper = stripped.upper()
    if re.match(r'^\s*\w+\s*:=\s*\w+\s*\|\|', stripped) and 'SELECT' not in upper:
        return True

    # Pure string literal assignments (trace/error messages)
    if re.match(r"^\s*\w+\s*:=\s*'[^']*'\s*$", stripped):
        return True

    return False


def is_dml_statement(stmt: str) -> bool:
    """Check if a statement contains lineage-relevant DML."""
    upper = stmt.strip().upper()
    # INSERT INTO / INSERT /*+ hint */ INTO
    if re.search(r'\bINSERT\s+(/\*.*?\*/\s*)?INTO\b', upper, re.DOTALL):
        return True
    # UPDATE table SET
    if re.search(r'\bUPDATE\s+\w+', upper):
        return True
    # DELETE FROM
    if re.search(r'\bDELETE\s+(FROM\s+)?\w+', upper):
        return True
    # MERGE INTO
    if re.search(r'\bMERGE\s+INTO\b', upper):
        return True
    return False


# ---------------------------------------------------------------------------
# Exception block removal
# ---------------------------------------------------------------------------

def remove_exception_blocks(sql: str) -> str:
    """Remove EXCEPTION WHEN OTHERS THEN ... END blocks."""
    result = re.sub(
        r'\bEXCEPTION\s+WHEN\s+\w+\s+THEN\b.*?(?=\bEND\s+\w+\s*;|\bEND\s*;)',
        '', sql, flags=re.DOTALL | re.IGNORECASE
    )
    return result


# ---------------------------------------------------------------------------
# MView / View DDL detection and cleaning
# ---------------------------------------------------------------------------

def _first_top_level_semicolon(sql: str) -> int:
    """
    Return the index of the first semicolon that sits at top-level scope
    (i.e. not inside parentheses or single-quoted strings).
    Returns len(sql) if none is found.
    """
    depth = 0
    in_str = False
    i = 0
    while i < len(sql):
        c = sql[i]
        if in_str:
            if c == "'":
                if i + 1 < len(sql) and sql[i + 1] == "'":
                    i += 1  # escaped '' inside string
                else:
                    in_str = False
        else:
            if c == "'":
                in_str = True
            elif c == '(':
                depth += 1
            elif c == ')':
                depth = max(depth - 1, 0)
            elif c == ';' and depth == 0:
                return i
        i += 1
    return len(sql)


def _split_union_all_branches(select_body: str) -> list:
    """
    Split a SELECT body at top-level UNION / UNION ALL keywords
    (not inside parentheses or single-quoted strings).
    Returns a list of individual branch strings.
    Returns [select_body] unchanged if no top-level UNION is found.
    """
    depth = 0
    in_str = False
    split_points = []  # list of (union_start, next_select_start)
    i = 0
    n = len(select_body)
    while i < n:
        c = select_body[i]
        if in_str:
            if c == "'":
                if i + 1 < n and select_body[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
        else:
            if c == "'":
                in_str = True
            elif c == '(':
                depth += 1
            elif c == ')':
                depth = max(depth - 1, 0)
            elif depth == 0 and select_body[i:i+5].upper() == 'UNION':
                # Verify left word boundary
                if i == 0 or not (select_body[i - 1].isalnum() or select_body[i - 1] == '_'):
                    after_union = i + 5
                    # Verify right word boundary
                    if after_union >= n or not (select_body[after_union].isalnum() or select_body[after_union] == '_'):
                        end = after_union
                        while end < n and select_body[end] in ' \t\r\n':
                            end += 1
                        # Absorb optional ALL
                        if select_body[end:end + 3].upper() == 'ALL' and (
                                end + 3 >= n or not (select_body[end + 3].isalnum() or select_body[end + 3] == '_')):
                            end += 3
                            while end < n and select_body[end] in ' \t\r\n':
                                end += 1
                        split_points.append((i, end))
                        i = end
                        continue
        i += 1

    if not split_points:
        return [select_body]

    branches = []
    prev_start = 0
    for union_start, next_start in split_points:
        branches.append(select_body[prev_start:union_start].strip())
        prev_start = next_start
    branches.append(select_body[prev_start:].strip())
    return [b for b in branches if b]


def _extract_union_view_branches(cleaned_sql: str, base_name: str) -> list:
    """
    If cleaned_sql is a CREATE VIEW ... AS SELECT ... UNION [ALL] SELECT ...
    with multiple branches, return list of (branch_name, branch_sql) tuples.
    Returns an empty list if no top-level UNION branches are found.
    Each branch_sql is a standalone CREATE VIEW <view_name> AS <branch_select>;
    """
    as_match = re.search(r'\bAS\s+(SELECT\b)', cleaned_sql, re.IGNORECASE)
    if not as_match:
        return []
    select_body = cleaned_sql[as_match.start(1):].rstrip().rstrip(';').strip()

    branches = _split_union_all_branches(select_body)
    if len(branches) <= 1:
        return []

    # Extract the full CREATE VIEW header (includes column list if present) up to AS SELECT.
    # e.g.  "CREATE VIEW FCT_CLAIM_PAYMENT_DETAIL_R (V_CLAIM_NUMBER_R, ...) "
    create_start = cleaned_sql.upper().find('CREATE VIEW')
    if create_start == -1:
        create_start = cleaned_sql.upper().find('CREATE MATERIALIZED VIEW')
    create_view_header = cleaned_sql[create_start:as_match.start()].strip() if create_start != -1 else f'CREATE VIEW {base_name}'

    result = []
    for idx, branch in enumerate(branches, 1):
        bname = f"{base_name}_union_{idx}"
        bsql = (
            f"-- Cleaned for lineage: {bname} (UNION branch {idx}/{len(branches)})\n\n"
            f"{create_view_header} AS\n{branch};"
        )
        result.append((bname, bsql))
    return result


def detect_file_type(sql: str) -> str:
    """
    Detect whether a SQL file is:
      'mview'  - CREATE MATERIALIZED VIEW ... AS SELECT
      'view'   - CREATE [OR REPLACE] [FORCE] VIEW ... AS SELECT
      'plsql'  - PL/SQL procedure/package body (default)
    """
    stripped = sql.strip()
    upper    = stripped.upper()
    # Leading whitespace / comments before CREATE is handled by strip
    if re.match(r'\s*CREATE\s+MATERIALIZED\s+VIEW\b', upper):
        return 'mview'
    if re.match(r'\s*CREATE\s+(?:OR\s+REPLACE\s+)?(?:(?:FORCE|NOFORCE)\s+)?(?:(?:EDITIONABLE|NONEDITIONABLE)\s+)?VIEW\b', upper):
        return 'view'
    return 'plsql'


def _qualify_mview_columns(sql: str) -> str:
    """
    Use sqlglot to add the driving-table alias qualifier to bare (unqualified)
    column references inside a CREATE MATERIALIZED VIEW / CREATE VIEW statement.

    Example: ``sum(n_paid_claim_benefits_r)`` becomes ``sum(a.n_paid_claim_benefits_r)``
    so that Gudu SQLFlow can trace the column back to its source table.

    Only qualifies columns that have no existing table qualifier.  Uses the
    first table listed in the FROM clause as the "driving" table alias.
    Returns the original SQL unchanged if parsing fails or no driving table
    can be identified.
    """
    try:
        import sqlglot
        import sqlglot.expressions as exp

        stmt = sqlglot.parse_one(sql, dialect='oracle')
        if stmt is None:
            return sql

        sel = stmt.find(exp.Select)
        from_clause = sel.find(exp.From) if sel else None
        first_table = from_clause.find(exp.Table) if from_clause else None
        if not first_table:
            return sql

        driving_alias = first_table.alias or first_table.name
        if not driving_alias:
            return sql

        for col in stmt.find_all(exp.Column):
            if not col.table:
                col.set('table', exp.Identifier(this=driving_alias, quoted=False))

        return stmt.sql(dialect='oracle', pretty=True)
    except Exception:
        return sql


def clean_mview_for_lineage(sql: str, source_name: str = '') -> str:
    """
    Extract a clean CREATE MATERIALIZED VIEW / CREATE VIEW statement from
    Oracle DDL that contains physical storage parameters.

    Strips: SEGMENT CREATION, TABLESPACE, STORAGE(...), PCTFREE, BUILD IMMEDIATE,
            REFRESH ..., USING ... constraints clauses, column-name list, etc.
    Keeps:  CREATE MATERIALIZED VIEW <name> AS <SELECT ...>;
    """
    # Remove comments
    sql = remove_block_comments(sql)
    sql = remove_line_comments(sql)

    # Determine view type
    is_mview = bool(re.search(r'CREATE\s+MATERIALIZED\s+VIEW', sql, re.IGNORECASE))
    view_type = 'MATERIALIZED VIEW' if is_mview else 'VIEW'

    # Extract object name — handle "SCHEMA"."NAME" or just NAME
    name_match = re.search(
        r'CREATE\s+(?:OR\s+REPLACE\s+)?(?:(?:FORCE|NOFORCE)\s+)?(?:(?:EDITIONABLE|NONEDITIONABLE)\s+)?(?:MATERIALIZED\s+)?VIEW\s+'
        r'(?:"[^"]+"\."([^"]+)"|"([^"]+)"|(\w+))',
        sql, re.IGNORECASE
    )
    obj_name = source_name
    if name_match:
        obj_name = name_match.group(1) or name_match.group(2) or name_match.group(3) or source_name

    # Find the AS that directly precedes the SELECT keyword
    # (not column aliases inside the column list at the top)
    as_select_match = re.search(r'\bAS\s+(SELECT\b)', sql, re.IGNORECASE)
    if not as_select_match:
        return ''

    select_body = sql[as_select_match.start(1):].strip()
    # Cut at the first top-level semicolon to exclude trailing DDL
    # (CREATE INDEX, COMMENT ON, GRANT, etc.) that often follows the view body.
    end_idx = _first_top_level_semicolon(select_body)
    select_body = select_body[:end_idx].strip()

    # Extract the column alias list from the CREATE VIEW header (plain views only).
    # This preserves the declared column names so Gudu maps CAST/TRIM expressions
    # to the correct column name rather than using the raw expression text.
    # e.g.  CREATE VIEW name (V_PAY_METHOD_R, V_PAYMENT_TYPE_R, ...) AS SELECT ...
    col_list_spec = ''
    if not is_mview and name_match:
        # Everything between the object name match and the AS SELECT is the column list
        between = sql[name_match.end():as_select_match.start()].strip()
        if between.startswith('('):
            quoted_cols = re.findall(r'"([^"]+)"', between)
            if quoted_cols:
                col_list_spec = f' ({", ".join(quoted_cols)})'

    result = f'CREATE {view_type} {obj_name}{col_list_spec} AS\n{select_body};'

    # Qualify bare column references for single-SELECT views only.
    # UNION ALL views have per-branch FROM clauses; cross-branch qualification would be wrong.
    if len(_split_union_all_branches(select_body)) <= 1:
        result = _qualify_mview_columns(result)

    if source_name:
        result = f'-- Cleaned for lineage: {source_name}\n\n' + result
    return result


# ---------------------------------------------------------------------------
# Cursor-based lineage extraction
# ---------------------------------------------------------------------------

def _infer_target_from_source_name(source_name: str) -> str:
    """
    Infer the target table name from a proc label like
    'PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST_PRC_GET_CUR_DATA'.
    Strips the 'PKG_GRP_LOAD_' prefix and the trailing '_PRC_...' suffix.
    Returns empty string if the pattern doesn't match.
    """
    # Remove trailing _PRC_... (or _INC_PRC_... etc.)
    s = re.sub(r'_PRC_\w+$', '', source_name, flags=re.IGNORECASE)
    # Remove PKG_GRP_LOAD_ prefix
    s = re.sub(r'^PKG_GRP_LOAD_', '', s, flags=re.IGNORECASE)
    return s.upper() if s else ''


def extract_cursor_lineage(sql: str, source_name: str = '') -> list:
    """
    Extract lineage from cursor-based patterns:
      CURSOR cur_name IS SELECT ... FROM ...;
      OPEN var FOR SELECT ... (REF CURSOR assignment)

    For bulk collect + FORALL UPDATE patterns, we reconstruct a synthetic
    UPDATE ... SET ... (SELECT ...) to express the lineage.

    Returns list of synthetic SQL strings.
    """
    synthetic = []

    # Find CURSOR ... IS SELECT ... patterns (terminated by semicolons)
    # Use a simpler approach: find CURSOR keyword, then grab until the closing semicolon
    cursor_pattern = re.compile(
        r'\bCURSOR\s+(\w+)\s*(?:\([^)]*\))?\s*IS\s*(SELECT\b.+?);',
        re.DOTALL | re.IGNORECASE
    )

    # Find FORALL ... UPDATE/INSERT patterns to map cursor -> target
    forall_update_pattern = re.compile(
        r'FORALL\s+\w+\s+IN\s+[^)]+\)\s*(UPDATE|INSERT)\s+(\w+)',
        re.IGNORECASE
    )
    # Also direct UPDATE after loop
    loop_update_pattern = re.compile(
        r'(UPDATE)\s+(\w+)\s+.*?SET\s+.*?(\w+)\s*\(\s*\w+\s*\)',
        re.DOTALL | re.IGNORECASE
    )

    # ── REF CURSOR: OPEN var FOR SELECT ... ──────────────────────────────
    open_for_pattern = re.compile(
        r'\bOPEN\s+\w+\s+FOR\s+(SELECT\b.+?);',
        re.DOTALL | re.IGNORECASE
    )
    for of_match in open_for_pattern.finditer(sql):
        select_sql = of_match.group(1).strip()
        # Try to find an INSERT INTO target in the same proc body
        ins_match = re.search(
            r'\bINSERT\s+(?:/\*[^*]*\*/\s*)?INTO\s+(\w+)\b',
            sql, re.IGNORECASE
        )
        if ins_match:
            target = ins_match.group(1).upper()
        else:
            target = _infer_target_from_source_name(source_name)
        if target:
            synthetic.append(
                f"-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO {target})\n"
                f"INSERT INTO {target}\n{select_sql};"
            )
        else:
            # No target available — keep bare SELECT so Gudu can find source tables
            synthetic.append(select_sql + ';')

    # ── Named cursors: CURSOR name IS SELECT ... ───────────────────────────
    cursors_found = {}
    for match in cursor_pattern.finditer(sql):
        cursor_name = match.group(1).upper()
        select_sql = match.group(2).strip()
        cursors_found[cursor_name] = select_sql

    # For each cursor, check if there's a corresponding UPDATE/INSERT referencing it
    for cursor_name, select_sql in cursors_found.items():
        # Look for UPDATE target ... cursor_name pattern
        update_ref = re.search(
            r'\b(UPDATE|INSERT\s+INTO)\s+(\w+)[\s\S]{0,500}?' + cursor_name.lower(),
            sql, re.IGNORECASE
        )
        if update_ref:
            dml_type = update_ref.group(1).upper()
            target_table = update_ref.group(2).upper()
            synthetic.append(
                f"-- Lineage: Cursor {cursor_name} -> {dml_type} {target_table}\n"
                f"-- Source query:\n{select_sql};"
            )
        else:
            # Cursor exists but no clear target mapping found — still include the SELECT
            # as it shows data sources (target is implied from procedure context)
            synthetic.append(
                f"-- Lineage: Cursor {cursor_name} (target inferred from procedure)\n"
                f"{select_sql};"
            )

    return synthetic


# ---------------------------------------------------------------------------
# Package body splitting
# Mirrors split_pkg_procs.py logic, adapted to work inline on raw SQL strings
# ---------------------------------------------------------------------------

_SKIP_PROCS = {
    "PRC_REBUILD_INDEXES", "PRC_TRUNC_PARTITION",
    "PRC_DEBUG_TRACE", "PRC_DEBUG_EXEC_TIME"
}

# Entire packages to skip — generic DIFW framework packages have no RPT-specific lineage
# Also skip files whose *filename* doesn't match their package name (e.g. a package body
# saved under the procedure name — its content is already covered by the correctly-named PKG file).
_SKIP_PACKAGES = {
    "PKG_GRP_LOAD_DIFW",
    "PKG_GRP_LOAD_DIFW_PD",
    # Duplicate: same package body as PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R,
    # but saved with the inner procedure name as the filename.
    "PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R",
}


def detect_package_body(sql: str) -> bool:
    """Return True if the SQL is an Oracle package body (CREATE [OR REPLACE] [EDITIONABLE] PACKAGE BODY)."""
    return bool(re.search(
        r'\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:EDITIONABLE\s+|NONEDITIONABLE\s+)?PACKAGE\s+BODY\b',
        sql, re.IGNORECASE
    ))


def _pkg_extract_header(lines: list) -> str:
    """Extract package-level variable/constant declarations as a comment block."""
    header_lines = []
    in_decl = False
    for line in lines:
        stripped = line.strip().upper()
        if re.match(r'^(IS|AS)\s*$', stripped):
            in_decl = True
            continue
        if in_decl:
            if re.match(r'^\s*(PROCEDURE|FUNCTION)\s+', line, re.IGNORECASE):
                break
            header_lines.append(line)
    if not header_lines:
        return ''
    block = '-- Package-level declarations (context only):\n'
    for hl in header_lines:
        s = hl.strip()
        if s:
            block += f'--   {s}\n'
    return block


def _pkg_find_proc_boundaries(lines: list) -> list:
    """
    Find start/end line indices for each PROCEDURE in a package body.
    Returns list of dicts: {name, start_idx, end_idx, commented}
    """
    proc_starts = []
    in_block_comment = False
    for i, line in enumerate(lines):
        if '/*' in line and '*/' not in line:
            in_block_comment = True
        if '*/' in line:
            in_block_comment = False
        is_commented = in_block_comment or line.strip().startswith('--')
        m = re.match(r'^\s*PROCEDURE\s+(\w+)', line, re.IGNORECASE)
        if m:
            proc_starts.append({
                'name': m.group(1).upper(),
                'start_idx': i,
                'commented': is_commented
            })

    procedures = []
    for idx, proc in enumerate(proc_starts):
        if proc['commented']:
            proc['end_idx'] = None
            procedures.append(proc)
            continue

        proc_name = proc['name']
        start = proc['start_idx']
        end_idx = None
        begin_count = 0
        found_first_begin = False
        in_block_comment = False  # track /* ... */ to avoid counting commented BEGIN/END

        for j in range(start, len(lines)):
            raw_line = lines[j]
            stripped = raw_line.strip().upper()
            if stripped.startswith('--'):
                continue
            # Handle block comments: lines inside /* ... */ are invisible to BEGIN/END tracking
            if in_block_comment:
                if '*/' in stripped:
                    in_block_comment = False
                continue
            if '/*' in stripped:
                if '*/' not in stripped[stripped.index('/*') + 2:]:
                    in_block_comment = True
                    continue
            # END PROC_NAME; — exact match wins immediately
            if re.match(r'^\s*END\s+' + re.escape(proc_name) + r'\s*;', stripped):
                end_idx = j
                break
            # Count BEGINs
            if re.search(r'\bBEGIN\b', stripped):
                begin_count += 1
                found_first_begin = True
            # END; at nesting level 0
            if found_first_begin and re.match(r'^\s*END\s*;', stripped):
                begin_count -= 1
                if begin_count <= 0:
                    end_idx = j
                    break

        if end_idx is None:
            if idx + 1 < len(proc_starts):
                end_idx = proc_starts[idx + 1]['start_idx'] - 1
            else:
                for j in range(len(lines) - 1, start, -1):
                    if re.match(r'^\s*END\s+\w+\s*;', lines[j].strip(), re.IGNORECASE):
                        end_idx = j - 1
                        break
                if end_idx is None:
                    end_idx = len(lines) - 1

        proc['end_idx'] = end_idx
        procedures.append(proc)

    return procedures


def _pkg_has_orchestrator_main(procedures: list) -> bool:
    """Return True if package has a MAIN that calls other procs (orchestrator pattern)."""
    active = [p for p in procedures if not p['commented'] and p['end_idx'] is not None]
    names = {p['name'] for p in active}
    non_main = [n for n in names if n != 'MAIN' and n not in _SKIP_PROCS]
    return 'MAIN' in names and len(non_main) > 0


def split_package_into_procs(raw_sql: str, pkg_name: str, output_dir: str) -> list:
    """
    Split a package body into individual procedure files (one per proc),
    then clean each for lineage.

    Returns list of (proc_file_name, output_path, char_count) tuples —
    same format as clean_sql_file — ready for Gudu.
    """
    lines = raw_sql.splitlines(keepends=True)
    header_comment = _pkg_extract_header(lines)
    procedures = _pkg_find_proc_boundaries(lines)
    is_orch = _pkg_has_orchestrator_main(procedures)

    output_files = []
    extracted = 0
    skipped = 0

    for proc in procedures:
        proc_name = proc['name']

        if proc['commented'] or proc['end_idx'] is None:
            skipped += 1
            continue

        # Skip utility / orchestrator MAIN
        if proc_name in _SKIP_PROCS:
            print(f'    [SKIP utility] {proc_name}')
            skipped += 1
            continue
        if proc_name == 'MAIN' and is_orch:
            # Peek at the proc body to decide whether MAIN is a pure orchestrator
            # (no DML — just calls children) or a Hybrid (has its own INSERT/MERGE/UPDATE
            # DML in addition to calling children).
            # Pure orchestrator MAIN: skip here — child procs handle all data movement.
            # Hybrid MAIN: also skip from Gudu (the INSERT is too large / too complex for
            # Gudu to resolve), but log it clearly so llm_lineage_extractor.py's
            # auto-detection picks it up.
            _main_proc_lines = lines[proc['start_idx']: proc['end_idx'] + 1]
            _main_proc_body  = ''.join(_main_proc_lines)
            _main_has_dml = bool(re.search(
                r'\b(INSERT\s+(?:/\*[^*]*\*/\s*)?INTO|MERGE\s+INTO|UPDATE\s+\w)\b',
                _main_proc_body, re.IGNORECASE,
            ))
            if _main_has_dml:
                print(f'    [SKIP hybrid MAIN → LLM will handle] {proc_name}')
            else:
                print(f'    [SKIP orchestrator MAIN] {proc_name}')
            skipped += 1
            continue

        # Extract procedure body
        proc_lines = lines[proc['start_idx']: proc['end_idx'] + 1]
        proc_body = ''.join(proc_lines)

        # Build source SQL: header context + proc body
        raw_proc_sql = (
            f'-- Source Package: {pkg_name}\n'
            f'-- Procedure: {proc_name}\n'
            f'-- {"=" * 70}\n'
            f'{header_comment}'
            f'-- {"=" * 70}\n\n'
            f'{proc_body}\n'
        )

        # Clean for lineage
        proc_label = f'{pkg_name}_{proc_name}'

        # ── Source-concept dispatcher: split proc into one file per branch ────
        # e.g. PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R dispatches on LC_SOURCE_CONCEPT
        # (set from IN_TYPE shell parameter) using equality/LIKE guards.
        if detect_source_concept_dispatcher(proc_body):
            sc_branches = extract_source_concept_branches(proc_body)
            if sc_branches:
                print(f'    [SC_DISPATCH] {proc_label} - {len(sc_branches)} source-concept branches')
                for concept_key, branch_sql in sc_branches:
                    branch_name = f'{proc_label}__{concept_key}'
                    char_count = len(branch_sql)
                    if char_count <= 10000:
                        out_path = os.path.join(output_dir, f'{branch_name}_cleaned.sql')
                        with open(out_path, 'w', encoding='utf-8') as f:
                            f.write(branch_sql)
                        status = 'OK'
                        print(f'    [{status}] {branch_name} ({char_count} chars)')
                        output_files.append((branch_name, out_path, char_count))
                    else:
                        segments = re.split(r'\n\n+', branch_sql)
                        chunks, current_chunk, current_size = [], [], 50
                        for seg in segments:
                            seg = seg.strip()
                            if not seg:
                                continue
                            seg_size = len(seg) + 2
                            # Only flush when current chunk already has a real SQL
                            # statement (ends with ';').  This prevents the comment
                            # header from being stranded alone in its own part when
                            # the only DML statement is very large (>9500 chars).
                            current_has_stmt = any(s.endswith(';') for s in current_chunk)
                            if current_size + seg_size > 9500 and current_chunk and current_has_stmt:
                                chunks.append('\n\n'.join(current_chunk))
                                current_chunk, current_size = [], 50
                            current_chunk.append(seg)
                            current_size += seg_size
                        if current_chunk:
                            chunks.append('\n\n'.join(current_chunk))
                        for pidx, chunk in enumerate(chunks, 1):
                            part_label = f'{branch_name}_part{pidx}'
                            out_path = os.path.join(output_dir, f'{part_label}_cleaned.sql')
                            content = (
                                f'-- Source-concept branch: {concept_key}'
                                f' (part {pidx}/{len(chunks)})\n\n{chunk}'
                            )
                            with open(out_path, 'w', encoding='utf-8') as f:
                                f.write(content)
                            ccount = len(content)
                            status = 'OK' if ccount <= 10000 else f'WARN:{ccount}ch'
                            print(f'    [{status}] {part_label} ({ccount} chars)')
                            output_files.append((part_label, out_path, ccount))
                extracted += 1
                continue

        cleaned = clean_plsql_for_lineage(raw_proc_sql, proc_label)

        if not cleaned.strip() or (
            cleaned.strip().startswith('-- Cleaned for lineage') and
            len(cleaned.strip().split('\n')) <= 1
        ):
            print(f'    [SKIP no DML] {proc_name}')
            skipped += 1
            continue

        char_count = len(cleaned)

        if char_count <= 10000:
            out_path = os.path.join(output_dir, f'{proc_label}_cleaned.sql')
            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            status = 'OK'
            print(f'    [{status}] {proc_label} ({char_count} chars)')
            output_files.append((proc_label, out_path, char_count))
        else:
            # Split oversized proc into parts
            header_line = ''
            body = cleaned
            if cleaned.startswith('--'):
                first_nl = cleaned.index('\n')
                header_line = cleaned[:first_nl]
                body = cleaned[first_nl + 1:]

            segments = re.split(r'\n\n+', body)
            chunks, current_chunk, current_size = [], [], len(header_line) + 50
            for seg in segments:
                seg = seg.strip()
                if not seg:
                    continue
                seg_size = len(seg) + 2
                current_has_stmt = any(s.endswith(';') for s in current_chunk)
                if current_size + seg_size > 9500 and current_chunk and current_has_stmt:
                    chunks.append('\n\n'.join(current_chunk))
                    current_chunk, current_size = [], len(header_line) + 50
                current_chunk.append(seg)
                current_size += seg_size
            if current_chunk:
                chunks.append('\n\n'.join(current_chunk))

            for pidx, chunk in enumerate(chunks, 1):
                part_label = f'{proc_label}_part{pidx}'
                out_path = os.path.join(output_dir, f'{part_label}_cleaned.sql')
                content = f'{header_line} (part {pidx}/{len(chunks)})\n\n{chunk}'
                with open(out_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                ccount = len(content)
                status = 'OK' if ccount <= 10000 else f'WARN:{ccount}ch'
                print(f'    [{status}] {part_label} ({ccount} chars)')
                output_files.append((part_label, out_path, ccount))

        extracted += 1

    print(f'  [PKG] {pkg_name}: {extracted} procs extracted, {skipped} skipped')
    return output_files


# ---------------------------------------------------------------------------
# Parameter-dispatcher proc handling
# (e.g. PROC_REFRESH_GRP_M_VIEW_TBLS — dispatches based on P_MV_TBL_NAME)
# ---------------------------------------------------------------------------

# Matches: IF UPPER(TRIM(param)) like '%TABLE_NAME%' THEN
_DISPATCH_IF_RE = re.compile(
    r"IF\s+UPPER\s*\(\s*TRIM\s*\(\s*(\w+)\s*\)\s*\)\s+like\s+'%([^%']+)%'",
    re.IGNORECASE
)


def detect_param_dispatcher(sql: str) -> bool:
    """Return True if the SQL is a parameter-dispatched proc using IF UPPER(TRIM(param)) LIKE patterns."""
    return bool(_DISPATCH_IF_RE.search(sql))


def extract_param_dispatcher_branches(sql: str) -> list:
    """
    Split a parameter-dispatcher proc into individual branch SQLs.

    Each branch is identified by:
        IF UPPER(TRIM(P_xxx)) like '%TABLE_NAME%' THEN ... END IF;

    Returns list of (branch_table_name, branch_dml_sql) tuples where
    branch_dml_sql contains only the DML statements for that branch,
    cleaned and ready for Gudu.
    """
    # Work on comment-stripped version to find IF positions reliably
    stripped = remove_block_comments(sql)
    stripped = remove_line_comments(stripped)

    branches = []
    lines = stripped.splitlines(keepends=True)
    n = len(lines)
    i = 0

    while i < n:
        line = lines[i]
        m = _DISPATCH_IF_RE.search(line)
        if m:
            table_key = m.group(2).strip().upper()  # e.g. LG_RESERVES_MAX_RESERVE_VAL_DATE

            # Collect lines until the matching END IF at depth 1
            # We track IF depth to handle nested IFs inside the branch body
            branch_lines = []
            depth = 1
            j = i + 1
            while j < n and depth > 0:
                bl = lines[j]
                upper_bl = bl.upper()
                # Count END IFs first, then count standalone IFs (not the IF in END IF)
                closes = len(re.findall(r'\bEND\s+IF\b', upper_bl))
                line_no_end_if = re.sub(r'\bEND\s+IF\b', '', upper_bl)
                opens = len(re.findall(r'\bIF\b', line_no_end_if))
                branch_lines.append(bl)
                depth += opens - closes
                j += 1

            # The last line collected is the END IF; — exclude it
            branch_body = ''.join(branch_lines[:-1]) if branch_lines else ''

            # Clean this branch body: extract only DML
            cleaned_branch = clean_plsql_for_lineage(branch_body, table_key)
            if cleaned_branch.strip():
                branches.append((table_key, cleaned_branch))

            i = j  # skip past END IF
        else:
            i += 1

    return branches


# ---------------------------------------------------------------------------
# Source-concept dispatcher proc handling
# (e.g. PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R
#  — dispatches based on LC_SOURCE_CONCEPT which is assigned from the IN_TYPE parameter
#  passed by the shell script.  Branches use equality / LIKE comparisons rather than
#  the UPPER(TRIM(param)) LIKE '%...%' pattern used by PROC_REFRESH_GRP_M_VIEW_TBLS.)
# ---------------------------------------------------------------------------

# Matches IF guards like:
#   IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT = 'BENEFIT_PAYMENT' THEN
#   IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE 'ADJUSTMENT' THEN
#   if LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT like 'DISBURS%' then
_SOURCE_CONCEPT_IF_RE = re.compile(
    r"IF\s+LC_SOURCE_CONCEPT\s*=\s*'ALL'\s+OR\s+LC_SOURCE_CONCEPT\s*(?:=|LIKE)\s*'([^']+)'",
    re.IGNORECASE,
)


def detect_source_concept_dispatcher(sql: str) -> bool:
    """Return True if the SQL dispatches via LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT = '...' pattern."""
    return bool(_SOURCE_CONCEPT_IF_RE.search(sql))


def extract_source_concept_branches(sql: str) -> list:
    """
    Split a LC_SOURCE_CONCEPT-dispatcher proc into per-branch SQLs.

    Each branch is identified by:
        IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT [=|LIKE] 'VALUE' THEN
            ...
        END IF;

    Returns list of (branch_concept_key, branch_dml_sql) tuples where
    branch_concept_key is the non-ALL value (e.g. 'BENEFIT_PAYMENT', 'ADJUSTMENT',
    'DISBURS') and branch_dml_sql contains only the DML statements for that branch,
    cleaned and ready for Gudu.
    """
    # Strip comments for structural parsing
    stripped = remove_block_comments(sql)
    stripped = remove_line_comments(stripped)

    branches = []
    lines = stripped.splitlines(keepends=True)
    n = len(lines)
    i = 0

    while i < n:
        line = lines[i]
        m = _SOURCE_CONCEPT_IF_RE.search(line)
        if m:
            concept_key = m.group(1).strip().upper()
            # Normalize wildcard suffix: 'DISBURS%' → 'DISBURS'
            concept_key = concept_key.rstrip('%').rstrip('_')

            # Collect lines until the matching END IF at depth 1
            branch_lines = []
            depth = 1
            j = i + 1
            while j < n and depth > 0:
                bl = lines[j]
                upper_bl = bl.upper()
                closes = len(re.findall(r'\bEND\s+IF\b', upper_bl))
                line_no_end_if = re.sub(r'\bEND\s+IF\b', '', upper_bl)
                opens = len(re.findall(r'\bIF\b', line_no_end_if))
                branch_lines.append(bl)
                depth += opens - closes
                j += 1

            # Exclude the closing END IF; line
            branch_body = ''.join(branch_lines[:-1]) if branch_lines else ''

            # Clean this branch body: extract only DML
            cleaned_branch = clean_plsql_for_lineage(branch_body, concept_key)
            if cleaned_branch.strip():
                branches.append((concept_key, cleaned_branch))

            i = j  # skip past END IF
        else:
            i += 1

    return branches


# ---------------------------------------------------------------------------
# Dynamic SQL extraction
# ---------------------------------------------------------------------------

def extract_dynamic_dml(sql: str) -> list:
    """
    Extract DML from EXECUTE IMMEDIATE where the variable contains MERGE/INSERT/UPDATE.
    Also handles string concatenation patterns for building dynamic SQL.
    """
    dynamic_stmts = []

    # Pattern: EXECUTE IMMEDIATE variable_name
    exec_pattern = re.compile(
        r'EXECUTE\s+IMMEDIATE\s+(\w+)',
        re.IGNORECASE
    )

    for match in exec_pattern.finditer(sql):
        var_name = match.group(1).upper()
        # Skip if it's a string literal (already handled)
        if var_name.startswith("'"):
            continue

        # Look for the variable being assigned a DML string
        # Pattern: var := 'MERGE INTO ...' or multi-line concat
        assign_pattern = re.compile(
            re.escape(var_name) + r"\s*:=\s*'((?:MERGE|INSERT|UPDATE|DELETE)\b[^']*)'",
            re.IGNORECASE
        )
        for amatch in assign_pattern.finditer(sql.upper()):
            # Get the actual text (case-preserved) by position
            start = amatch.start(1) - (len(sql.upper()) - len(sql))
            dml_text = sql[amatch.start(1):amatch.end(1)].replace("''", "'")
            dynamic_stmts.append(f"-- Dynamic SQL via {var_name}:\n{dml_text};")

    return dynamic_stmts


# ---------------------------------------------------------------------------
# Main cleaning logic
# ---------------------------------------------------------------------------

def clean_plsql_for_lineage(raw_sql: str, source_name: str = "") -> str:
    """
    Clean a PL/SQL procedure body, extracting only lineage-relevant DML.
    Returns cleaned SQL string ready for Gudu.
    """
    # Step 1: Remove comments
    sql = remove_block_comments(raw_sql)
    sql = remove_line_comments(sql)

    # Step 2: Remove exception blocks
    sql = remove_exception_blocks(sql)

    # Step 3: Extract cursor-based lineage
    cursor_lineage = extract_cursor_lineage(sql, source_name)

    # Step 4: Extract dynamic SQL
    dynamic_lineage = extract_dynamic_dml(sql)

    # Step 5: Split into statements and filter
    statements = split_statements(sql)
    kept = []

    # Regex to find the first DML keyword in a statement that may have a
    # PROCEDURE/FUNCTION/IS/BEGIN/AS header prepended by split_statements.
    # e.g. "PROCEDURE prc_X IS BEGIN INSERT INTO ..." → keep from INSERT onward.
    _DML_START_RE = re.compile(
        r'\b(INSERT\s+(?:/\*[^*]*\*/\s*)?INTO|UPDATE\s+\w|DELETE\s+(?:FROM\s+)?\w|MERGE\s+INTO)\b',
        re.IGNORECASE | re.DOTALL,
    )

    for stmt in statements:
        stripped = stmt.strip()
        if not stripped:
            continue

        # Keep DML statements FIRST — DML always wins over boilerplate filters.
        # split_statements can produce a statement like
        # "PROCEDURE prc_X IS BEGIN INSERT INTO T ..." when the proc header
        # has no semicolon before the first DML statement. In that case
        # is_boilerplate() fires (starts with PROCEDURE) and would wrongly skip it.
        if is_dml_statement(stripped):
            # Strip any PROCEDURE/FUNCTION/IS/BEGIN/AS header that split_statements
            # may have prepended (no semicolon between proc header and first DML).
            m = _DML_START_RE.search(stripped)
            if m and m.start() > 0:
                stripped = stripped[m.start():]
            # Strip FORALL prefix if present on same statement
            cleaned_stmt = re.sub(
                r'^\s*FORALL\s+\w+\s+IN\s+\w+\.FIRST\s*\.\.\s*\w+\.LAST\s*',
                '', stripped, flags=re.IGNORECASE
            )
            kept.append(cleaned_stmt)
            continue

        # Skip boilerplate (only reached when statement has no DML)
        if is_boilerplate(stripped):
            continue

        # EXECUTE IMMEDIATE with DML or CTAS — handles both direct and BEGIN-wrapped blocks
        if re.search(r'\bEXECUTE\s+IMMEDIATE\b', stripped, re.IGNORECASE):
            if re.search(r'\b(INSERT|UPDATE|DELETE|MERGE)\b', stripped, re.IGNORECASE):
                kept.append(stripped)
            elif re.search(r'\bCREATE\s+TABLE\b.*\bAS\s+SELECT\b', stripped, re.IGNORECASE | re.DOTALL):
                # CTAS inside EXECUTE IMMEDIATE is lineage: new table ← SELECT source
                kept.append(stripped)

    # Step 6: Build output
    parts = []
    if source_name:
        parts.append(f"-- Cleaned for lineage: {source_name}")

    # Direct DML statements
    for stmt in kept:
        s = stmt.rstrip(';').strip()
        if s:
            # Collapse blank lines within the statement so that '\n\n'.join()
            # separators remain unambiguous statement boundaries.  Sub-splitting
            # later (re.split(r'\n\n+', ...)) must not cut inside a statement
            # that has blank lines between column groups.
            # Use (\\n[ \\t]*)+ to handle consecutive blank/whitespace-only lines
            # in a single pass (the simpler \\n[ \\t]*\\n misses the second of two
            # back-to-back blank lines because its leading \\n is consumed by the
            # first match).
            s = re.sub(r'(\n[ \t]*)+\n', '\n', s)
            parts.append(s + ';')

    # Cursor-derived lineage
    for cl in cursor_lineage:
        parts.append(cl)

    # Dynamic SQL lineage
    for dl in dynamic_lineage:
        parts.append(dl)

    result = '\n\n'.join(parts)
    # Collapse excessive blank lines
    result = re.sub(r'\n\s*\n(\s*\n)+', '\n\n', result)

    return result.strip()


# ---------------------------------------------------------------------------
# File processing with chunk splitting
# ---------------------------------------------------------------------------

def clean_sql_file(input_path: str, output_dir: str) -> list:
    """
    Clean a SQL file and output cleaned SQL suitable for Gudu.
    Auto-detects PL/SQL procedures vs CREATE MATERIALIZED VIEW / CREATE VIEW DDL.
    If output exceeds 10K chars, splits into multiple files (PL/SQL only).
    Returns list of (name, output_path, char_count) tuples.
    """
    with open(input_path, 'r', encoding='utf-8', errors='replace') as f:
        raw_sql = f.read()

    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(input_path))[0]

    # Skip entire packages that have no RPT-specific lineage (e.g. DIFW framework)
    if base_name.upper() in _SKIP_PACKAGES:
        # Also purge any stale output files left over from a previous run
        stale = glob.glob(os.path.join(output_dir, f'{base_name}_*'))
        for sf in stale:
            os.remove(sf)
            print(f'  [PURGE stale] {os.path.basename(sf)}')
        print(f'  [SKIP package] {base_name} - in _SKIP_PACKAGES list')
        return []

    file_type = detect_file_type(raw_sql)
    if file_type in ('mview', 'view'):
        cleaned = clean_mview_for_lineage(raw_sql, base_name)
        # For plain views with UNION ALL branches, split into one cleaned file per branch
        # (the generic double-newline splitter would break UNION ALL statements)
        if file_type == 'view' and cleaned:
            union_branches = _extract_union_view_branches(cleaned, base_name)
            if union_branches:
                output_files = []
                print(f'  [VIEW-UNION] {base_name} - {len(union_branches)} UNION branches detected')
                for bname, bsql in union_branches:
                    out_path = os.path.join(output_dir, f'{bname}_cleaned.sql')
                    with open(out_path, 'w', encoding='utf-8') as f:
                        f.write(bsql)
                    ccount = len(bsql)
                    status = 'OK' if ccount <= 10000 else f'WARN:{ccount}ch'
                    print(f'    [{status}] {bname} ({ccount} chars)')
                    output_files.append((bname, out_path, ccount))
                return output_files
    elif detect_package_body(raw_sql):
        # Package body: split into one file per procedure, then clean each
        print(f'  [PACKAGE] {base_name} - splitting into individual procedures')
        return split_package_into_procs(raw_sql, base_name, output_dir)
    elif detect_param_dispatcher(raw_sql):
        # Parameter-dispatcher proc (e.g. PROC_REFRESH_GRP_M_VIEW_TBLS):
        # split into one cleaned file per branch so Gudu sees the right sources
        branches = extract_param_dispatcher_branches(raw_sql)
        if not branches:
            print(f"  [SKIP] {base_name} - param-dispatcher detected but no branches extracted")
            return []

        output_files = []
        print(f"  [DISPATCH] {base_name} - {len(branches)} branches detected")
        for table_key, branch_sql in branches:
            branch_name = f"{base_name}__{table_key}"
            char_count = len(branch_sql)
            if char_count > 10000:
                # Split oversized branches the same way as normal files
                segments = re.split(r'\n\n+', branch_sql)
                chunks, current_chunk, current_size = [], [], 0
                for seg in segments:
                    seg = seg.strip()
                    if not seg:
                        continue
                    seg_size = len(seg) + 2
                    if current_size + seg_size > 9500 and current_chunk:
                        chunks.append('\n\n'.join(current_chunk))
                        current_chunk, current_size = [], 0
                    current_chunk.append(seg)
                    current_size += seg_size
                if current_chunk:
                    chunks.append('\n\n'.join(current_chunk))
                for idx, chunk in enumerate(chunks, 1):
                    part_name = f"{branch_name}_part{idx}"
                    out_path = os.path.join(output_dir, f"{part_name}_cleaned.sql")
                    content = f"-- Cleaned for lineage: {branch_name} (part {idx}/{len(chunks)})\n\n{chunk}"
                    with open(out_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    ccount = len(content)
                    print(f"    [{('OK' if ccount <= 10000 else f'WARN:{ccount}ch')}] {part_name} ({ccount} chars)")
                    output_files.append((part_name, out_path, ccount))
            else:
                out_path = os.path.join(output_dir, f"{branch_name}_cleaned.sql")
                with open(out_path, 'w', encoding='utf-8') as f:
                    f.write(branch_sql)
                print(f"    [OK] {branch_name} ({char_count} chars)")
                output_files.append((branch_name, out_path, char_count))

        return output_files
    else:
        cleaned = clean_plsql_for_lineage(raw_sql, base_name)

    if not cleaned.strip() or cleaned.strip().startswith('-- Cleaned for lineage') and len(cleaned.strip().split('\n')) <= 1:
        print(f"  [SKIP] {base_name} - no lineage-relevant SQL found")
        return []

    char_count = len(cleaned)
    output_files = []

    if char_count <= 10000:
        out_path = os.path.join(output_dir, f"{base_name}_cleaned.sql")
        with open(out_path, 'w', encoding='utf-8') as f:
            f.write(cleaned)
        print(f"  [OK] {base_name} ({char_count} chars)")
        output_files.append((base_name, out_path, char_count))
    else:
        # Split by double-newline separated statements
        header_line = ""
        body = cleaned
        if cleaned.startswith('--'):
            first_nl = cleaned.index('\n')
            header_line = cleaned[:first_nl]
            body = cleaned[first_nl+1:]

        segments = re.split(r'\n\n+', body)
        chunks = []
        current_chunk = []
        current_size = len(header_line) + 50  # header overhead per chunk

        for seg in segments:
            seg = seg.strip()
            if not seg:
                continue
            seg_size = len(seg) + 2

            if current_size + seg_size > 9500 and current_chunk:
                chunks.append('\n\n'.join(current_chunk))
                current_chunk = []
                current_size = len(header_line) + 50

            current_chunk.append(seg)
            current_size += seg_size

        if current_chunk:
            chunks.append('\n\n'.join(current_chunk))

        for idx, chunk in enumerate(chunks, 1):
            chunk_name = f"{base_name}_part{idx}"
            out_path = os.path.join(output_dir, f"{chunk_name}_cleaned.sql")
            chunk_content = f"{header_line} (part {idx}/{len(chunks)})\n\n{chunk}"

            with open(out_path, 'w', encoding='utf-8') as f:
                f.write(chunk_content)

            ccount = len(chunk_content)
            status = "OK" if ccount <= 10000 else f"WARN:{ccount}ch"
            print(f"  [{status}] {base_name} part {idx}/{len(chunks)} ({ccount} chars)")
            output_files.append((chunk_name, out_path, ccount))

        print(f"         Split {base_name} into {len(chunks)} parts (was {char_count} chars)")

    return output_files


def process_directory(input_dir: str, output_dir: str, pattern: str = "*.sql",
                      exclude_prefix: str = None) -> list:
    """
    Process all SQL files in a directory.
    exclude_prefix: skip files whose basename starts with this prefix (case-insensitive).
    """
    import glob
    files = sorted(glob.glob(os.path.join(input_dir, pattern)))
    if not files:
        print(f"No files matching '{pattern}' in {input_dir}")
        return []

    if exclude_prefix:
        orig_count = len(files)
        files = [f for f in files
                 if not os.path.basename(f).upper().startswith(exclude_prefix.upper())]
        skipped = orig_count - len(files)
        print(f"Found {orig_count} files; skipping {skipped} with prefix '{exclude_prefix}'")

    print(f"Processing {len(files)} files\n")
    all_output = []
    for filepath in files:
        print(f"--- {os.path.basename(filepath)} ---")
        result = clean_sql_file(filepath, output_dir)
        all_output.extend(result)

    return all_output


# ---------------------------------------------------------------------------
# Gudu part-stitcher
# ---------------------------------------------------------------------------

def stitch_gudu_part_lineages(output_files: list, output_dir: str) -> list:
    """
    After Gudu has processed all files, merge the per-part _lineage.json files
    back into one _lineage.json per logical branch.

    A "part" file is any name ending in _partN (e.g. F_PSR_CLAIM_MV_1_part3).
    The branch name is everything before _partN.

    Merging strategy:
      - relationships: union all entries, re-sequence IDs to avoid collisions
      - dbobjs tables: union by table name (dedup), re-sequence IDs
      - processes: union all, re-sequence IDs
      - errors: union all (for diagnostics)

    Returns list of (branch_name, stitched_json_path) for each merged file.
    """
    import json

    # Group (name, sql_path) by base branch name (strip _partN suffix)
    part_re = re.compile(r'^(.+?)_part\d+(?:_cleaned)?$')
    groups = {}   # base_name -> list of sql_paths in order
    singles = []  # names that are already single (no partN)

    for name, sql_path, _ in output_files:
        m = part_re.match(name)
        if m:
            base = m.group(1)
            groups.setdefault(base, []).append((name, sql_path))
        else:
            singles.append((name, sql_path))

    if not groups:
        return []  # nothing to stitch

    stitched = []
    for base_name, parts in groups.items():
        # Collect _lineage.json paths in part order
        lineage_files = []
        for name, sql_path in sorted(parts, key=lambda x: x[0]):
            lpath = os.path.splitext(sql_path)[0] + '_lineage.json'
            if os.path.exists(lpath):
                lineage_files.append(lpath)

        if not lineage_files:
            continue  # Gudu produced no output for this branch

        # Load all part JSONs, offsetting all IDs in each part so they don't
        # collide with the previous parts.  ID offsetting must be applied
        # consistently to dbobjs (table + column IDs) AND to every ID
        # reference inside relationships (target.id, sources[*].id) so that
        # extract_gudu_lineage can look up relationship participants in id_map.
        #
        # Gudu uses two ID formats:
        #   simple:   "66"        -> numeric string
        #   compound: "89_0"      -> "<base>_<suffix>" where base is numeric
        # We offset the numeric part of both formats.

        def _parse_id(id_str):
            """Return (numeric_base, suffix_or_None)."""
            parts = id_str.split('_', 1)
            try:
                base = int(parts[0])
                suffix = parts[1] if len(parts) > 1 else None
                return base, suffix
            except (ValueError, IndexError):
                return None, None

        def _offset_id(id_str, offset):
            base, suffix = _parse_id(id_str)
            if base is None:
                return id_str  # can't offset — leave as-is
            new_base = base + offset
            return f"{new_base}_{suffix}" if suffix is not None else str(new_base)

        def _max_numeric_id(data_dict):
            """Find the largest numeric base ID used in dbobjs + relationships."""
            max_id = 0
            try:
                tables = data_dict['dbobjs']['servers'][0]['databases'][0]['schemas'][0]['tables']
                for tbl in tables:
                    b, _ = _parse_id(str(tbl.get('id', '0')))
                    if b and b > max_id:
                        max_id = b
                    for col in tbl.get('columns', []):
                        b, _ = _parse_id(str(col.get('id', '0')))
                        if b and b > max_id:
                            max_id = b
            except (KeyError, IndexError):
                pass
            for rel in data_dict.get('relationships', []):
                if 'target' in rel:
                    b, _ = _parse_id(str(rel['target'].get('id', '0')))
                    if b and b > max_id:
                        max_id = b
                for src in rel.get('sources', []):
                    b, _ = _parse_id(str(src.get('id', '0')))
                    if b and b > max_id:
                        max_id = b
            for proc in data_dict.get('processes', []):
                b, _ = _parse_id(str(proc.get('id', '0')))
                if b and b > max_id:
                    max_id = b
            return max_id

        def _apply_offset(data_dict, offset):
            """Return a deep-copy-like dict with all numeric IDs shifted by offset."""
            if offset == 0:
                return data_dict
            import copy
            d = copy.deepcopy(data_dict)
            # Offset dbobjs table + column IDs
            try:
                tables = d['dbobjs']['servers'][0]['databases'][0]['schemas'][0]['tables']
                for tbl in tables:
                    tbl['id'] = _offset_id(str(tbl['id']), offset)
                    for col in tbl.get('columns', []):
                        col['id'] = _offset_id(str(col['id']), offset)
            except (KeyError, IndexError):
                pass
            # Offset relationship target + source IDs
            for rel in d.get('relationships', []):
                if 'target' in rel:
                    rel['target']['id'] = _offset_id(str(rel['target']['id']), offset)
                    if 'parentId' in rel['target']:
                        rel['target']['parentId'] = _offset_id(str(rel['target']['parentId']), offset)
                for src in rel.get('sources', []):
                    src['id'] = _offset_id(str(src['id']), offset)
                    if 'parentId' in src:
                        src['parentId'] = _offset_id(str(src['parentId']), offset)
            # Offset process IDs
            for proc in d.get('processes', []):
                proc['id'] = _offset_id(str(proc['id']), offset)
            return d

        all_rels = []
        all_tables = {}   # table name (upper) -> table dict with already-offset IDs
        all_processes = []
        all_errors = []
        db_vendor = 'dbvoracle'
        cumulative_offset = 0

        for lpath in lineage_files:
            try:
                with open(lpath, encoding='utf-8') as f:
                    raw = f.read()
                # Gudu appends "Error log:\n..." after the JSON on a new line
                # Strip anything after the first newline-separated non-JSON block
                json_text = raw.split('\nError log:')[0].split('\nError log')[0].strip()
                data = json.loads(json_text)
            except Exception:
                continue

            # Extract vendor
            try:
                db_vendor = data['dbobjs']['servers'][0]['dbVendor']
            except (KeyError, IndexError):
                pass

            max_id_this_part = _max_numeric_id(data)
            data = _apply_offset(data, cumulative_offset)
            # Next part starts IDs after the highest ID seen so far
            cumulative_offset += max_id_this_part + 1000  # 1000 gap to avoid edge cases

            # Collect tables from dbobjs (already offset)
            try:
                tables = data['dbobjs']['servers'][0]['databases'][0]['schemas'][0]['tables']
                for tbl in tables:
                    tname = tbl.get('name', '').upper()
                    if tname and tname not in all_tables:
                        import copy
                        all_tables[tname] = copy.deepcopy(tbl)
                    elif tname:
                        # Merge columns from this part (offset IDs already applied)
                        existing_cols = {c['name'].upper() for c in all_tables[tname].get('columns', [])}
                        for col in tbl.get('columns', []):
                            if col['name'].upper() not in existing_cols:
                                all_tables[tname].setdefault('columns', []).append(col)
                                existing_cols.add(col['name'].upper())
            except (KeyError, IndexError):
                pass

            # Collect relationships + processes (already offset)
            all_rels.extend(data.get('relationships', []))
            all_processes.extend(data.get('processes', []))
            all_errors.extend(data.get('errors', []))

        if not all_rels and not all_tables:
            continue

        # Re-sequence only the top-level relationship IDs (not target/source IDs).
        # These are just array identifiers; order doesn't need to match content IDs.
        for ridx, rel in enumerate(all_rels, start=1):
            rel['id'] = str(ridx)

        table_list = list(all_tables.values())

        merged = {
            "dbobjs": {
                "createdBy": "sqlflow v1.0.0 (stitched)",
                "servers": [{
                    "name": "DEFAULT_SERVER",
                    "dbVendor": db_vendor,
                    "supportsCatalogs": True,
                    "supportsSchemas": True,
                    "databases": [{
                        "name": "DEFAULT",
                        "schemas": [{
                            "name": "DEFAULT",
                            "tables": table_list
                        }]
                    }]
                }]
            },
            "relationships": all_rels,
            "processes": all_processes,
            "errors": all_errors
        }

        out_path = os.path.join(output_dir, f"{base_name}_lineage.json")
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(merged, f, indent=2, ensure_ascii=False)

        rel_count = len(all_rels)
        part_count = len(lineage_files)
        print(f"  [STITCH] {base_name} <- {part_count} parts merged ({rel_count} relationships) -> {os.path.basename(out_path)}")
        stitched.append((base_name, out_path))

    return stitched


# ---------------------------------------------------------------------------
# Gudu runner
# ---------------------------------------------------------------------------

def run_gudu(sql_file: str, db_type: str = 'oracle', dlineage_dir: str = None,
             output_format: str = 'json', extra_args: list = None):
    """Run gudu dlineage.py on a cleaned SQL file."""
    if dlineage_dir is None:
        dlineage_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                    'python_data_lineage')

    # Always use absolute paths so subprocess cwd change doesn't break relative lookups
    dlineage_dir    = os.path.abspath(dlineage_dir)
    dlineage_script = os.path.join(dlineage_dir, 'dlineage.py')
    if not os.path.exists(dlineage_script):
        print(f"  ERROR: dlineage.py not found at {dlineage_script}")
        return -1

    sql_file_abs = os.path.abspath(sql_file)

    # Verify file is under 10K chars
    with open(sql_file_abs, 'r', encoding='utf-8') as f:
        char_count = len(f.read())
    if char_count > 10000:
        print(f"  [SKIP] {os.path.basename(sql_file)} ({char_count} chars) exceeds Gudu 10K limit")
        return -1

    cmd = [sys.executable, dlineage_script, '/t', db_type, '/f', sql_file_abs]

    if output_format == 'json':
        cmd.append('/json')
    elif output_format == 'csv':
        cmd.append('/csv')
    elif output_format == 'graph':
        cmd.append('/graph')

    if extra_args:
        cmd.extend(extra_args)

    out_ext = {'json': '.json', 'csv': '.csv', 'graph': '.json'}
    output_path = os.path.splitext(sql_file_abs)[0] + '_lineage' + out_ext.get(output_format, '.txt')

    print(f"  Gudu: {os.path.basename(sql_file)}")
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=dlineage_dir,
                            env={**os.environ})

    if result.stdout and result.stdout.strip():
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(result.stdout)
        print(f"    -> {os.path.basename(output_path)}")
    if result.stderr:
        stderr_clean = result.stderr.strip()
        if stderr_clean and 'WARNING' not in stderr_clean.upper():
            print(f"    STDERR: {stderr_clean[:200]}")

    return result.returncode


# ---------------------------------------------------------------------------
# Pre-flight assessment: predict Gudu reliability before running
# ---------------------------------------------------------------------------

# Patterns that signal a cleaned file will produce reliable Gudu output
_GUDU_RELIABLE_DML = re.compile(
    r'\b(INSERT\s+(?:/\*[^*]*\*/\s*)?INTO|MERGE\s+INTO|UPDATE\s+\w|DELETE\s+(FROM\s+)?\w)\b',
    re.IGNORECASE,
)
# Patterns that signal problematic SQL that Gudu historically fails on
_GUDU_PROBLEMATIC = [
    # Dynamic SQL built as strings — Gudu can't parse these
    re.compile(r'EXECUTE\s+IMMEDIATE\s+\w+\s*\|\|', re.IGNORECASE),
    re.compile(r'EXECUTE\s+IMMEDIATE\s+\w+\s*;', re.IGNORECASE),
    # CLOB/XML concatenation patterns
    re.compile(r'SYS\.XMLTYPE\s*\(', re.IGNORECASE),
    re.compile(r'XMLELEMENT\s*\(', re.IGNORECASE),
    # Cursor-only files (only synthetic comments, no real DML)
    re.compile(r'^--\s+Lineage:\s+Cursor', re.IGNORECASE | re.MULTILINE),
]
# Already-has-lineage: JSON exists and has relationships
def _json_already_ok(sql_path: str) -> bool:
    json_path = os.path.splitext(sql_path)[0] + '_lineage.json'
    if not os.path.exists(json_path):
        return False
    try:
        with open(json_path, encoding='utf-8') as f:
            raw = f.read()
        json_text = raw.split('\nError log:')[0].strip()
        import json as _json
        return bool(_json.loads(json_text).get('relationships'))
    except Exception:
        return False


def assess_for_gudu(sql_path: str) -> tuple[str, str]:
    """
    Assess whether a cleaned SQL file is likely to produce reliable Gudu output.

    Returns (verdict, reason) where verdict is one of:
      'PASS'   — send to Gudu
      'SKIP'   — already has good lineage JSON
      'REJECT' — known problematic; route to LLM instead
    """
    try:
        content = open(sql_path, encoding='utf-8', errors='ignore').read()
    except OSError:
        return 'REJECT', 'File unreadable'

    char_count = len(content)

    # Already has a good lineage result
    if _json_already_ok(sql_path):
        return 'SKIP', 'Lineage JSON already exists with relationships'

    # Over Gudu's 10K limit
    if char_count > 10000:
        return 'REJECT', f'Exceeds Gudu 10K limit ({char_count:,} chars)'

    # No usable DML left after cleaning
    if not _GUDU_RELIABLE_DML.search(content):
        return 'REJECT', 'No INSERT/MERGE/UPDATE/DELETE found after cleaning'

    # Known problematic patterns
    for pat in _GUDU_PROBLEMATIC:
        if pat.search(content):
            return 'REJECT', f'Problematic pattern: {pat.pattern[:60]}'

    # Empty or near-empty (only comments)
    code_lines = [l for l in content.splitlines() if l.strip() and not l.strip().startswith('--')]
    if len(code_lines) < 3:
        return 'REJECT', 'Effectively empty after removing comments'

    return 'PASS', f'OK ({char_count:,} chars, has DML)'


def write_gudu_assessment_report(
    results: list[tuple[str, str, str]],   # (filename, verdict, reason)
    output_dir: str,
    report_name: str = 'gudu_assessment_report.csv',
) -> str:
    """
    Write a CSV report of which files were passed to Gudu and which were rejected.
    Returns the path to the written report.
    """
    import csv
    report_path = os.path.join(output_dir, report_name)
    with open(report_path, 'w', newline='', encoding='utf-8-sig') as f:
        writer = csv.DictWriter(f, fieldnames=['File', 'Verdict', 'Reason'])
        writer.writeheader()
        for fname, verdict, reason in results:
            writer.writerow({'File': fname, 'Verdict': verdict, 'Reason': reason})

    total   = len(results)
    passed  = sum(1 for _, v, _ in results if v == 'PASS')
    skipped = sum(1 for _, v, _ in results if v == 'SKIP')
    rejected = sum(1 for _, v, _ in results if v == 'REJECT')
    print(f"\n{'='*60}")
    print(f"  Pre-flight assessment complete:")
    print(f"    PASS    (sent to Gudu)   : {passed}")
    print(f"    SKIP    (already done)   : {skipped}")
    print(f"    REJECT  (route to LLM)   : {rejected}")
    print(f"    Total                    : {total}")
    print(f"  Report : {report_path}")
    print(f"{'='*60}\n")
    return report_path


# ---------------------------------------------------------------------------
# Main CLI
# ---------------------------------------------------------------------------

def run_gudu_on_directory(cleaned_dir: str, db_type: str, dlineage_dir: str,
                          output_format: str, extra_args: list):
    """
    Run Gudu directly on all *_cleaned.sql files in a directory.
    Pre-flight assesses each file: only PASS files are sent to Gudu.
    REJECT files are written to gudu_assessment_report.csv for LLM fallback.
    Skips re-cleaning. Saves output as *_lineage.<ext> next to each file.
    """
    import glob
    files = sorted(glob.glob(os.path.join(cleaned_dir, '*_cleaned.sql')))
    if not files:
        print(f"No *_cleaned.sql files found in {cleaned_dir}")
        return

    # ── Pre-flight assessment ───────────────────────────────────────────────
    print(f"Found {len(files)} cleaned files. Running pre-flight assessment...\n")
    assessment_results = []
    pass_files = []

    for filepath in files:
        fname = os.path.basename(filepath)
        verdict, reason = assess_for_gudu(filepath)
        assessment_results.append((fname, verdict, reason))
        if verdict == 'PASS':
            pass_files.append(filepath)
        else:
            marker = '[SKIP]' if verdict == 'SKIP' else '[REJECT]'
            print(f"  {marker} {fname}: {reason}")

    write_gudu_assessment_report(assessment_results, cleaned_dir)

    if not pass_files:
        print("No files to send to Gudu after assessment.")
        return 0, len(files)

    print(f"Sending {len(pass_files)} file(s) to Gudu...\n")
    # ── Run Gudu on PASS files only ─────────────────────────────────────────
    success = 0
    failed  = 0

    for filepath in pass_files:
        ret = run_gudu(filepath, db_type, dlineage_dir, output_format, extra_args)
        if ret == 0:
            success += 1
        else:
            failed += 1

    print(f"\nGudu results: {success} succeeded, {failed} failed")

    # ── Stitch part lineages ────────────────────────────────────────────────
    part_files = [(os.path.splitext(os.path.basename(f))[0], f, 0)
                  for f in files if re.search(r'_part\d+_cleaned\.sql$', f)]
    if part_files:
        print(f"\n{'='*60}")
        print("Stitching part lineages back into per-branch files...")
        print(f"{'='*60}\n")
        stitched = stitch_gudu_part_lineages(part_files, cleaned_dir)
        if stitched:
            print(f"\n  {len(stitched)} branch lineage file(s) stitched in: {cleaned_dir}")

    return success, failed


def main():
    parser = argparse.ArgumentParser(
        description='Clean Oracle PL/SQL for data lineage and optionally run Gudu analysis'
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--file', '-f', help='Path to a single SQL file to clean')
    group.add_argument('--dir', '-d', help='Path to directory of SQL files to clean')
    group.add_argument('--gudu-only', '-g',
                        help='Skip cleaning; run Gudu directly on all *_cleaned.sql files in this directory')

    parser.add_argument('--output-dir', '-o', default=None,
                        help='Output directory for cleaned SQL files')
    parser.add_argument('--pattern', '-p', default='*.sql',
                        help='File glob pattern when using --dir (default: *.sql)')
    parser.add_argument('--exclude-prefix', default=None,
                        help='Skip files whose name starts with this prefix (e.g. PKG)')
    parser.add_argument('--db-type', '-t', default='oracle',
                        help='Database type for Gudu (default: oracle)')
    parser.add_argument('--run-gudu', '-r', action='store_true',
                        help='After cleaning, also run Gudu dlineage on each cleaned file')
    parser.add_argument('--gudu-dir', default=None,
                        help='Path to python_data_lineage directory')
    parser.add_argument('--format', default='json', choices=['graph', 'json', 'csv'],
                        help='Output format for Gudu (default: json)')
    parser.add_argument('--gudu-args', nargs='*', default=None,
                        help='Extra arguments to pass to dlineage.py')

    args = parser.parse_args()

    # --gudu-only: skip cleaning, run Gudu on pre-cleaned files
    if args.gudu_only:
        cleaned_dir = os.path.abspath(args.gudu_only)
        if not os.path.isdir(cleaned_dir):
            print(f"ERROR: Directory not found: {cleaned_dir}")
            sys.exit(1)
        print(f"{'='*60}")
        print(f"  Mode:   Gudu-only (no cleaning)")
        print(f"  Input:  {cleaned_dir}")
        print(f"  DB:     {args.db_type}")
        print(f"{'='*60}\n")
        run_gudu_on_directory(cleaned_dir, args.db_type, args.gudu_dir,
                              args.format, args.gudu_args)
        return

    # Determine output directory
    if args.output_dir:
        output_dir = args.output_dir
    elif args.file:
        output_dir = os.path.join(os.path.dirname(os.path.abspath(args.file)), 'cleaned_for_lineage')
    else:
        output_dir = os.path.join(
            os.path.dirname(os.path.abspath(args.dir)),
            os.path.basename(os.path.abspath(args.dir)) + '_cleaned'
        )

    output_dir = os.path.abspath(output_dir)

    print(f"{'='*60}")
    print(f"  Input:  {args.file or args.dir}")
    print(f"  Output: {output_dir}")
    print(f"  DB:     {args.db_type}")
    print(f"{'='*60}\n")

    # Process
    if args.file:
        if not os.path.exists(args.file):
            print(f"ERROR: File not found: {args.file}")
            sys.exit(1)
        output_files = clean_sql_file(args.file, output_dir)
    else:
        if not os.path.isdir(args.dir):
            print(f"ERROR: Directory not found: {args.dir}")
            sys.exit(1)
        output_files = process_directory(args.dir, output_dir, args.pattern,
                                          exclude_prefix=args.exclude_prefix)

    if not output_files:
        print("\nNo lineage-relevant SQL found in any file.")
        sys.exit(0)

    # Run Gudu if requested
    if args.run_gudu:
        print(f"\n{'='*60}")
        print("Running Gudu lineage analysis...")
        print(f"{'='*60}\n")

        success = 0
        skipped = 0
        for name, sql_path, char_count in output_files:
            ret = run_gudu(sql_path, args.db_type, args.gudu_dir, args.format, args.gudu_args)
            if ret == 0:
                success += 1
            else:
                skipped += 1

        print(f"\nGudu results: {success} succeeded, {skipped} skipped/failed")

        # Stitch part files back together per branch
        has_parts = any(re.search(r'_part\d+$', name) for name, _, _ in output_files)
        if has_parts:
            print(f"\n{'='*60}")
            print("Stitching part lineages back into per-branch files...")
            print(f"{'='*60}\n")
            stitched = stitch_gudu_part_lineages(output_files, output_dir)
            if stitched:
                print(f"\n  {len(stitched)} branch lineage file(s) stitched in: {output_dir}")

    # Summary
    total_chars = sum(c for _, _, c in output_files)
    under_10k = sum(1 for _, _, c in output_files if c <= 10000)
    over_10k = sum(1 for _, _, c in output_files if c > 10000)

    print(f"\n{'='*60}")
    print(f"  SUMMARY")
    print(f"  Total cleaned files: {len(output_files)}")
    print(f"  Under 10K (Gudu-ready): {under_10k}")
    if over_10k:
        print(f"  Over 10K (need further split): {over_10k}")
    print(f"  Total chars: {total_chars:,}")
    print(f"  Output dir: {output_dir}")
    print(f"{'='*60}")


if __name__ == '__main__':
    main()
