# P7-T6 — Acceptance Criteria Mapping

- Timestamp: 2026-05-19T08-44
- Issue: #33
- AC Source: `docs/features/active/2026-05-19-rename-cross-language-stages-33/issue.md` (section `## Acceptance Criteria (early draft)`, lines 39–45)

## Mapping

| # | AC Text | Status | Evidence |
|---|---|---|---|
| 1 | All five misleading "Cross-language X" workflow files are renamed under the chosen pattern. | verified | `evidence/baseline/workflow-files-baseline.2026-05-19T08-44.md` (pre-rename SHAs) + `git status` rename entries + `evidence/qa-gates/p1-yaml-parse.2026-05-19T08-44.md` (all five renamed files parse) |
| 2 | `.github/workflows/pr-pipeline.yml` `uses:` references point to the new filenames. | verified | `evidence/qa-gates/p2-uses-resolution.2026-05-19T08-44.md` (all 15 `uses:` resolve, five new names present) + `evidence/qa-gates/p7-uses-graph.2026-05-19T08-44.md` (`missing: []`, `orphans: []`) |
| 3 | Job names inside each renamed file match the new filename. | verified | `evidence/qa-gates/p3-job-names.2026-05-19T08-44.md` (per-file table: `name:` equals single key under `jobs:` for all five) |
| 4 | `.github/workflows/README.md` table descriptors accurately name the toolchain and covered file types for each row. | verified | `evidence/qa-gates/p4-readme-structure.2026-05-19T08-44.md` (table well-formed, `Cross-language` removed) + README rows 2–8 list Prettier / ESLint v9 / tsc / Vitest / Vitest integration toolchains and file-type scope |
| 5 | Branch-protection check-name mapping documented in the PR description so an admin can update protection without searching. | verified | `branch-protection-mapping.md` (paste-ready table at feature root, five mapping rows, admin instructions paragraph) + `issue.md` cross-link (line 68) |
| 6 | No behavioral change to any stage; only names and descriptors move. | verified | `evidence/baseline/workflow-files-baseline.2026-05-19T08-44.md` (pre-rename blob SHAs) — only `name:` and the single `jobs:` key were edited in each renamed file (P3); `steps:`, `on:`, and `permissions:` blocks unchanged; orchestrator changes are `uses:` path edits only. `evidence/qa-gates/p7-actionlint.2026-05-19T08-44.md` (zero diagnostics) confirms no structural regression. |
| 7 | Full CI pipeline run on the change branch is green under the new names. | deferred | `evidence/qa-gates/p7-gh-workflow-view.2026-05-19T08-44.md` documents `gh workflow view --ref` deferral because the branch has not been pushed yet. This AC is satisfied by the first `pr-pipeline.yml` run after the PR is opened; it is not directly testable in this executor session and is explicitly out of scope for the rename change set. |

## Output Summary

Six of seven AC bullets are verified locally with on-disk evidence artifacts. Bullet 7 (full green pipeline run) is deferred to the first PR pipeline run after the branch is pushed, per plan acknowledgement and per the issue's own note that the pipeline-run check happens on the change branch.
