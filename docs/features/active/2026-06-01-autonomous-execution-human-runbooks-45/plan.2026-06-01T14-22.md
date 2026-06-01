# autonomous-execution-human-runbooks — Plan

- **Issue:** #45
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-01T14-22
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Required References

- General Code Change Policy: `.claude/rules/general-code-change.md`
- General Unit Test Policy: `.claude/rules/general-unit-test.md`
- PowerShell Code Standards: `.claude/rules/powershell.md`
- Module Rigor Tiers: `.claude/rules/quality-tiers.md`
- Tonality Policy: `.claude/rules/tonality.md`
- Policy reading order: `.claude/skills/policy-compliance-order/SKILL.md`
- Evidence/timestamp conventions: `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`
- Feature-review workflow: `.claude/skills/feature-review-workflow/SKILL.md`

**All work must comply with these policies; do not duplicate their content here.**

## Authoritative Sources

- Acceptance criteria (authoritative): `docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45/spec.md` AC-1..AC-12.
- Design shapes + verified third-party UI citations: `artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md`.

## Evidence Location Invariant

All evidence artifacts produced by this plan are written under
`docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45/evidence/<kind>/`
per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. Non-canonical
`artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, etc. are forbidden.
The example/reference runbook (deliverable, not evidence) is written under
`.claude/skills/human-exception-runbook/` and is not governed by
`enforce-evidence-locations.ps1`.

For brevity, `<FEATURE-45>` denotes
`docs/features/active/2026-06-01-autonomous-execution-human-runbooks-45`.

## CI-verifiable Scope

#45 is mechanism-only and every acceptance criterion (AC-1..AC-12) is
CI-verifiable via schema validation, hook Pester tests, presence/format checks of
artifacts and skill/contract docs, or the PoshQC toolchain. There is no manual
acceptance criterion in #45.

## Out of Scope (Delivered on PR #44)

The two iFile (#43) runbooks (`entra-admin-consent.runbook.md`,
`outlook-on-device-verification.runbook.md`) and iFile's `human_interaction`
exception declaration are delivered separately on PR #44 against the skill
contract defined here. The iFile feature folder exists only on PR #44's branch and
is absent on #45's branch, so #45 does not author those artifacts. AC-12 in #45 is
satisfied by a self-contained example/reference runbook under
`.claude/skills/human-exception-runbook/`, not by any iFile runbook.

## Implementation Plan (Atomic Tasks)

### Phase 0 — Baseline Capture and Policy Reading

- [x] [P0-T1] Read the repo policy files in the order defined by `.claude/skills/policy-compliance-order/SKILL.md` (`.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/powershell.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/tonality.md`) and the evidence conventions skill, then write a Phase 0 policy-read evidence artifact.
  - Acceptance: `<FEATURE-45>/evidence/baseline/phase0-instructions-read.md` exists and contains `Timestamp:`, `Policy Order:`, and an explicit list of every file read.
- [x] [P0-T2] Capture the PowerShell formatting baseline for the in-scope hook files by running `mcp__drm-copilot__run_poshqc_format` (check/report mode) against `.claude/hooks/validate-orchestrator-output.ps1` and `.claude/hooks/validate-task-researcher-output.ps1`.
  - Acceptance: `<FEATURE-45>/evidence/baseline/poshqc-format-baseline.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
- [x] [P0-T3] Capture the PSScriptAnalyzer baseline by running `mcp__drm-copilot__run_poshqc_analyze` against the two in-scope hook files.
  - Acceptance: `<FEATURE-45>/evidence/baseline/poshqc-analyze-baseline.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (analyzer finding count).
- [x] [P0-T4] Capture the Pester test + coverage baseline by running `mcp__drm-copilot__run_poshqc_test` with the repo config `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`.
  - Acceptance: `<FEATURE-45>/evidence/baseline/poshqc-test-baseline.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` recording numeric baseline line coverage and branch coverage values (not placeholders).
- [x] [P0-T5] Capture the schema-validator baseline by running `mcp__drm-copilot__validate_orchestration_artifacts` against the current `.claude/schemas/orchestrator-state.schema.json` (and/or the orchestrator-state checkpoint) to record the pre-change validator state.
  - Acceptance: `<FEATURE-45>/evidence/baseline/schema-validator-baseline.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.

### Phase 1 — Schema: `human_interaction` Object and Exception Invariant

- [x] [P1-T1] Add a top-level `human_interaction` object to `.claude/schemas/orchestrator-state.schema.json` `properties`: an object with a `requirements` array whose items require `id` (string), `description` (string), `discovered_at_stage` (string), and `response` (enum `scope_change` | `exception` | `halt`), plus an optional `runbook_path` (string), preserving the existing root-level `additionalProperties: true`. [AC-2, AC-4]
  - Acceptance: the schema file contains the `human_interaction.requirements[]` definition with the four required fields and the response enum; root `additionalProperties: true` is unchanged.
