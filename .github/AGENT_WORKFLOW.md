# RSL EDP PL/SQL Code Improvement — Agent Workflow Guide

**Version:** 1.0  
**Date:** 2026-07-30  
**Model:** Claude Sonnet 4.6  
**Audience:** Developers, data engineers, and tech leads working on RSLI-DataLineage code improvement

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Architecture](#2-system-architecture)
3. [Pipeline Registry — The Shared Context](#3-pipeline-registry--the-shared-context)
4. [Agent Catalog](#4-agent-catalog)
5. [End-to-End Workflow](#5-end-to-end-workflow)
6. [File Versioning — The Pipeline Stages](#6-file-versioning--the-pipeline-stages)
7. [Human-in-the-Loop Checkpoints](#7-human-in-the-loop-checkpoints)
8. [How to Invoke Each Agent](#8-how-to-invoke-each-agent)
9. [Working Through the Backlog](#9-working-through-the-backlog)
10. [Reading Strategy — Context Management](#10-reading-strategy--context-management)
11. [Troubleshooting](#11-troubleshooting)
12. [Quick Reference Card](#12-quick-reference-card)

---

## 1. Overview

This system provides a set of AI-powered VS Code agents that automate the improvement of Oracle PL/SQL packages in the RSL EDP data pipeline. The improvements are driven by **validated recommendations** from the hop-reduction analysis (stored in `MASTER_Hop_Reduction_Recommendations.xlsx`) and cover three types of work:

| Type | What it does | Agent |
|------|-------------|-------|
| **Merge** | Consolidates duplicate procedures, removes circular UPDATE chains, merges multi-source loads | `@PL/SQL Merger` |
| **Optimize** | Folds cursor-based UPDATEs into INSERT SELECTs, externalises hardcoded lookups, removes pass-through writes | `@PL/SQL Optimizer` |
| **Standardize** | Applies RSL EDP PL/SQL coding standards (exception handling, naming, SELECT *, etc.) | `@PL/SQL Standardize` |

**Key principles:**
- Every change requires **human approval** before any file is written
- Changes are **versioned** — original source is never modified
- Agents read from a **JSON registry** (`pipeline_registry.json`) that contains full recommendation context, so they always know *what* to change and *why*
- 91 SQL scripts are in scope: 26 with explicit recommendations + 65 standalone candidates

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  MASTER_Hop_Reduction_Recommendations.xlsx                       │
│  (validated recommendations, data team approvals)               │
└───────────────────┬─────────────────────────────────────────────┘
                    │
                    ▼  generate_pipeline_registry.py
┌─────────────────────────────────────────────────────────────────┐
│  pipeline_registry.json                                          │
│  + pipeline/  directory scaffold (00_source.sql, decisions.md)  │
│  (RSLI-DataLineage-VDI/output/pipeline/)                        │
└──────┬──────────────┬───────────────────┬────────────────────────┘
       │              │                   │
       ▼              ▼                   ▼
 ┌──────────┐  ┌──────────────┐  ┌───────────────────┐
 │  Merger  │  │  Optimizer   │  │   Standardizer    │
 │ (Stage 1)│  │  (Stage 2)   │  │   (Stage 3)       │
 └────┬─────┘  └──────┬───────┘  └────────┬──────────┘
      │               │                   │
      │         ┌─────┴──────┐            │
      │         │            │            │
   Sub-agents  Q-lookup   P-cursor      Standards
   Offset       externaliser  folder    Checker +
   Circular                             Fixer
   MultiSrc
      │               │                   │
      ▼               ▼                   ▼
 01_merged.sql  02_optimized.sql  03_standardized.sql
```

**Flow summary:** Recommendations travel from the Excel workbook → JSON registry → agents → versioned SQL files. Each stage builds on the previous one.

---

## 3. Pipeline Registry — The Shared Context

### What it is

`RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json` is the single source of truth that all agents read. It contains:

- **Every actionable recommendation** (from the validated XLSX), with full description and "what to do" text
- **Package-level metadata**: which RPT it belongs to, implementation rank/tier, scope (LOCAL/GLOBAL/STANDALONE)
- **Agent routing**: which agent(s) handle each package, which sub-agent handles each rec category
- **Pipeline state**: `pipeline_stage` field tracks whether a package is `raw`, `merged`, `optimized`, or `standardized`
- **91 SQL packages** total: 26 recommendation-driven + 65 standalone candidates

### Registry structure (per package)

```json
"PKG_GRP_LOAD_RPT_POLICY_DTL_R": {
  "rpt": "RPT_POLICY_DTL_R",
  "impl_rank": 1,
  "impl_tier": 1,
  "scope": "LOCAL",
  "source_type": "recommended",
  "source_sql": "All_Metadata/PKG_GRP_LOAD_RPT_POLICY_DTL_R.sql",
  "pipeline_stage": "raw",
  "applicable_agents": ["optimizer", "merger", "standardizer"],
  "standardizer_mode": "auto-final-pass",
  "recommendations": [
    {
      "master_id": "M-0058",
      "phase": 3,
      "category": "P. Post-Load Cursor UPDATE — Fold into INSERT SELECT",
      "agent": "optimizer",
      "sub_agent": "p-cursor-folder",
      "description": "...",       ← full description from XLSX
      "recommendation": "...",    ← full 'What To Do' text from XLSX
      "validation_status": "✅ Consider"
    }
  ]
}
```

### Regenerating the registry

Run this whenever the master Excel workbook is updated:

```powershell
cd SQLObjectParser
python generate_pipeline_registry.py
```

Options:
```powershell
# Use a different master XLSX
python generate_pipeline_registry.py --master "path/to/MASTER.xlsx"

# Use a different pipeline output folder
python generate_pipeline_registry.py --pipeline-root "C:/my/path/pipeline"

# Skip file copying (just update the JSON)
python generate_pipeline_registry.py --no-scaffold
```

---

## 4. Agent Catalog

### User-invocable agents (you call these directly)

| Agent | `@` mention | Handles | Output file |
|-------|-------------|---------|------------|
| **PL/SQL Merger** | `@PL/SQL Merger` | C. OFFSET, N. Circular, A. Multi-Source, D. Serial, M. Orchestration | `01_merged.sql` |
| **PL/SQL Optimizer** | `@PL/SQL Optimizer` | B. Pass-Through, Q. Hardcoded, P. Cursor, O. GTT, F. LLM findings, free-scan | `02_optimized.sql` |
| **PL/SQL Standardize** | `@PL/SQL Standardize` | RSL EDP coding standards (all packages) | `03_standardized.sql` |

### Sub-agents (called automatically by parent agents — not invoked directly)

| Sub-agent | Called by | Handles |
|-----------|-----------|---------|
| **PL/SQL Merger-Offset** | Merger | C. OFFSET / Near-Duplicate Procedures — compares N OFFSET variants, generates one parameterised proc |
| **PL/SQL Merger-Circular** | Merger | N. Circular Update Chain — folds post-load UPDATE into the preceding INSERT SELECT |
| **PL/SQL Merger-MultiSrc** | Merger | A. Redundant Multi-Source Load — consolidates source-specific procs into a UNION ALL or parameterised version |
| **PL/SQL Optimizer-Q** | Optimizer | Q. Hardcoded Value Mapping — extracts CASE/WHEN to REF_ table, replaces with LEFT JOIN |
| **PL/SQL Optimizer-P** | Optimizer | P. Post-Load Cursor UPDATE — folds BULK COLLECT + FORALL UPDATE into INSERT SELECT |
| **PL/SQL Standards Checker** | Standardize | Reads SQL, finds all RSL EDP standard violations with line numbers |
| **PL/SQL Fixer** | Standardize | Applies approved violation fixes, creates versioned output |

---

## 5. End-to-End Workflow

### Step 1 — Generate / refresh the pipeline registry

```powershell
cd SQLObjectParser
python generate_pipeline_registry.py
```

This creates/refreshes:
- `RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json`
- `RSLI-DataLineage-VDI/output/pipeline/<RPT>/<PKG>/00_source.sql` (copy of original)
- `RSLI-DataLineage-VDI/output/pipeline/<RPT>/<PKG>/decisions.md` (stage log)
- `RSLI-DataLineage-VDI/output/pipeline/STANDALONE/<PKG>/` (65 scripts with no recs)

Do this once at the start, and again after any updates to the master Excel workbook.

---

### Step 2 — Run the Merger (for packages with merge recs)

The Merger runs **first** — its output feeds into the Optimizer.

```
@PL/SQL Merger next
```

Or for a specific package:

```
@PL/SQL Merger PKG_GRP_FULLLOAD_OFFSETS
```

**What happens:**
1. Agent reads `pipeline_registry.json`, selects the package
2. Identifies rec categories (C/N/A → sub-agents, D/M → Tidal notes only)
3. Reads the source SQL (smart size-check: ≤ 1,500 lines = full read, > 1,500 = targeted)
4. Delegates to appropriate sub-agent(s), or handles D/M inline
5. Presents a diff summary and asks for approval
6. On approval: writes `01_merged.sql`, updates `decisions.md`, updates `pipeline_stage` in registry

---

### Step 3 — Run the Optimizer

```
@PL/SQL Optimizer next
```

Or for a specific package:

```
@PL/SQL Optimizer PKG_GRP_LOAD_RPT_POLICY_DTL_R
```

For a standalone script (free-scan, no recommendations):

```
@PL/SQL Optimizer scan PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS
```

**What happens:**
1. Reads `pipeline_registry.json`
2. Determines input: `01_merged.sql` if it exists (post-merger), else `00_source.sql`
3. Reads the full file (1M token window — no chunking needed)
4. For each rec (`agent = "optimizer"`):
   - Q category → delegates to `PL/SQL Optimizer-Q` (returns **complete modified package** + REF_ DDL)
   - P category → delegates to `PL/SQL Optimizer-P` (returns **complete modified package**)
   - B/O/F/G/H categories → handles inline following rec's `recommendation` text
5. In free-scan mode: scans SQL for optimization signals, presents numbered findings, asks which to apply
6. Presents **diff view** (changed sections only) and asks for approval
7. On approval: writes the **complete modified package** to `02_optimized.sql`, writes any REF_ DDL files, updates `decisions.md` and registry

---

### Step 4 — Run the Standardizer

```
@PL/SQL Standardize next
```

Or for a specific package (pipeline mode):

```
@PL/SQL Standardize PKG_GRP_LOAD_RPT_POLICY_DTL_R
```

Or for any arbitrary SQL file (standalone mode):

```
@PL/SQL Standardize SQLObjectParser/All_Metadata/PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.sql
```

**What happens:**
1. Determines input: `02_optimized.sql` → `01_merged.sql` → `00_source.sql` (most recent stage)
2. Delegates to `PL/SQL Standards Checker` — produces numbered violation list
3. Asks for approval: `all`, `none`, `1,3,5`, `critical`, `high+`
4. Delegates to `PL/SQL Fixer` with approved violation numbers
5. Fixer writes `03_standardized.sql` (never overwrites earlier stages)
6. Updates `decisions.md` and `pipeline_stage = "standardized"` in registry

---

## 6. File Versioning — The Pipeline Stages

Every package folder contains:

```
RSLI-DataLineage-VDI/output/pipeline/
  RPT_POLICY_DTL_R/
    PKG_GRP_LOAD_RPT_POLICY_DTL_R/
      00_source.sql          ← IMMUTABLE original (never modified)
      01_merged.sql          ← Merger output (only exists if merger ran)
      02_optimized.sql       ← Optimizer output (only exists if optimizer ran)
      03_standardized.sql    ← Standardizer output (final version)
      REF_CLAIM_TYPE_DDL.sql ← DDL for any REF_ tables created by Q-rec
      decisions.md           ← Full audit log of every stage decision
```

**Rules:**
- `00_source.sql` is **never modified** — it is the immutable baseline
- Each stage writes a **complete, fully deployable package file** — not a patch or diff.
  The developer can take `03_standardized.sql` and deploy it directly with no manual edits.
- Each stage only creates a new versioned file — it never overwrites the previous stage
- If a stage is skipped (e.g., no merger recs), the next stage reads the latest available file
- `decisions.md` is appended at each stage, building a complete change history
- **Diff view in chat vs. complete file on disk**: agents show only changed sections in the
  conversation (for readability), but always write the complete package to disk.

### decisions.md format

```markdown
# Pipeline Decisions — PKG_GRP_LOAD_RPT_POLICY_DTL_R

**RPT:** RPT_POLICY_DTL_R  |  **Rank:** 1  |  **Tier:** 1  |  **Scope:** LOCAL

## Recommendations
- M-0058 | P. Post-Load Cursor UPDATE | ✅ Consider
- M-0073 | N. Circular Update Chain   | ✅ Consider

## Stage Log

| Stage           | Date       | Decision          | Notes                              |
|-----------------|------------|-------------------|------------------------------------|
| 01_merged       | 2026-07-30 | Applied merges    | M-0073 (N fold), M-0103 Tidal note |
| 02_optimized    | 2026-07-30 | Applied optimizer | M-0058 (P cursor fold)             |
| 03_standardized | 2026-07-30 | Standards applied | 4 fixed, 1 skipped (EH-02 manual)  |
```

---

## 7. Human-in-the-Loop Checkpoints

**No file is ever written without your explicit approval.** Each agent pauses at these points:

### Checkpoint 1 — Package selection confirmation
After reading the registry and selecting a package, the agent shows:
```
## 📦 Package Selected
| Package | PKG_GRP_FULLLOAD_OFFSETS |
| RPT     | RPT_CLAIM_PAYMENT_DTL_R  |
| Recs    | 2 (C. OFFSET, N. Circular) |
Proceed? (yes / skip / pick different package)
```
You can redirect to a different package before any work starts.

### Checkpoint 2 — Diff approval (Merger / Optimizer)
After generating the changed SQL, the agent presents:
```
## 🔧 Changes — Review Required
| # | Rec ID | Category       | Change summary                        |
|---|--------|----------------|---------------------------------------|
| 1 | M-0057 | C. OFFSET      | 3 procs consolidated → 1 parameterised |
| 2 | M-0073 | N. Circular    | UPDATE folded into INSERT SELECT       |
Approve? (approve / reject / approve-partial 1)
```
You can approve all, reject all, or approve individual changes.

### Checkpoint 3 — Violation approval (Standardizer)
```
## 🔍 Violations Found — 6 issues
| # | Rule  | Severity | Line | Description            |
|---|-------|----------|------|------------------------|
| 1 | EH-01 | CRITICAL | 245  | WHEN OTHERS THEN NULL  |
| 2 | SQL-01| CRITICAL | 88   | SELECT * usage         |
...
Apply fixes: (all / none / 1,3,5 / critical / high+)
```

### Checkpoint 4 — Free-scan findings (Optimizer standalone mode)
```
## 🔎 Free-Scan Signals Found
| # | Type              | Location |
|---|-------------------|----------|
| 1 | Pass-through UPDATE | line 156 |
| 2 | Hardcoded CASE    | line 89  |
Apply? (all / none / 1,2)
```

---

## 8. How to Invoke Each Agent

### `@PL/SQL Merger`

| Invocation | Behaviour |
|-----------|-----------|
| `@PL/SQL Merger next` | Pick first unprocessed package with merger recs |
| `@PL/SQL Merger PKG_GRP_FULLLOAD_OFFSETS` | Process specific package by name |
| `@PL/SQL Merger RPT_CLAIM_PAYMENT_DTL_R` | Process all merger packages in that RPT (prompts one at a time) |

### `@PL/SQL Optimizer`

| Invocation | Behaviour |
|-----------|-----------|
| `@PL/SQL Optimizer next` | Pick first unoptimized package |
| `@PL/SQL Optimizer PKG_GRP_LOAD_RPT_POLICY_DTL_R` | Process specific package |
| `@PL/SQL Optimizer scan PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS` | Free-scan a standalone script |
| `@PL/SQL Optimizer scan next` | Free-scan next unprocessed standalone script |

### `@PL/SQL Standardize`

| Invocation | Behaviour |
|-----------|-----------|
| `@PL/SQL Standardize next` | Pipeline mode — next unstandardized package |
| `@PL/SQL Standardize PKG_GRP_LOAD_RPT_POLICY_DTL_R` | Pipeline mode — specific package |
| `@PL/SQL Standardize path/to/file.sql` | Standalone mode — any file |
| `@PL/SQL Standardize check only path/to/file.sql` | Analysis only, no fixes |

### Checking progress

To see how many packages are in each stage, run:

```powershell
python -c "
import json
from pathlib import Path
reg = json.loads(Path('RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json').read_text(encoding='utf-8'))
from collections import Counter
stages = Counter(e['pipeline_stage'] for e in reg['packages'].values())
for s, n in sorted(stages.items()): print(f'  {s:15s}: {n}')
"
```

---

## 9. Working Through the Backlog

### Recommended sequence

Work through packages in `implementation_order` from the registry — this is the **bottom-up** order optimised for the RPT dependency graph (simpler, lower-risk RPTs first).

**Recommended starting point:**
1. Start with a package from `RPT_POLICY_DTL_R` (Rank 1, Tier 1 — lowest complexity)
2. Process merger recs first (if any), then optimizer, then standardizer
3. Move to the next package in `implementation_order`

### A full single-package session

```
1. @PL/SQL Merger PKG_GRP_LOAD_RPT_POLICY_DTL_R
   → Review diff → approve
   → 01_merged.sql written

2. @PL/SQL Optimizer PKG_GRP_LOAD_RPT_POLICY_DTL_R
   → Reads 01_merged.sql automatically
   → Review diff → approve
   → 02_optimized.sql written

3. @PL/SQL Standardize PKG_GRP_LOAD_RPT_POLICY_DTL_R
   → Reads 02_optimized.sql automatically
   → Review violations → approve
   → 03_standardized.sql written
```

### Processing standalone candidates

Standalone scripts (no recommendations) get optimizer free-scan + standardizer only:

```
1. @PL/SQL Optimizer scan PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE
   → Agent scans for signals → presents findings → approve
   → 02_optimized.sql written (or stays at 00_source.sql if no signals found)

2. @PL/SQL Standardize PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE
   → Standards check → approve
   → 03_standardized.sql written
```

### Batch processing tip

You can process multiple packages in one session by chaining `next`:
```
@PL/SQL Standardize next   ← completes one, then you run it again
@PL/SQL Standardize next
@PL/SQL Standardize next
```

The registry tracks `pipeline_stage` so `next` always picks up where you left off.

---

## 10. Reading Strategy — Context Management

Claude Sonnet 4.6 has a **1 million token context window**. This means every SQL script
in this codebase can always be read in full — no chunking, no multi-pass strategy needed.

| Metric | Value |
|--------|-------|
| Context window | 1,000,000 tokens |
| Reserved for prompt / history / output | ~50,000 tokens |
| Available for file content | ~950,000 tokens |
| Largest file (`PROC_REFRESH_GRP_M_VIEW_TBLS`) | 6,298 lines ≈ 94,000 tokens (**9.9%** of budget) |
| All 91 files combined | ~67,000 lines ≈ 1,010,000 tokens |

**Every individual file reads in one pass.** The entire codebase combined barely exceeds
the context window — so even reading multiple files simultaneously is safe for most sessions.

### One rule that remains — Diff in chat, complete file on disk

This is a review quality rule, not a context constraint:

| Where | What the agent produces |
|-------|------------------------|
| **Written to disk** (`01/02/03_*.sql`) | **Complete modified package** — all procedures intact, fully deployable. Developer deploys this file directly. No manual assembly. |
| **Shown in chat** (review step) | **Diff only** — only the changed sections shown, so the human can review what changed without reading thousands of unchanged lines. |

---

## 11. Troubleshooting

### "Package not found in registry"
The package name in your invocation doesn't match the key in `pipeline_registry.json`.
- Check the exact key: `python -c "import json; reg=json.load(open('RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json')); print(list(reg['packages'].keys())[:10])"`
- Package names are case-sensitive

### "pipeline_registry.json not found"
Run the generator first:
```powershell
cd SQLObjectParser
python generate_pipeline_registry.py
```

### "00_source.sql not found"
The `All_Metadata/` folder path may differ. Check the `source_sql` field in the registry for the package. Pass the correct `--all-metadata` path when regenerating.

### Agent applies wrong change / misidentifies the pattern
The rec's `description` and `recommendation` fields drive the agent's understanding. If the agent misidentifies a pattern:
1. Tell the agent: `"The CASE block is at line 287, not 312"` to redirect it
2. If the rec's description is ambiguous, add a clarifying note to `decisions.md`

### "cannot fold cleanly" / "cannot consolidate" from a sub-agent
The sub-agent found the pattern but it has an edge case that prevents automated merging (e.g., cursor used in multiple places, structural differences between OFFSETs). The sub-agent will explain the issue. Options:
- Approve a partial change (what can be automated)
- Skip the rec and handle it manually
- Add a note to `decisions.md` for a human developer to complete

### Pipeline stage not updating
The registry JSON is updated at the end of each successful agent run. If the file was locked or an error occurred:
```powershell
# Manually set a stage
python -c "
import json
from pathlib import Path
p = Path('RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json')
reg = json.loads(p.read_text(encoding='utf-8'))
reg['packages']['PKG_GRP_LOAD_RPT_POLICY_DTL_R']['pipeline_stage'] = 'optimized'
p.write_text(json.dumps(reg, indent=2, ensure_ascii=False), encoding='utf-8')
"
```

---

## 12. Quick Reference Card

```
═══════════════════════════════════════════════════════
  RSL EDP PL/SQL Agent Quick Reference
═══════════════════════════════════════════════════════

SETUP (run once, then again after XLSX updates)
  cd SQLObjectParser
  python generate_pipeline_registry.py

REGISTRY
  Location : RSLI-DataLineage-VDI/output/pipeline/pipeline_registry.json
  Packages : 91 total (26 recommended + 65 standalone)
  Stages   : raw → merged → optimized → standardized

STAGE 1 — MERGER (run before optimizer)
  @PL/SQL Merger next
  @PL/SQL Merger <package_name>
  Output   → 01_merged.sql

STAGE 2 — OPTIMIZER
  @PL/SQL Optimizer next
  @PL/SQL Optimizer <package_name>
  @PL/SQL Optimizer scan <package_name>   ← standalone free-scan
  Output   → 02_optimized.sql

STAGE 3 — STANDARDIZER (always last)
  @PL/SQL Standardize next
  @PL/SQL Standardize <package_name>
  @PL/SQL Standardize <path/to/file.sql>  ← standalone mode
  Output   → 03_standardized.sql

APPROVAL KEYWORDS
  approve                 → apply all proposed changes
  reject                  → discard all changes
  approve-partial 1,3     → apply only changes 1 and 3
  all / none / 1,3,5      → standards violations (Standardize)
  critical / high+        → by severity (Standardize)

FILES PER PACKAGE
  00_source.sql           ← original (immutable)
  01_merged.sql           ← after merger
  02_optimized.sql        ← after optimizer
  03_standardized.sql     ← after standardizer (deploy this)
  decisions.md            ← full audit log
  REF_*_DDL.sql           ← lookup table DDL (Q-rec output)

IMPLEMENTATION ORDER
  Start with Tier 1 packages (lowest complexity):
    PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R  ← Rank 1
    PKG_GRP_LOAD_RPT_POLICY_DTL_R               ← Rank 1
    PKG_GRP_FULLLOAD_OFFSETS                     ← Rank 2
    ...
  Use 'next' to let the agent follow the registry order.

═══════════════════════════════════════════════════════
```

---

## Appendix — Recommendation Category → Agent Routing

| Category | Agent | Sub-agent | Notes |
|----------|-------|-----------|-------|
| C. OFFSET / Near-Duplicate | Merger | Merger-Offset | Consolidates OFFSET1/2/3 into one parameterised proc |
| N. Circular Update Chain | Merger | Merger-Circular | Folds post-load UPDATE into INSERT SELECT |
| A. Redundant Multi-Source | Merger | Merger-MultiSrc | UNION ALL or parameterised consolidation |
| D. Serial Chain | Merger | inline | **Tidal-only** — no SQL change, note added to decisions.md |
| M. Orchestration Edge | Merger | inline | **Tidal-only** — note added to decisions.md |
| Q. Hardcoded Value Mapping | Optimizer | Optimizer-Q | CASE→LEFT JOIN REF_ table; generates DDL |
| P. Post-Load Cursor UPDATE | Optimizer | Optimizer-P | BULK COLLECT + FORALL → inline JOIN |
| B. Pass-Through Update | Optimizer | inline | SET clause folded into INSERT SELECT |
| O. GTT Intra-Procedure | Optimizer | inline | GTT INSERT+SELECT → WITH clause CTE |
| O. Intermediate/Hybrid Naming | Optimizer | inline | Table rename as per rec |
| O. View Naming | Standardizer | inline | DDL rename |
| F. LLM-Identified | Optimizer | inline | Follows rec's specific instruction |
| G/H/K/L. (code quality) | Optimizer | inline | Follows rec's specific instruction |
| E. MV (all phases) | — | skip | Architecture/DBA only — agents cannot handle |
| J. Over-Fanout MV | — | skip | Architecture/DBA only |
| C/A. Source System Architectural | — | skip | By design — do not consolidate |

---


*Agent files: `.github/agents/` | Standards: `.github/instructions/plsql-standards.instructions.md`*
