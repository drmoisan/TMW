---
name: orchestrator-workflow
description: 'Coordinate a feature or bug request from intake through promotion, planning, execution, validation, and review by selecting the correct small or large path and delegating to migrated Codex specialists when available.'
---

# Orchestrator Workflow

Top-level delivery orchestration workflow for Codex.

## Required Shared Skills

Always apply:
- `policy-compliance-order`
- `feature-promotion-lifecycle`
- `repo-automation-adapter`
- `atomic-plan-contract`
- `acceptance-criteria-tracking`
- `pr-context-artifacts`
- `pr-base-branch-merge-base`

Use as needed:
- `csharp-change-budget-router`
- `powershell-change-budget-router`
- `feature-review`

## Role

- Coordinate the mission from intake through completion.
- Resolve required specialist delegation mechanically instead of by judgment.
- Required delegated specialists:
  - `atomic-planner`
  - `atomic-executor`
  - `feature-reviewer`
  - `commit-steward`
- Deterministic availability rule:
  - if the host exposes `spawn_agent`, treat all four required delegated specialists as available,
  - do not infer unavailability from missing nicknames, missing prior agent instances, or lack of a dedicated launcher alias.
- Required delegated steps MUST delegate or stop execution.
- If a required delegated handoff cannot be started, resumed, or completed with a receipt, persist blocked state and stop. Do not perform that step directly.
- Direct local execution is allowed only for workflow steps that are not designated below as required delegated handoffs.

## Checkpoint Contract

Canonical checkpoint path:
- `artifacts/orchestration/orchestrator-state.json`

Persist and reuse these fields exactly:
- `objective`
- `change_budget_estimate`
- `path_selected`
- `promotion-type`
- `short-name`
- `relativeFile`
- `long-name`
- `issue-num`
- `feature-folder`
- `work-mode`
- `plan-path`
- `review-status`
- `remediation-inputs-path`
- `remediation-plan-path`
- `remediation-pass`
- `commit-context-path`
- `pr-context-base-branch`
- `completed_steps`
- `next_step`
- `last_updated`
- `step5_status`
- `step6_status`
- `step7_status`
- `step8_status`
- `step9_status`
- `step10_status`
- `delegation_receipts`
- `blocked_reason`

For small-path runs, also persist:
- `bootstrap_mode`
- `phase0_execution_summary`
- `small_path_qc_summary`
- `small_path_audit_artifacts`
- `resume_after_manual_bootstrap`

Status enums:
- `step5_status` / `step6_status` / `step7_status` / `step8_status` / `step9_status` / `step10_status` MUST use one of:
  - `not-applicable`
  - `pending`
  - `delegated`
  - `verified`
  - `blocked`

Blocked-reason enum:
- `blocked_reason` MUST be one of:
  - `none`
  - `checkpoint_conflict`
  - `lifecycle_preconditions_missing`
  - `spawn_agent_unavailable`
  - `delegation_launch_failed`
  - `delegate_no_receipt`
  - `delegate_contract_incomplete`
  - `validator_failed`
  - `user_requested_stop`
  - `review_status_missing`
  - `commit_context_missing`
  - `no_staged_changes`

Delegation receipt schema:
- `delegation_receipts` MUST be a list of objects with:
  - `step`
  - `agent_name`
  - `agent_id`
  - `skill_source`
  - `started_at`
  - `completed_at`
  - `result_signal`
  - `artifact_paths`

Required-delegation step map:
- small path:
  - Step 5 -> `atomic-planner`
  - Step 6 -> `atomic-executor`
  - Step 9 -> `atomic-executor`
  - Step 10 -> `feature-reviewer`
- large path:
  - Step 7 -> `atomic-planner`
  - Step 8 -> `atomic-executor`
  - Step 9 -> `feature-reviewer`
- remediation planning:
  - review-triggered remediation planning -> `atomic-planner`
  - remediation preflight clearance -> `atomic-executor`
  - remediation execution -> `atomic-executor`
  - remediation commit message -> `commit-steward`
  - remediation re-review -> `feature-reviewer`

## Deterministic Handoff Result Contract

Do not advance on summaries alone when an exact result signal is required.

