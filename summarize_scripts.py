"""
SQL Script Summarizer for Hop Reduction Analysis
=================================================
Reads PL/SQL scripts from All_Metadata/, sends each
through Azure OpenAI with the summarizer prompt, and collects structured
JSON summaries into a consolidated output.

Skips:
  - Generic DIFW dispatcher packages (pkg_grp_load_difw*)
  - PROC_REFRESH_GRP_M_VIEW_TBLS (mega-refresh, too large / not actionable per-script)

Handles large files by chunking and merging partial summaries.

Usage:
  python summarize_scripts.py                  # summarize all priority scripts
  python summarize_scripts.py --file <name>    # summarize a single file
  python summarize_scripts.py --dry-run        # list files that would be processed
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import json
import os
import re
import sys
import threading
import time
from pathlib import Path
from dotenv import load_dotenv
from openai import AzureOpenAI

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
SQL_META_DIR = SCRIPT_DIR / "All_Metadata"
OUTPUT_DIR = SCRIPT_DIR / "output"
OUTPUT_JSON = OUTPUT_DIR / "script_summaries_all.json"
OUTPUT_CONSOLIDATED = OUTPUT_DIR / "hop_reduction_from_summaries_all.json"

# Files to skip (generic dispatchers / too large to be useful per-script)
SKIP_FILES = {
    "pkg_grp_load_difw.sql",
    "pkg_grp_load_difw_pd.sql",
    "PKG_GRP_LOAD_DIFW.sql",
    "PKG_GRP_LOAD_DIFW_PD.sql",
    "PROC_REFRESH_GRP_M_VIEW_TBLS.sql",
}

# Max characters per LLM call (~4 chars/token, target <120K tokens input)
MAX_CHARS_PER_CHUNK = 120_000

load_dotenv(SCRIPT_DIR / ".env")

SYSTEM_PROMPT = (Path(SCRIPT_DIR) / "script_sumarizer_prompt.txt").read_text(
    encoding="utf-8"
)

# ---------------------------------------------------------------------------
# Azure OpenAI client
# ---------------------------------------------------------------------------
def get_client():
    """Create Azure OpenAI client from .env config."""
    env_path = SCRIPT_DIR / ".env"
    if env_path.exists():
        # Parse .env manually to handle the INI-style format
        with open(env_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("#") or "=" not in line:
                    continue
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip().strip('"').strip("'")
                if key == "api_key":
                    os.environ["AZURE_OPENAI_API_KEY"] = val
                elif key == "endpoint":
                    os.environ["AZURE_OPENAI_ENDPOINT"] = val
                elif key == "deployment_name":
                    os.environ["AZURE_OPENAI_DEPLOYMENT_NAME"] = val
                elif key == "api_version":
                    os.environ["AZURE_OPENAI_API_VERSION"] = val

    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-12-01-preview")

    if not api_key or not endpoint:
        print("[ERROR] AZURE_OPENAI_API_KEY and AZURE_OPENAI_ENDPOINT must be set.")
        sys.exit(1)

    return AzureOpenAI(
        api_key=api_key,
        azure_endpoint=endpoint,
        api_version=api_version,
    )


def get_deployment():
    return os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-5-mini")


_THREAD_STATE = threading.local()


def get_thread_client():
    """Get/create one Azure client per worker thread."""
    client = getattr(_THREAD_STATE, "client", None)
    if client is None:
        client = get_client()
        _THREAD_STATE.client = client
    return client


# ---------------------------------------------------------------------------
# SQL cleaning – strip comments & blank lines to reduce token usage
# ---------------------------------------------------------------------------
def clean_sql(sql_text: str) -> str:
    """Remove comments and collapse blank lines to reduce LLM token count.

    Handles:
      - Block comments  /* ... */
      - Single-line comments  -- ...
      - Oracle REM comments   REM ...
      - Excessive blank lines (3+ → 1)
      - Trailing whitespace per line
    """
    # Block comments (non-greedy, across newlines)
    text = re.sub(r"/\*.*?\*/", "", sql_text, flags=re.DOTALL)
    # Single-line comments
    text = re.sub(r"--[^\n]*", "", text)
    # Oracle REM comments
    text = re.sub(r"(?m)^REM\s.*$", "", text)
    # Collapse 3+ consecutive blank lines to one
    text = re.sub(r"\n{3,}", "\n\n", text)
    # Strip trailing whitespace per line
    lines = [line.rstrip() for line in text.split("\n")]
    return "\n".join(lines).strip()


# ---------------------------------------------------------------------------
# Chunking for large files
# ---------------------------------------------------------------------------
def chunk_sql(sql_text: str, max_chars: int = MAX_CHARS_PER_CHUNK) -> list[str]:
    """Split large SQL into chunks at procedure/function boundaries."""
    if len(sql_text) <= max_chars:
        return [sql_text]

    chunks = []
    # Try to split on CREATE OR REPLACE boundaries
    boundaries = [
        m.start()
        for m in re.finditer(
            r"(?:^|\n)\s*CREATE\s+OR\s+REPLACE", sql_text, re.IGNORECASE
        )
    ]

    if len(boundaries) > 1:
        for i, start in enumerate(boundaries):
            end = boundaries[i + 1] if i + 1 < len(boundaries) else len(sql_text)
            segment = sql_text[start:end]
            # If a single segment is still too large, do a hard split
            while len(segment) > max_chars:
                chunks.append(segment[:max_chars])
                segment = segment[max_chars:]
            if segment.strip():
                chunks.append(segment)
    else:
        # No CREATE OR REPLACE boundaries, do hard split at line boundaries
        lines = sql_text.split("\n")
        current = []
        current_len = 0
        for line in lines:
            if current_len + len(line) + 1 > max_chars and current:
                chunks.append("\n".join(current))
                current = []
                current_len = 0
            current.append(line)
            current_len += len(line) + 1
        if current:
            chunks.append("\n".join(current))

    return chunks


# ---------------------------------------------------------------------------
# LLM call
# ---------------------------------------------------------------------------
def summarize_script(client, deployment: str, script_name: str, sql_text: str) -> dict:
    """Clean SQL, send to LLM, and get structured JSON summary."""
    raw_len = len(sql_text)
    sql_text = clean_sql(sql_text)
    clean_len = len(sql_text)
    saved_pct = (1 - clean_len / raw_len) * 100 if raw_len else 0
    print(f"    Cleaned: {raw_len:,} -> {clean_len:,} chars ({saved_pct:.0f}% reduction)")

    chunks = chunk_sql(sql_text)
    total_chunks = len(chunks)

    if total_chunks == 1:
        return _call_llm(client, deployment, script_name, chunks[0])
    else:
        print(f"    Large file - processing in {total_chunks} chunks...")
        partial_summaries = []
        for i, chunk in enumerate(chunks):
            print(f"    Chunk {i + 1}/{total_chunks} ({len(chunk):,} chars)...")
            extra = (
                f"\n\nNOTE: This is chunk {i + 1} of {total_chunks} from file "
                f"'{script_name}'. Focus on what's in THIS chunk."
            )
            result = _call_llm(
                client, deployment, script_name, chunk + extra
            )
            partial_summaries.append(result)
            if i < total_chunks - 1:
                time.sleep(2)  # rate limiting

        # Merge partial summaries
        return _merge_summaries(
            client, deployment, script_name, partial_summaries
        )


def _call_llm(client, deployment: str, script_name: str, sql_text: str) -> dict:
    """Single LLM call."""
    user_msg = (
        f"Script file: {script_name}\n"
        f"Analyze the following SQL script and return your analysis as JSON.\n\n"
        f"```sql\n{sql_text}\n```"
    )

    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(
                model=deployment,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_msg},
                ],
                max_completion_tokens=12000,
                response_format={"type": "json_object"},
            )
            content = response.choices[0].message.content
            return json.loads(content)
        except json.JSONDecodeError:
            # Try to extract JSON from response
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                try:
                    return json.loads(match.group())
                except json.JSONDecodeError:
                    pass
            if attempt < max_retries - 1:
                print(f"    Retry {attempt + 2}/{max_retries} (JSON parse error)...")
                time.sleep(3)
            else:
                return {"error": "Failed to parse JSON", "raw": content[:500]}
        except Exception as e:
            if attempt < max_retries - 1:
                wait = (attempt + 1) * 5
                print(f"    Retry {attempt + 2}/{max_retries} after error: {e}")
                time.sleep(wait)
            else:
                return {"error": str(e)}


def _merge_summaries(
    client, deployment: str, script_name: str, partials: list[dict]
) -> dict:
    """Merge partial chunk summaries into one consolidated summary."""
    merge_prompt = (
        f"You previously analyzed '{script_name}' in {len(partials)} chunks. "
        "Below are the partial JSON summaries. Merge them into a SINGLE consolidated "
        "JSON summary following the same schema. Combine lists, take the maximum "
        "complexity scores, and merge hop reduction opportunities. "
        "Return STRICT JSON only.\n\n"
    )
    for i, p in enumerate(partials):
        merge_prompt += f"--- Chunk {i + 1} ---\n{json.dumps(p, indent=1)}\n\n"

    try:
        response = client.chat.completions.create(
            model=deployment,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": merge_prompt},
            ],
            max_completion_tokens=12000,
            response_format={"type": "json_object"},
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        # Fallback: return first partial with a note
        result = partials[0] if partials else {}
        result["_merge_error"] = str(e)
        result["_partial_count"] = len(partials)
        return result


def process_file(filepath: Path, deployment: str) -> tuple[str, dict, float, float]:
    """Process one metadata file and return (name, result, elapsed_sec, size_kb)."""
    size_kb = filepath.stat().st_size / 1024
    sql_text = filepath.read_text(encoding="utf-8", errors="replace")
    start_time = time.time()
    result = summarize_script(get_thread_client(), deployment, filepath.name, sql_text)
    elapsed = time.time() - start_time
    return filepath.name, result, elapsed, size_kb


# ---------------------------------------------------------------------------
# Consolidation: extract hop reduction recommendations across all scripts
# ---------------------------------------------------------------------------
def consolidate_hop_reductions(summaries: dict) -> dict:
    """Extract and deduplicate hop reduction opportunities from all summaries.

    The LLM returns free-form JSON with inconsistent keys, so we search
    broadly for keys containing recommendation/issue/risk/optimization
    related content.
    """
    # Keys that typically contain actionable findings
    _ISSUE_PATTERNS = (
        "issue", "risk", "bug", "problem", "potential", "warning",
        "recommendation", "improvement", "suggestion", "action",
        "optimization", "performance", "refactor", "smell",
    )

    all_opportunities = []
    script_summaries_compact = []

    for script_name, summary in summaries.items():
        if "error" in summary:
            continue

        script_entry = {"script": script_name, "findings": []}

        for key, value in summary.items():
            key_lower = key.lower()

            # Skip metadata keys
            if any(
                key_lower.startswith(p)
                for p in (
                    "name", "object", "schema", "package", "procedure",
                    "script", "type", "summary", "purpose", "signature",
                    "column", "source_table", "select", "parameter",
                    "input", "output", "entry", "status", "comment",
                    "description", "grant", "target", "declared",
                    "creation", "build", "parallel", "refresh",
                    "constraint", "storage", "segment",
                )
            ):
                continue

            # Check if key matches issue/recommendation patterns
            if not any(p in key_lower for p in _ISSUE_PATTERNS):
                continue

            # Extract items
            if isinstance(value, list) and value:
                for item in value:
                    finding = {
                        "_source_script": script_name,
                        "_section": key,
                    }
                    if isinstance(item, dict):
                        finding.update(item)
                    elif isinstance(item, str) and item.strip():
                        finding["detail"] = item
                    else:
                        continue
                    all_opportunities.append(finding)
                    script_entry["findings"].append(finding)
            elif isinstance(value, dict) and value:
                for sub_key, sub_val in value.items():
                    if isinstance(sub_val, list):
                        for item in sub_val:
                            finding = {
                                "_source_script": script_name,
                                "_section": f"{key}.{sub_key}",
                            }
                            if isinstance(item, dict):
                                finding.update(item)
                            elif isinstance(item, str) and item.strip():
                                finding["detail"] = item
                            else:
                                continue
                            all_opportunities.append(finding)
                            script_entry["findings"].append(finding)
                    elif isinstance(sub_val, str) and sub_val.strip():
                        finding = {
                            "_source_script": script_name,
                            "_section": key,
                            "detail": f"{sub_key}: {sub_val}",
                        }
                        all_opportunities.append(finding)
                        script_entry["findings"].append(finding)
            elif isinstance(value, str) and value.strip():
                finding = {
                    "_source_script": script_name,
                    "_section": key,
                    "detail": value,
                }
                all_opportunities.append(finding)
                script_entry["findings"].append(finding)

        if script_entry["findings"]:
            script_summaries_compact.append(script_entry)

    return {
        "total_scripts_analyzed": len(summaries),
        "total_findings": len(all_opportunities),
        "scripts_with_findings": len(script_summaries_compact),
        "findings": all_opportunities,
        "per_script_summary": script_summaries_compact,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def get_priority_files() -> list[Path]:
    """Return list of SQL/TXT files to process, skipping exclusions."""
    files = []
    for ext in ("*.sql", "*.txt"):
        for f in SQL_META_DIR.glob(ext):
            if f.name.lower() not in {s.lower() for s in SKIP_FILES}:
                files.append(f)
    return sorted(files, key=lambda f: f.stat().st_size)  # smallest first


def main():
    parser = argparse.ArgumentParser(description="Summarize SQL scripts for hop reduction")
    parser.add_argument("--file", help="Process a single file by name")
    parser.add_argument("--dry-run", action="store_true", help="List files without processing")
    parser.add_argument("--resume", action="store_true", help="Skip already-summarized files")
    parser.add_argument(
        "--workers",
        type=int,
        default=4,
        help="Parallel worker count for LLM calls (default: 4, use 1 for sequential)",
    )
    args = parser.parse_args()

    if args.workers < 1:
        print("ERROR: --workers must be >= 1")
        sys.exit(1)

    # Verify metadata directory exists
    if not SQL_META_DIR.exists():
        print(f"ERROR: Metadata directory not found: {SQL_META_DIR}")
        sys.exit(1)

    files = get_priority_files()
    
    if not files:
        print(f"ERROR: No SQL/TXT files found in {SQL_META_DIR}")
        sys.exit(1)

    if args.file:
        files = [f for f in files if f.name == args.file]
        if not files:
            print(f"File '{args.file}' not found in {SQL_META_DIR}")
            sys.exit(1)

    skip_set = {s.lower() for s in SKIP_FILES}
    total_to_process = len([f for f in files if f.name.lower() not in skip_set])
    
    print(f"=== SQL Script Summarizer (All Metadata) ===")
    print(f"Source: {SQL_META_DIR}")
    print(f"Total files found: {len(files)}")
    print(f"Files to process: {total_to_process}")
    print(f"Files to skip: {len(files) - total_to_process}\n")

    for f in files:
        size_kb = f.stat().st_size / 1024
        skip_reason = ""
        if f.name.lower() in skip_set:
            skip_reason = " (generic/large)"
        print(f"  {'[SKIP]' if f.name.lower() in skip_set else '[OK]  '} {f.name} ({size_kb:.1f} KB){skip_reason}")

    if args.dry_run:
        print("\n(dry-run mode - no LLM calls made)")
        return

    # Load existing summaries if resuming
    existing = {}
    if args.resume and OUTPUT_JSON.exists():
        try:
            with open(OUTPUT_JSON, "r", encoding="utf-8") as f:
                existing = json.load(f)
            print(f"\nResuming: {len(existing)} scripts already summarized")
        except (json.JSONDecodeError, IOError) as e:
            print(f"WARNING: Could not load existing summaries: {e}")
            existing = {}
    elif OUTPUT_JSON.exists() and not args.resume:
        print(f"\nNote: {OUTPUT_JSON} exists. Use --resume to skip already-processed files.")

    client = get_client()
    deployment = get_deployment()
    print(f"\nUsing deployment: {deployment}")
    print(f"Output files:")
    print(f"  Per-script: {OUTPUT_JSON}")
    print(f"  Consolidated: {OUTPUT_CONSOLIDATED}\n")
    print(f"Execution mode: {'parallel' if args.workers > 1 else 'sequential'} ({args.workers} workers)\n")

    summaries = dict(existing)
    failed = []
    skip_set = {s.lower() for s in SKIP_FILES}
    processed_count = 0
    skipped_count = 0
    resume_skipped_count = 0

    work_items = []
    for i, filepath in enumerate(files, 1):
        if filepath.name.lower() in skip_set:
            skipped_count += 1
            continue
        if args.resume and filepath.name in existing:
            print(f"[{i}/{len(files)}] SKIP (already done): {filepath.name}")
            resume_skipped_count += 1
            continue
        work_items.append(filepath)

    if not work_items:
        print("No new files to process.")
    elif args.workers == 1:
        for i, filepath in enumerate(work_items, 1):
            print(f"[{i}/{len(work_items)}] Processing: {filepath.name}")
            file_name, result, elapsed, size_kb = process_file(filepath, deployment)
            processed_count += 1
            if "error" in result:
                print(f"    FAILED ({elapsed:.1f}s): {file_name} ({size_kb:.1f} KB) -> {result['error']}")
                failed.append(file_name)
            else:
                print(f"    OK ({elapsed:.1f}s): {file_name} ({size_kb:.1f} KB)")

            summaries[file_name] = result
            OUTPUT_DIR.mkdir(exist_ok=True)
            with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
                json.dump(summaries, f, indent=2, ensure_ascii=False)
    else:
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            future_map = {
                executor.submit(process_file, filepath, deployment): filepath
                for filepath in work_items
            }
            for i, future in enumerate(as_completed(future_map), 1):
                filepath = future_map[future]
                try:
                    file_name, result, elapsed, size_kb = future.result()
                except Exception as e:
                    file_name = filepath.name
                    size_kb = filepath.stat().st_size / 1024
                    result = {"error": str(e)}
                    elapsed = 0.0

                processed_count += 1
                if "error" in result:
                    print(f"[{i}/{len(work_items)}] FAILED ({elapsed:.1f}s): {file_name} ({size_kb:.1f} KB) -> {result['error']}")
                    failed.append(file_name)
                else:
                    print(f"[{i}/{len(work_items)}] OK ({elapsed:.1f}s): {file_name} ({size_kb:.1f} KB)")

                summaries[file_name] = result
                OUTPUT_DIR.mkdir(exist_ok=True)
                with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
                    json.dump(summaries, f, indent=2, ensure_ascii=False)

    # Consolidate hop reduction recommendations
    print(f"\n=== Consolidating hop reduction opportunities ===")
    consolidated = consolidate_hop_reductions(summaries)
    with open(OUTPUT_CONSOLIDATED, "w", encoding="utf-8") as f:
        json.dump(consolidated, f, indent=2, ensure_ascii=False)

    print(f"Total files found: {len(files)}")
    print(f"Files skipped: {skipped_count}")
    print(f"Files skipped (resume): {resume_skipped_count}")
    print(f"Files processed: {processed_count}")
    if failed:
        print(f"Files failed: {len(failed)}")
    print(f"\nAnalysis Results:")
    print(f"  Total scripts analyzed: {consolidated['total_scripts_analyzed']}")
    print(f"  Total findings extracted: {consolidated['total_findings']}")
    print(f"  Scripts with findings: {consolidated['scripts_with_findings']}")
    print(f"\nOutputs:")
    print(f"  Per-script summaries: {OUTPUT_JSON}")
    print(f"  Consolidated recommendations: {OUTPUT_CONSOLIDATED}")


if __name__ == "__main__":
    main()
