"""
Tidal Recursive Job Lineage Generator
======================================
Starting from each RPT root job, recursively walks all upstream
DEPENDENT_JOB edges from TIDAL_15_April_updated.xlsx.

Meaning of the Excel relationship:
  JOB_NAME depends on DEPENDENT_JOB  →  DEPENDENT_JOB must run BEFORE JOB_NAME.

Outputs (in /output/):
  tidal_recursive_lineage.csv   — flat edge-list with depth + metadata
  tidal_recursive_lineage.txt   — indented tree view per RPT table

CSV columns:
  RPT_TABLE | ROOT_JOB | DEPTH | JOB_NAME | DEPENDENT_JOB
  | JOB_CATEGORY | DEP_CATEGORY | INFERRED_TABLE
  | CMD | PARAMS | PARENT_NAME | DURATION_MIN

DEPTH = depth of JOB_NAME measured from the root (root = 0).
Each row represents one edge: JOB_NAME → DEPENDENT_JOB.

Usage:
  python generate_tidal_job_recursive_lineage.py
"""

import os
import re
import csv
import shutil
import openpyxl
from collections import defaultdict, deque
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_DIR = os.path.join(SCRIPT_DIR, "input")
# Primary TIDAL dump — may be missing some jobs (Excel row-limit truncation etc.),
# so it's supplemented below with the 30-day CSV export and the newer xlsx dump,
# same sources/logic as tidal_shell_combiner.py.
TIDAL_FILE = os.path.join(INPUT_DIR, "TIDAL_15_April_updated.xlsx")
TIDAL_SUPPLEMENT = os.path.join(INPUT_DIR, "Tidal_Deps_Last30days_as_of_20270617.csv")
TIDAL_SUPPLEMENT2 = os.path.join(INPUT_DIR, "Tidal Deps 20270713.xlsx")
OUTPUT_DIR = os.path.join(SCRIPT_DIR, "output")
OUTPUT_CSV = os.path.join(OUTPUT_DIR, "tidal_recursive_lineage.csv")
OUTPUT_TXT = os.path.join(OUTPUT_DIR, "tidal_recursive_lineage.txt")

# ── The 14 target RPT root jobs ────────────────────────────────────────────
RPT_ROOT_JOBS = {
    "RPT_CLAIM_DTL_R":              "EDP_GRP_EDW_LOAD_RPT_CLAIM_DTL_R_UPD_IND_COLS",  #"EDP_GRP_EDW_LOAD_RPT_CLAIM_DTL_R-19",
    "RPT_CLAIM_NOTE_R":             "EDP_GRP_EDW_LOAD_RPT_CLAIM_NOTE_R-18",
    "RPT_CLAIM_PAYMENT_DTL_R":      "EDP_GRP_EDW_LOAD_RPT_CLAIM_PAYMENT_DTL_R-21",
    "RPT_CLAIM_PAYMENT_R":          "EDP_GRP_EDW_LOAD_RPT_CLAIM_PAYMENT_R-20",
    "RPT_CLAIM_SUM_R":              "EDP_GRP_EDW_LOAD_RPT_CLAIM_SUM_R_UPD_COLS",   #"EDP_GRP_EDW_LOAD_RPT_CLAIM_SUM_R-22",
    "RPT_CLAIM_TASK_R":             "EDP_GRP_EDW_LOAD_RPT_CLAIM_TASK_R-UW-7.1",
    "RPT_CLAIMANT_DTL_R":           "EDP_GRP_EDW_LOAD_RPT_CLAIMANT_DTL_R-23",
    "RPT_FCT_RPT_CLAIM_SUMMARY_R":  "EDP_GRP_EDW_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R-24",
    "RPT_DICS_CLAIMS_DETAIL_OAC_R": "EDP_GRP_EDW_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R-1",
    "RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST": "EDP_GRP_EDW_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST-28",
    "RPT_CLIENT_DTL_R":           "EDP_GRP_EDW_LOAD_RPT_CLIENT_DTL_R-17",
    "RPT_GRP_PRODUCT_R":          "EDP_GRP_EDW_LOAD_RPT_GRP_PRODUCT_R-14",
    "RPT_EMPLOYEE_R":             "EDP_GRP_EDW_LOAD_RPT_EMPLOYEE_R-13",
    "RPT_POLICY_DTL_R":           "EDP_GRP_EDW_LOAD_RPT_POLICY_DTL_R-16",

}

