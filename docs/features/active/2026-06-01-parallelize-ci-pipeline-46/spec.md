# parallelize-ci-pipeline - Refactor Spec

- **Issue:** #46
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-01T09-58
- **Status:** Draft
- **Version:** 0.1

## Intent & Outcomes

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


## Invariants (must not change)

These behaviors, contracts, and external surfaces must remain identical after the refactor.

1. **Job names in `pr-pipeline.yml` are unchanged.** The orchestrator job keys
   (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`,
   `stage-4-architecture`, `stage-5-test`, `stage-6-contract`,
   `stage-7-integration`, `stage-1-dotnet-format`, `stage-2-dotnet-build`,
   `stage-3-dotnet-typecheck`, `stage-4-dotnet-architecture`,
   `stage-5-dotnet-test`, `stage-e2e-smoke`, `secret-scan`) are the values
   GitHub reports as status-check contexts to branch protection. They must not
   be renamed.
2. **Required status-check contexts are unchanged.** The required set is the one
   declared in `.github/scripts/apply-branch-protection.ps1`
   (`Get-RequiredStatusCheckContextList`) and asserted in
   `tests/powershell/apply-branch-protection.Tests.ps1`: `tier-classification`,
   `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`,
   `stage-5-test`, `stage-6-contract`, `stage-7-integration`. Because job names
   do not change, this script and its test do **not** change.
3. **Each callee still runs exactly once and produces the same outcome.** Every
   `_*.yml` callee remains self-contained (its own `actions/checkout` and
   composite-action environment setup). No callee is added, removed, merged, or
   modified. The pass/fail result of each gate is unchanged; only its scheduling
   order changes.
4. **`tier-classification` remains the single root gate.** It runs first and is a
   `needs:` ancestor of every other stage. Environment/tier validation continues
   to precede all gates.
5. **`secret-scan` continues to run unconditionally** (no `needs:` on the gate
   chain, no `if:` guard).
6. **`stage-e2e-smoke` remains label-gated** by
   `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')` and keeps
   `secrets: inherit`.
7. **Reusable-workflow nesting depth stays at one level** (orchestrator -> callee).
   The cap is 4; this refactor introduces no additional nesting.
8. **The orchestrator contains no inline `steps:`.** Every job remains a `uses:`
   reference to a callee plus `needs:`, `if:`, and `secrets:` only.

- Performance characteristics to preserve (latency/throughput/memory): no
  per-callee runtime regression is intended; each gate runs the same work on the
  same runner class. The intended change is to total pipeline wall-clock time
  (reduced), not to any individual job's runtime. Concurrent runner-minute
  consumption is expected to increase (see Risks).
- Compatibility guarantees (CLI flags, config schemas, versions): no changes to
  callee inputs, `workflow_dispatch` invocations, `quality-tiers.yml`, the
  branch-protection ruleset schema, or the per-stage dispatch commands in
  `.github/workflows/README.md`.

## Scope (structural changes)

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


## Non-Goals

- Renaming any orchestrator job or any status-check context.
- Changing the required-check set or the branch-protection ruleset, including
  `.github/scripts/apply-branch-protection.ps1` and its test.
- Adding, removing, merging, or editing any `_*.yml` callee.
- Adding inline `steps:` to the orchestrator.
- Introducing a second level of reusable-workflow nesting.
- Changing per-callee runtime, runner class, or the work any gate performs.
- Migrating status-check contexts to a nested `<caller> / <callee>` form. The
  "Branch-protection rename procedure" already present in
  `.github/workflows/README.md` describes a hypothetical nested-name migration
  that is **not** triggered by a `needs:`-graph-only change; current job names
  and contexts stay flat, so that procedure remains dormant and out of scope for
  this refactor.
- Modifying `pre-merge-pipeline.yml` or any nightly/mutation pipeline.
- Adding or changing artifact upload/download between jobs (no cross-job
  filesystem dependency is introduced).

## Dependencies / Touchpoints

- `pr-pipeline.yml` — the only workflow whose `needs:` graph changes.
- `.github/workflows/README.md` — documentation of the orchestrator topology is
  updated to describe the fan-out graph and the fail-fast tradeoff.
- Branch protection on `main` — consumes the required status-check contexts.
  Unaffected because contexts/job names are unchanged.
- `.github/scripts/apply-branch-protection.ps1` and
  `tests/powershell/apply-branch-protection.Tests.ps1` — read-only touchpoints
  that pin the required-check names; they must continue to pass unchanged and
  serve as the regression anchor for invariant #2.
- The 15 `_*.yml` callees — referenced (`uses:`) but not modified.
- `feature-review-workflow` policy `modified-workflow-needs-green-run` and the
  orchestrator S9 gate — gate the merge of this workflow change on a green
  `pr-pipeline.yml` run against the branch head.
- Required coordination (other teams, CI/CD, release tooling): none beyond the
  green-run requirement. No admin branch-protection edit is required because
  status-check contexts do not change. GitHub's scheduler will run the fanned-out
  jobs concurrently subject to repository/org runner concurrency limits;
  available concurrency determines realized wall-clock savings.

## Risks & Mitigations

- Branch protection required-check names must not change (keep job names).
- Full fan-out removes per-lane fail-fast economy (a format failure no longer
  short-circuits later stages in the same lane), increasing concurrent runner
  usage in exchange for lower wall-clock time. The user explicitly prioritizes
  wall-clock time.
- Reusable-workflow nesting depth cap is 4; this change keeps one level.
- Workflow-file change requires a green CI run on the branch head before merge.


## Technical Specifications

- **Files/modules expected to change:**
  - `.github/workflows/pr-pipeline.yml` — `needs:` edges only.
  - `.github/workflows/README.md` — orchestrator topology description.

- **Current `needs:` graph (two serial lanes):**
  - TypeScript lane: `tier-classification -> stage-1-format -> stage-2-lint ->
    stage-3-typecheck -> stage-4-architecture -> stage-5-test ->
    stage-6-contract -> stage-7-integration`.
  - .NET lane: `tier-classification -> stage-1-dotnet-format ->
    stage-2-dotnet-build -> stage-3-dotnet-typecheck ->
    stage-4-dotnet-architecture -> stage-5-dotnet-test`.
  - `stage-e2e-smoke`: `needs: [stage-7-integration]`, label-gated.
  - `secret-scan`: no `needs:` (runs immediately).

- **Target `needs:` graph (fan-out after the root gate):** every gate stage
  re-parents to `needs: [tier-classification]` so the scheduler can run the
  independent stages concurrently once the root gate is green. Concretely:
  - `tier-classification` — unchanged root (no `needs:`).
  - `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`,
    `stage-5-test`, `stage-6-contract`, `stage-7-integration` — each
    `needs: [tier-classification]`.
  - `stage-1-dotnet-format`, `stage-2-dotnet-build`, `stage-3-dotnet-typecheck`,
    `stage-4-dotnet-architecture`, `stage-5-dotnet-test` — each
    `needs: [tier-classification]`.
  - `stage-e2e-smoke` — re-parented to `needs: [tier-classification]`, retaining
    its `if: contains(...'e2e:run')` guard and `secrets: inherit`. The prior
    `needs: [stage-7-integration]` edge was artificial ordering; E2E smoke does
    not consume integration-stage output (callees are self-contained).
  - `secret-scan` — unchanged (still no `needs:`; runs unconditionally).
  - This is the full fan-out the user prioritized. If a future genuine data
    dependency is identified for a specific stage, that stage may retain a
    justified additional `needs:` edge; none is known today.

- **Public interfaces/contracts affected (even if behavior is unchanged):** none.
  Job names, status-check contexts, callee inputs/outputs, dispatch commands,
  and the branch-protection ruleset are all unchanged.
- **Data flow or validation adjustments:** none. No cross-job artifact transfer
  is added or removed; each callee performs its own checkout and setup.
- **Logging/telemetry updates (if any):** none.
- **Migration or backfill needs (if any):** none. No admin branch-protection
  reconfiguration is needed because status-check contexts do not change.

## Test Strategy

This is a `needs:`-graph change to a single workflow. The graph is not exercised
by any local unit test; GitHub Actions evaluates it only at runtime. There are
therefore **no new unit tests** for this change. Validation is structural plus a
runtime green run.

- **Authoritative validation — green `pr-pipeline.yml` run against the branch
  head.** A successful end-to-end run of the modified orchestrator on the branch
  head is the primary acceptance signal. This satisfies the
  `modified-workflow-needs-green-run` policy (see
  `.claude/skills/feature-review-workflow/SKILL.md`) and the orchestrator S9
  gate. The run must show every required gate passing and the independent stages
  scheduled concurrently after `tier-classification` (verifiable from the run's
  job graph / timeline).
- **Static workflow validation:** `actionlint` on `pr-pipeline.yml` (and YAML
  validity) must pass, confirming the `needs:` references resolve to defined jobs
  and no dependency cycle is introduced.
- **Invariant validation tests (outputs/behavior unchanged):**
  `tests/powershell/apply-branch-protection.Tests.ps1` must continue to pass
  unchanged. It asserts the required status-check context set; an unchanged pass
  confirms invariant #2 (no job-name or required-check drift). No edit to the
  test or to `apply-branch-protection.ps1` is permitted.
- **Edge cases and negative scenarios:** confirm `secret-scan` still has no
  `needs:` (runs unconditionally); confirm `stage-e2e-smoke` is skipped on a PR
  without the `e2e:run` label and runs when the label is present; confirm the
  graph has no cycle and a single root.
- **Error handling and logging verification:** not applicable; no `run:` script
  logic is added. The `ci-workflows.md` deliberately-failing-nested-command rule
  does not apply because no inline `pwsh` step is added or modified.
- **Coverage impact and targets for changed lines/modules:** none. No production
  code changes; coverage thresholds are unaffected. The changed lines are YAML
  `needs:` edges, which are not covered by line/branch coverage tooling.
- **Toolchain commands to run (format -> lint -> type-check -> test):** the
  seven-stage code-change loop does not apply to a YAML-only `needs:` change.
  The applicable checks are `actionlint`/YAML validity, the unchanged Pester run
  of `apply-branch-protection.Tests.ps1`, and the green orchestrator run.
- **Manual validation steps (if required):** inspect the branch-head pipeline run
  timeline to confirm the gate stages start concurrently after
  `tier-classification` rather than serially, demonstrating the wall-clock
  reduction.

## Definition of Done

- [x] `pr-pipeline.yml` `needs:` graph re-parents every gate stage to
      `needs: [tier-classification]`; no artificial serial lane edge remains.
- [x] `stage-e2e-smoke` re-parented to `needs: [tier-classification]` with its
      `e2e:run` label gate and `secrets: inherit` retained.
- [x] `secret-scan` still runs unconditionally (no `needs:`, no `if:`).
- [x] Job names and required status-check contexts unchanged;
      `apply-branch-protection.ps1` and its test are untouched and pass.
- [x] No new callee, no inline `steps:` in the orchestrator, nesting stays at
      one level.
- [x] `actionlint` / YAML validity passes for `pr-pipeline.yml`.
- [ ] Green `pr-pipeline.yml` run produced against the branch head (S9 /
      `modified-workflow-needs-green-run`), with concurrent post-root scheduling
      visible in the run timeline.
- [x] `.github/workflows/README.md` updated to describe the fan-out topology and
      the fail-fast / runner-minute tradeoff.

## Seeded Test Conditions (from potential)
- [ ] `actionlint` / workflow YAML validity.
- [ ] `apply-branch-protection.Tests.ps1` continues to pass (names unchanged).
- [ ] Green `pr-pipeline.yml` run on branch head (S9 gate).
