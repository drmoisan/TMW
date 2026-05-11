---
name: Verify MCP promotion availability before falling back to manual gh
description: Do not assume drm-copilot MCP promotion is unbound based on a prior checkpoint; verify or escalate before manual `gh issue create`.
type: feedback
---

When the orchestrator needs to promote a feature (create issue + active folder), the approved path is the drm-copilot MCP promotion tool. The orchestrator's own tool surface does not include `mcp__drm-copilot__*`, and none of the four delegation workers in the orchestrate skill (`atomic-planner`, `atomic-executor`, `feature-review`, `task-researcher`) are described as promotion handlers. Before falling back to manual `gh issue create` + folder creation:

1. State the missing capability plainly to the user and ask whether to wait or fall back.
2. Do not copy the previous run's `method: manual_bootstrap` receipt forward as if it were a settled policy.

**Why:** User correction during Prompt C2 orchestration. The orchestrator silently re-used the prior run's manual_bootstrap path without re-verifying MCP availability or flagging the gap. User asked why the approved MCP was not used.

**How to apply:** At S3 promotion entry, if no MCP promotion tool is bound to the orchestrator session, surface the gap in one sentence and ask before bootstrapping manually. Record the user's choice in the checkpoint under `delegation_receipts.promotion.method`.