# ── Helpers ────────────────────────────────────────────────────────────────

_PREFIXES = [
    "EDP_GRP_EDW_MV_REFRESH_", "EDP_GRP_EDW_LOAD_", "EDP_GRP_EDW_REFRESH_",
    "EDP_EDW_GRP_PACS_LOAD_", "EDP_EDW_GRP_STACS_LOAD_", "EDP_EDW_GRP_LOAD_",
    "EDP_EDW_CV_SHINKA_LOAD_", "EDP_EDW_DAILY_LOAD_GRP_LOAD_",
    "EDP_DL_EDW_GRP_APS_LOAD_", "EDP_DL_EDW_GRP_PACS_LOAD_",
    "EDP_DL_EDW_GRP_VUE_LOAD_", "EDP_DL_EDW_GRP_STACS_LOAD_",
    "EDP_DL_EDW_GRP_LOAD_", "EDP_DL_EDW_SHINKA_CV_LOAD_",
    "EDP_EDW_EIS_SHINKA_LOAD_", "EDP_EDW_EIS_VUE_LOAD_",
    "EDP_EDW_EIS_APS_LOAD_", "EDP_EDW_EIS_PACS_LOAD_",
    "EDP_EDW_GRP_VUE_LOAD_", "EDP_EDW_GRP_APS_LOAD_",
    "EDL_GRP_DL_STACS_LOAD_", "EDL_GRP_DL_VUE_LOAD_",
    "EDL_GRP_DL_APS_LOAD_", "EDL_GRP_DL_PACS_LOAD_",
    "EDL_DL_EDW_GRP_LOAD_", "EDL_DL_EDW_GRP_APS_LOAD_",
    "EDP_DL_EDW_GRP_", "EDP_EDW_GRP_",
    "EDP_GRP_EDW_",
]


def infer_table(job_name: str) -> str:
    """Strip known prefixes/suffixes to get the likely table name."""
    name = job_name.upper()
    for prefix in _PREFIXES:
        if name.startswith(prefix):
            rest = name[len(prefix):]
            rest = re.sub(
                r'[-_](MONTH_END|UPD_IND_COLS|UPD_COLS|HIST|INCR_LIFE_ADHOC_R|MGIS)$',
                '', rest
            )
            rest = re.sub(r'-[\dUW.]+$', '', rest)
            return rest if rest else ""
    return ""


def classify_job(job_name: str, table: str) -> str:
    upper = job_name.upper()
    tn = (table or "").upper()
    if tn.startswith("RPT_"):
        return "RPT"
    if tn.startswith(("VW_FCT_", "VW_")):
        return "MV"
    if tn.startswith(("FCT_", "VUE_FCT_")):
        return "FCT"
    if tn.startswith("DIM_"):
        return "DIM"
    if tn.startswith("STG_"):
        return "STG"
    if tn.startswith("REF_"):
        return "REF"
    if "_MV_SSL" in tn:
        return "MV"
    if "MV_REFRESH" in upper:
        return "MV"
    if "MONTH_END" in upper:
        return "MONTH_END"
    if "COPY_VUE" in upper or upper.startswith("EDL_"):
        return "SOURCE"
    if "LOAD_STG_" in upper:
        return "STG"
    if "LOAD_DIM_" in upper:
        return "DIM"
    if "LOAD_FCT_" in upper or "LOAD_VUE_FCT_" in upper:
        return "FCT"
    if "LOAD_REF_" in upper:
        return "REF"
    if "LOOKUP" in upper:
        return "REF"
    return "OTHER"


