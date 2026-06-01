# autonomous-execution-human-runbooks — Feature Document

- **Issue:** #45
- **Issue URL:** https://github.com/drmoisan/TMW/issues/45
- **Owner:** drmoisan
- **Work Mode:** full-feature
- **Last Updated:** 2026-06-01
- **Status:** Draft

This document consolidates the spec and user-story for issue #45. The authoritative acceptance-criteria source files for this full-feature work mode are `spec.md` and `user-story.md`.

## 1. Problem / Why

The orchestrator workflow must achieve all actions agentically with no human interaction; full autonomy is a hard requirement. The iFile feature (#43 / PR #44) reached the PR gate parked on manual device/tenant steps (Azure AD scope consent, on-device Outlook verification, production-domain configuration) that were never declared up front. That outcome is a workflow defect: an unautomatable dependency surfaced as a silent manual blocker at the end of the workflow rather than being detected early and resolved through an explicit, enforced mechanism.

## 2. The Mechanism

### 2.1 Autonomous-execution mandate

Full agentic execution is mandatory. A silent manual blocker discovered at the end of a workflow is a defect. The mandate is documented authoritatively in the orchestrate skill contract.

### 2.2 Detection points

- Unautomatable requirements are enumerated as mandatory unachievable requirements before kickoff where knowable.
- Where research is required to discover them, they MUST be surfaced no later than the research stage.
- Research touching third-party UIs MUST include an explicit automation-feasibility / human-interaction assessment recorded under an `## Automation Feasibility` section.

### 2.3 Three permitted responses

Per requirement, exactly one is chosen and recorded in orchestrator state:

1. **`scope_change`** — remove the manual dependency (for example, replace a portal click with an unattended `az` CLI step).
2. **`exception`** — permit an exception; requires a human-exception runbook.
3. **`halt`** — halt until further instruction; blocks DONE.

### 2.4 Human-exception runbook

On a permitted exception, the orchestrator emits `<FEATURE>/runbooks/<name>.runbook.md` (path stored relative to repo root) with these sections: Cue, Prerequisites, Step-by-step Instructions, Verification, and Source and Citation. Third-party UI steps are sourced MCP-first / web-second, never from training data, with source URL and capture date recorded. The contract is defined in the new `.claude/skills/human-exception-runbook/SKILL.md`. The runbook path is under the feature folder but is not an `evidence/` sub-path, so it is not governed by `enforce-evidence-locations.ps1`.

### 2.5 State and enforcement

- **Schema** (`orchestrator-state.schema.json`): top-level `human_interaction.requirements[]`, each with required `id`, `description`, `discovered_at_stage`, `response` (enum `scope_change` | `exception` | `halt`), and conditionally-required `runbook_path`. Invariant: `response == "exception"` requires a non-empty `runbook_path`. Top-level `additionalProperties: true` is preserved.
- **Completion gate** (`validate-orchestrator-output.ps1`): a new `Test-HumanInteractionShape` (pattern-matching the existing `Test-RemediationLoopShape`, with an injectable `FileExistsCheck` seam) blocks DONE when any requirement is unresolved, when any `halt` response is present, or when an `exception` lacks an existing `runbook_path` file. Absent `human_interaction` passes.
- **Research hook** (`validate-task-researcher-output.ps1`): a new `Test-AutomationFeasibilitySection` (with an injectable `ReadFileContent` seam) requires the `## Automation Feasibility` section for applicable research artifacts.
- **Contract** (orchestrate SKILL): documents the mandate, detection points, three responses, runbook requirement, and enforcement points.

## 3. Example Runbook (in #45) and iFile Application (on PR #44)

#45 ships a self-contained example/reference runbook with the skill so the runbook format is CI-verifiable within this feature without depending on the iFile feature folder:

- `.claude/skills/human-exception-runbook/example.runbook.md` — conforms to the contract (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation) with dated citations. Verified by AC-12.

**Delivered on PR #44 (out of scope for #45's branch).** The iFile (#43) feature folder exists only on the separate iFile branch / PR #44, not on #45's branch. #45 cannot author artifacts in a folder that does not exist on its branch, and #45 must not depend on them. The following are produced on PR #44 using #45's skill contract:

- `entra-admin-consent.runbook.md` — Global-Admin admin-consent. Only a Global Administrator can grant consent; without a scripted Global-Admin credential in CI, this is human-gated (resolved decision OD-45-1).
- `outlook-on-device-verification.runbook.md` — iOS on-device rendering. No programmatic rendering-assertion API exists; verification requires a physical device and a signed-in user.
- iFile's `human_interaction` exception declaration for the two items above.

The automatable iFile items are classified on PR #44 as scope-change/automatable and are NOT runbook steps:

- Graph delegated-permission declarations via `az ad app permission add`.
- Production manifest-domain substitution (build-time text substitution).

## 4. Resolved Decisions (do not re-open)

- **OD-45-1.** Do NOT place Global-Administrator credentials in CI; admin consent remains a permitted exception with a runbook. The iFile runbook applying this is delivered on PR #44.
- **OD-45-2.** Do NOT expand `modified-workflow-needs-green-run` to `.claude/hooks/**` in this feature; record as a recommended follow-up. #45 changes hooks/schema/skills/docs only, not `.github/workflows/**`.
- **OD-45-3.** A `halt` is clearable via a checkpoint update: it blocks DONE while present, but when the underlying requirement is later resolved (checkpoint updated to a `scope_change` or runbook-backed `exception`, or the `halt` otherwise cleared), the completion gate no longer blocks on it. `halt` is recoverable, not terminal.
- **OD-45-4.** No `settings.json` change is needed; the dedicated hook files are already wired via existing `.claude/settings.json` SubagentStop entries.
- **OD-45-5.** Third-party UI steps MUST be sourced MCP-first / web-second, never from training data. Non-UI CLI steps (for example `az` commands) still require a cited current source; the MCP-first/web-second ordering is mandatory only for third-party UI navigation, but every step type carries a current, dated citation.
- **OD-45-6.** Runbooks are stored per-feature under `<FEATURE>/runbooks/<name>.runbook.md`, with `runbook_path` recorded relative to the repo root; this path is not an `evidence/` sub-path and is not governed by `enforce-evidence-locations.ps1`.
- **OD-45-7.** Research-hook detection is narrow: `Test-AutomationFeasibilitySection` enforces the `## Automation Feasibility` section only when the filename/agent-output token match identifies an autonomous-execution research artifact; non-matching research is unaffected.
- All new/changed PowerShell hooks require Pester tests and must pass the PoshQC format → analyze → test toolchain; hooks stay dot-sourceable and deterministic.
- Schema changes preserve backward compatibility (`additionalProperties: true`).

## 5. Backward Compatibility

- Checkpoints without `human_interaction` validate and pass the completion gate.
- The research hook enforces the `## Automation Feasibility` section only for applicable artifacts.
- New functions are additive; no signatures are removed.

## 6. Personas

- **Workflow maintainer** — owns the orchestration workflow; wants tool-enforced autonomy and early detection of unautomatable work.
- **User who executes runbooks** — has the necessary tenant/device access; relies entirely on the runbook artifact and needs current, verifiable instructions.

Full persona narratives and scenarios are in `user-story.md`.

## 7. Acceptance Criteria (all CI-verifiable)

The authoritative list is in `spec.md` (AC-1 through AC-12). Every #45 AC is CI-verifiable; #45 is pure workflow infrastructure with no Outlook UI, so it has no manual criterion. Summary:

| AC | Summary | Verification |
|---|---|---|
| AC-1 | Orchestrate skill defines mandate, three responses, detection points, runbook requirement | CI-verifiable (presence/format) |
| AC-2 | Schema defines `human_interaction.requirements[]` with required fields and `response` enum | CI-verifiable (schema validation) |
| AC-3 | Schema rejects exception without non-empty `runbook_path`; accepts with it | CI-verifiable (schema validation) |
| AC-4 | Absent `human_interaction` validates (backward compatibility) | CI-verifiable (schema validation) |
| AC-5 | `Test-HumanInteractionShape` passes when `human_interaction` is null | CI-verifiable (Pester) |
| AC-6 | Gate blocks when a requirement is unresolved | CI-verifiable (Pester) |
| AC-7 | Gate blocks when any `halt` response is present | CI-verifiable (Pester) |
| AC-8 | Gate blocks on exception with missing/empty/non-existent runbook; passes when file exists | CI-verifiable (Pester) |
| AC-9 | Research hook requires `## Automation Feasibility` for applicable artifacts | CI-verifiable (Pester) |
| AC-10 | human-exception-runbook SKILL defines path, five sections, sourcing rule | CI-verifiable (presence/format) |
| AC-11 | New/changed hooks have Pester tests; PoshQC green | CI-verifiable (toolchain) |
| AC-12 | Example/reference runbook exists, conforms to contract (five sections + dated citations) | CI-verifiable (presence/format) |

**Delivered on PR #44 (out of scope for #45's branch).** The two iFile runbooks (`entra-admin-consent.runbook.md`, `outlook-on-device-verification.runbook.md`) and iFile's `human_interaction` exception declaration are produced on PR #44 using the skill contract defined here. The iFile feature folder exists only on the iFile branch / PR #44, not on #45's branch, so these artifacts cannot be authored within #45 and are not #45 acceptance criteria. The on-device iOS Outlook rendering verification (no programmatic rendering-assertion API; requires a physical device and a signed-in user) is therefore an iFile/PR #44 concern, not a #45 manual AC.

## 8. Non-Goals

- Authoring the iFile (#43) runbooks or iFile's `human_interaction` exception declaration (delivered on PR #44 against #45's skill contract).
- Any manual / human-verified acceptance criterion; every #45 AC is CI-verifiable.
- Scripted Global-Administrator credential in CI.
- Expanding `modified-workflow-needs-green-run` to `.claude/hooks/**` (follow-up).
- Modifying `.github/workflows/**`.