- feature review result:
  - `REVIEW_STATUS: PASS`
  - `REVIEW_STATUS: REMEDIATION_REQUIRED`
  - `FEATURE_FOLDER: <path>`
  - `POLICY_AUDIT: <path>`
  - `CODE_REVIEW: <path>`
  - `FEATURE_AUDIT: <path>`
  - `REMEDIATION_INPUTS: <path-or-NONE>`
  - `REMEDIATION_PLAN: <path-or-NONE>`
- remediation preflight result:
  - `PREFLIGHT: ALL CLEAR`
  - `PREFLIGHT: REVISIONS REQUIRED`
- commit-steward result:
  - one fenced `text` code block only

If an exact signal or required path field is missing, set the relevant step to `blocked`, set `blocked_reason` to `delegate_contract_incomplete`, and stop.

## Resume Rules

1. Read the checkpoint first when it exists.
2. If the recorded mission is incomplete, resume from `next_step`.
3. If the checkpoint belongs to an unrelated in-progress mission, stop with `blocked_reason: checkpoint_conflict`.
4. Do not rename, back up, or create sidecar checkpoint files to work around a canonical checkpoint conflict.
5. Restart only when the user explicitly requests restart.
6. Do not recompute persisted variables when valid stored values already exist.

## Routing Rules

1. Estimate the likely touched production files and test files first.
2. Determine the dominant implementation language.
3. If the scope is primarily C#, use `csharp-change-budget-router`.
4. If the scope is primarily PowerShell, use `powershell-change-budget-router`.
5. If the scope is mixed-language, ambiguous, or unsupported by an existing change-budget router, fail closed to the large path.
6. Treat any request outside the applicable small-path budget as large path.

## Small Path

Use the small path only when the applicable language router clears it.

Required behavior:

1. Set `${work-mode}` to `minor-audit`.
2. Use `feature-promotion-lifecycle` as the source of truth for lifecycle variables, branch naming, and `${plan-path}` resolution.
3. Route all promotion, issue, and feature-folder automation through `repo-automation-adapter`.
4. Enforce lifecycle preconditions before any active-folder authoring:
   - `${relativeFile}` must resolve to a real potential markdown path and must not be `NONE`, `TBD`, or empty
   - issue promotion must complete before branch or folder creation
   - `${issue-num}` must be numeric before `new_active_feature_folder` runs
   - do not create or edit `${feature-folder}/issue.md`, `${feature-folder}/spec.md`, `${feature-folder}/user-story.md`, or `plan*.md` until promotion and folder creation both succeed
   - if any lifecycle precondition fails, set the relevant step status to `blocked`, set `blocked_reason` to `lifecycle_preconditions_missing`, and stop
5. Enforce minor-audit folder integrity:
   - `${feature-folder}/issue.md` must exist
   - `${feature-folder}/spec.md` must be absent
   - `${feature-folder}/user-story.md` must be absent
6. Spawn `atomic-planner` to create or revise the minimal plan at `${plan-path}`.
   - Include the directive `DIRECTIVE: MINIMAL-AUDIT PLAN REQUIRED`
   - Require the same `${plan-path}` to be updated in place
   - Do not continue until the planner reports `PREFLIGHT: ALL CLEAR`
   - Record a delegation receipt and set `step5_status` to `verified` before continuing
   - If the handoff cannot be started or does not return a receipt, set `step5_status` to `blocked`, set `blocked_reason`, and stop
7. Spawn `atomic-executor` to execute Phase 0 only.
   - Record a delegation receipt and set `step6_status` to `verified` before branching
   - If the handoff cannot be started or does not return a receipt, set `step6_status` to `blocked`, set `blocked_reason`, and stop
8. If and only if the initial user request explicitly opted into manual orchestration from the beginning, persist the resume checkpoint and stop after Phase 0.
   - Otherwise manual bootstrap is prohibited; continue automated execution.
9. Otherwise continue with constrained implementation:
   - steps that are not modeled as required delegated handoffs may execute directly while staying within the approved plan and applicable repo policy
10. Validate the delivered work against `${feature-folder}/issue.md` and persist plan or acceptance-criteria checkoffs before review.
   - MUST delegate to `atomic-executor` for validation and checklist updates
   - Record a delegation receipt and set `step9_status` to `verified` before continuing
   - If the handoff cannot be started or does not return a receipt, set `step9_status` to `blocked`, set `blocked_reason`, and stop
