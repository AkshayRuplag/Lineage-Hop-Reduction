"""
Shell Script SQL Object Parser
================================
Parses EDW shell scripts (.sh) to extract SQL objects they execute:
  - Oracle Packages (PKG_*)
  - Oracle Procedures (PRC_*, PROC_*)
  - Materialized View refreshes (dbms_mview.refresh)
  - Static SQL statements (INSERT INTO ... SELECT FROM)
  - EXECUTE IMMEDIATE with dynamic package/procedure names
  - Remote SSH script calls

Classifies each shell script into a pattern category and identifies
whether SQL object names are hardcoded or passed as TIDAL parameters.

Usage:
    python shell_parser.py [--sh-dir PATH] [--tidal-file PATH] [--output-dir PATH]

Outputs:
    shell_parsed_objects.csv  — One row per SQL object extracted from each shell script
    shell_parsed_objects.json — Same data in JSON format
"""

import os
import re
import csv
import json
import argparse
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Optional


# ─────────────────────────────────────────────────────────────────────────────
# DATA MODELS
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class SQLObjectRef:
    """A single SQL object reference extracted from a shell script."""
    shell_script: str               # Shell script filename
    pattern_type: str               # Category of the shell script pattern
    object_type: str                # PACKAGE, PROCEDURE, MV_REFRESH, STATIC_SQL, etc.
    schema: str                     # Schema prefix (ATOMIC, ATOMIC_PLSQL, etc.)
    object_name: str                # SQL object name (package/proc/MV/table)
    sub_object: str                 # Sub-object (e.g., .main, .PRC_xxx for pkg.proc calls)
    is_parameterized: bool          # True if name comes from TIDAL params ($1, $2, etc.)
    param_position: str             # Which positional param ($1, $2, etc.) if parameterized
    table_references: list          # Tables referenced (TABLE_NAME var, INSERT INTO targets, etc.)
    static_sql: str                 # Raw static SQL if inline SQL found
    remote_script: str              # Remote script path if SSH pattern
    notes: str                      # Additional context from comments/description


# ─────────────────────────────────────────────────────────────────────────────
# PARSER
# ─────────────────────────────────────────────────────────────────────────────

