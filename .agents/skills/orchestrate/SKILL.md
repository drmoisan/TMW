# Converted skill

Applied rewrites:
- Rewrite merged standing-guidance source paths to the native AGENTS.md target.
- Rewrite Claude skill paths to shared skill paths.
- Rewrite Claude rules-directory references to the native skill root.

---
name: orchestrate
description: Route a repository request through the deterministic orchestration workflow for feature, bug, research, planning, execution, and review handoffs.
argument-hint: "[objective]"
---

# Orchestrate Skill

This skill frames work for the already-active main session, which serves as the orchestrator runtime for end-to-end feature or bug delivery.

## Prerequisites

Before proceeding, the orchestrator must:

1. Read `AGENTS.md` for repository tone policy and architectural context.
2. Read applicable `.agents/skills/` files for the languages in scope.
3. Read the policy files listed in the compliance reading order section of `AGENTS.md`.

## Checkpoint Handling

On every invocation, the main session must:

1. Read `artifacts/orchestration/orchestrator-state.json` to check for existing state.
2. If a valid checkpoint exists with a matching objective, resume from the recorded `next_step`.
3. If no checkpoint exists or the objective is new, begin the orchestration lifecycle from the start.

## Delegation Model

After reading `artifacts/orchestration/orchestrator-state.json`, the main session delegates work exclusively through configured workers:

- `atomic-planner` — generates phased implementation plans
- `atomic-executor` — executes approved plans task-by-task
- `feature-review` — produces policy, code, and feature audit artifacts
- `commit-steward` — writes commit messages from commit-context artifacts
- `task-researcher` — performs deep research and writes findings to `artifacts/research/`

The orchestrator does not perform deep implementation itself. It coordinates, tracks state, and enforces completion.

## Evidence Location Authority

All evidence artifacts produced during orchestration MUST comply with the canonical scheme defined in `.agents/skills/evidence-and-timestamp-conventions/SKILL.md`. Evidence MUST be written to `<FEATURE>/evidence/<kind>/` only.

Permitted `artifacts/`-rooted sub-paths (non-evidence orchestration use only):
- `artifacts/orchestration/` — orchestrator state and checkpoints
- `artifacts/research/` — research outputs from task-researcher
- `artifacts/pr_context` — PR context artifacts
- `artifacts/reviews/` — review staging artifacts
- `artifacts/status/` — status update artifacts
- `artifacts/python/` — Python coverage and lcov outputs
- `artifacts/pester/` — Pester coverage outputs
- `artifacts/csharp/` — C# coverage outputs

