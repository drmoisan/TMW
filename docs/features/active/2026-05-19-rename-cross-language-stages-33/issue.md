# rename-cross-language-stages (Issue #33)

- Date captured: 2026-05-19
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/rename-cross-language-stages/ (Issue #33)

- Issue: #33
- Issue URL: https://github.com/drmoisan/TMW/issues/33
- Last Updated: 2026-05-19
- Work Mode: minor-audit

## Problem / Why

The CI orchestrator `.github/workflows/pr-pipeline.yml` and its README at `.github/workflows/README.md` use the label "Cross-language" for five callees that do not actually cover all languages:

| Callee | README label | Actual coverage |
|---|---|---|
| `_stage-1-format.yml` | "Cross-language format check" | Prettier only (JS/TS/JSON/YAML/MD) |
| `_stage-2-lint.yml` | "Cross-language lint" | ESLint v9 flat-config with typescript-eslint (TS/JS) |
| `_stage-3-typecheck.yml` | "Cross-language type-check" | `tsc --noEmit` (TS only) |
| `_stage-5-test.yml` | "Cross-language unit tests" | Vitest with V8 coverage (TS only) |
| `_stage-7-integration.yml` | "Cross-language integration tests" | Placeholder no-op (no integration tests exist yet) |

C# is handled by parallel `_stage-N-dotnet-*.yml` callees (CSharpier for format, MSBuild warnings-as-errors for build/lint, nullable analysis explainer for typecheck, NetArchTest for architecture, `dotnet test` for unit). PowerShell and Python formatters/linters/tests (PSScriptAnalyzer, Pester, Black, Ruff, Pyright, Pytest) are not present in the orchestrator at all.

The "Cross-language" labels are aspirational and misleading. A new contributor reading the workflow inventory plausibly concludes that C# is covered by `stage-1-format` and therefore that the additional `stage-1-dotnet-format` is redundant — which is wrong. A partial fix landed for the format row only as part of issue #32; this potential covers the remaining rows plus the workflow filename and job name renames so the labels are consistent end-to-end.

## Proposed Behavior

Rename each TypeScript-only callee so its filename, job name, and README description accurately reflect its scope. Two viable naming patterns:

- **Pattern A — language-scoped suffix.** `_stage-1-format-prettier.yml`, `_stage-2-lint-eslint.yml`, `_stage-3-typecheck-tsc.yml`, `_stage-5-test-vitest.yml`, `_stage-7-integration-vitest.yml`. Pairs cleanly with the existing `_stage-N-dotnet-*.yml` siblings.
- **Pattern B — language-prefix sibling.** `_stage-1-ts-format.yml`, `_stage-2-ts-lint.yml`, etc., to mirror `_stage-N-dotnet-*.yml`.

Pick one pattern repo-wide. The README should additionally clarify what each stage actually checks (toolchain name + file types covered).

## Acceptance Criteria (early draft)

- [x] All five misleading "Cross-language X" workflow files are renamed under the chosen pattern.
- [x] `.github/workflows/pr-pipeline.yml` `uses:` references point to the new filenames.
- [x] Job names inside each renamed file match the new filename (so the status-check name reported to GitHub also updates).
- [x] `.github/workflows/README.md` table descriptors accurately name the toolchain and covered file types for each row.
- [x] Branch-protection check name mapping is documented in the PR description so an admin can update the protection rule on `main` without searching.
- [x] No behavioral change to any stage; only names and descriptors move.
- [ ] Full CI pipeline run on the change branch is green under the new names.

## Constraints & Risks

- **Branch-protection breakage.** Required-status-check names embed the workflow/job name. Renaming changes the reported name; the protection rule on `main` must be updated in the same change or merges will block. Coordinate with a repo admin.
- **PR-history search friction.** Old workflow run names disappear from the Actions UI under the new names. Searching for historical failures by stage name will require knowing both old and new names for a transition window.
- **External references.** Any external automation (dashboards, status-monitoring scripts) that pins the old stage names must be updated.
- **Pattern bikeshedding.** Picking Pattern A vs. B is a one-time decision that affects future stage additions; resolve before opening the PR.

## Test Conditions to Consider

- [ ] Full PR pipeline dry-run on the change branch confirms every renamed stage runs green and the orchestrator's `uses:` resolution succeeds.
- [ ] Repo-wide grep for residual references to each old stage name returns zero hits outside `docs/features/**` historical evidence.
- [ ] Dispatch each renamed callee individually via `gh workflow run _stage-...yml --ref <branch>` and confirm a single isolated job runs.
- [ ] README table renders correctly; all dispatch invocation snippets list the new filenames.

## Next Step

- [ ] Promote to GitHub issue (refactor template)
- [ ] Create `docs/features/active/rename-cross-language-stages/` folder from the template

## Related Artifacts

- Branch-protection check-name mapping (paste-ready for PR description): [`branch-protection-mapping.md`](./branch-protection-mapping.md)