- [x] [P1-T2] Add the exception-requires-runbook invariant to the `human_interaction.requirements` item definition as an `if`/`then` conditional (`response == "exception"` then `runbook_path` is required with `minLength: 1`), expressed in the same `allOf` style used by the existing `cycle` definition. [AC-3]
  - Acceptance: the schema rejects a requirement with `response: "exception"` and missing/empty `runbook_path`, and accepts the same requirement with a non-empty `runbook_path`.
- [x] [P1-T3] Author a schema self-test fixture set as three JSON instances under `<FEATURE-45>/evidence/qa-gates/` for validator use: a well-formed `human_interaction` instance (AC-2), a malformed exception with no `runbook_path` (AC-3 negative), and an existing-shape checkpoint with no `human_interaction` key (AC-4).
  - Acceptance: three fixture files exist (`hi-valid.json`, `hi-exception-no-runbook.json`, `hi-absent.json`) under `<FEATURE-45>/evidence/qa-gates/schema-fixtures/`.
- [x] [P1-T4] Validate the schema change by running `mcp__drm-copilot__validate_orchestration_artifacts` against the schema and confirming the well-formed and absent-key instances validate while the malformed-exception instance is rejected. [AC-2, AC-3, AC-4]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/schema-validation.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` recording accept/accept/reject results for the three fixtures.

### Phase 2 — Orchestrator Completion-Gate Hook

> PowerShell batch 1 of 2: one production file (`validate-orchestrator-output.ps1`) + one test file. Within the per-batch cap (<=3 prod + <=3 test).

- [x] [P2-T1] Add a pure, dot-sourceable `Test-HumanInteractionShape` function to `.claude/hooks/validate-orchestrator-output.ps1`, mirroring `Test-RemediationLoopShape`: accept `[AllowNull()] $HumanInteraction` and an injectable `[scriptblock] $FileExistsCheck` seam defaulting to `Test-Path -PathType Leaf`; return `@{ Ok; Message }`; block on unresolved/missing `response`, out-of-enum `response`, any `response == "halt"`, and `exception` with missing/empty/non-existent `runbook_path`; pass on `$null` input. [AC-5, AC-6, AC-7, AC-8]
  - Acceptance: function is defined, returns a hashtable, uses the injected seam for file existence, and the file remains under 500 lines and dot-sourceable (entrypoint guard unchanged).
- [x] [P2-T2] Wire `Test-HumanInteractionShape` into `Invoke-OrchestratorOutputValidation` after the existing `Test-RemediationLoopShape` call, passing `$checkpoint.human_interaction` (read via the existing `$checkpointProps` guard so an absent key yields `$null`), and return its blocking message when `Ok` is `$false`. [AC-5, AC-6, AC-7, AC-8]
  - Acceptance: `Invoke-OrchestratorOutputValidation` calls the new function and returns its block message; existing checkpoint-field checks are unchanged.
- [x] [P2-T3] Add Pester tests for `Test-HumanInteractionShape` in `tests/powershell/validate-orchestrator-output.Tests.ps1`, dot-sourcing the hook in dot-import mode (mirroring `validate-feature-review-coverage.Tests.ps1`): cases for null passes (AC-5), unresolved-response blocks (AC-6), `halt` blocks (AC-7), and exception missing-path / non-existent-file / existing-file via the injected `FileExistsCheck` seam (AC-8). No temp files. [AC-5, AC-6, AC-7, AC-8, AC-11]
  - Acceptance: the test file exists, contains the listed `It` cases keyed to AC-5..AC-8, and uses the injected seam (no filesystem writes).
- [x] [P2-T4] Run the PowerShell toolchain for batch 1 in order — `mcp__drm-copilot__run_poshqc_format`, then `mcp__drm-copilot__run_poshqc_analyze`, then `mcp__drm-copilot__run_poshqc_test` (coverage mode) — restarting from format if any stage changes files or fails, until a single clean pass. [AC-11]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/poshqc-batch1.2026-06-01T14-22.md` exists with one section per stage, each with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:`; the test section records numeric line and branch coverage for the changed file.

### Phase 3 — Researcher Hook: Automation-Feasibility Section

> PowerShell batch 2 of 2: one production file (`validate-task-researcher-output.ps1`) + one test file. Within the per-batch cap.

- [x] [P3-T1] Add a pure, dot-sourceable `Test-AutomationFeasibilitySection` function to `.claude/hooks/validate-task-researcher-output.ps1`: accept `[string] $ResearchFilePath`, `[string] $AgentOutput`, and an injectable `[scriptblock] $ReadFileContent` seam defaulting to `Get-Content -Raw`; apply the narrow detection condition (filename/agent-output token match for autonomous-execution research per OD-45-7); when applicable, require an `## Automation Feasibility` section and block when absent; return `@{ Ok; Message }`. Non-applicable artifacts pass. [AC-9]
  - Acceptance: function is defined, returns a hashtable, uses the injected read seam, applies the narrow detection condition, and the file remains under 500 lines and dot-sourceable.
