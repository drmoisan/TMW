---
name: autonomous-execution-no-manual-steps
description: Orchestrator workflows must be fully autonomous; unautomatable steps require an early-declared exception with a human-readable runbook, scope change, or halt.
metadata:
  type: feedback
---

The orchestrator workflow must achieve all actions agentically with no human interaction. Manual steps are not an acceptable silent outcome.

**Why:** Autonomous, hands-off execution is a hard requirement of the agentic workflow. The iFile feature (#43/PR #44, 2026-06-01) reached the PR gate parked on manual device/tenant steps that were never declared up front — the user flagged this as a workflow defect, not an acceptable result.

**How to apply:**
- Detect unautomatable requirements as early as possible. Ideally enumerate them as **mandatory unachievable requirements** before kickoff; at the latest they must be surfaced at the **research stage**. Research that touches third-party UIs (Azure portal, Outlook desktop/mobile, M365 admin) must explicitly assess what can and cannot be automated.
- When a step cannot be done without a human, choose exactly one of three responses: **(1) change the scope** to remove the manual dependency, **(2) permit an exception**, or **(3) halt until further instruction**.
- If an exception is permitted (#2), produce a separate **human-readable runbook** for the user containing: a `cue` (when to perform the actions), step-by-step human-readable instructions (often detailed third-party UI navigation), and a verification section (how the user confirms they did it correctly).
- Never rely on training data for third-party UI instructions. Use **MCP servers first, web search second** to get the current UI. (See [[refresh-product-ui-instructions]].)
- The mechanism is enforced in `.claude/skills/orchestrate`, the orchestrator state schema, and hooks (`.claude/hooks/`). DONE must not be written while an undeclared manual dependency exists; a permitted exception requires the runbook artifact to exist.
