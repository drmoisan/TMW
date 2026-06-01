# parallelize-ci-pipeline - User Story

- **Issue:** #46
- **Owner:** drmoisan
- **Last Updated:** 2026-06-01
- **Status:** Draft
- **Work Mode:** full-feature

## Story

As a developer waiting on PR CI for a pull request to `main`,
I want the independent pipeline gates to run in parallel after the
`tier-classification` root gate completes,
so that I get a pass/fail signal in less wall-clock time and can iterate or merge
sooner.

## Context

The PR pipeline (`.github/workflows/pr-pipeline.yml`) currently chains gates
through `needs:` into two long serial lanes: a 7-job TypeScript lane and a 5-job
.NET lane. Each lane stage waits for the previous stage even though every callee
(`_*.yml`) is self-contained — it performs its own checkout and environment
setup and does not consume any prior stage's filesystem output. The serial
`needs:` edges are artificial ordering, not real data dependencies, so total
wall-clock time is roughly the sum of each lane's stages rather than the longest
single stage. A developer pushing a commit waits for that full serial sum before
seeing the overall result.

## Value

- Lower wall-clock time from push to a complete PR-CI verdict, which is the
  developer's primary feedback latency.
- Faster identification of failures across all gates at once (each gate reports
  independently rather than being blocked behind an earlier stage in its lane).

## Acknowledged Tradeoff

Full fan-out removes per-lane fail-fast economy: when an early gate (for example
format) fails, later gates in the same lane no longer short-circuit and instead
run concurrently, increasing concurrent runner-minute consumption. The user has
explicitly prioritized wall-clock time over runner-minute savings, so this
tradeoff is accepted.

## Acceptance Criteria

- [x] After `tier-classification`, all independent TypeScript-lane and .NET-lane
      stages are schedulable in parallel; no artificial serial `needs:` chain
      remains in `pr-pipeline.yml`.
- [x] Every non-root stage has `needs: [tier-classification]` (or a justified
      genuine dependency), so the environment/tier gate still runs first.
- [x] Job names in `pr-pipeline.yml` are unchanged, and the required
      status-check contexts remain identical to the current set
      (`tier-classification`, `stage-1-format`, `stage-2-lint`,
      `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`,
      `stage-6-contract`, `stage-7-integration`).
- [x] `secret-scan` continues to run unconditionally; `stage-e2e-smoke` remains
      label-gated on `e2e:run`.
- [ ] A green `pr-pipeline.yml` run against the branch head is produced, with the
      run timeline showing the gate stages starting concurrently after
      `tier-classification` rather than serially.
- [x] `tests/powershell/apply-branch-protection.Tests.ps1` continues to pass
      unchanged (confirming no status-check-name drift).

## Out of Scope

- Renaming jobs or status-check contexts, or editing the branch-protection script
  or its test.
- Adding, removing, or modifying any `_*.yml` callee, or adding inline steps to
  the orchestrator.
- Changing `pre-merge-pipeline.yml` or any nightly/mutation pipeline.