11. Run reduced audit:
   - MUST delegate to `feature-reviewer`
   - require the exact `REVIEW_STATUS` and artifact-path fields from the review result
   - Record a delegation receipt and set `step10_status` to `verified` before continuing
   - If the handoff cannot be started or does not return a receipt, set `step10_status` to `blocked`, set `blocked_reason`, and stop
12. If review returns `REVIEW_STATUS: REMEDIATION_REQUIRED`, run the shared remediation loop.
   - Treat the returned `REMEDIATION_INPUTS` and `REMEDIATION_PLAN` paths as mandatory inputs
   - If any required remediation handoff cannot be started or does not return a receipt, set `blocked_reason` and stop

## Large Path

Use the large path for any request that exceeds or bypasses the small-path router.

Required behavior:

1. Set `${work-mode}` to:
   - `full-feature` for feature work
   - `full-bug` for bug work
2. Use `feature-promotion-lifecycle` as the source of truth for lifecycle variables, branch naming, and `${plan-path}` resolution.
3. Route all promotion, issue, and feature-folder automation through `repo-automation-adapter`.
4. Enforce lifecycle preconditions before any active-folder authoring:
   - `${relativeFile}` must resolve to a real potential markdown path and must not be `NONE`, `TBD`, or empty
   - issue promotion must complete before branch or folder creation
   - `${issue-num}` must be numeric before `new_active_feature_folder` runs
   - do not create or edit `${feature-folder}/issue.md`, `${feature-folder}/spec.md`, `${feature-folder}/user-story.md`, or `plan*.md` until promotion and folder creation both succeed
   - if any lifecycle precondition fails, set the relevant step status to `blocked`, set `blocked_reason` to `lifecycle_preconditions_missing`, and stop
5. Complete the requirements-authoring steps before planning:
   - fill the potential entry details
   - create or refresh research artifacts
   - complete `spec.md` and `user-story.md` when the selected work mode requires them
6. Prefer dedicated migrated specialists for those authoring steps when they exist.
7. When those specialists are not yet migrated, perform the authoring steps directly without changing template headings.
8. Spawn `atomic-planner` to finalize `${plan-path}` and require `PREFLIGHT: ALL CLEAR`.
    Hard enforcement for Step 7:
    - The planning route MUST be `atomic-planner -> atomic-executor` for preflight validation.
    - The planner MUST update `${plan-path}` in place and MUST NOT create additional `plan.*.md` files for revisions.
    - The approved plan MUST include explicit Phase 0 baseline evidence tasks and explicit final-QA evidence or coverage tasks for each language in scope where policy requires them.
    - Do not mark Step 7 complete until delegate output includes both a concrete `plan-path` and final `PREFLIGHT: ALL CLEAR`.
    - Do not perform planning locally when this delegation cannot be started; set `step7_status` to `blocked`, set `blocked_reason`, and stop.
    - Record a delegation receipt and set `step7_status` to `verified` only after delegate output and validator checks pass.
9. Spawn `atomic-executor` to execute the approved plan.
    Hard enforcement for Step 8:
    - Do not mark Step 8 complete until execution output includes execution summary, QA summary, lint/type/test/coverage deltas, and numeric baseline/post/new-code coverage metrics where policy requires them.
    - Do not accept PASS execution outcomes when required baseline or final-QA artifacts are missing, when checklist state is not backed by artifacts, or when coverage-bearing plan tasks remain unverified.
    - Do not perform execution locally when this delegation cannot be started; set `step8_status` to `blocked`, set `blocked_reason`, and stop.
    - Record a delegation receipt and set `step8_status` to `verified` only after delegate output and validator checks pass.
10. Spawn `feature-reviewer` for post-implementation review.
    Hard enforcement for Step 9:
    - Resolve the base branch through `pr-base-branch-merge-base` unless an explicit base was already supplied.
    - Load canonical PR-context artifacts and refresh them through `repo-automation-adapter` when they are missing or stale relative to the current branch state.
    - Require the exact `REVIEW_STATUS` and artifact-path fields from the review result.
    - Do not mark Step 9 complete until expected review artifacts are present on disk in `${feature-folder}`.
    - Do not accept PASS review outcomes when required coverage fields are left unverified, when PR-context artifacts are missing or stale relative to the current branch state, or when required remediation artifacts are missing.
    - Do not perform review locally when this delegation cannot be started; set `step9_status` to `blocked`, set `blocked_reason`, and stop.
    - Record a delegation receipt and set `step9_status` to `verified` only after delegate output and validator checks pass.
