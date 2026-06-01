# autonomous-execution-human-runbooks — Spec

- **Issue:** #45
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-06-01
- **Status:** Draft
- **Version:** 0.2
- **Work Mode:** full-feature

## Overview

The orchestrator workflow must achieve all actions agentically with no human interaction; full autonomy is a hard requirement. The iFile feature (#43 / PR #44) reached the PR gate parked on manual device/tenant steps (Azure AD scope consent, on-device Outlook verification, production-domain configuration) that were never declared up front. That outcome is a workflow defect: an unautomatable dependency surfaced as a silent manual blocker at the end of the workflow rather than being detected early and resolved through an explicit, enforced mechanism.

This feature introduces and enforces an autonomous-execution mandate. Every unautomatable requirement must be detected (pre-kickoff where knowable, at the research stage at the latest), resolved by exactly one of three permitted responses (scope change, permitted exception, or halt), and recorded in orchestrator state. A permitted exception must be backed by a human-readable runbook artifact. Enforcement is wired into the orchestrate skill contract, the orchestrator-state schema, the research-stage hook, and the orchestrator completion gate, so that DONE cannot be written while any human-interaction requirement is unresolved, a halt is present, or an exception lacks an existing runbook file.

## Scope

### In scope

- A documented autonomous-execution mandate in the orchestrate skill contract: full agentic execution is mandatory, and a silent manual blocker at the end of a workflow is a defect.
- Detection-point rules: unautomatable requirements enumerated pre-kickoff where knowable; otherwise surfaced no later than the research stage. Research that touches third-party UIs must include an explicit automation-feasibility / human-interaction assessment.
- The three permitted responses to a human-interaction dependency (scope change, exception, halt), with the rule that exactly one is chosen per requirement and recorded.
- A `human_interaction.requirements[]` top-level addition to `orchestrator-state.schema.json`, with the exception-requires-runbook invariant.
- Completion-gate enforcement in `validate-orchestrator-output.ps1`: block DONE while any requirement is unresolved, when any `halt` response is present, or when an `exception` lacks an existing `runbook_path` file.
- Research-stage enforcement in `validate-task-researcher-output.ps1`: require an `## Automation Feasibility` section for applicable research artifacts.
- A new `.claude/skills/human-exception-runbook/SKILL.md` defining the runbook artifact contract: canonical path, required sections, and the MCP-first / web-second sourcing rule.
- A self-contained example/reference runbook (`.claude/skills/human-exception-runbook/example.runbook.md`) that conforms to the contract and contains all required sections (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation). The example ships within #45 and is CI-verifiable.
- Pester tests for all new/changed PowerShell hook functions, passing the PoshQC format → analyze → test toolchain; hooks remain dot-sourceable and deterministic.

### Out of scope

- Authoring the two iFile (#43) runbooks (`entra-admin-consent.runbook.md`, `outlook-on-device-verification.runbook.md`) and iFile's `human_interaction` exception declaration. The iFile feature folder exists only on the separate iFile branch / PR #44, not on #45's branch; #45 cannot author artifacts in a folder that does not exist on its branch, and #45 must not depend on them. These iFile artifacts are delivered separately on PR #44 against this feature's skill contract. See the cross-reference note under Acceptance Criteria.
- Any manual / human-verified acceptance criterion. #45 is pure workflow infrastructure (hooks, schema, skills, docs) with no Outlook UI to verify; every #45 acceptance criterion is CI-verifiable. The on-device iOS Outlook rendering verification is an iFile concern delivered on PR #44, not a #45 AC.
- Expanding the `modified-workflow-needs-green-run` rule to cover `.claude/hooks/**`. Recorded as a recommended follow-up (OD-45-2). This feature changes hooks, schema, skills, and docs only; it does not change `.github/workflows/**`.
- Adding a scripted Global-Administrator service-principal credential to CI. Admin consent remains a permitted exception with a runbook (resolved decision OD-45-1); the iFile runbook applying this is delivered on PR #44.
- External hosting / DNS / TLS provisioning decisions for production manifest domains. These are one-time human administrative decisions outside the orchestrator's recurring workflow scope.
- Automating the iFile items that are automatable (Graph delegated-permission declarations via `az ad app permission add`; production manifest-domain substitution). These are classified as scope-change/automatable and are explicitly NOT runbook steps; their implementation is iFile's concern, not this feature's.

## Behavior (the mechanism)

### 1. Autonomous-execution mandate

The orchestrator must achieve all actions agentically with no human interaction; full autonomy is a hard requirement. A silent manual blocker discovered at the end of a workflow is a defect. The mandate is documented authoritatively in the orchestrate skill contract.

### 2. Detection points

- Unautomatable requirements are enumerated as mandatory unachievable requirements before kickoff where knowable.
- Where research is required to discover them, they MUST be surfaced no later than the research stage.
- Research that touches third-party UIs (Azure portal / Entra admin center, Outlook desktop/mobile, Microsoft 365 admin center) MUST include an explicit automation-feasibility / human-interaction assessment, recorded under an `## Automation Feasibility` section in the research artifact.

### 3. Three permitted responses

When a step cannot be performed without a human, the orchestrator must choose exactly one response per requirement and record it in orchestrator state:

1. **`scope_change`** — change the scope to remove the manual dependency (for example, replace a portal click with an `az` CLI step that runs unattended).
2. **`exception`** — permit an exception. This requires emitting a human-exception runbook (see section 4).
3. **`halt`** — halt until further instruction. A `halt` blocks DONE.

### 4. Human-exception runbook

On a permitted exception, the orchestrator emits a human-readable runbook at `<FEATURE>/runbooks/<name>.runbook.md`. The path stored in `runbook_path` is relative to the repo root. The runbook contains these sections:

- **Cue** — when to act; the event or state that triggers the runbook.
- **Prerequisites** — what must be true before the human starts (accounts, roles, devices, tools).
- **Step-by-step Instructions** — numbered steps, including detailed third-party UI navigation where applicable.
- **Verification** — how the user confirms success (observable state or confirmation dialog).
- **Source and Citation** — MCP/web source URLs plus capture date for each third-party UI section.

Third-party UI steps MUST be sourced MCP-first / web-second, never from training data. The contract is defined authoritatively in the new `.claude/skills/human-exception-runbook/SKILL.md`. The runbook path is under the feature folder but is not an `evidence/` sub-path, so it is not governed by `enforce-evidence-locations.ps1`.

### 5. State and enforcement

- **Schema.** `orchestrator-state.schema.json` gains a top-level `human_interaction` object with a `requirements[]` array. Each requirement: `id` (string, required), `description` (string, required), `discovered_at_stage` (string, required), `response` (enum `scope_change` | `exception` | `halt`, required), `runbook_path` (string, conditionally required). Invariant, expressed as an `if`/`then` conditional consistent with the existing schema style: `response == "exception"` requires a non-empty `runbook_path`. The top-level schema retains `additionalProperties: true`, so existing checkpoints with no `human_interaction` key remain valid.
- **Completion gate.** `validate-orchestrator-output.ps1` gains a `Test-HumanInteractionShape` function following the existing `Test-RemediationLoopShape` pattern (pure, dot-sourceable, with an injectable `FileExistsCheck` scriptblock seam). It blocks DONE when: a requirement has no resolved `response`; a `response` value is outside the enum; a `halt` response is present; or an `exception` has a missing/empty `runbook_path` or one whose file does not exist on disk. A null `human_interaction` (absent key) passes the gate. It is called from `Invoke-OrchestratorOutputValidation` after the existing `Test-RemediationLoopShape` call.
- **Research hook.** `validate-task-researcher-output.ps1` gains a `Test-AutomationFeasibilitySection` function (pure, dot-sourceable, with an injectable `ReadFileContent` seam). For applicable research artifacts (detection condition: filename/agent-output token match for autonomous-execution research), it requires an `## Automation Feasibility` section and blocks otherwise. Non-applicable research is unaffected.
- **Contract.** The orchestrate SKILL contract documents the mandate, the detection points, the three responses, the runbook requirement, and the enforcement points above.

## Inputs / Outputs

- **Inputs:** orchestrator-state checkpoint JSON (with the optional `human_interaction` object); research artifacts under `artifacts/research/`; the agent output passed to each hook.
- **Outputs:** human-exception runbooks under `<FEATURE>/runbooks/`; hook pass/block decisions (exit 0 / exit 1); orchestrator-state with resolved `human_interaction.requirements[]`.
- **Config keys and defaults:** none added. Hooks remain wired via existing `.claude/settings.json` SubagentStop entries; no `settings.json` change is needed (the dedicated hook files are already wired — verified OD-45-4).
- **Versioning / backward-compatibility constraints:** schema change is additive under `additionalProperties: true`; checkpoints without `human_interaction` remain valid and pass the completion gate.

## API / CLI Surface

- `Test-HumanInteractionShape -HumanInteraction <obj> [-FileExistsCheck <scriptblock>]` → `@{ Ok = <bool>; Message = <string|null> }`. Pure; default `FileExistsCheck` calls `Test-Path -PathType Leaf`.
- `Test-AutomationFeasibilitySection -ResearchFilePath <string> -AgentOutput <string> [-ReadFileContent <scriptblock>]` → `@{ Ok = <bool>; Message = <string|null> }`. Pure; default `ReadFileContent` calls `Get-Content -Raw`.
- Both functions are dot-sourceable for Pester without invoking the hook entrypoint, consistent with `.claude/rules/powershell.md`.

## Data & State

- New top-level `human_interaction.requirements[]` in orchestrator-state. A requirement is resolved when `response` is set to one of the three enum values and, in the `exception` case, `runbook_path` points to an existing file. Unresolved means a missing/blank `response` or, for `exception`, a missing/non-existent `runbook_path` file.
- No migration or backfill is required; the field is optional and additive.

## Constraints & Risks

- PowerShell hook changes require Pester tests and the PoshQC format → analyze → test toolchain; hooks must remain dot-sourceable and deterministic per `.claude/rules/powershell.md`.
- Schema changes must preserve backward compatibility (`additionalProperties: true`).
- `modified-workflow-needs-green-run` covers `.github/workflows/**`, `scripts/benchmarks/**`, and `.github/actions/**`. This feature does not touch those paths, so the rule does not fire. Extending the rule to `.claude/hooks/**` is deliberately deferred (see Out of scope and OD-45-2).
- Third-party UI documentation drifts; each runbook must cite source URL and capture date and prefer MCP/web over training data.

## Backward Compatibility

- Top-level schema `additionalProperties: true` is preserved; checkpoints with no `human_interaction` key validate and pass the completion gate (the `Test-HumanInteractionShape` null guard returns `Ok = $true`).
- The research hook enforces the `## Automation Feasibility` section only for applicable (autonomous-execution) research artifacts; existing research files outside that detection condition are unaffected.
- No public function signatures are removed; the new functions are additive.

## Resolved Decisions (do not re-open)

- **OD-45-1.** Do NOT place Global-Administrator credentials in CI; admin consent remains a permitted exception with a runbook. The iFile runbook applying this is delivered on PR #44.
- **OD-45-2.** Do NOT expand `modified-workflow-needs-green-run` to `.claude/hooks/**` in this feature; record as a recommended follow-up. #45 changes hooks/schema/skills/docs only, not `.github/workflows/**`.
- **OD-45-4.** No `settings.json` change is needed; the dedicated hook files (`validate-orchestrator-output.ps1`, `validate-task-researcher-output.ps1`) are already wired via existing `.claude/settings.json` SubagentStop entries.
- **OD-45-3.** A `halt` response is clearable via a checkpoint update. A `halt` blocks DONE while present; when the underlying requirement is later resolved (the orchestrator-state checkpoint is updated to a `scope_change` or runbook-backed `exception`, or the `halt` is otherwise cleared), the completion gate no longer blocks on it. `halt` is a recoverable state, not a terminal one.
- **OD-45-5.** Third-party UI steps MUST be sourced MCP-first / web-second, never from training data. Non-UI CLI steps (for example `az` commands) still require a cited current source in the Source-and-Citation section; the MCP-first/web-second ordering is mandatory only for third-party UI navigation, but every step type carries a current, dated citation.
- **OD-45-6.** Runbooks are stored per-feature under `<FEATURE>/runbooks/<name>.runbook.md`, with `runbook_path` recorded relative to the repo root. This path is under the feature folder but is not an `evidence/` sub-path, so it is not governed by `enforce-evidence-locations.ps1`.
- **OD-45-7.** Research-hook detection of applicable artifacts is narrow: `Test-AutomationFeasibilitySection` enforces the `## Automation Feasibility` section only when the filename/agent-output token match identifies an autonomous-execution research artifact. Non-matching research is unaffected, so the hook does not impose the section on unrelated research output.

## Implementation Strategy

- Add the `human_interaction` object and the exception-requires-runbook conditional to `orchestrator-state.schema.json`.
- Add `Test-HumanInteractionShape` to `validate-orchestrator-output.ps1` and call it from `Invoke-OrchestratorOutputValidation`.
- Add `Test-AutomationFeasibilitySection` to `validate-task-researcher-output.ps1` and call it from `Invoke-TaskResearcherOutputValidation`.
- Author `.claude/skills/human-exception-runbook/SKILL.md` and a conforming `.claude/skills/human-exception-runbook/example.runbook.md`.
- Update the orchestrate SKILL contract to document the mandate, detection points, three responses, runbook requirement, and enforcement.
- Add Pester tests for both new functions covering positive, negative, and edge/boundary cases.
- Sequencing note: the production hook/schema/skill changes are out of scope for THIS agent (PRD authoring only). They are listed here for the implementing plan. The two iFile runbooks and iFile's `human_interaction` exception declaration are delivered separately on PR #44 against this skill contract and are out of scope for #45's branch.

## Acceptance Criteria

Every criterion is CI-verifiable. #45 is pure workflow infrastructure (hooks, schema, skills, docs) with no Outlook UI, so it has no manual acceptance criterion; full CI verifiability is the autonomy ideal this feature exists to enforce, and the feature applies that ideal to itself. CI-verifiable items are verified by schema validation, hook Pester tests, presence/format checks of artifacts and skill/contract docs, or the PoshQC toolchain.

- [x] **AC-1 (CI-verifiable).** The orchestrate skill contract defines the autonomous-execution mandate, states that a silent end-of-workflow manual blocker is a defect, and documents the three responses, the detection points (pre-kickoff and research-stage-at-latest), and the exception-runbook requirement. Verify: presence/format check that `.claude/skills/orchestrate/SKILL.md` contains the mandate statement, the three response tokens (`scope_change`, `exception`, `halt`), and the detection-point and runbook-requirement language.
- [x] **AC-2 (CI-verifiable).** `orchestrator-state.schema.json` defines a top-level `human_interaction.requirements[]` with required `id`, `description`, `discovered_at_stage`, and `response` (enum `scope_change` | `exception` | `halt`). Verify: a well-formed instance validates against the schema.
- [x] **AC-3 (CI-verifiable).** The schema rejects a malformed exception: a requirement with `response == "exception"` and no non-empty `runbook_path` fails validation; the same requirement with a non-empty `runbook_path` validates. Verify: two schema-validation cases (negative rejected, positive accepted).
- [x] **AC-4 (CI-verifiable).** Top-level schema backward compatibility is preserved: a checkpoint with no `human_interaction` key validates. Verify: schema-validation case on an existing-shape checkpoint.
- [x] **AC-5 (CI-verifiable).** `Test-HumanInteractionShape` returns `Ok = $true` when `human_interaction` is `$null` (absent). Verify: Pester case.
- [x] **AC-6 (CI-verifiable).** `Test-HumanInteractionShape` blocks (`Ok = $false`) when a requirement has no resolved `response`. Verify: Pester case.
- [x] **AC-7 (CI-verifiable).** `Test-HumanInteractionShape` blocks when any requirement has `response == "halt"`. Verify: Pester case.
- [x] **AC-8 (CI-verifiable).** `Test-HumanInteractionShape` blocks when `response == "exception"` and `runbook_path` is missing/empty, or present but the file does not exist (via the injected `FileExistsCheck` seam); and passes when the runbook file exists. Verify: three Pester cases (missing path, non-existent file, existing file).
- [x] **AC-9 (CI-verifiable).** `Test-AutomationFeasibilitySection` requires an `## Automation Feasibility` section for applicable research artifacts and blocks when it is absent; it passes for non-applicable artifacts and for applicable artifacts that contain the section. Verify: three Pester cases (applicable-missing blocked, applicable-present passes, non-applicable passes), using the injected `ReadFileContent` seam (no temp files).
- [x] **AC-10 (CI-verifiable).** The `.claude/skills/human-exception-runbook/SKILL.md` exists and defines the canonical path `<FEATURE>/runbooks/<name>.runbook.md`, the five required sections (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation), and the MCP-first / web-second sourcing rule. Verify: presence/format check for the path token, the five section names, and the sourcing-rule language.
- [x] **AC-11 (CI-verifiable).** All new/changed PowerShell hook functions have Pester tests and pass the PoshQC format → analyze → test toolchain; hooks remain dot-sourceable and deterministic. Verify: PoshQC run is green and the Pester suite covers both new functions per the coverage thresholds in `.claude/rules/general-unit-test.md`.
- [x] **AC-12 (CI-verifiable).** A self-contained example/reference runbook `.claude/skills/human-exception-runbook/example.runbook.md` exists, conforms to the contract, and contains all five required sections (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation), with the Source-and-Citation section recording source URL(s) and a capture date. Verify: presence/format check that the example file exists and contains the five section names and citation content. This keeps the runbook-format AC CI-verifiable within #45 without depending on the iFile feature folder.

> **Delivered on PR #44 (out of scope for #45's branch).** The two iFile (#43) runbooks — `entra-admin-consent.runbook.md` (Global-Admin admin-consent, genuinely human-gated) and `outlook-on-device-verification.runbook.md` (iOS on-device rendering, genuinely human-gated) — and iFile's `human_interaction` exception declaration are produced on PR #44 using the skill contract defined here. The iFile feature folder exists only on the iFile branch / PR #44, not on #45's branch, so these artifacts cannot be authored within #45 and are not #45 acceptance criteria. This is a cross-reference, not a #45 AC. The automatable iFile items (Graph permission declarations via `az ad app permission add`; production manifest-domain substitution) are classified as scope-change/automatable and are not runbook steps; that classification is also an iFile (PR #44) concern.

## Definition of Done

- [ ] All acceptance criteria above documented and mapped to CI verification (schema validation, hook Pester tests, presence/format checks, or the PoshQC toolchain). No #45 AC requires manual verification.
- [ ] Behavior matches acceptance criteria in all documented environments.
- [ ] Tests added for both new hook functions (positive, negative, edge cases) with no temp files.
- [ ] Docs updated: orchestrate SKILL contract, new human-exception-runbook SKILL and its conforming example runbook, this spec, and user-story.
- [ ] Toolchain pass completed (format → analyze → test) for PowerShell hooks.

## Seeded Test Conditions (from potential)

- [ ] Hook unit tests: DONE blocked when a requirement is unresolved; allowed when `human_interaction` is absent; blocked when a permitted exception references a missing runbook; allowed when the runbook exists; blocked when a `halt` response is present.
- [ ] Schema validation: malformed exception (permitted, no runbook path) rejected; well-formed accepted; absent `human_interaction` accepted.
- [ ] Research hook: feasibility-assessment presence enforcement for applicable artifacts.
- [ ] The example/reference runbook (`.claude/skills/human-exception-runbook/example.runbook.md`) is well-formed (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation) and validates against the contract.
