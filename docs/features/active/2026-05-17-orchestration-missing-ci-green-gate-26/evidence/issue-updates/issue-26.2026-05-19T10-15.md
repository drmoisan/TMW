# Issue #26 update mirror

Timestamp: 2026-05-19T10-15
PostedAs: comment
GitHub URL: https://github.com/drmoisan/TMW/issues/26#issuecomment-4493866034

---

## Implementation update — orchestration CI green gate (issue #26)

The fix has been implemented and verified against the spec acceptance criteria (full-bug mode; spec.md is the AC source). Summary of delivered changes:

Skill changes:
- `.claude/skills/orchestrate/SKILL.md`: added `S9_ci_green` step after `S8_create_pr` (AC1); extended the checkpoint schema with the `ci_gate` object, `last_verified_ci_sha`, and `step9_status` enum (AC2); added the fifth PR Creation Gate condition (AC3); documented CI-failure remediation handling (AC4) and the `remediation_pass` cap of 3 with `blocked_ci_loop_limit` halt (AC5); documented backward compatibility (missing `ci_gate` treated as pending).
- `.claude/skills/feature-review-workflow/SKILL.md`: added the `modified-workflow-needs-green-run` policy rule with the three trigger globs and the `workflow_dispatch` allowance (AC6).

New rule files:
- `.claude/rules/benchmark-baselines.md`: rejects `ProcessorName == "Unknown processor"` and requires a sibling `baseline.provenance.json` (AC7).
- `.claude/rules/ci-workflows.md`: documents the `pwsh` deliberately-failing-nested-command exit-code pattern (AC8).

New validators + tests:
- `scripts/orchestration/Invoke-CiGateParser.ps1` (AC9) with five-scenario Pester coverage (AC10).
- `scripts/benchmarks/Test-BaselineProvenance.ps1` (AC11) with three-scenario Pester coverage (AC12).
- `scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1` supporting the AC6 rule.
- An S9 end-to-end integration test against fixture `gh` output.

Quality:
- Bundled-mirror parity confirmed for all existing mirrors; roots without a mirror target recorded explicitly (AC13).
- Full local mandatory toolchain passed in a single clean pass; new-code line coverage 100% (AC14).

Status of AC15: PARTIAL/UNVERIFIED at this stage. AC15 requires a green PR Pipeline against the branch head SHA with the `ci_gate` recorded on this feature's checkpoint before DONE. That step is performed by the orchestrator's S8/S9 lifecycle after handoff (no PR is open yet). The S9 mechanism that AC15 exercises is implemented and tested.

AC checkoff: AC1-AC14 are checked off in spec.md. AC15 remains unchecked pending the orchestrator green-run.
