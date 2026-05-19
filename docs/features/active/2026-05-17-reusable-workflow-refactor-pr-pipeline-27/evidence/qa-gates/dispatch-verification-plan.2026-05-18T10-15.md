# Phase 6 — Post-merge dispatch-verification plan

Timestamp: 2026-05-18T10-15
Command (planned, executed by maintainer post-merge):
- gh workflow run _stage-10-benchmark-regression.yml --ref <branch>
- gh workflow run _stage-1-format.yml --ref <branch>
- gh workflow run pr-pipeline.yml --ref <branch>
- (synthetic failure scenario — revert before merge) introduce a malformed `run:` line in _stage-1-format.yml; then `gh workflow run pr-pipeline.yml --ref <branch>`

EXIT_CODE: planned-post-merge

Expected outputs per scenario:

1. `gh workflow run _stage-10-benchmark-regression.yml --ref <branch>` -> exactly one run id; one job (`stage-10-benchmark-regression`); no `stage-7-integration` queued. Confirms isolated dispatch contract.

2. `gh workflow run _stage-1-format.yml --ref <branch>` -> exactly one run id; one job (`stage-1-format`); no other stages queued. Confirms isolated dispatch contract.

3. `gh workflow run pr-pipeline.yml --ref <branch>` -> orchestrator chains all 17 callees in the expected `needs:` order:
   - tier-classification first (no needs).
   - secret-scan in parallel (no needs).
   - stage-1-format and stage-1-dotnet-format after tier-classification.
   - linear chains stage-1-format -> stage-2-lint -> stage-3-typecheck -> stage-4-architecture -> stage-5-test -> stage-6-contract -> stage-7-integration.
   - linear chain stage-1-dotnet-format -> stage-2-dotnet-build -> stage-3-dotnet-typecheck -> stage-4-dotnet-architecture -> stage-5-dotnet-test.
   - stage-e2e-smoke (if `e2e:run` label), stage-10-benchmark-regression, benchmark-gate-self-validation all branch off stage-7-integration.
   - Check names take the form `<caller-job-name> / <callee-job-name>`.

4. Synthetic failure (revert before merge): introduce a malformed `run:` line in `_stage-1-format.yml`; the orchestrator's check list surfaces the failure under the combined name `stage-1-format / stage-1-format`. Confirms branch-protection rename procedure is correct.

Output Summary: four dispatch scenarios documented with expected outcomes; commands ready for maintainer to execute post-merge. Run ids captured in this artifact (or a sibling artifact) after the merge.
