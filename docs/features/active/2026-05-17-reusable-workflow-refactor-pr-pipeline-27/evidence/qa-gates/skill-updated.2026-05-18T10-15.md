# Phase 5 — orchestrate SKILL.md updated

Timestamp: 2026-05-18T10-15
Command: grep "GitHub Actions Reusable Workflows" .claude/skills/orchestrate/SKILL.md
EXIT_CODE: 0

Inserted new subsection "GitHub Actions Reusable Workflows" between "Evidence Location Authority" and "Completion Requirements".

Content states:
- Every new CI gate is a `_<name>.yml` callee with `workflow_call:` + `workflow_dispatch:`.
- Orchestrator workflows contain no inline `steps:` and reference callees via `uses:`.
- Cross-job filesystem reliance requires explicit `actions/upload-artifact` + `actions/download-artifact`.
- GitHub Actions reusable-workflow nesting depth cap is 4.
- Cross-reference to `.github/workflows/README.md`.

Output Summary: subsection added (8 lines including heading); cross-reference to .github/workflows/README.md included; nesting-cap of 4 documented.