class ShellParser:
    """Parses shell scripts to extract SQL object references."""

    def __init__(self, sh_dir: Path):
        self.sh_dir = sh_dir

    def parse_all(self) -> list[SQLObjectRef]:
        """Parse all .sh files in the directory."""
        results = []
        sh_files = sorted(self.sh_dir.glob("*.sh"))
        for sh_file in sh_files:
            try:
                refs = self.parse_file(sh_file)
                results.extend(refs)
            except Exception as e:
                results.append(SQLObjectRef(
                    shell_script=sh_file.name,
                    pattern_type="PARSE_ERROR",
                    object_type="ERROR",
                    schema="",
                    object_name="",
                    sub_object="",
                    is_parameterized=False,
                    param_position="",
                    table_references=[],
                    static_sql="",
                    remote_script="",
                    notes=f"Parse error: {e}"
                ))
        return results

    def parse_file(self, sh_path: Path) -> list[SQLObjectRef]:
        """Parse a single shell script file."""
        content = sh_path.read_text(encoding='utf-8', errors='replace')
        filename = sh_path.name
        refs = []

        # Extract header comments for context
        description = self._extract_description(content)
        db_objects_comment = self._extract_db_objects_comment(content)

        # Extract TABLE_NAME variable assignments
        table_vars = self._extract_table_name_vars(content)

        # Try each pattern extractor in order
        # 1. SSH remote execution
        ssh_refs = self._extract_ssh_remote(content, filename, description)
        if ssh_refs:
            refs.extend(ssh_refs)

        # 2. EXECUTE IMMEDIATE with dynamic package name (param-based)
        exec_imm_refs = self._extract_execute_immediate(content, filename, description)
        if exec_imm_refs:
            refs.extend(exec_imm_refs)

        # 3. dbms_mview.refresh calls
        mv_refs = self._extract_mv_refresh(content, filename, description)
        if mv_refs:
            refs.extend(mv_refs)

        # 4. Direct PL/SQL calls (package.main, package.procedure, procedure)
        plsql_refs = self._extract_direct_plsql_calls(content, filename, description, table_vars)
        if plsql_refs:
            refs.extend(plsql_refs)

        # 5. Static SQL (INSERT INTO ... SELECT FROM)
        sql_refs = self._extract_static_sql(content, filename, description)
        if sql_refs:
            refs.extend(sql_refs)

        # 6. TRUNCATE TABLE statements
        trunc_refs = self._extract_truncate(content, filename, description)
        if trunc_refs:
            refs.extend(trunc_refs)

        # 7. DELETE FROM statements
        del_refs = self._extract_delete(content, filename, description)
        if del_refs:
            refs.extend(del_refs)

        # 8. UPDATE TABLE statements
        upd_refs = self._extract_update(content, filename, description)
        if upd_refs:
            refs.extend(upd_refs)

        # If nothing was extracted, create an entry noting it.
        # Distinguish scripts with no sqlplus call (NO_SQL: scheduler, empty, test)
        # from scripts that have sqlplus but an unrecognized pattern (UNKNOWN).
        if not refs:
            has_sqlplus = bool(re.search(r'sqlplus', content, re.IGNORECASE))
            ptype = "UNKNOWN" if has_sqlplus else "NO_SQL"
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type=ptype,
                object_type=ptype,
                schema="",
                object_name="",
                sub_object="",
                is_parameterized=False,
                param_position="",
                table_references=table_vars,
                static_sql="",
                remote_script="",
                notes=f"No recognized SQL pattern. Desc: {description}. DB objects: {db_objects_comment}"
            ))

        # Global dedup: remove identical (pattern_type, schema, object_name, sub_object, remote_script)
        # to handle cases like echo+actual ssh calls both matching the same pattern.
        seen = set()
        deduped_refs = []
        for r in refs:
            key = (r.pattern_type, r.schema, r.object_name.upper(), r.sub_object.upper(), r.remote_script)
            if key not in seen:
                seen.add(key)
                deduped_refs.append(r)
        return deduped_refs

    # ── Header extraction ─────────────────────────────────────────────────

    def _extract_description(self, content: str) -> str:
        """Extract Description from header comments."""
        m = re.search(r'#\s*Description\s*-\s*(.*?)(?:\n#\s*(?:Change|Modification)\s*log|\n#\s*-{5,})', 
                       content, re.DOTALL | re.IGNORECASE)
        if m:
            desc = m.group(1).strip()
            # Clean up multi-line descriptions
            desc = re.sub(r'\n#\s*', ' ', desc)
            return desc.strip()
        return ""

    def _extract_db_objects_comment(self, content: str) -> str:
        """Extract 'DB objects used' from header."""
        m = re.search(r'#\s*DB objects used\s*-\s*(.*?)(?:\n#\s*Created)', content, re.DOTALL | re.IGNORECASE)
        if m:
            text = m.group(1).strip()
            text = re.sub(r'\n#\s*', ' ', text)
            return text.strip()
        return ""

    def _extract_table_name_vars(self, content: str) -> list[str]:
        """Extract TABLE_NAME / MV_NAME / TBL_NAME and IN_TYPE variable assignments.

        Returns plain values for table names (e.g. 'FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R')
        and prefixed values for type discriminators (e.g. 'IN_TYPE:DISBURSEMENT').
        IN_TYPE is passed as a parameter to procedures such as PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R
        to select which data subset to load, so it is essential for lineage context.
        """
        tables = []
        # Use [^\S\n]* (non-newline whitespace) instead of \s* to prevent
        # crossing line boundaries (e.g. TABLE_NAME=\nexport ORACLE_HOME=...)
        # Use \b to avoid matching inside longer names like TMP_TABLE_NAME.
        for m in re.finditer(r'\b(?:TABLE_NAME|MV_NAME|TBL_NAME)[^\S\n]*=[^\S\n]*([A-Za-z_][A-Za-z0-9_]*)', content):
            tables.append(m.group(1).upper())
        # Capture IN_TYPE — a data-type discriminator passed to procedures
        # (e.g. IN_TYPE=DISBURSEMENT, BENEFIT_PAYMENT, ADJUSTMENT).
        # Tagged with 'IN_TYPE:' prefix to distinguish from plain table names.
        for m in re.finditer(r'\bIN_TYPE[^\S\n]*=[^\S\n]*([A-Za-z_][A-Za-z0-9_]*)', content):
            tables.append(f"IN_TYPE:{m.group(1).upper()}")
        return tables

    # ── Pattern 1: SSH Remote ─────────────────────────────────────────────

    def _extract_ssh_remote(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract SSH remote script calls."""
        refs = []
        for m in re.finditer(r'ssh\s+\S+\s+"[^"]*?(/\S+\.sh)\s', content):
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="SSH_REMOTE",
                object_type="REMOTE_SCRIPT",
                schema="",
                object_name=Path(m.group(1)).name,
                sub_object="",
                is_parameterized=True,
                param_position="$1,$2,...",
                table_references=[],
                static_sql="",
                remote_script=m.group(1),
                notes=description
            ))
        return refs

    # ── Pattern 2: EXECUTE IMMEDIATE (dynamic package) ────────────────────

    def _extract_execute_immediate(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract EXECUTE IMMEDIATE with dynamic package/procedure calls."""
        refs = []

        # Pattern: EXECUTE IMMEDIATE 'begin ' || 'SCHEMA.' || '$var' || '.main(...)...'
        for m in re.finditer(
            r"EXECUTE\s+IMMEDIATE\s+'begin\s*'\s*\|\|\s*'(\w+)\.'\s*\|\|\s*'\$(\w+)'\s*\|\|\s*'\.(\w+)",
            content, re.IGNORECASE
        ):
            schema = m.group(1).upper()
            param_var = m.group(2)
            sub_obj = m.group(3)
            # Find which positional param this variable maps to
            param_pos = self._find_param_position(content, param_var)
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="EXECUTE_IMMEDIATE_DYNAMIC",
                object_type="PACKAGE",
                schema=schema,
                object_name=f"${param_var} (from TIDAL param {param_pos})",
                sub_object=sub_obj,
                is_parameterized=True,
                param_position=param_pos,
                table_references=[],
                static_sql="",
                remote_script="",
                notes=description
            ))

        # Pattern: EXECUTE IMMEDIATE 'begin atomic.pkg_name' || '.main(...)...'
        for m in re.finditer(
            r"EXECUTE\s+IMMEDIATE\s+'begin\s+(\w+)\.(\w+)'\s*\|\|\s*'\.(\w+)",
            content, re.IGNORECASE
        ):
            schema = m.group(1).upper()
            pkg = m.group(2).upper()
            sub_obj = m.group(3)
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="EXECUTE_IMMEDIATE_STATIC",
                object_type="PACKAGE",
                schema=schema,
                object_name=pkg,
                sub_object=sub_obj,
                is_parameterized=self._has_param_in_args(content, m.end()),
                param_position=self._get_param_positions_from_using(content, m.end()),
                table_references=[],
                static_sql="",
                remote_script="",
                notes=description
            ))

        # Pattern: EXECUTE IMMEDIATE 'begin ATOMIC.PRC_xxx' || '(...)...'
        for m in re.finditer(
            r"EXECUTE\s+IMMEDIATE\s+'begin\s+(\w+)\.(\w+)'\s*\|\|\s*'\(",
            content, re.IGNORECASE
        ):
            schema = m.group(1).upper()
            proc = m.group(2).upper()
            # Skip if already captured as package pattern above
            if any(r.object_name == proc for r in refs):
                continue
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="EXECUTE_IMMEDIATE_STATIC",
                object_type="PROCEDURE",
                schema=schema,
                object_name=proc,
                sub_object="",
                is_parameterized=self._has_param_in_args(content, m.end()),
                param_position=self._get_param_positions_from_using(content, m.end()),
                table_references=[],
                static_sql="",
                remote_script="",
                notes=description
            ))

        # Pattern: EXECUTE IMMEDIATE 'BEGIN schema.pkg.proc(...); END;' (literal string)
        # e.g., EXECUTE IMMEDIATE 'BEGIN atomic_plsql.pkg_grp_load_rpt_month_end_update_flag.main(202502); END;'
        for m in re.finditer(
            r"EXECUTE\s+IMMEDIATE\s+'BEGIN\s+(\w+)\.(\w+)\.(\w+)\s*\([^)]*\)\s*;\s*END\s*;'",
            content, re.IGNORECASE
        ):
            schema = m.group(1).upper()
            pkg = m.group(2).upper()
            sub = m.group(3).upper()
            if any(r.object_name == pkg for r in refs):
                continue
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="EXECUTE_IMMEDIATE_STATIC",
                object_type="PACKAGE",
                schema=schema,
                object_name=pkg,
                sub_object=sub,
                is_parameterized=False,
                param_position="",
                table_references=[],
                static_sql="",
                remote_script="",
                notes=description
            ))

        # Pattern: EXECUTE IMMEDIATE 'begin '|| 'SCHEMA.' || '$var' || '($args)...;end;'
        # OR: EXECUTE IMMEDIATE 'begin '|| 'SCHEMA.' || '$var' || ';end;'
        # Direct procedure call (no package sub-object) with param-based proc name.
        # Negative lookahead (?!\s*'\.\w) ensures we don't capture the pkg.sub form.
        for m in re.finditer(
            r"EXECUTE\s+IMMEDIATE\s+'begin\s*'\s*\|\|\s*'(\w+)\.'\s*\|\|\s*'\$(\w+)'\s*\|\|(?!\s*'\.\w)",
            content, re.IGNORECASE
        ):
            schema = m.group(1).upper()
            param_var = m.group(2)
            # Skip if this var was already captured as a pkg.sub pattern (has sub_object)
            if any(r.schema == schema and r.sub_object for r in refs):
                continue
            param_pos = self._find_param_position(content, param_var)
            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type="EXECUTE_IMMEDIATE_DYNAMIC",
                object_type="PROCEDURE",
                schema=schema,
                object_name=f"${param_var} (from TIDAL param {param_pos})",
                sub_object="",
                is_parameterized=True,
                param_position=param_pos,
                table_references=[],
                static_sql="",
                remote_script="",
                notes=description
            ))

        return refs

    def _find_param_position(self, content: str, var_name: str) -> str:
        """Find which positional parameter ($1, $2, etc.) a variable is assigned from."""
        m = re.search(rf'{var_name}\s*=\s*\$(\d+)', content)
        if m:
            return f"${m.group(1)}"
        return "unknown"

    def _has_param_in_args(self, content: str, pos: int) -> bool:
        """Check if USING clause after pos contains shell variables."""
        chunk = content[pos:pos+500]
        return bool(re.search(r'\$\{?\w+\}?', chunk))

    def _get_param_positions_from_using(self, content: str, pos: int) -> str:
        """Extract parameter positions from USING clause."""
        chunk = content[pos:pos+500]
        m = re.search(r'USING\s+(.*?);', chunk, re.IGNORECASE | re.DOTALL)
        if m:
            using_vars = m.group(1).strip()
            # Find which positional params these map to
            var_names = re.findall(r'(\w+)', using_vars)
            positions = []
            for v in var_names:
                pm = re.search(rf'{v}\s*=\s*\$(\d+)', content)
                if pm:
                    positions.append(f"${pm.group(1)}")
            if positions:
                return ",".join(positions)
        return ""

    # ── Pattern 3: MV Refresh ─────────────────────────────────────────────

    def _extract_mv_refresh(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract dbms_mview.refresh calls (both literal string and variable forms)."""
        refs = []
        # Match both:
        #   dbms_mview.refresh('LITERAL_MV_NAME', ...)  — quoted string
        #   dbms_mview.refresh(VARIABLE, ...)            — variable name
        for m in re.finditer(r"dbms_mview\.refresh\s*\(\s*(?:'([^']+)'|(\w+))", content, re.IGNORECASE):
            literal_name = m.group(1)   # set when MV name is a quoted string literal
            mv_var = m.group(2)         # set when MV name is a variable

            if literal_name:
                # Hardcoded MV name as a string literal — no resolution needed
                is_param = False
                param_pos = ""
                display_name = literal_name.upper()
                needle = literal_name
            else:
                # Variable — attempt full resolution chain
                is_param, param_pos, resolved = self._resolve_variable(content, mv_var)

                # If not truly resolved (fallback returned var_name itself), check if mv_var is a
                # PL/SQL local variable initialized from a shell variable:
                #   e.g.  V_MV_NAME VARCHAR2(300):='${MV_NAME}';
                if not is_param and resolved == mv_var.upper():
                    plsql_init = re.search(
                        rf'{re.escape(mv_var)}\s+\w+(?:\(\d+\))?\s*:=\s*\'(?:\$\{{(\w+)\}}|\$(\w+))\'',
                        content, re.IGNORECASE
                    )
                    if plsql_init:
                        shell_var = plsql_init.group(1) or plsql_init.group(2)
                        is_param, param_pos, resolved = self._resolve_variable(content, shell_var)
                        if not is_param and resolved == shell_var.upper():
                            resolved = shell_var.upper()

                if is_param:
                    display_name = f"(from TIDAL param {param_pos})"
                elif resolved and resolved != mv_var.upper():
                    display_name = resolved
                else:
                    display_name = mv_var.upper()
                needle = mv_var

            # Check for TRUNCATE TABLE before refresh (SSL pattern)
            has_truncate = bool(re.search(r"TRUNCATE\s+TABLE.*?" + re.escape(needle), content, re.IGNORECASE))
            ptype = "MV_REFRESH_WITH_TRUNCATE" if has_truncate else "MV_REFRESH"

            refs.append(SQLObjectRef(
                shell_script=filename,
                pattern_type=ptype,
                object_type="MATERIALIZED_VIEW",
                schema="",
                object_name=display_name,
                sub_object="DBMS_MVIEW.REFRESH",
                is_parameterized=is_param,
                param_position=param_pos,
                table_references=self._extract_table_name_vars(content),
                static_sql="",
                remote_script="",
                notes=description
            ))
        return refs

    # ── Pattern 4: Direct PL/SQL Calls ────────────────────────────────────

    def _extract_direct_plsql_calls(self, content: str, filename: str, description: str, table_vars: list) -> list[SQLObjectRef]:
        """Extract direct PL/SQL package/procedure calls from heredoc SQL blocks."""
        refs = []

        # Extract content inside heredoc (between <<ENDOFSQL and ENDOFSQL, or piped echo)
        sql_blocks = self._extract_sql_blocks(content)

        for sql_block in sql_blocks:
            # Skip EXECUTE IMMEDIATE blocks (handled separately)
            if re.search(r'EXECUTE\s+IMMEDIATE', sql_block, re.IGNORECASE):
                continue
            # Skip dbms_mview.refresh blocks (handled separately)
            if re.search(r'dbms_mview\.refresh', sql_block, re.IGNORECASE):
                continue

            # Strip single-quoted string literals before pattern matching to avoid
            # false positives from PKG_ names inside log message strings, e.g.:
            #   LOG_TIME(..., '1.a Call package PKG_GRP_LOAD_RPT_CLAIM_TASKS_R_INC.main', ...)
            # The actual call PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.main; stays unaffected.
            clean_block = self._strip_string_literals(sql_block)

            # Pattern A: schema.PACKAGE.PROCEDURE(args)
            # e.g., atomic.PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R(OUT_STATUS)
            for m in re.finditer(
                r'(?<![\'"])(\w+)\.(\w+)\.(\w+)\s*(?:\(([^)]*)\))?',
                clean_block, re.IGNORECASE
            ):
                schema = m.group(1).upper()
                pkg = m.group(2).upper()
                proc = m.group(3).upper()
                # Skip LOG_TIME, DBMS_UTILITY, DBMS_OUTPUT, SQLERRM etc.
                if pkg in ('LOG_TIME', 'DBMS_UTILITY', 'DBMS_OUTPUT', 'DBMS_MVIEW') or \
                   schema in ('DBMS_UTILITY', 'DBMS_OUTPUT', 'DBMS_MVIEW', 'V_START_TIME'):
                    continue
                if proc in ('GET_TIME', 'PUT_LINE'):
                    continue
                # Skip version-like patterns (e.g., 19.0.0 from Oracle path)
                if re.match(r'^\d+$', schema) or re.match(r'^\d+$', pkg):
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DIRECT_PKG_PROC_CALL",
                    object_type="PACKAGE",
                    schema=schema,
                    object_name=pkg,
                    sub_object=proc,
                    is_parameterized=False,
                    param_position="",
                    table_references=table_vars,
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

            # Pattern B: schema.PROCEDURE(args) — NOT schema.PKG.proc
            # e.g., atomic.PRC_FCT_RPT_CLAIM_SUMMARY_R_daily
            for m in re.finditer(
                r'(?<![\'"\w.])(\w+)\.(\w+)\s*(?:\(([^)]*)\))?\s*;',
                clean_block, re.IGNORECASE
            ):
                schema = m.group(1).upper()
                obj = m.group(2).upper()
                # Skip already captured pkg.proc, and skip utility calls
                if schema in ('DBMS_UTILITY', 'DBMS_OUTPUT', 'DBMS_MVIEW', 'V_START_TIME'):
                    continue
                if obj in ('GET_TIME', 'PUT_LINE', 'LOG_TIME', 'REFRESH'):
                    continue
                # Skip SQL.SQLCODE, version patterns
                if schema == 'SQL' and obj == 'SQLCODE':
                    continue
                if re.match(r'^\d+$', schema) or re.match(r'^\d+$', obj):
                    continue
                # Skip if this is a pkg.proc pattern (has 3 dots)
                pre_context = clean_block[max(0, m.start()-1):m.start()]
                if pre_context and pre_context[-1:] == '.':
                    continue
                # Check it's not part of a 3-part name
                post_check = clean_block[m.end():m.end()+50]
                if post_check.lstrip().startswith('.'):
                    continue
                # Skip if it looks like ATOMIC.LOG_TIME
                if obj == 'LOG_TIME':
                    continue
                # Skip PKG_xxx.main — these are package.main calls, handled by Pattern C
                if obj == 'MAIN' and schema.startswith('PKG_'):
                    continue
                # Reclassify PKG_xxx.PRC_yyy as PACKAGE (not schema.procedure).
                # e.g., PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R
                # has no schema prefix — Pattern B would treat PKG_ name as schema, which is wrong.
                if re.match(r'^PKG_', schema, re.IGNORECASE):
                    refs.append(SQLObjectRef(
                        shell_script=filename,
                        pattern_type="DIRECT_PKG_PROC_CALL",
                        object_type="PACKAGE",
                        schema="ATOMIC",  # default schema when none specified
                        object_name=schema,
                        sub_object=obj,
                        is_parameterized=False,
                        param_position="",
                        table_references=table_vars,
                        static_sql="",
                        remote_script="",
                        notes=description
                    ))
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DIRECT_PROC_CALL",
                    object_type="PROCEDURE",
                    schema=schema,
                    object_name=obj,
                    sub_object="",
                    is_parameterized=False,
                    param_position="",
                    table_references=table_vars,
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

            # Pattern C: PACKAGE_NAME.main (no schema prefix)
            # e.g., PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.main
            for m in re.finditer(
                r'(?<![\'"\w.])([A-Z_][A-Z0-9_]*)\.(main)\b',
                clean_block, re.IGNORECASE
            ):
                pkg = m.group(1).upper()
                sub = m.group(2).lower()
                # Skip utility objects
                if pkg in ('ATOMIC', 'DBMS_UTILITY', 'DBMS_OUTPUT', 'V_START_TIME', 'DBMS_MVIEW', 'SQL'):
                    continue
                if re.match(r'^\d+', pkg):
                    continue
                # Skip if already captured via schema.pkg.proc pattern OR via Pattern B
                already = any(r.object_name == pkg or r.schema == pkg for r in refs)
                if already:
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DIRECT_PKG_MAIN_CALL",
                    object_type="PACKAGE",
                    schema="ATOMIC",  # Default schema
                    object_name=pkg,
                    sub_object=sub,
                    is_parameterized=False,
                    param_position="",
                    table_references=table_vars,
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

            # Pattern E: schema.$variable(args) — shell variable as procedure name in heredoc
            # e.g., ATOMIC.$v_prc_name_r(n_status_r);
            for m in re.finditer(
                r'(?<![\'".\w])(\w+)\.\$(\w+)\s*\(([^)]*)\)\s*;',
                clean_block, re.IGNORECASE
            ):
                schema = m.group(1).upper()
                var_name = m.group(2)
                if schema in ('DBMS_UTILITY', 'DBMS_OUTPUT', 'DBMS_MVIEW'):
                    continue
                param_pos = self._find_param_position(content, var_name)
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DIRECT_PROC_CALL",
                    object_type="PROCEDURE",
                    schema=schema,
                    object_name=f"${var_name} (from TIDAL param {param_pos})",
                    sub_object="",
                    is_parameterized=True,
                    param_position=param_pos,
                    table_references=table_vars,
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

            # Pattern D: Standalone procedure call (no schema, no package)
            # e.g., PROC_REBUILD_INDEXES_RPT_CLAIM_PAYMENT_R;
            for m in re.finditer(
                r'(?<![\'"\w.])(?:PROC_|PRC_)([A-Z0-9_]+?)(?:\s*\(([^)]*)\))?\s*;',
                clean_block, re.IGNORECASE
            ):
                proc_suffix = m.group(1).upper()
                full_name = m.group(0).strip().rstrip(';').strip()
                # Extract just the proc name
                proc_name_match = re.match(r'((?:PROC_|PRC_)\w+)', full_name, re.IGNORECASE)
                if proc_name_match:
                    proc_name = proc_name_match.group(1).upper()
                else:
                    proc_name = full_name.upper()
                # Skip if already captured
                already = any(r.object_name == proc_name or r.sub_object == proc_name for r in refs)
                if already:
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DIRECT_PROC_CALL",
                    object_type="PROCEDURE",
                    schema="ATOMIC",
                    object_name=proc_name,
                    sub_object="",
                    is_parameterized=False,
                    param_position="",
                    table_references=table_vars,
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

        # Deduplicate by (schema, object_name, sub_object) — same object matched
        # multiple times (e.g., once in actual call, once inside a string literal)
        seen_keys = set()
        deduped = []
        for r in refs:
            key = (r.schema, r.object_name.upper(), r.sub_object.upper())
            if key not in seen_keys:
                seen_keys.add(key)
                deduped.append(r)
        return deduped

    # ── Pattern 5: Static SQL ─────────────────────────────────────────────

    def _extract_static_sql(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract static INSERT INTO ... SELECT FROM statements."""
        refs = []
        sql_blocks = self._extract_sql_blocks(content)

        for sql_block in sql_blocks:
            # Find INSERT INTO ... SELECT ... FROM patterns
            for m in re.finditer(
                r'INSERT\s+(?:/\*.*?\*/\s*)?INTO\s+(\S+)\s*(.*?)(?:;|\bEND\b)',
                sql_block, re.IGNORECASE | re.DOTALL
            ):
                target_table = self._clean_table_name(m.group(1))
                rest = m.group(2)

                # Extract source tables from SELECT ... FROM
                source_tables = []
                for fm in re.finditer(r'\bFROM\s+(\S+)', rest, re.IGNORECASE):
                    src = self._clean_table_name(fm.group(1))
                    if src and not src.startswith('(') and src.upper() != 'DUAL':
                        source_tables.append(src)

                # Also check JOIN
                for jm in re.finditer(r'\bJOIN\s+(\S+)', rest, re.IGNORECASE):
                    src = self._clean_table_name(jm.group(1))
                    if src and not src.startswith('('):
                        source_tables.append(src)

                if target_table:
                    # Truncate the static SQL for readability
                    raw_sql = m.group(0).strip()
                    if len(raw_sql) > 500:
                        raw_sql = raw_sql[:500] + "..."

                    refs.append(SQLObjectRef(
                        shell_script=filename,
                        pattern_type="STATIC_SQL",
                        object_type="INSERT_SELECT",
                        schema="",
                        object_name=target_table,
                        sub_object="",
                        is_parameterized=False,
                        param_position="",
                        table_references=source_tables,
                        static_sql=raw_sql,
                        remote_script="",
                        notes=f"INSERT INTO {target_table} SELECT FROM {', '.join(source_tables)}"
                    ))

        return refs

    # ── Pattern 6: TRUNCATE TABLE ─────────────────────────────────────────

    def _extract_truncate(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract standalone TRUNCATE TABLE statements (not part of MV refresh)."""
        refs = []
        sql_blocks = self._extract_sql_blocks(content)
        for sql_block in sql_blocks:
            # Skip if dbms_mview.refresh is in this block (handled by MV pattern)
            if re.search(r'dbms_mview\.refresh', sql_block, re.IGNORECASE):
                continue

            # Pattern A: EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || var  (concatenated variable)
            for m in re.finditer(
                r"execute\s+immediate\s+'TRUNCATE\s+TABLE\s+'\s*\|\|\s*(\w+)",
                sql_block, re.IGNORECASE
            ):
                var = m.group(1)
                is_param, param_pos, resolved = self._resolve_variable(content, var)
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="TRUNCATE_TABLE",
                    object_type="TABLE",
                    schema="",
                    object_name=resolved if resolved else var,
                    sub_object="TRUNCATE",
                    is_parameterized=is_param,
                    param_position=param_pos,
                    table_references=[],
                    static_sql="",
                    remote_script="",
                    notes=description
                ))

            # Pattern B: EXECUTE IMMEDIATE 'TRUNCATE TABLE [schema.]table [PURGE SNAPSHOT LOG]'
            # (hardcoded literal string inside EXECUTE IMMEDIATE)
            for m in re.finditer(
                r"EXECUTE\s+IMMEDIATE\s+'TRUNCATE\s+TABLE\s+(\w+(?:\.\w+)?)\b[^']*'",
                sql_block, re.IGNORECASE
            ):
                table_ref = m.group(1)
                parts = table_ref.split('.')
                table_name = parts[-1].upper()
                schema = parts[0].upper() if len(parts) > 1 else ""
                if any(r.object_name == table_name for r in refs):
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="TRUNCATE_TABLE",
                    object_type="TABLE",
                    schema=schema,
                    object_name=table_name,
                    sub_object="TRUNCATE",
                    is_parameterized=False,
                    param_position="",
                    table_references=[],
                    static_sql="",
                    remote_script="",
                    notes=description
                ))
        return refs

    # ── Pattern 7: DELETE FROM ────────────────────────────────────────────

    def _extract_delete(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract DELETE FROM statements inside SQL blocks."""
        refs = []
        sql_blocks = self._extract_sql_blocks(content)
        for sql_block in sql_blocks:
            for m in re.finditer(
                r'DELETE\s+(?:/\*[^*]*\*/\s*)?FROM\s+(\w+(?:\.\w+)?)\b',
                sql_block, re.IGNORECASE
            ):
                table_ref = m.group(1)
                parts = table_ref.split('.')
                table_name = parts[-1].upper()
                schema = parts[0].upper() if len(parts) > 1 else ""
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="DELETE_FROM",
                    object_type="TABLE",
                    schema=schema,
                    object_name=table_name,
                    sub_object="DELETE",
                    is_parameterized=False,
                    param_position="",
                    table_references=[],
                    static_sql="",
                    remote_script="",
                    notes=description
                ))
        # Deduplicate by (schema, object_name)
        seen = set()
        deduped = []
        for r in refs:
            key = (r.schema, r.object_name)
            if key not in seen:
                seen.add(key)
                deduped.append(r)
        return deduped

    # ── Pattern 8: UPDATE TABLE ───────────────────────────────────────────

    def _extract_update(self, content: str, filename: str, description: str) -> list[SQLObjectRef]:
        """Extract UPDATE TABLE SET statements inside SQL blocks."""
        refs = []
        sql_blocks = self._extract_sql_blocks(content)
        for sql_block in sql_blocks:
            for m in re.finditer(
                r'UPDATE\s+(?:/\*[^*]*\*/\s*)?(\w+(?:\.\w+)?)\b(?:\s+\w+)?\s+SET\s',
                sql_block, re.IGNORECASE
            ):
                table_ref = m.group(1)
                parts = table_ref.split('.')
                table_name = parts[-1].upper()
                schema = parts[0].upper() if len(parts) > 1 else ""
                # Skip Oracle SQL*Plus commands that look like UPDATE
                if table_name in ('SQLERROR', 'SERVEROUTPUT', 'TIMING', 'FEEDBACK', 'WHENEVER'):
                    continue
                refs.append(SQLObjectRef(
                    shell_script=filename,
                    pattern_type="UPDATE_TABLE",
                    object_type="TABLE",
                    schema=schema,
                    object_name=table_name,
                    sub_object="UPDATE",
                    is_parameterized=False,
                    param_position="",
                    table_references=[],
                    static_sql="",
                    remote_script="",
                    notes=description
                ))
        # Deduplicate by (schema, object_name)
        seen = set()
        deduped = []
        for r in refs:
            key = (r.schema, r.object_name)
            if key not in seen:
                seen.add(key)
                deduped.append(r)
        return deduped

    # ── Helpers ───────────────────────────────────────────────────────────

    def _extract_sql_blocks(self, content: str) -> list[str]:
        """Extract SQL content from heredoc blocks and piped echo statements."""
        blocks = []

        # Heredoc pattern: <<ENDOFSQL ... ENDOFSQL (or similar)
        for m in re.finditer(r'<<\s*(\w+)(.*?)^\1\b', content, re.DOTALL | re.MULTILINE):
            blocks.append(m.group(2))

        # Piped echo to sqlplus: echo "..." | sqlplus
        for m in re.finditer(r'echo\s+"(.*?)"\s*\|', content, re.DOTALL):
            blocks.append(m.group(1))

        # Also try $( echo "..." | sqlplus pattern
        for m in re.finditer(r'\$\(\s*echo\s+"(.*?)"\s*\|', content, re.DOTALL):
            if m.group(1) not in [b for b in blocks]:
                blocks.append(m.group(1))

        return blocks

    def _resolve_variable(self, content: str, var_name: str) -> tuple[bool, str, str]:
        """
        Resolve a variable to check if it comes from a shell parameter.
        Returns: (is_parameterized, param_position, resolved_value)
        """
        # Check if directly assigned from positional param
        m = re.search(rf'{var_name}\s*=\s*\$(\d+)', content)
        if m:
            return (True, f"${m.group(1)}", "")

        # Check if assigned a hardcoded value
        m = re.search(rf'{var_name}\s*=\s*([A-Za-z_][A-Za-z0-9_]*)\s*$', content, re.MULTILINE)
        if m:
            return (False, "", m.group(1).upper())

        return (False, "", var_name.upper())

    def _clean_table_name(self, name: str) -> str:
        """Clean a table name reference."""
        name = name.strip()
        # Remove hints
        name = re.sub(r'/\*.*?\*/', '', name).strip()
        # Remove schema prefix
        if '.' in name:
            parts = name.split('.')
            name = parts[-1]
        # Remove quotes
        name = name.strip('"\'')
        return name.upper() if name else ""

    def _strip_string_literals(self, sql: str) -> str:
        """Replace the *contents* of single-quoted string literals with a placeholder.
        This prevents PKG_ / PRC_ names that appear only inside Oracle string literals
        (e.g., LOG_TIME log messages) from being matched as real procedure calls.
        Single-quoted Oracle strings may span multiple lines; the regex uses DOTALL.
        Escaped single quotes ('') inside strings are handled by the non-greedy match.
        """
        return re.sub(r"'[^']*'", "''", sql, flags=re.DOTALL)


