# parallelize-ci-pipeline - Refactor Plan

- **Issue:** #46
- **Issue URL:** https://github.com/drmoisan/TMW/issues/46
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-01T09-58
- **Status:** Draft
- **Version:** 0.2
- **Work Mode:** full-feature

## Required References (read, do not restate)

- `.claude/rules/general-code-change.md` (cross-language code change policy)
- `.claude/rules/general-unit-test.md` (cross-language unit test policy)
- `.claude/rules/ci-workflows.md` (CI workflow authoring; pwsh exit-code rule)
- `spec.md`, `user-story.md`, `issue.md` in this feature folder

## Strategy

This is a `needs:`-graph-only refactor of a single orchestrator workflow
(`.github/workflows/pr-pipeline.yml`) plus a documentation update to
`.github/workflows/README.md`. After `tier-classification`, every gate stage is
re-parented to `needs: [tier-classification]` so the independent stages fan out
and run concurrently instead of in two serial per-language lanes.

Validation reality: this change is not exercised by any language toolchain stage
(no Black/Ruff/Pyright/ESLint/tsc/CSharpier/Pester production code changes). The
applicable plan verification tasks are: (a) `actionlint` if available (and/or YAML
parse validity), (b) confirm job keys and `needs:` edges match the required
end-state, (c) confirm `tests/powershell/apply-branch-protection.Tests.ps1` is
unaffected. The authoritative acceptance gate is a green `pr-pipeline.yml` run
against the branch head (the `modified-workflow-needs-green-run` policy and the
orchestrator S9 gate), which the orchestrator handles after PR creation — not
inside plan execution.

Hard constraints (invariants): job keys MUST NOT change;
`.github/scripts/apply-branch-protection.ps1` and
`tests/powershell/apply-branch-protection.Tests.ps1` MUST NOT be modified; no
`_*.yml` callee is added, removed, or modified; `pre-merge-pipeline.yml` is not
touched; the orchestrator keeps zero inline `steps:`; one level of
reusable-workflow nesting is preserved.

Evidence rule: every evidence-producing task records its artifact under the
canonical location `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/<kind>/`.
Evidence MUST NOT be written to `artifacts/baselines/`, `artifacts/qa/`,
`artifacts/coverage/`, or any other non-canonical path. There is no mandatory
coverage capture for this change because no production code is modified and YAML
`needs:` edges are not covered by line/branch coverage tooling.

## Work Breakdown

### Phase 0 — Baseline Capture

- [x] [P0-T1] Read policy files in required order and record a Phase 0 read-evidence artifact.
      Read in order: `CLAUDE.md`, `.claude/rules/general-code-change.md`,
      `.claude/rules/general-unit-test.md`, `.claude/rules/ci-workflows.md`,
      `.claude/rules/quality-tiers.md`. Write
      `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/phase0-instructions-read.md`
      containing `Timestamp:`, `Policy Order:`, and the explicit list of files read.
      Acceptance: artifact exists with all three fields populated and lists every file above.

- [x] [P0-T2] Capture the baseline `needs:` graph of `.github/workflows/pr-pipeline.yml`.
      Command: read `.github/workflows/pr-pipeline.yml` and record each job key with its
      current `needs:` value. Write
      `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-needs-graph.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` enumerating the two
      serial lanes (TS 7-job chain, .NET 5-job chain), `stage-e2e-smoke needs: [stage-7-integration]`,
      and `secret-scan` with no `needs:`.
      Acceptance: artifact exists; Output Summary lists all 15 job keys and their current `needs:` edges.