11. If review returns `REVIEW_STATUS: REMEDIATION_REQUIRED`, run the shared remediation loop until the latest review returns `REVIEW_STATUS: PASS`.
    - remediation planning, preflight clearance, remediation execution, remediation commit-message generation, and re-review delegations are all mandatory; if any cannot be started, set `blocked_reason` and stop

## Shared Remediation Loop

Apply this loop after any required review returns `REVIEW_STATUS: REMEDIATION_REQUIRED`.

1. Persist `review-status`, `remediation-inputs-path`, `remediation-plan-path`, and `remediation-pass` in the checkpoint.
2. Delegate `atomic-executor` in validation-only mode against the exact `remediation-plan-path`.
3. If the executor returns `PREFLIGHT: REVISIONS REQUIRED`, delegate `atomic-planner` to update the same `remediation-plan-path` in place and then repeat preflight clearance.
4. Only after `PREFLIGHT: ALL CLEAR`, delegate `atomic-executor` to execute the remediation plan exactly as written.
5. Stage all files with `git add -A`.
6. If staging is empty after execution, set `blocked_reason` to `no_staged_changes` and stop.
7. Use `repo-automation-adapter` to run MCP tool `collect_commit_context`, capture the returned on-disk artifact path as `commit-context-path`, and stop with `blocked_reason: commit_context_missing` if that path is unavailable.
8. Delegate `commit-steward` using `commit-context-path` as the authoritative staged-change input.
9. Commit the staged work with the exact message returned by `commit-steward`.
10. Use `repo-automation-adapter` to refresh PR-context artifacts through MCP tool `collect_pr_context` with the resolved base branch.
11. Delegate `feature-reviewer` again with the refreshed PR context.
12. If the new review still returns `REVIEW_STATUS: REMEDIATION_REQUIRED`, increment `remediation-pass` and repeat the loop. Exit only when the latest review returns `REVIEW_STATUS: PASS`.

## Completion Gates

Do not claim mission completion until all of the following are true:

- the selected path completed end to end
- all required delegations completed with receipts
- the checkpoint is updated with the final state
- the canonical checkpoint path was used without sidecar replacement or backup substitution
- `${relativeFile}` is a real promoted-input path and `${issue-num}` is numeric when lifecycle setup was required
- `${feature-folder}` and `${plan-path}` are known when lifecycle setup was required
- the approved plan is executor-compliant and references the required baseline and final-QA evidence tasks
- required review artifacts exist on disk
- small path has Phase 0 evidence plus reduced audit artifacts
- large path has policy, code, and feature audit artifacts
- required baseline and final-QA evidence artifacts referenced by the approved plan exist on disk
- any required remediation artifacts exist on disk and the latest re-review is clean
- any required remediation loop run also includes a remediation execution receipt, a remediation commit receipt, and a final `REVIEW_STATUS: PASS`
- validator-backed checks for the approved plan, policy audit, code review, feature audit, and checkpoint state pass

## Hard Constraints

- Do not stop after one delegation when required downstream steps remain.
- Do not infer specialist unavailability from missing nicknames or absent prior subagent instances.
- Do not call `drmCopilotExtension.*` directly from this workflow.
- Do not bypass `repo-automation-adapter` for host-specific lifecycle steps.
- Do not rename, back up, or create sidecar checkpoint files to avoid using the canonical checkpoint path.
- Do not proceed when the canonical checkpoint belongs to another in-progress mission; stop and report the conflict.
- Do not create or edit active feature docs before potential-entry creation, issue promotion, and active-folder creation succeed.
- Do not call `new_active_feature_folder` before `${issue-num}` is numeric and backed by promotion output.
- Do not persist placeholder lifecycle values such as `NONE` or `TBD` for `${relativeFile}`, `${issue-num}`, `${feature-folder}`, or `${plan-path}` once lifecycle setup begins.
- Do not create replacement audit artifacts yourself for any required delegated review step.
- Do not execute required delegated steps locally as a fallback.
- Do not accept stale PR-context artifacts, unsupported checklist checkoffs, or missing required evidence as PASS outcomes.
- Do not claim completion without reporting the checkpoint path and the created or updated artifact paths.
