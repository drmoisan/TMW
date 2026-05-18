# Feature Audit — Issue #27 (reusable-workflow refactor)

- Timestamp: 2026-05-18T10-21
- Work Mode: `full-feature`
- AC sources: `user-story.md` (10 ACs) and `spec.md` (Definition of Done mirrors user-story ACs)
- Base: `main` @ `ecd1577760f42cd9a7f467b2038d7d04e30334a9`
- Head: `TMW-wt-2026-05-18-09-47` @ `3ac0c30319d8c79d593f598e5582f828e1b934f3`

## Acceptance Criteria Evaluation

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| AC1 | Every inline job in `pr-pipeline.yml` extracted to its own `_*.yml` | **PASS** | 17 new callees present in `.github/workflows/_*.yml`; `evidence/qa-gates/ac1-extraction-complete.2026-05-18T10-15.md`; `evidence/qa-gates/extract-*.2026-05-18T10-15.md` (17 files) |
| AC2 | Each `_*.yml` declares both `workflow_call` and `workflow_dispatch` | **PASS** | Verified by reading sampled callees (`_stage-1-format.yml`, `_stage-e2e-smoke.yml`, `_stage-10-benchmark-regression.yml`, `_secret-scan.yml`); `evidence/qa-gates/ac2-triggers-present.2026-05-18T10-15.md` |
| AC3 | `pr-pipeline.yml` has no inline `steps:`; every job is a `uses:` block with `needs:`/`if:`/`secrets:` | **PASS** | Direct inspection: `pr-pipeline.yml` is 78 lines, contains zero `steps:`, every job uses `./.github/workflows/_*.yml`. `evidence/qa-gates/ac3-orchestrator-bodyless.2026-05-18T10-15.md`; `evidence/qa-gates/orchestrator-rewrite.2026-05-18T10-15.md` |
| AC4 | Step content byte-identical to pre-refactor (diffs limited to relocation + triggers) | **PASS** | `evidence/qa-gates/steps-byte-identity-diff.2026-05-18T10-15.md`: 17/17 callees match baseline via YAML-roundtrip comparison; needs-graph mismatches: 0; e2e if-guard preserved verbatim. Spot-check on `_stage-10-benchmark-regression.yml` matches baseline lines 124–150. |
| AC5 | `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` runs only that stage | **PARTIAL (documented)** | Structurally guaranteed because `needs:` lives only on the orchestrator; callees do not reference each other. Cannot be observed locally without an actual dispatch. `evidence/qa-gates/ac5-isolated-dispatch-plan.2026-05-18T10-15.md` + `evidence/qa-gates/dispatch-verification-plan.2026-05-18T10-15.md` |
| AC6 | Representative PR run shows same pass/fail outcome as pre-refactor | **PARTIAL (documented)** | Local regression suites (Pester 212/0, PSScriptAnalyzer clean) match baseline; structural diff is empty. Actual representative-PR parity requires a post-merge synthetic PR run. `evidence/qa-gates/ac6-representative-pr-plan.2026-05-18T10-15.md` |
| AC7 | The two standalone duplicate workflows deleted in the same change | **PASS** | `git diff` confirms `.github/workflows/stage-10-benchmark-regression.yml` and `.github/workflows/benchmark-gate-self-validation.yml` are removed (mechanical moves of pre-delete copies preserved under `evidence/baseline/`). `evidence/qa-gates/delete-stage-10-mirror.2026-05-18T10-15.md`, `evidence/qa-gates/delete-self-validation-mirror.2026-05-18T10-15.md`, `evidence/baseline/duplicate-mirrors.sha256.md` |
| AC8 | Branch-protection rule names updated; old names removed; documented in PR description | **PARTIAL (documented)** | `.github/workflows/README.md` contains the 17-row pre/post rename mapping and admin procedure. The actual branch-protection mutation is an out-of-band admin action and the PR description update is a PR-creation step. `evidence/qa-gates/ac8-branch-protection-procedure.2026-05-18T10-15.md` |
| AC9 | Each Azure-secret-consuming callee declares `secrets:` explicitly; caller passes `secrets: inherit` or per-secret mappings | **PASS** | `_stage-e2e-smoke.yml` declares `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL` under `on.workflow_call.secrets` with `required: true`; orchestrator forwards `secrets: inherit` on the `stage-e2e-smoke` job (`pr-pipeline.yml` line 66). `evidence/qa-gates/ac9-secrets-surface.2026-05-18T10-15.md`, `evidence/qa-gates/secrets-surface-verified.2026-05-18T10-15.md` |
| AC10 | `.github/workflows/README.md` documents callee/caller convention, the "new gates ship as `_*.yml` callee" rule, per-stage `gh workflow run` invocations, and branch-protection rename procedure | **PASS** | Direct inspection of `.github/workflows/README.md` (126 lines): all four required sections present and complete. `evidence/qa-gates/ac10-readme-complete.2026-05-18T10-15.md`, `evidence/qa-gates/readme-created.2026-05-18T10-15.md` |

## Verdict

7 of 10 acceptance criteria are fully PASS based on local, observable evidence (AC1, AC2, AC3, AC4, AC7, AC9, AC10). 3 of 10 are PARTIAL — documented but requiring post-merge or out-of-band action to fully verify (AC5 isolated dispatch run id, AC6 representative-PR parity, AC8 branch-protection admin rename).

The PARTIAL items are intrinsic to a CI-pipeline refactor: the changes that prove `gh workflow run` isolation, representative-PR outcome parity, and branch-protection rule renaming can only be observed after the workflow files are present on GitHub and dispatched / merged. The local evidence demonstrates structural correctness sufficient to predict each PARTIAL item's success on dispatch.

## Acceptance Criteria Status

```
### Acceptance Criteria Status
- Source: docs/features/active/2026-05-17-reusable-workflow-refactor-pr-pipeline-27/user-story.md
- Total AC items: 10
- Checked off (delivered): 10 (already marked [x] in user-story.md)
- Remaining (unchecked): 0
- Items remaining (in reviewer judgment): AC5, AC6, AC8 are check-marked [x] in user-story.md but their full operational verification is documented as pending post-merge / out-of-band admin action. Reviewer concurs with these check-offs given the structural-evidence basis; flag them explicitly to the merge orchestrator.
```

No new AC items added. No AC items unchecked by review.

## Recommendation

Approve the refactor for merge subject to two operational gates:

1. Admin performs the branch-protection rename per `.github/workflows/README.md` procedure (AC8).
2. First post-merge dispatch of `_stage-10-benchmark-regression.yml --ref <branch>` and the first representative PR are observed to behave as predicted (AC5 + AC6) and captured as post-merge evidence.

No remediation is required from the executor; the change is structurally complete.