- [x] [P0-T3] Capture the baseline `apply-branch-protection.Tests.ps1` Pester result (regression anchor for invariant #2).
      Command: `pwsh -NoProfile -Command "Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI"`.
      Write `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-apply-branch-protection-pester.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` (pass/fail counts).
      If Pester or pwsh is unavailable in the execution environment, record `EXIT_CODE:` with the
      tool-missing diagnostic in `Output Summary:` and state that the green branch-head run is the
      authoritative substitute. Acceptance: artifact exists with all four fields populated.

- [x] [P0-T4] Capture the baseline `actionlint` (and/or YAML-validity) result for `.github/workflows/pr-pipeline.yml`.
      Command: `actionlint .github/workflows/pr-pipeline.yml` if `actionlint` is on PATH; otherwise a YAML
      parse check, e.g.
      `pwsh -NoProfile -Command "Get-Content .github/workflows/pr-pipeline.yml -Raw | ConvertFrom-Yaml | Out-Null"`
      or `python -c "import sys,yaml; yaml.safe_load(open('.github/workflows/pr-pipeline.yml'))"`.
      Write `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/baseline/baseline-actionlint.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` (clean/diagnostics, or tool-missing note).
      Acceptance: artifact exists with all four fields populated.

### Phase 1 — Constrained Small-Path Implementation

- [x] [P1-T1] Re-parent the TypeScript-lane gates in `.github/workflows/pr-pipeline.yml` to the root gate.
      Edit only the `needs:` values so each of `stage-2-lint`, `stage-3-typecheck`,
      `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration` becomes
      `needs: [tier-classification]`. `stage-1-format` already has `needs: [tier-classification]`
      (leave unchanged). Do not change any `uses:` reference, job key, or add `steps:`.
      Acceptance: in `pr-pipeline.yml`, all seven TS-lane jobs (`stage-1-format` through
      `stage-7-integration`) have `needs: [tier-classification]`; no serial TS-lane edge remains.

- [x] [P1-T2] Re-parent the .NET-lane gates in `.github/workflows/pr-pipeline.yml` to the root gate.
      Edit only the `needs:` values so each of `stage-2-dotnet-build`, `stage-3-dotnet-typecheck`,
      `stage-4-dotnet-architecture`, `stage-5-dotnet-test` becomes `needs: [tier-classification]`.
      `stage-1-dotnet-format` already has `needs: [tier-classification]` (leave unchanged).
      Do not change any `uses:` reference, job key, or add `steps:`.
      Acceptance: in `pr-pipeline.yml`, all five .NET-lane jobs (`stage-1-dotnet-format` through
      `stage-5-dotnet-test`) have `needs: [tier-classification]`; no serial .NET-lane edge remains.

- [x] [P1-T3] Re-parent `stage-e2e-smoke` in `.github/workflows/pr-pipeline.yml` to the root gate while preserving its guards.
      Change `needs: [stage-7-integration]` to `needs: [tier-classification]`. Keep
      `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')`, keep the `uses:` reference
      to `_stage-e2e-smoke.yml`, and keep `secrets: inherit`.
      Acceptance: `stage-e2e-smoke` has `needs: [tier-classification]`, retains its `e2e:run` `if:`
      guard, its `uses:` callee, and `secrets: inherit`; no other field changed.

- [x] [P1-T4] Confirm `secret-scan` and `tier-classification` are unchanged in `.github/workflows/pr-pipeline.yml`.
      Verify `secret-scan` still has no `needs:` and no `if:` (runs unconditionally), and
      `tier-classification` still has no `needs:` (single root). Make no edit unless an unintended
      change was introduced. Acceptance: `secret-scan` has no `needs:`/`if:`; `tier-classification`
      has no `needs:`.

- [x] [P1-T5] Update `.github/workflows/README.md` to describe the parallel (fan-out) execution model.
      In the orchestrator topology description (the `pr-pipeline.yml` bullet under "Files" and/or a
      short topology note), state that after `tier-classification` the independent gate stages fan out
      and run concurrently rather than in two serial per-language lanes, and note the accepted tradeoff
      (loss of per-lane fail-fast economy in exchange for lower wall-clock time, with increased
      concurrent runner-minute consumption). Do NOT modify the "Branch-protection rename procedure"
      section content beyond what the parallel model requires: job keys and required-check contexts
      are unchanged by this `needs:`-graph-only change, so the rename mapping is unaffected and remains
      dormant/out of scope. Acceptance: README describes fan-out-after-`tier-classification`; the
      rename-procedure mapping table is unchanged.

### Phase 2 — Final QC Loop

- [x] [P2-T1] Run `actionlint` (and/or YAML validity) on the modified `.github/workflows/pr-pipeline.yml`.
      Command: `actionlint .github/workflows/pr-pipeline.yml` if available; otherwise the YAML parse
      check from P0-T4. Write
      `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-actionlint.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:`. The check must confirm all
      `needs:` references resolve to defined jobs and no dependency cycle exists. Re-run after any fix.
      Acceptance: artifact exists with `EXIT_CODE: 0` (or, if the tool is missing, a YAML-valid parse
      recorded with the substitution noted).

- [x] [P2-T2] Verify the post-change `needs:` graph matches the required end-state.
      Command: read `.github/workflows/pr-pipeline.yml` and confirm each job key's `needs:` value.
      Write `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-needs-graph.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` confirming: `tier-classification`
      no `needs:`; the twelve gate jobs each `needs: [tier-classification]`; `stage-e2e-smoke`
      `needs: [tier-classification]` with `e2e:run` `if:` and `secrets: inherit`; `secret-scan` no `needs:`.
      Acceptance: artifact confirms every job key matches the required end-state and that all 15 job
      keys are unchanged from baseline.

- [x] [P2-T3] Confirm `apply-branch-protection.Tests.ps1` is unaffected and still passes (regression anchor for invariant #2).
      Command: `pwsh -NoProfile -Command "Invoke-Pester -Path tests/powershell/apply-branch-protection.Tests.ps1 -CI"`.
      Also confirm via `git status`/`git diff --name-only` that neither
      `tests/powershell/apply-branch-protection.Tests.ps1` nor `.github/scripts/apply-branch-protection.ps1`
      appears in the change set. Write
      `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-apply-branch-protection-pester.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` (pass/fail counts and the
      untouched-files confirmation). If Pester/pwsh is unavailable, record the tool-missing diagnostic
      and state the green branch-head run is the authoritative substitute, but still record the
      untouched-files confirmation from `git diff --name-only`. Acceptance: artifact confirms the two
      branch-protection files are unmodified and the Pester run passes (or records the documented
      tool-missing substitution with the untouched-files confirmation present).

- [x] [P2-T4] Confirm the diff scope is limited to the two permitted files.
      Command: `git diff --name-only`. Write
      `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-diff-scope.md`
      with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` listing changed files. The
      change set must contain only `.github/workflows/pr-pipeline.yml` and `.github/workflows/README.md`
      (plus evidence artifacts under this feature's `evidence/` folder). No `_*.yml` callee,
      `pre-merge-pipeline.yml`, or branch-protection file may appear.
      Acceptance: artifact confirms only the two permitted production/doc files changed.

- [x] [P2-T5] Record that the authoritative acceptance gate is the orchestrator-handled green branch-head run.
      Write `docs/features/active/2026-06-01-parallelize-ci-pipeline-46/evidence/qa-gates/qa-greenrun-handoff.md`
      with `Timestamp:` and an `Output Summary:` stating that a green `pr-pipeline.yml` run against the
      branch head (with the post-root stages scheduled concurrently in the run timeline) is the
      authoritative acceptance gate under `modified-workflow-needs-green-run` and the orchestrator S9
      gate, and that this run is produced by the orchestrator after PR creation, not inside plan
      execution. Acceptance: artifact exists and names the green branch-head run as the S9 acceptance gate.

## Test Plan

- No new unit tests: the `needs:` graph is evaluated only at GitHub Actions runtime and is not
  exercised by any local unit test (spec Test Strategy).
- Static validation: `actionlint`/YAML validity on `pr-pipeline.yml` (P2-T1).
- Structural validation: post-change `needs:` graph matches the required end-state (P2-T2);
  diff scope limited to the two permitted files (P2-T4).
- Regression anchor: `apply-branch-protection.Tests.ps1` passes unchanged and the two
  branch-protection files are untouched (P2-T3) — confirms invariant #2 (no status-check-name drift).
- Authoritative acceptance: green `pr-pipeline.yml` run on the branch head with concurrent post-root
  scheduling (P2-T5 handoff; executed by the orchestrator S9 gate after PR creation).
- Coverage evidence: not applicable. No production code changes; YAML `needs:` edges are not covered
  by line/branch coverage tooling, so no baseline/post-change coverage capture is required.

## Rollback / Contingency

Revert is a single-file `git checkout` of `.github/workflows/pr-pipeline.yml` (and the README) to
restore the prior serial `needs:` lanes. Because job keys and required status-check contexts are
unchanged, no branch-protection reconfiguration is needed on rollback.

## Open Questions / Notes

- No genuine cross-job data dependency is known today; full fan-out is intended per the user story.
  If a future genuine dependency is identified for a specific stage, that stage may retain a justified
  additional `needs:` edge.
- `stage-e2e-smoke` remains label-gated (`e2e:run`); it is skipped on PRs without the label, so its
  green status in a branch-head run depends on the label being present.
