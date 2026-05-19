# P7-T5 — Orchestrator `uses:` Graph Consistency

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command (plan, semantic): Python script enumerating referenced vs on-disk callees for `pr-pipeline.yml`
- Command (executed): equivalent inline script (path-prefix strip via `p[2:] if p.startswith('./')`, glob `.github/workflows/_*.yml`)
- EXIT_CODE: 0

## Deviation Note

The plan's inline command uses `str.lstrip('./')`, which mangles `./.github/...` paths (see P2-T6 deviation note). The semantically equivalent script using `p[2:] if p.startswith('./')` was executed. The temporary helper script was deleted immediately after execution per the file-size-limit policy's throwaway-script allowance.

## Output Summary

```
referenced count: 15
missing: []
orphans: []
```

All 15 `uses:` paths in `pr-pipeline.yml` resolve to files on disk; no callee file under `.github/workflows/_*.yml` is unreferenced by the orchestrator. The renamed callees (`_stage-1-format-prettier.yml`, `_stage-2-lint-eslint.yml`, `_stage-3-typecheck-tsc.yml`, `_stage-5-test-vitest.yml`, `_stage-7-integration-vitest.yml`) are all wired in via `uses:` references.
