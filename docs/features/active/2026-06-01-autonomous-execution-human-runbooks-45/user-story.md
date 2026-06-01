# `autonomous-execution-human-runbooks` — User Story

- Issue: #45
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-06-01

## Story Statement

- As a workflow maintainer, I want unautomatable requirements detected early and resolved by exactly one recorded response (scope change, exception, or halt), so that a workflow cannot silently park on a manual blocker at the PR gate.
- As a workflow maintainer, I want the completion gate to block DONE while any human-interaction requirement is unresolved, any halt is present, or a permitted exception lacks an existing runbook file, so that the autonomy mandate is enforced by tooling rather than reviewer vigilance.
- As a user who executes runbooks, I want a self-contained, current, and verifiable runbook for each permitted exception, so that I can complete the human-gated step correctly and confirm success without consulting the orchestrator.

## Problem / Why

The orchestrator workflow must achieve all actions agentically with no human interaction; full autonomy is a hard requirement. The iFile feature (#43 / PR #44) reached the PR gate parked on manual device/tenant steps (Azure AD scope consent, on-device Outlook verification, production-domain configuration) that were never declared up front. This is a workflow defect: unautomatable dependencies must be detected early and handled by an explicit, enforced mechanism rather than surfacing as a silent manual blocker at the end.

## Personas & Scenarios

### Persona: Workflow maintainer

- Who: an engineer responsible for the agentic orchestration workflow (orchestrate skill, hooks, schema).
- What they care about: full autonomy as a hard requirement; deterministic, tool-enforced gates; backward compatibility of the orchestrator-state schema.
- Constraints: PowerShell hooks must be dot-sourceable, deterministic, and Pester-tested; schema changes must preserve `additionalProperties: true`; this change must not touch `.github/workflows/**`.
- Goals and frustrations: wants unautomatable work surfaced at the research stage at the latest, not at the PR gate; frustrated when a manual blocker is discovered after a workflow reports near-completion.

#### Scenario: A research stage discovers a human-gated step

- Acting: the orchestrator running a feature that touches a third-party UI.
- Trigger: the research stage assesses automation feasibility for an Entra admin-center step.
- Steps: research records an `## Automation Feasibility` section (enforced by `validate-task-researcher-output.ps1`); the orchestrator records a `human_interaction` requirement; it selects `exception` and emits a runbook at `<FEATURE>/runbooks/<name>.runbook.md`.
- Obstacle/decision: the orchestrator must choose exactly one of `scope_change`, `exception`, or `halt`; for admin consent without a scripted Global-Admin credential, the resolved decision is `exception`.
- Outcome: the completion gate permits DONE only because the requirement is resolved and the runbook file exists; an unresolved requirement, a `halt`, or a missing runbook would block DONE.

### Persona: User who executes runbooks

- Who: a person with the necessary tenant/device access (for example, a Global Administrator, or a tester with a signed-in iOS Outlook client).
- What they care about: clear instructions that match the current third-party UI, and an unambiguous way to confirm they did it correctly.
- Constraints: no access to the orchestrator's internal state; relies entirely on the runbook artifact.
- Goals and frustrations: wants steps sourced from current documentation (MCP/web), not stale training data; frustrated by instructions that no longer match the live portal.

#### Scenario: Executing the Entra admin-consent runbook

- Acting: a Global Administrator.
- Trigger: the Cue section states when to act (for example, before first production deployment of the add-in).
- Steps: the user follows the Prerequisites, then the numbered Step-by-step Instructions for the Entra admin center, then the Verification section to confirm "Granted for <tenant>" appears.
- Obstacle/decision: only a Global Administrator can grant admin consent; the runbook states this in Prerequisites.
- Outcome: the user confirms success via the Verification section and the Source-and-Citation section lets them check the instructions against the current Microsoft Learn page and capture date.

## Acceptance Criteria

> Authoritative acceptance criteria are maintained in `spec.md` (AC-1 through AC-12). Every #45 acceptance criterion is CI-verifiable; #45 is pure workflow infrastructure with no Outlook UI, so it has no manual criterion. The criteria below are the user-facing restatements for the two personas and map onto the spec ACs.

- [x] The orchestrate skill defines the autonomous-execution mandate, the three responses, the detection points (pre-kickoff and research-stage-at-latest), and the exception-runbook requirement. (maps to spec AC-1)
- [x] The orchestrator-state schema models declared unachievable requirements and permitted exceptions, each referencing a runbook artifact path; malformed exceptions (permitted without a runbook) are rejected; absent `human_interaction` remains valid. (maps to spec AC-2, AC-3, AC-4)
- [x] A human-exception-runbook artifact format is defined (Cue, Prerequisites, Step-by-step Instructions, Verification, Source and Citation) with the MCP-first / web-second sourcing rule and a canonical location under the active feature folder. (maps to spec AC-10)
- [x] A self-contained example/reference runbook ships with the skill and conforms to the contract (all five required sections plus dated citations), keeping the runbook-format criterion CI-verifiable within #45. (maps to spec AC-12)
- [x] The research-stage contract requires an explicit automation-feasibility / human-interaction assessment; the task-researcher hook enforces its presence when applicable. (maps to spec AC-9)
- [x] The orchestrator completion gate blocks DONE while a requirement is unresolved, a halt is present, or a permitted exception lacks an existing runbook artifact. (maps to spec AC-5, AC-6, AC-7, AC-8)
- [x] All new/changed PowerShell hooks have Pester tests and pass the format → analyze → test toolchain. (maps to spec AC-11)

> **Delivered on PR #44 (out of scope for #45's branch).** The mechanism is applied to iFile (#43) on PR #44, not within #45: two runbooks for the genuinely human-gated items (admin consent, on-device iOS verification) and iFile's `human_interaction` exception declaration are produced there using #45's skill contract, with current UI steps sourced via MCP/web (not training data); the automatable items are classified as scope-change and are not runbook steps. The iFile feature folder exists only on the iFile branch / PR #44, so these artifacts cannot be authored within #45 and are not #45 acceptance criteria.

## Non-Goals

- Authoring the iFile (#43) runbooks or iFile's `human_interaction` exception declaration. The iFile feature folder exists only on the iFile branch / PR #44, not on #45's branch; these artifacts are delivered on PR #44 against #45's skill contract.
- Any manual / human-verified acceptance criterion. #45 is pure workflow infrastructure with no Outlook UI; every #45 AC is CI-verifiable. The on-device iOS Outlook rendering verification is an iFile concern on PR #44, not a #45 AC.
- Adding a scripted Global-Administrator credential to CI to automate admin consent.
- Expanding `modified-workflow-needs-green-run` to `.claude/hooks/**` (recommended follow-up).
- Modifying `.github/workflows/**` in this feature.