def _safe_open_excel(path: str) -> str:
    """Return a readable copy of the file if the original is locked."""
    try:
        with open(path, 'rb') as f:
            f.read(1)
        return path
    except PermissionError:
        p = Path(path)
        copy_path = p.parent / (p.stem + "_copy" + p.suffix)
        shutil.copy2(str(p), str(copy_path))
        return str(copy_path)


# ── Load Excel / CSV ───────────────────────────────────────────────────────

_NULL_STRS = {'NULL', 'NONE', 'N/A', 'NAN', ''}


def _clean(v):
    if v is None:
        return None
    s = str(v).strip()
    return None if s.upper() in _NULL_STRS else s


def _rows_from_xlsx(path: str):
    """Yield header-keyed (UPPER) dicts from a TIDAL xlsx export."""
    path = _safe_open_excel(path)
    wb = openpyxl.load_workbook(path, read_only=True)
    ws = wb[wb.sheetnames[0]]
    rows = ws.iter_rows(values_only=True)
    headers = [str(h).strip().upper() for h in next(rows)]
    for row in rows:
        yield {headers[i]: _clean(row[i] if i < len(row) else None) for i in range(len(headers))}
    wb.close()


def _rows_from_csv(path: str):
    """Yield header-keyed (UPPER) dicts from a TIDAL CSV multi-run export."""
    with open(path, 'r', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            yield {k.strip().upper(): _clean(v) for k, v in row.items()}


def _merge_tidal_file(path: str, dep_map: dict, job_meta: dict, seen_edges: set) -> tuple[int, int]:
    """Parse one TIDAL file (xlsx or csv) and merge its (job, dep) pairs into
    dep_map/job_meta in place, skipping pairs already present. Job metadata
    (CMD/PARAMS/PARENT_NAME/duration) is only filled in for jobs not yet seen.
    Returns (added_pairs, added_jobs) for logging.
    """
    if not os.path.exists(path):
        print(f"  WARNING: TIDAL file not found, skipping: {path}")
        return 0, 0

    rows = _rows_from_csv(path) if path.lower().endswith('.csv') else _rows_from_xlsx(path)

    added_pairs, added_jobs = 0, 0
    for record in rows:
        jn = record.get('JOB_NAME') or ''
        dj = record.get('DEPENDENT_JOB') or ''
        if not jn:
            continue

        is_new_job = jn not in job_meta
        if is_new_job:
            duration_raw = record.get('TOTAL_RUN_TIME_MIN')
            try:
                duration = round(float(duration_raw), 2) if duration_raw is not None else 0.0
            except (TypeError, ValueError):
                duration = 0.0
            job_meta[jn] = {
                "cmd":          record.get('CMD') or "",
                "params":       record.get('PARAMS') or "",
                "parent":       record.get('PARENT_NAME') or "",
                "duration_min": duration,
            }
            added_jobs += 1

        if dj:
            edge = (jn, dj)
            if edge not in seen_edges:
                seen_edges.add(edge)
                dep_map[jn].append(dj)
                added_pairs += 1

    return added_pairs, added_jobs


def load_tidal(primary_path: str, supplement_paths: list[str] | None = None):
    """Load TIDAL dependencies from a primary file, filling in any (job, dep)
    pairs missing from it using one or more supplement files (same approach as
    tidal_shell_combiner.py — primary wins, supplements only add what's absent).

    Returns:
        dep_map  : dict[job_name -> list[dep_job]]  (ordered, deduped)
        job_meta : dict[job_name -> {cmd, params, parent, duration_min}]
    """
    dep_map: dict[str, list[str]] = defaultdict(list)
    job_meta: dict[str, dict] = {}
    seen_edges: set[tuple[str, str]] = set()

    added_pairs, added_jobs = _merge_tidal_file(primary_path, dep_map, job_meta, seen_edges)
    print(f"  Primary: {added_pairs:,} (job, dep) pairs, {added_jobs:,} unique jobs")

    for supp_path in (supplement_paths or []):
        added_pairs, added_jobs = _merge_tidal_file(supp_path, dep_map, job_meta, seen_edges)
        print(f"  Supplement ({os.path.basename(supp_path)}): added {added_pairs:,} new pairs, "
              f"{added_jobs:,} entirely new jobs")

    return dict(dep_map), job_meta


# ── Recursive BFS per root job ─────────────────────────────────────────────

def bfs_lineage(root_job: str, dep_map: dict, job_meta: dict) -> list[dict]:
    """
    BFS from root_job following DEPENDENT_JOB edges.
    Returns a list of edge dicts ordered by (depth, job_name, dep_job).
    Cycles are detected and skipped.
    """
    # visited tracks which jobs we have already EXPANDED (not just seen)
    # to avoid cycles while still allowing the same dep to appear under
    # multiple parents at different depths.
    edges: list[dict] = []
    # queue entries: (job_name, depth, path_so_far)
    queue: deque[tuple[str, int, tuple]] = deque()
    queue.append((root_job, 0, (root_job,)))

    # Track the minimum depth at which each job was first reached
    # so we don't re-expand a job we already expanded at the same or smaller depth.
    min_depth_seen: dict[str, int] = {root_job: 0}

    while queue:
        job, depth, path = queue.popleft()

        deps = dep_map.get(job, [])
        if not deps:
            continue  # leaf node — no dependencies

        for dep in deps:
            # Cycle guard: if dep is already in the current path, skip
            if dep in path:
                continue

            # Emit edge
            job_tbl = infer_table(job)
            dep_tbl = infer_table(dep)
            meta = job_meta.get(job, {})

            edges.append({
                "DEPTH":          depth,
                "JOB_NAME":       job,
                "DEPENDENT_JOB":  dep,
                "JOB_CATEGORY":   classify_job(job, job_tbl),
                "DEP_CATEGORY":   classify_job(dep, dep_tbl),
                "INFERRED_TABLE": dep_tbl,
                "CMD":            meta.get("cmd", ""),
                "PARAMS":         meta.get("params", ""),
                "PARENT_NAME":    meta.get("parent", ""),
                "DURATION_MIN":   meta.get("duration_min", 0.0),
            })

            # Only expand dep if we haven't already expanded it at a smaller
            # or equal depth (avoids exponential explosion on diamond graphs).
            new_depth = depth + 1
            if dep not in min_depth_seen or min_depth_seen[dep] > new_depth:
                min_depth_seen[dep] = new_depth
                queue.append((dep, new_depth, path + (dep,)))

    return edges


# ── Indented tree builder ──────────────────────────────────────────────────

def build_tree_text(rpt_table: str, root_job: str, dep_map: dict) -> list[str]:
    """
    Produce an indented tree string like:
      [D0] EDP_GRP_EDW_LOAD_RPT_CLAIM_PAYMENT_R-20
        [D1] EDP_GRP_EDW_LOAD_FCT_CLAIM_PMNT_R-14
          [D2] EDP_GRP_EDW_LOAD_DIM_BENEFIT_TYPE_R
          ...
    Cycles are indicated with [CYCLE → <job>].
    """
    lines = [f"{'='*80}", f"RPT TABLE : {rpt_table}", f"ROOT JOB  : {root_job}", ""]

    def _recurse(job: str, depth: int, path: tuple):
        indent = "  " * depth
        label = f"[D{depth}] {job}"
        lines.append(f"{indent}{label}")
        for dep in dep_map.get(job, []):
            if dep in path:
                lines.append(f"{'  '*(depth+1)}[CYCLE → {dep}]")
                continue
            _recurse(dep, depth + 1, path + (dep,))

    # Use iterative DFS to avoid Python recursion limits on deep graphs
    # Stack entries: (job, depth, path, already_printed)
    stack: list[tuple[str, int, tuple, bool]] = [(root_job, 0, (root_job,), False)]
    seen_at: dict[str, int] = {root_job: 0}
    _lines_local: list[str] = []

    def _iter_tree(job: str, depth: int, path: tuple):
        indent = "  " * depth
        _lines_local.append(f"{indent}[D{depth}] {job}")
        for dep in dep_map.get(job, []):
            if dep in path:
                _lines_local.append(f"{'  '*(depth+1)}[CYCLE → {dep}]")
                continue
            already_expanded = dep in seen_at and seen_at[dep] <= depth + 1
            if already_expanded:
                _lines_local.append(
                    f"{'  '*(depth+1)}[D{depth+1}] {dep}  "
                    f"[already expanded at depth {seen_at[dep]}]"
                )
                continue
            seen_at[dep] = depth + 1
            _iter_tree(dep, depth + 1, path + (dep,))

    import sys
    sys.setrecursionlimit(5000)
    _iter_tree(root_job, 0, (root_job,))
    lines.extend(_lines_local)
    lines.append("")
    return lines


# ── Main ───────────────────────────────────────────────────────────────────

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Loading TIDAL_15_April_updated.xlsx (+ supplements) …")
    dep_map, job_meta = load_tidal(TIDAL_FILE, [TIDAL_SUPPLEMENT, TIDAL_SUPPLEMENT2])

    # ── CSV output ─────────────────────────────────────────────────────────
    csv_rows: list[dict] = []
    txt_lines: list[str] = [
        "TIDAL RECURSIVE JOB LINEAGE",
        "Generated from TIDAL_15_April_updated.xlsx + supplements",
        f"Root jobs: {len(RPT_ROOT_JOBS)}",
        "",
    ]

    for rpt_table, root_job in RPT_ROOT_JOBS.items():
        print(f"\n  Processing {rpt_table} -> {root_job}")

        if root_job not in dep_map and root_job not in job_meta:
            print(f"    WARNING: root job '{root_job}' not found in Tidal dump — skipping")
            continue

        edges = bfs_lineage(root_job, dep_map, job_meta)
        print(f"    -> {len(edges)} edges across {max((e['DEPTH'] for e in edges), default=0)+1} depth levels")

        for edge in edges:
            csv_rows.append({
                "RPT_TABLE":      rpt_table,
                "ROOT_JOB":       root_job,
                **edge,
            })

        tree = build_tree_text(rpt_table, root_job, dep_map)
        txt_lines.extend(tree)

    # Write CSV
    fieldnames = [
        "RPT_TABLE", "ROOT_JOB", "DEPTH",
        "JOB_NAME", "DEPENDENT_JOB",
        "JOB_CATEGORY", "DEP_CATEGORY", "INFERRED_TABLE",
        "CMD", "PARAMS", "PARENT_NAME", "DURATION_MIN",
    ]
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_rows)

    # Write TXT tree
    with open(OUTPUT_TXT, "w", encoding="utf-8") as f:
        f.write("\n".join(txt_lines))

    print(f"\n{'='*60}")
    print(f"CSV  -> {OUTPUT_CSV}  ({len(csv_rows):,} rows)")
    print(f"TXT  -> {OUTPUT_TXT}")
    print(f"{'='*60}")

    # ── Per-RPT summary ────────────────────────────────────────────────────
    from itertools import groupby
    print("\nSummary per RPT table:")
    print(f"  {'RPT_TABLE':<40} {'Edges':>6}  {'Max Depth':>9}  {'Unique Jobs':>11}")
    print(f"  {'-'*40} {'-'*6}  {'-'*9}  {'-'*11}")

    rows_by_rpt = defaultdict(list)
    for r in csv_rows:
        rows_by_rpt[r["RPT_TABLE"]].append(r)

    for rpt_table, root_job in RPT_ROOT_JOBS.items():
        rows = rows_by_rpt.get(rpt_table, [])
        if not rows:
            print(f"  {rpt_table:<40} {'N/A':>6}  {'N/A':>9}  {'N/A':>11}")
            continue
        max_depth = max(r["DEPTH"] for r in rows)
        all_jobs = set(r["JOB_NAME"] for r in rows) | set(r["DEPENDENT_JOB"] for r in rows)
        print(f"  {rpt_table:<40} {len(rows):>6}  {max_depth:>9}  {len(all_jobs):>11}")


if __name__ == "__main__":
    main()