# ─────────────────────────────────────────────────────────────────────────────
# DEDUPLICATION & FILTERING
# ─────────────────────────────────────────────────────────────────────────────

def deduplicate_refs(refs: list[SQLObjectRef]) -> list[SQLObjectRef]:
    """Remove duplicate entries. Prefer PACKAGE over PROCEDURE for PKG_ objects, prefer schema-qualified."""
    # Group by (shell_script, normalized object identity)
    by_script = {}
    for r in refs:
        key = r.shell_script
        if key not in by_script:
            by_script[key] = []
        by_script[key].append(r)

    deduped = []
    for script, script_refs in by_script.items():
        seen_objects = {}  # object_name -> best ref
        for r in script_refs:
            obj_key = (r.object_name, r.sub_object)
            if obj_key in seen_objects:
                existing = seen_objects[obj_key]
                # Prefer the one with schema
                if r.schema and not existing.schema:
                    seen_objects[obj_key] = r
                # Prefer PACKAGE over PROCEDURE for PKG_ objects
                elif r.object_type == 'PACKAGE' and existing.object_type == 'PROCEDURE':
                    seen_objects[obj_key] = r
            else:
                seen_objects[obj_key] = r
        deduped.extend(seen_objects.values())

    return deduped


# ─────────────────────────────────────────────────────────────────────────────
# OUTPUT
# ─────────────────────────────────────────────────────────────────────────────

