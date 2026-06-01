# parallelize-ci-pipeline (Issue #46)

- Date captured: 2026-06-01
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/parallelize-ci-pipeline/ (Issue #46)
- Type: refactor (CI performance)

- Issue: #46
- Issue URL: https://github.com/drmoisan/TMW/issues/46
- Last Updated: 2026-06-01
- Work Mode: full-feature

## Problem / Why

The PR CI pipeline (`.github/workflows/pr-pipeline.yml`) has a long wall-clock
runtime. The orchestrator chains gates through `needs:` into two long
sequential per-language lanes:

- TypeScript lane: `stage-1-format -> stage-2-lint -> stage-3-typecheck ->
  stage-4-architecture -> stage-5-test -> stage-6-contract -> stage-7-integration`
  (7 jobs serialized).
- .NET lane: `stage-1-dotnet-format -> stage-2-dotnet-build ->
  stage-3-dotnet-typecheck -> stage-4-dotnet-architecture -> stage-5-dotnet-test`
  (5 jobs serialized).

Each stage callee (`_*.yml`) is fully self-contained: it performs its own
`actions/checkout` and environment setup via a composite action. There is no
implicit cross-job filesystem dependency between callees, so the sequential
`needs:` edges are artificial ordering rather than real data dependencies. The
serialization is the primary contributor to wall-clock time.

## Proposed Behavior

After the environment/root gate (`tier-classification`) completes, the
remaining independent stages fan out to run in parallel instead of in long
serial chains. The `tier-classification` gate runs first; downstream stages
depend on it (and only it, except where a genuine dependency exists), allowing
GitHub Actions to schedule them concurrently.

Constraint: job names must not change, so required status-check names reported
to branch protection (and asserted in
`tests/powershell/apply-branch-protection.Tests.ps1` /
`.github/scripts/apply-branch-protection.ps1`) remain stable. Only the `needs:`
graph in `pr-pipeline.yml` changes.

## Acceptance Criteria (early draft)

- [ ] After `tier-classification`, all independent TS-lane and .NET-lane stages
      are schedulable in parallel (no artificial serial `needs:` chain remains).
- [ ] Every stage that is not the root still has `needs: [tier-classification]`
      (or a justified genuine dependency) so the environment gate runs first.
- [ ] Job names in `pr-pipeline.yml` are unchanged; required status-check names
      remain identical to the current set.
- [ ] `secret-scan` continues to run unconditionally; `stage-e2e-smoke` remains
      label-gated.
- [ ] A green run of `pr-pipeline.yml` against the branch head is produced
      (satisfies `modified-workflow-needs-green-run`).

## Constraints & Risks

- Branch protection required-check names must not change (keep job names).
- Full fan-out removes per-lane fail-fast economy (a format failure no longer
  short-circuits later stages in the same lane), increasing concurrent runner
  usage in exchange for lower wall-clock time. The user explicitly prioritizes
  wall-clock time.
- Reusable-workflow nesting depth cap is 4; this change keeps one level.
- Workflow-file change requires a green CI run on the branch head before merge.

## Test Conditions to Consider

- [ ] `actionlint` / workflow YAML validity.
- [ ] `apply-branch-protection.Tests.ps1` continues to pass (names unchanged).
- [ ] Green `pr-pipeline.yml` run on branch head (S9 gate).

## Next Step

- [ ] Promote to GitHub issue (refactor template).
- [ ] Create `docs/features/active/parallelize-ci-pipeline/` folder from the template.