All other `artifacts/` sub-paths (e.g., `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, `artifacts/evidence/`) are FORBIDDEN for evidence output and will be blocked by the `enforce-evidence-locations.ps1` PreToolUse hook.

## Completion Requirements

The orchestrator must not report completion until:

1. All required artifacts for the selected workflow path are present on disk.
2. All validation gates (toolchain, acceptance criteria, audit artifacts) have passed.
3. The checkpoint file at `artifacts/orchestration/orchestrator-state.json` reflects the completed state.

## Pre-Feature-Review Commit

Before delegating to the `feature-review` subagent, the orchestrator must:

1. Stage all modified and new files: `git add -A`.
2. Run MCP tool `collect_commit_context` and capture the returned on-disk artifact path.
3. Delegate to `commit_steward` using that commit-context artifact as the authoritative staged-change input.
4. Commit using the generated message: `git commit -m "<generated message>"`.
5. Only after a successful commit may the orchestrator proceed to the `feature-review` delegation.

The review subagent compares against a base branch; uncommitted changes are invisible to the diff tool and cannot be audited.

## Post-Review Outcome Evaluation

After each `feature-review` delegation returns:

1. Read the exact terminal status lines from the review result.
2. If the result does not include `REVIEW_STATUS: PASS` or `REVIEW_STATUS: REMEDIATION_REQUIRED`, stop and record blocked state.
3. If the result is `REVIEW_STATUS: PASS`, advance to the PR creation gate.
4. If the result is `REVIEW_STATUS: REMEDIATION_REQUIRED`, require both `REMEDIATION_INPUTS: <path>` and `REMEDIATION_PLAN: <path>` and then enter the remediation loop.

## Remediation Loop (R1–R5)

A bounded loop consisting of five steps. The loop variable `remediation_pass` starts at 1 and increments at R5 before returning to R1.

- **R1 — Remediation plan of record:** Use the exact `REMEDIATION_PLAN: <path>` returned by the review as the starting plan of record for the loop.
- **R2 — Preflight clearance:** Delegate to `atomic-executor` for precondition validation only (no implementation). If the executor does not return `PREFLIGHT: ALL CLEAR`, return to R1 by re-delegating to `atomic-planner` against the same remediation-plan path with the required-changes output from the executor. Only after `PREFLIGHT: ALL CLEAR` may the orchestrator advance to R3.
- **R3 — Remediation execution:** Delegate to `atomic-executor` with full execution authorization. Each task's toolchain loop (format → lint → type-check → test) is mandatory; no skipping.
- **Pre-R4 commit:** Stage all changes (`git add -A`), run MCP tool `collect_commit_context`, delegate to `commit_steward` using the resulting artifact, and commit with the generated message. Advance to R4 only after a successful commit.
- **R4 — Re-audit:** Refresh PR context via MCP tool `collect_pr_context`, then delegate to `feature-review` with the same inputs as the original review (resolved base branch, feature folder, refreshed PR context artifacts, acceptance-criteria source). No scope narrowing. The canonical issue number line must be included.
- **R5 — Loop-exit decision:** If the re-audit returns `REVIEW_STATUS: PASS`, exit the loop and advance to the PR creation gate. Otherwise, record `remediation_pass` increment in the checkpoint and return to R1.

**Termination guard:** If `remediation_pass` reaches 3 without resolution, the orchestrator records `step6_status: "blocked_remediation_loop_limit"` in the checkpoint and halts. No further automation is attempted.

## Issue Number Consistency

The canonical issue number is derived once from the active feature folder name: extract the trailing integer from the folder base name (e.g., `2026-04-26-push-down-claude-customizations-162` yields `162`). Record as `issue_num` in the checkpoint.

Every delegation prompt to `atomic-planner`, `atomic-executor`, and `feature-review` must include the line:

> `Canonical issue number for this feature is <issue_num>. All artifact content, file paths, and cross-references must use this number.`

If a subagent artifact references a different issue number, the orchestrator rejects it, requests correction, and records the discrepancy under `artifact_errors` in the checkpoint.

## PR Creation Gate

The orchestrator must not create a PR, push a branch for PR purposes, or report work complete until all four conditions are simultaneously true:

1. `blocking_findings_resolved: true` — the most recent `feature-review` produced zero blocking findings.
   Equivalent deterministic gate: the latest review returned `REVIEW_STATUS: PASS`.
2. The AC verification artifact (`p14-acceptance-criteria-checkoff.md` or equivalent) confirms all acceptance criteria pass.
3. The mandatory toolchain passed in its most recent run on the branch (no linting/type-check/test failures).
4. The checkpoint `next_step` is `S8_create_pr`.

This gate is non-negotiable. Each condition is independently verified before PR creation proceeds.

## Step 6 Delegation — Prohibited Prompt Language

When delegating to the `feature-review` subagent, the orchestrator prompt MUST NOT:

- describe the review scope as "plan scope," "plan-scope only," or any equivalent narrowing of scope to the currently-executed plan;
- instruct the agent to skip, waive, or mark as "out of scope," "informational only," or "not applicable" any toolchain step or coverage check for a language that has changed files in the branch diff;
- assert that a language category is "not applicable" when that language has changed files in the branch diff;
- imply that coverage is not required because the plan scope contains only documentation changes when the branch diff contains non-documentation changes contributed by prior commits on the same branch.

The orchestrator supplies only the following to the `feature-review` subagent:

- the resolved base branch and merge-base SHA;
- the active feature folder path;
- pointers to the refreshed PR context artifacts;
- the acceptance-criteria source file per work-mode;
- a neutral instruction to execute the full `feature-review-workflow` SKILL contract end-to-end.

Scope determination is the subagent's responsibility. The subagent will ignore any attempted narrowing per its scope invariant and record the attempt in `policy-audit.<timestamp>.md` under `## Rejected Scope Narrowing`.