- [x] [P3-T2] Wire `Test-AutomationFeasibilitySection` into `Invoke-TaskResearcherOutputValidation` after the existing `Test-ResearchFile` check and before the final `Ok = $true` return, passing the resolved research path and agent output. [AC-9]
  - Acceptance: `Invoke-TaskResearcherOutputValidation` calls the new function and returns its block message when `Ok` is `$false`; existing path/filename/existence checks are unchanged.
- [x] [P3-T3] Add Pester tests for `Test-AutomationFeasibilitySection` in `tests/powershell/validate-task-researcher-output.Tests.ps1`, dot-sourcing the hook in dot-import mode: cases for applicable-missing blocks, applicable-present passes, and non-applicable passes, all via the injected `ReadFileContent` seam. No temp files. [AC-9, AC-11]
  - Acceptance: the test file exists, contains the three `It` cases keyed to AC-9, and uses the injected seam (no filesystem writes).
- [x] [P3-T4] Run the PowerShell toolchain for batch 2 in order — `mcp__drm-copilot__run_poshqc_format`, then `mcp__drm-copilot__run_poshqc_analyze`, then `mcp__drm-copilot__run_poshqc_test` (coverage mode) — restarting from format if any stage changes files or fails, until a single clean pass. [AC-11]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/poshqc-batch2.2026-06-01T14-22.md` exists with one section per stage, each with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:`; the test section records numeric line and branch coverage for the changed file.

### Phase 4 — Skill, Example Runbook, and Contract Documentation

- [x] [P4-T1] Create `.claude/skills/human-exception-runbook/SKILL.md` defining the runbook contract: canonical path `<FEATURE>/runbooks/<name>.runbook.md`; the five required sections (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation); and the sourcing rule (MCP-first / web-second for third-party UI; training data is not an acceptable sole source; per OD-45-5 non-UI CLI steps still require a cited current source). [AC-10]
  - Acceptance: the file exists and contains the canonical path token, all five section names, and the MCP-first/web-second sourcing-rule language.
- [x] [P4-T2] Author a self-contained example/reference runbook at `.claude/skills/human-exception-runbook/example.runbook.md` that conforms to the contract and contains all five required sections (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation); the Source-and-Citation section records source URL(s) and a dated capture (`updated_at`) for each cited step. The example is self-contained and does not reference the iFile feature folder. [AC-12]
  - Acceptance: `.claude/skills/human-exception-runbook/example.runbook.md` exists, contains all five named section headers, and its Source-and-Citation section contains at least one source URL with a capture date.
- [x] [P4-T3] Update `.claude/skills/orchestrate/SKILL.md` to document the autonomous-execution mandate, the rule that a silent end-of-workflow manual blocker is a defect, the detection points (pre-kickoff where knowable; research-stage at latest), the three responses (`scope_change`, `exception`, `halt`), the exception-runbook requirement, and the schema/hook enforcement points (schema `human_interaction`, `Test-HumanInteractionShape` completion gate, `Test-AutomationFeasibilitySection` research gate). [AC-1]
  - Acceptance: `.claude/skills/orchestrate/SKILL.md` contains the mandate statement, the three response tokens, the detection-point language, and the runbook-requirement and enforcement language.
