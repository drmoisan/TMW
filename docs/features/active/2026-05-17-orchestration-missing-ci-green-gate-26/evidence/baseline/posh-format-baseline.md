# Baseline — Invoke-Formatter dry-run (P0-T6)

Timestamp: 2026-05-19T10-15

Command: Invoke-Formatter -ScriptDefinition <content> over scripts/**/*.ps1 (compare formatted vs original)

EXIT_CODE: 0

Output Summary:
- Files scanned: 1 (scripts/benchmarks/parse-cobertura.ps1).
- Result: ALL_FORMATTED. No file requires reformatting; formatter output is byte-identical to current content.
- Bundled PoshQC format (mcp__drm-copilot__run_poshqc_format) is the authoritative format tool and will be applied to new Phase 5 scripts.
- Baseline: clean formatting state.