def write_csv(refs: list[SQLObjectRef], output_path: Path):
    """Write results to CSV."""
    fieldnames = [
        'shell_script', 'pattern_type', 'object_type', 'schema',
        'object_name', 'sub_object', 'is_parameterized', 'param_position',
        'table_references', 'static_sql', 'remote_script', 'notes'
    ]
    with open(output_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in refs:
            row = asdict(r)
            row['table_references'] = '; '.join(row['table_references']) if row['table_references'] else ''
            writer.writerow(row)


def write_json(refs: list[SQLObjectRef], output_path: Path):
    """Write results to JSON."""
    data = [asdict(r) for r in refs]
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def print_summary(refs: list[SQLObjectRef]):
    """Print a summary of findings."""
    print("\n" + "=" * 80)
    print("SHELL SCRIPT PARSER — SUMMARY")
    print("=" * 80)

    total_scripts = len(set(r.shell_script for r in refs))
    print(f"\nTotal shell scripts parsed: {total_scripts}")
    print(f"Total SQL object references found: {len(refs)}")

    # By pattern type
    print("\n--- By Pattern Type ---")
    pattern_counts = {}
    for r in refs:
        pattern_counts[r.pattern_type] = pattern_counts.get(r.pattern_type, 0) + 1
    for p, c in sorted(pattern_counts.items(), key=lambda x: -x[1]):
        print(f"  {p:40s} : {c}")

    # By object type
    print("\n--- By Object Type ---")
    obj_counts = {}
    for r in refs:
        obj_counts[r.object_type] = obj_counts.get(r.object_type, 0) + 1
    for o, c in sorted(obj_counts.items(), key=lambda x: -x[1]):
        print(f"  {o:40s} : {c}")

    # Parameterized vs hardcoded
    param = sum(1 for r in refs if r.is_parameterized)
    hardcoded = len(refs) - param
    print(f"\n--- Parameterized vs Hardcoded ---")
    print(f"  Hardcoded (in shell script)              : {hardcoded}")
    print(f"  Parameterized (from TIDAL params)        : {param}")

    # List all unique SQL objects
    print("\n--- Unique SQL Objects (Hardcoded) ---")
    unique_objs = set()
    for r in refs:
        if not r.is_parameterized and r.object_name and r.object_type not in ('ERROR', 'UNKNOWN', 'INSERT_SELECT', 'REMOTE_SCRIPT', 'TABLE'):
            full = f"{r.schema + '.' if r.schema else ''}{r.object_name}{('.' + r.sub_object) if r.sub_object else ''}"
            unique_objs.add((r.object_type, full))
    for otype, name in sorted(unique_objs):
        print(f"  [{otype:12s}] {name}")

    print("\n" + "=" * 80)


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Parse EDW shell scripts to extract SQL objects")
    parser.add_argument('--sh-dir', type=str,
                        default=str(Path(__file__).resolve().parent / "RSL-Delphi-TidalEDW_SH_scripts"),
                        help="Directory containing .sh files")
    parser.add_argument('--output-dir', type=str,
                        default=str(Path(__file__).resolve().parent / "output"),
                        help="Output directory for results")
    args = parser.parse_args()

    sh_dir = Path(args.sh_dir)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"Parsing shell scripts from: {sh_dir}")
    print(f"Output directory: {output_dir}")

    shell_parser = ShellParser(sh_dir)
    refs = shell_parser.parse_all()
    refs = deduplicate_refs(refs)

    # Write outputs
    csv_path = output_dir / "shell_parsed_objects.csv"
    json_path = output_dir / "shell_parsed_objects.json"

    write_csv(refs, csv_path)
    write_json(refs, json_path)

    print(f"\nCSV written to: {csv_path}")
    print(f"JSON written to: {json_path}")

    print_summary(refs)


if __name__ == "__main__":
    main()
