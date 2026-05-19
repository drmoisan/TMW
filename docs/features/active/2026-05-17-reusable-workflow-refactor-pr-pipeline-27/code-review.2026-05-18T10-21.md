# Code Review — Issue #27 (reusable-workflow refactor)

- Timestamp: 2026-05-18T10-21
- Scope: 17 new `_*.yml` callees, refactored `pr-pipeline.yml`, new `README.md`, 2 deleted mirror files, `orchestrate` skill update, feature documentation + evidence.

## Design

The change implements the spec.md "Scope (structural changes)" section verbatim:

- Each pre-existing inline job in `pr-pipeline.yml` is extracted to its own `_<name>.yml` callee file.
- Each callee declares `on: workflow_call:` and `on: workflow_dispatch:` — same file serves both orchestrated and standalone invocation.
- `pr-pipeline.yml` is now a bodyless orchestrator: `uses:` + `needs:` + `if:` + `secrets:` only; no inline `steps:`.

Design principles assessment:
- **Simplicity**: the orchestrator dropped from 190 to 78 lines and contains only declarative `uses`/`needs`. Single read pass conveys the full DAG.
- **Reusability**: gate logic is factored into one canonical file per gate; the duplication that motivated the refactor is eliminated.
- **Extensibility**: documented contract is "any new gate ships as `_*.yml`, not inline". README explicitly carries this rule.
- **Separation of concerns**: orchestration vs. gate logic is now structurally separated, not just conceptually.

## Byte-Identity Verification (spot-checked)

Sampled `.github/workflows/_stage-10-benchmark-regression.yml` (lines 12–38) against `evidence/baseline/pr-pipeline.pre-refactor.yml` (lines 124–150). Every `run:` line, `shell:`, `uses:` reference, `with:` parameter, `if:`, and step ordering matches. The only differences are:

- `on:` triggers added (`workflow_call:` + `workflow_dispatch:`)
- `needs: [stage-7-integration]` relocated from callee to caller (correct per the design)

`evidence/qa-gates/steps-byte-identity-diff.2026-05-18T10-15.md` reports `Mismatches: 0` across all 17 callees using YAML-roundtrip comparison; this matches the spot-check.

## Code Quality Observations

### Workflow files

- All 17 callees declare `permissions: contents: read` at file scope — consistent and minimal.
- `_stage-e2e-smoke.yml` correctly hoists secrets into `on.workflow_call.secrets` with `required: true` for all four Azure secrets, and the orchestrator forwards via `secrets: inherit` on the `stage-e2e-smoke` job. The `if:` guard `contains(github.event.pull_request.labels.*.name, 'e2e:run')` remains on the caller (correct: `if:` on a `uses:` job is a caller-level construct).
- `_secret-scan.yml` keeps `env.GH_TOKEN: ${{ github.token }}` and `fetch-depth: 0` exactly as before.
- `_stage-10-benchmark-regression.yml` preserves the `if: always()` `upload-artifact@v4` step that publishes `stage-10-benchmark-report`.
- All callees pin third-party actions to a major version (`@v4`) — consistent with the pre-refactor file.

### Orchestrator (`pr-pipeline.yml`)

- 78 lines, fully declarative. Each job is exactly a `uses:` + `needs:` + (where applicable) `if:` + `secrets:`.
- `needs:` graph matches the pre-refactor dependency chain exactly (verified per `steps-byte-identity-diff` evidence and `orchestrator-rewrite` evidence).
- `secret-scan` correctly retains no `needs:` (parallel with `tier-classification`).
- `stage-e2e-smoke` correctly retains `secrets: inherit` and the label-gated `if:` guard.

### Documentation

- `.github/workflows/README.md` is well-structured: convention, file inventory, per-stage dispatch commands, branch-protection rename mapping, and secrets-forwarding contract.
- Branch-protection mapping table covers all 17 stages with explicit pre/post names.
- The nesting-depth cap (4) is documented as a guardrail for future refactors.

## Risks / Findings

| # | Severity | Finding | Recommendation |
|---|---|---|---|
| 1 | Medium | Branch-protection rename is a manual admin action gated on AC8. If the rename is forgotten on merge, all PRs to `main` will be blocked until the rule is updated. | Block merge until admin confirms rename per README procedure. README procedure step 3 also relies on the new check names appearing in the GitHub picker only *after* a successful run, so the orchestrator must be dispatched at least once first. This sequencing is documented; ensure it is followed. |
| 2 | Low | AC5, AC6, AC8 are signed off as "documented pending post-merge / PR-creation verification" rather than fully verified. The local evidence demonstrates structural correctness (callees have no `needs:` between each other; regression suites match baseline) but the actual `gh workflow run` isolation and representative-PR pass parity cannot be observed locally. | Acceptable for a CI refactor that cannot run its own dispatch flow locally. Capture run-ids on the first post-merge dispatch and append to evidence. |
| 3 | Low | README per-stage dispatch table lists stages with `--ref <branch>`. For callees that consume secrets (`_stage-e2e-smoke.yml`) the standalone dispatch will fail unless the dispatching user supplies them through repository-secret inheritance from the dispatch context. Worth a one-line note in the README. | Optional clarification, not blocking. |
| 4 | None (informational) | `_stage-3-dotnet-typecheck.yml` is described in the README as "explainer (real check runs inside the build)". This matches the pre-refactor behavior. No action. | None. |

No FAIL-severity findings.

## Conclusion

The refactor is mechanically faithful to the spec's invariants. Byte-identity of step content is preserved across all 17 callees; the `needs:` DAG is preserved on the caller side; the secrets-forwarding contract is correctly bifurcated between callee declaration and caller forwarding; the duplicated mirror files are deleted. Regression suites (Pester 212/0 pass, PSScriptAnalyzer clean, Pytest baseline parity) confirm no incidental side effects.

The two remaining risks are operational (branch-protection rename and post-merge dispatch verification), both documented and procedurally gated.

Overall code-review verdict: **PASS**.
