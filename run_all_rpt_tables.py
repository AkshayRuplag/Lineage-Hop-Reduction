#!/usr/bin/env python3
"""
Run hop reduction analysis for ALL RPT tables in a single process.

Loads the graph JSON and lineage XLSX ONCE and reuses the data for every
RPT table — eliminating the N × (subprocess startup + double file I/O)
bottleneck of the old subprocess-per-RPT approach.
"""

import json
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR / "output"
GRAPH_JSON = OUTPUT_DIR / "tidal_dependency_graph.json"


def main():
    # ── Import the analyser module (runs module-level init once) ─────────────
    sys.path.insert(0, str(SCRIPT_DIR))
    import analyze_hop_reduction_merged as arm  # noqa: E402 (local import)

    # ── Load shared data ONCE ─────────────────────────────────────────────────
    print("Loading graph JSON...")
    t0 = time.time()
    with open(GRAPH_JSON, "r", encoding="utf-8") as f:
        all_graphs = json.load(f)

    rpt_tables = sorted(all_graphs.keys())
    if not rpt_tables:
        print("ERROR: No RPT tables found in graph JSON")
        sys.exit(1)

    print(f"Loading lineage XLSX (once for all {len(rpt_tables)} RPTs)...")
    all_lineage = arm.load_all_lineage()
    print(f"Data loaded in {time.time() - t0:.1f}s — "
          f"{len(all_lineage)} lineage rows, {len(rpt_tables)} RPT tables\n")

    print(f"Found {len(rpt_tables)} RPT tables:")
    for i, table in enumerate(rpt_tables, 1):
        print(f"  {i}. {table}")

    print(f"\n{'='*70}")
    print("Starting batch analysis...")
    print(f"{'='*70}\n")

    results = {}
    start_time = time.time()

    for i, rpt_table in enumerate(rpt_tables, 1):
        print(f"\n[{i}/{len(rpt_tables)}] {'='*60}")
        t_rpt = time.time()
        try:
            arm.main(
                rpt_table=rpt_table,
                preloaded_all_graphs=all_graphs,
                preloaded_all_lineage=all_lineage,
            )
            elapsed_rpt = time.time() - t_rpt
            results[rpt_table] = f"OK ({elapsed_rpt:.0f}s)"
        except SystemExit as exc:
            # arm.main() calls sys.exit() on validation errors — catch and continue
            results[rpt_table] = f"FAILED (exit {exc.code})"
            print(f"  *** Skipping {rpt_table} due to error (exit {exc.code}) ***")
        except Exception as exc:
            results[rpt_table] = f"FAILED: {exc}"
            print(f"  *** ERROR for {rpt_table}: {exc} ***")

    elapsed = time.time() - start_time
    
    # Summary
    print(f"\n{'='*70}")
    print(f"BATCH ANALYSIS COMPLETE in {elapsed/60:.1f} minutes ({elapsed:.0f}s)")
    print(f"{'='*70}")
    print(f"Total tables: {len(rpt_tables)}\n")

    success_count = 0
    for table, status in results.items():
        ok = status.startswith("OK")
        icon = "[OK]  " if ok else "[FAIL]"
        print(f"  {icon} {table}: {status}")
        if ok:
            success_count += 1

    print(f"\nSuccessful: {success_count}/{len(rpt_tables)}")

    # List output files
    print(f"\nGenerated recommendation files:")
    hop_rec_dir = OUTPUT_DIR / "hop_reduction_recommendations"
    xlsx_files = sorted(hop_rec_dir.glob("hop_reduction_recommendations_RPT_*.xlsx"))
    for xlsx in xlsx_files:
        size_mb = xlsx.stat().st_size / (1024 * 1024)
        print(f"  - {xlsx.name} ({size_mb:.2f} MB)")

    sys.exit(0 if success_count == len(rpt_tables) else 1)

if __name__ == "__main__":
    main()
