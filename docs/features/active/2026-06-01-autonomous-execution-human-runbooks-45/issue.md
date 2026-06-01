# autonomous-execution-human-runbooks (Issue #45)

- Date captured: 2026-06-01
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/autonomous-execution-human-runbooks/ (Issue #45)
- Promotion type: feature
- Work mode: full-feature
- Scope: agentic-workflow infrastructure (`.claude/skills/orchestrate`, `.claude/schemas`, `.claude/hooks`, research-stage contract)

- Issue: #45
- Issue URL: https://github.com/drmoisan/TMW/issues/45
- Last Updated: 2026-06-01
- Work Mode: full-feature

## Problem / Why

The orchestrator workflow must achieve all actions agentically with no human interaction; full autonomy is a hard requirement. The iFile feature (#43 / PR #44) reached the PR gate parked on manual device/tenant steps (Azure AD scope consent, on-device Outlook verification, production-domain config) that were never declared up front. This is a workflow defect: unautomatable dependencies must be detected early and handled by an explicit, enforced mechanism rather than surfacing as a silent manual blocker at the end.

## Proposed Behavior

Introduce and enforce an "autonomous-execution mandate" with explicit handling of unautomatable requirements:

1. **Early detection.** Unautomatable requirements are enumerated as *mandatory unachievable requirements* before kickoff where knowable. Where research is required to discover them, they MUST be surfaced no later than the research stage. Research that touches third-party UIs (Azure portal, Outlook desktop/mobile, M365 admin) must include an explicit automation-feasibility / human-interaction assessment.
2. **Three permitted responses.** When a step cannot be performed without a human, the orchestrator must choose exactly one: **(1) change the scope** to remove the manual dependency, **(2) permit an exception**, or **(3) halt until further instruction**.
3. **Exception runbook.** If an exception is permitted, the orchestrator produces a separate **human-readable runbook** for the user containing:
   - a `cue` — when to perform the actions (the trigger/condition);
   - step-by-step human-readable instructions, including detailed third-party UI navigation where applicable;
   - a verification section — how the user confirms they performed the steps correctly.
4. **Sourcing rule.** Third-party UI instructions must never rely on training data. Use MCP servers first and web search second to obtain the current UI.
5. **Enforcement.** The mechanism is wired into the orchestrate skill contract, the orchestrator-state schema (declared exceptions + runbook references), the research-stage contract/hook, and the orchestrator completion gate so DONE cannot be written while an undeclared manual dependency exists, and a permitted exception requires its runbook artifact to exist.

## Acceptance Criteria (early draft)

- [ ] The orchestrate skill defines the autonomous-execution mandate, the three responses, the detection points (pre-kickoff and research-stage-at-latest), and the exception-runbook requirement.
- [ ] The orchestrator-state schema models declared unachievable requirements and permitted exceptions, each referencing a runbook artifact path; malformed exceptions (permitted without a runbook) are rejected.
- [ ] A human-exception-runbook artifact format is defined (cue, step-by-step instructions, verification) with the MCP-first / web-second sourcing rule, and a canonical location under the active feature folder.
- [ ] The research-stage contract requires an explicit automation-feasibility / human-interaction assessment; the task-researcher hook enforces its presence when applicable.
- [ ] The orchestrator completion gate (hook) blocks DONE while a manual dependency is undeclared or a permitted exception lacks an existing runbook artifact.
- [ ] All new/changed PowerShell hooks have Pester tests and pass the format -> analyze -> test toolchain.
- [ ] The mechanism is applied retroactively to iFile (#43): a human-exception runbook is produced for the AAD scope consent, on-device verification, and production-domain configuration, with current UI steps sourced via MCP/web (not training data).

## Constraints & Risks

- PowerShell hook changes require Pester tests and the PoshQC toolchain; hooks must remain dot-sourceable and deterministic per `.claude/rules/powershell.md`.
- Schema changes must preserve backward compatibility (`additionalProperties: true`).
- Workflow-file or hook changes may trigger `modified-workflow-needs-green-run` and the green-run rule; sequence accordingly.
- Third-party UI documentation drifts; the runbook must cite source and capture-date and prefer MCP/web over training data.

## Test Conditions to Consider

- [ ] Hook unit tests: DONE blocked when an undeclared manual dependency exists; allowed when exceptions are absent; blocked when a permitted exception references a missing runbook; allowed when the runbook exists.
- [ ] Schema validation: malformed exception (permitted, no runbook path) rejected; well-formed accepted.
- [ ] Research hook: feasibility-assessment presence enforcement.
- [ ] Retroactive iFile runbook is well-formed (cue, steps, verification) and validates.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create active feature folder from the template