- [x] [P4-T4] Verify the documentation and example-runbook deliverables with a presence/format check and record evidence: confirm AC-1 tokens in `orchestrate/SKILL.md`, AC-10 tokens in `human-exception-runbook/SKILL.md`, and AC-12 tokens (five sections + dated citation) in `human-exception-runbook/example.runbook.md`. [AC-1, AC-10, AC-12]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/skill-presence-check.2026-06-01T14-22.md` exists listing the matched tokens and their files for all three deliverables.

### Phase 5 — Final QA Loop

- [x] [P5-T1] Run the full PowerShell toolchain in order across all changed hook and test files — `mcp__drm-copilot__run_poshqc_format`, then `mcp__drm-copilot__run_poshqc_analyze`, then `mcp__drm-copilot__run_poshqc_test` (coverage mode, repo config `scripts/powershell/PoshQC/settings/pester.runsettings.psd1`) — restarting from format if any stage changes files or fails, until a single clean pass. [AC-11]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/poshqc-final.2026-06-01T14-22.md` exists with one section per stage, each with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:`.
- [x] [P5-T2] Record final PowerShell coverage and the no-regression / threshold delta versus the Phase 0 baseline: report baseline line/branch coverage, post-change line/branch coverage, and changed-line coverage for `validate-orchestrator-output.ps1` and `validate-task-researcher-output.ps1`, confirming line >= 85% and branch >= 75% with no regression on changed lines. [AC-11]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/coverage-delta.2026-06-01T14-22.md` exists with numeric baseline, post-change, and changed-code coverage values; outcome is PASS only if thresholds and no-regression hold, otherwise remediation-required.
- [x] [P5-T3] Run the final schema validation via `mcp__drm-copilot__validate_orchestration_artifacts` against `.claude/schemas/orchestrator-state.schema.json` and the three Phase 1 fixtures, confirming accept/reject behavior is unchanged from Phase 1. [AC-2, AC-3, AC-4]
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/schema-validation-final.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` recording accept/accept/reject for the three fixtures.
- [x] [P5-T4] Run the orchestration plan validator on this plan via `mcp__drm-copilot__validate_orchestration_artifacts` with `artifact_type: "plan"` and `artifact_path: <FEATURE-45>/plan.2026-06-01T14-22.md`, confirming a zero exit.
  - Acceptance: `<FEATURE-45>/evidence/qa-gates/plan-validation.2026-06-01T14-22.md` exists with `Timestamp:`, `Command:`, `EXIT_CODE: 0`, `Output Summary:`.

## Acceptance-Criteria Coverage Map

- AC-1 → P4-T3, P4-T4
- AC-2 → P1-T1, P1-T3, P1-T4, P5-T3
- AC-3 → P1-T2, P1-T3, P1-T4, P5-T3
- AC-4 → P1-T1, P1-T3, P1-T4, P5-T3
- AC-5 → P2-T1, P2-T3
- AC-6 → P2-T1, P2-T3
- AC-7 → P2-T1, P2-T3
- AC-8 → P2-T1, P2-T3
- AC-9 → P3-T1, P3-T3
- AC-10 → P4-T1, P4-T4
- AC-11 → P2-T4, P3-T4, P5-T1, P5-T2
- AC-12 → P4-T2, P4-T4

## Test Plan

- Unit (Pester): `Test-HumanInteractionShape` (null passes, unresolved blocks, halt blocks, exception missing/non-existent/existing via injected seam) and `Test-AutomationFeasibilitySection` (applicable-missing blocks, applicable-present passes, non-applicable passes via injected seam). No temp files; both functions dot-sourced.
- Schema validation: well-formed `human_interaction` accepted; malformed exception rejected; absent-key checkpoint accepted.
- Presence/format: orchestrate SKILL mandate tokens; human-exception-runbook SKILL section + sourcing tokens; the example/reference runbook's five sections + dated citation.
- Coverage evidence: baseline `<FEATURE-45>/evidence/baseline/poshqc-test-baseline.2026-06-01T14-22.md`; post-change `<FEATURE-45>/evidence/qa-gates/poshqc-final.2026-06-01T14-22.md`; delta `<FEATURE-45>/evidence/qa-gates/coverage-delta.2026-06-01T14-22.md`.

## Open Questions / Notes

- The iFile feature folder exists only on PR #44's branch and is absent on #45's branch; #45 is mechanism-only and does not author iFile runbooks. The two iFile runbooks (`entra-admin-consent.runbook.md`, `outlook-on-device-verification.runbook.md`) and iFile's `human_interaction` exception declaration are delivered on PR #44 against the skill contract defined here. AC-12 in #45 is satisfied by the self-contained example/reference runbook at `.claude/skills/human-exception-runbook/example.runbook.md` (P4-T2).
- This feature does not modify `.github/workflows/**`, `scripts/benchmarks/**`, or `.github/actions/**`, so `modified-workflow-needs-green-run` does not fire. Extending that rule to `.claude/hooks/**` is a recommended follow-up only (OD-45-2; out of scope).
- No `.claude/settings.json` change is required; the dedicated hook files are already wired (OD-45-4).
- A `halt` is clearable by a later checkpoint update; the completion gate blocks DONE only while a halt is present (OD-45-3).
- Mirror-sync note: per prior repo inspection the `.codex/`, `.agents/`, and `.github/` bundle mirrors are non-uniform and there is no 1:1 `rules/`/`hooks/` mirror for these files; no mirror-sync tasks are included. Re-verify before adding any.
