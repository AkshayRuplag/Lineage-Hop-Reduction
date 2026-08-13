# RSLI Data Lineage — Copilot Runtime and Cost Guardrails

These instructions apply to all assistant and custom-agent work in this repository.
Goal: reduce end-to-end runtime and AI credit usage without lowering implementation quality.

## Operating Modes

Default mode: BALANCED.

Use FAST mode when the user asks for quick pass, runtime reduction, or cost-aware run.
Use DEEP mode only when the user explicitly asks for full forensic analysis.

## Read Strategy (Token Discipline)

1. Start with targeted reads:
- Use search first to find relevant procedures, statements, and line ranges.
- Read only required sections for analysis or edits.

2. Escalate to full-file read only when needed:
- Full-file read is allowed for final verification, complex cross-procedure refactors, or when targeted reads are insufficient.

3. Avoid repeated file reads:
- Do not re-read unchanged files in the same stage unless the user requests re-validation.

## Approval Strategy (Latency Discipline)

1. Use a single approval checkpoint per stage by default.
2. Ask additional confirmations only for high-risk/global changes:
- GLOBAL scope changes affecting multiple packages/RPTs.
- Destructive removal or decommissioning recommendations.

## Output Strategy (Cost and Time)

1. Prefer concise summaries in chat:
- Show only changed sections and key evidence.
- Do not emit long repeated tables unless requested.

2. Make documentation generation conditional:
- Generate full documentation and exhaustive change logs only when requested, or for final sign-off.

## Model Allocation Guidance

When model selection is available:
- Use a smaller/faster model for classification, search planning, standards scans, and report formatting.
- Use a stronger code model only for transformation, semantic rewrites, and final validation passes.

Do not use the strongest model for every sub-task by default.

## Quality Guardrails

1. Do not skip standards checks.
2. Do not skip safety checks for GLOBAL/cascade impacts.
3. Preserve deterministic outputs and traceability in decisions logs.

## Execution Notes

- Prefer batching related operations in one pass to reduce orchestration overhead.
- Avoid re-running completed stages unless inputs changed.
- Record assumptions briefly and proceed with explicit defaults when safe.