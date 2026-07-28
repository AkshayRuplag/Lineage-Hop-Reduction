"""
RSLI Data Lineage — Pipeline Runner
=====================================
Runs the full lineage + hop-reduction pipeline in order.
All paths are sourced from config.py — edit that file before running.

Usage:
  python run_pipeline.py                    # run all stages
  python run_pipeline.py --from-stage 6    # resume from Stage 6
  python run_pipeline.py --stages 6 7 8    # run specific stages only

Stages:
  1  shell_parser              — parse TIDAL .sh scripts → shell_parsed_objects.csv
  2  clean_and_run_gudu        — clean PL/SQL + run Gudu → All_Metadata_cleaned/  (needs Gudu JAR)
  3  extract_gudu_lineage      — convert Gudu JSON → gudu_lineage_output.csv
  4  llm_lineage_extractor     — LLM column-level lineage → llm_lineage_output.csv  (needs API key)
  5  generate_pkg_proc_analysis— build PKG→proc call structure → PKG_PROC_Analysis_All_Metadata.xlsx
  6  tidal_shell_combiner      — join TIDAL + shell + Gudu + LLM → combined_lineage_latest.csv/xlsx
  7  generate_tidal_graph      — interactive D3 HTML graph → tidal_dependency_graph.html
  8  run_all_rpt_tables        — hop reduction analysis for all 14 RPT tables
  9  generate_master_recs      — consolidate → MASTER_Hop_Reduction_Recommendations.xlsx
  10 generate_verified_savings — savings simulation → verified_savings_simulation_aggregate.xlsx

NOTE: Stages 2 and 4 require external tools (Gudu JAR, LLM API key).
      If you already have gudu_lineage_output.csv and llm_lineage_output.csv,
      copy them to output/ and run from Stage 6 onwards.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

import config as cfg

PYTHON  = sys.executable
HERE    = Path(__file__).resolve().parent


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def _run(script: str, *args, desc: str = ""):
    """Run a Python script in the project directory with given CLI arguments."""
    label = desc or script
    print(f"\n{'='*70}")
    print(f"  {label}")
    print(f"{'='*70}")
    cmd = [PYTHON, str(HERE / script)] + [str(a) for a in args]
    print(f"  CMD: {' '.join(cmd[1:])}\n")
    result = subprocess.run(cmd, cwd=str(HERE))
    if result.returncode != 0:
        print(f"\n  ERROR: {script} exited with code {result.returncode}. Stopping.")
        sys.exit(result.returncode)


def _ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# STAGE FUNCTIONS
# ─────────────────────────────────────────────────────────────────────────────

def stage1_shell_parser():
    """Parse TIDAL .sh scripts to extract SQL objects → shell_parsed_objects.csv."""
    _ensure_dir(cfg.OUTPUT_DIR)
    _run(
        "shell_parser.py",
        "--sh-dir",     cfg.SHELL_SCRIPTS_DIR,
        "--output-dir", cfg.OUTPUT_DIR,
        desc="STAGE 1 — Shell Parser: extract SQL objects from .sh scripts",
    )


def stage2_clean_and_gudu():
    """Clean PL/SQL and run Gudu SQLFlow Lite → All_Metadata_cleaned/ + JSON files."""
    cleaned_dir = cfg.OUTPUT_DIR / "All_Metadata_cleaned"
    _ensure_dir(cleaned_dir)
    _run(
        "clean_and_run_gudu.py",
        "-d",           cfg.ALL_METADATA_DIR,
        "-o",           cleaned_dir,
        "--run-gudu",
        "--gudu-dir",   cfg.GUDU_JAR_DIR,
        "--format",     "json",
        desc="STAGE 2 — Gudu: clean PL/SQL + extract column lineage (requires Gudu JAR)",
    )


def stage3_extract_gudu():
    """Convert Gudu JSON outputs → gudu_lineage_output.csv."""
    cleaned_dir = cfg.OUTPUT_DIR / "All_Metadata_cleaned"
    _run(
        "extract_gudu_lineage.py",
        "--input",  cleaned_dir,
        "--output", cfg.GUDU_LINEAGE_CSV,
        "--format", "csv",
        desc="STAGE 3 — Extract Gudu Lineage: convert Gudu JSON to CSV",
    )


def stage4_llm_lineage():
    """Run LLM-based column-level lineage extraction → llm_lineage_output.csv."""
    _run(
        "llm_lineage_extractor.py",
        "--source-dir", cfg.ALL_METADATA_DIR,
        "--output",     cfg.LLM_LINEAGE_CSV,
        desc="STAGE 4 — LLM Extractor: extract column lineage via LLM (requires API key)",
    )


def stage5_pkg_proc_analysis():
    """Build PKG → child proc call structure → PKG_PROC_Analysis_All_Metadata.xlsx."""
    _run(
        "generate_pkg_proc_analysis.py",
        desc="STAGE 5 — PKG/Proc Analysis: build orchestrator call structure",
    )
    # generate_pkg_proc_analysis.py writes to project root; copy to input/ as backup
    generated = HERE / "PKG_PROC_Analysis_All_Metadata.xlsx"
    if generated.exists() and generated != cfg.PKG_PROC_ANALYSIS:
        shutil.copy2(generated, cfg.INPUT_DIR / "PKG_PROC_Analysis_All_Metadata.xlsx")


def stage6_combine():
    """Join TIDAL + shell parser + Gudu + LLM → combined_lineage_latest.csv/xlsx."""
    # Use pre-built PKG_PROC_Analysis from input/ if the generated one isn't present yet
    pkg_proc = cfg.PKG_PROC_ANALYSIS
    if not pkg_proc.exists():
        fallback = cfg.INPUT_DIR / "PKG_PROC_Analysis_All_Metadata.xlsx"
        if fallback.exists():
            pkg_proc = fallback

    _run(
        "tidal_shell_combiner.py",
        "--rpt-schema",       cfg.DIFW_QUERY_RESULTS,
        "--tidal",            cfg.TIDAL_PRIMARY,
        "--tidal-supplement", cfg.TIDAL_SUPPLEMENT,
        "--shell-parsed",     cfg.SHELL_PARSED_CSV,
        "--gudu-lineage",     cfg.GUDU_LINEAGE_CSV,
        "--llm-lineage",      cfg.LLM_LINEAGE_CSV,
        "--pkg-proc-analysis",pkg_proc,
        "--runtime",          cfg.TIDAL_RUNTIME,
        "--output-dir",       cfg.OUTPUT_DIR,
        desc="STAGE 6 — Combiner: join TIDAL + Shell + Gudu + LLM lineage",
    )


def stage7_tidal_graph():
    """Generate interactive D3 HTML dependency graph → tidal_dependency_graph.html."""
    _run(
        "generate_tidal_graph.py",
        desc="STAGE 7 — Tidal Graph: interactive HTML dependency graph",
    )


def stage8_hop_reduction():
    """Run hop-reduction analysis for all 14 RPT tables."""
    _run(
        "run_all_rpt_tables.py",
        desc="STAGE 8 — Hop Reduction: analyze all 14 RPT tables",
    )


def stage9_master_recommendations():
    """Consolidate per-table hop reduction findings → MASTER_Hop_Reduction_Recommendations.xlsx."""
    _run(
        "generate_master_recommendations.py",
        desc="STAGE 9 — Master Recommendations: consolidate hop reduction findings",
    )


def stage10_verified_savings():
    """Simulate hop reduction savings → verified_savings_simulation_aggregate.xlsx."""
    _run(
        "generate_verified_savings.py",
        desc="STAGE 10 — Verified Savings: simulate hop reduction impact",
    )


# ─────────────────────────────────────────────────────────────────────────────
# STAGE REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

STAGES = {
    1:  stage1_shell_parser,
    2:  stage2_clean_and_gudu,
    3:  stage3_extract_gudu,
    4:  stage4_llm_lineage,
    5:  stage5_pkg_proc_analysis,
    6:  stage6_combine,
    7:  stage7_tidal_graph,
    8:  stage8_hop_reduction,
    9:  stage9_master_recommendations,
    10: stage10_verified_savings,
}

STAGE_NAMES = {
    1:  "shell_parser",
    2:  "clean_and_run_gudu",
    3:  "extract_gudu_lineage",
    4:  "llm_lineage_extractor",
    5:  "generate_pkg_proc_analysis",
    6:  "tidal_shell_combiner",
    7:  "generate_tidal_graph",
    8:  "run_all_rpt_tables (hop reduction)",
    9:  "generate_master_recommendations",
    10: "generate_verified_savings",
}


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="RSLI Data Lineage Pipeline Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="\n".join(f"  {n:2d}  {name}" for n, name in STAGE_NAMES.items()),
    )
    parser.add_argument(
        "--stages", nargs="+", type=int, metavar="N",
        help="Run only these stage numbers, e.g. --stages 6 7 8",
    )
    parser.add_argument(
        "--from-stage", type=int, default=1, metavar="N",
        help="Start from this stage number (default: 1)",
    )
    parser.add_argument(
        "--list", action="store_true",
        help="Print stage list and exit",
    )
    args = parser.parse_args()

    if args.list:
        print("\nAvailable stages:")
        for n, name in STAGE_NAMES.items():
            print(f"  {n:2d}  {name}")
        return

    to_run = sorted(args.stages) if args.stages else [s for s in STAGES if s >= args.from_stage]

    print(f"\nProject root : {HERE}")
    print(f"Output dir   : {cfg.OUTPUT_DIR}")
    print(f"Stages to run: {to_run}\n")

    _ensure_dir(cfg.OUTPUT_DIR)
    _ensure_dir(cfg.INPUT_DIR)

    for s in to_run:
        if s not in STAGES:
            print(f"  WARNING: Stage {s} not defined — skipping")
            continue
        STAGES[s]()

    print(f"\n{'='*70}")
    print("  Pipeline complete.")
    print(f"  Outputs in: {cfg.OUTPUT_DIR}")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    main()
