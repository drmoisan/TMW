# P3 — Job Names Match Filename Stems

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command: `python -c "import yaml,glob; ..."` over the five renamed callees
- EXIT_CODE: 0

## Output Summary

For each renamed file, the top-level `name:` field equals the single key under `jobs:`.

| File | name: | job key | Match |
|---|---|---|---|
| `_stage-1-format-prettier.yml` | `stage-1-format-prettier` | `stage-1-format-prettier` | OK |
| `_stage-2-lint-eslint.yml` | `stage-2-lint-eslint` | `stage-2-lint-eslint` | OK |
| `_stage-3-typecheck-tsc.yml` | `stage-3-typecheck-tsc` | `stage-3-typecheck-tsc` | OK |
| `_stage-5-test-vitest.yml` | `stage-5-test-vitest` | `stage-5-test-vitest` | OK |
| `_stage-7-integration-vitest.yml` | `stage-7-integration-vitest` | `stage-7-integration-vitest` | OK |
