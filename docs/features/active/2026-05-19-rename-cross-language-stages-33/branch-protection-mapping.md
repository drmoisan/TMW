# Branch-Protection Check-Name Mapping

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Issue URL: https://github.com/drmoisan/TMW/issues/33

After the workflow rename in this PR, the required status-check names reported to GitHub change for the five renamed TypeScript-only callees. The protection rule on `main` must be updated in the same change window or merges will block on stale required checks.

## Mapping

| Remove (old) | Add (new) |
|---|---|
| `stage-1-format / stage-1-format` | `stage-1-format / stage-1-format-prettier` |
| `stage-2-lint / stage-2-lint` | `stage-2-lint / stage-2-lint-eslint` |
| `stage-3-typecheck / stage-3-typecheck` | `stage-3-typecheck / stage-3-typecheck-tsc` |
| `stage-5-test / stage-5-test` | `stage-5-test / stage-5-test-vitest` |
| `stage-7-integration / stage-7-integration` | `stage-7-integration / stage-7-integration-vitest` |

## Admin Instructions

A repo admin must apply this mapping to the branch protection rule on `main`: navigate to Settings -> Branches -> branch protection rule for `main` -> "Require status checks to pass before merging", remove each old name listed in the Remove column, and add each new name from the Add column. The new names appear in the picker only after the renamed pipeline has produced at least one run on a PR against `main`; if a name is missing, dispatch `pr-pipeline.yml` once against this feature branch first, then re-open the rule editor. Save the rule.
