---
name: feedback_no_confirm_registered_decisions
description: Do not pause orchestration to confirm an action that is already registered as a decision in memory or prior checkpoint.
metadata:
  type: feedback
---

Do not stop orchestration to ask the user to confirm an action that is already a registered decision (memory entry, prior checkpoint, or skill contract). Just execute it.

**Why:** Stopping the orchestration unnecessarily is unacceptable to the user. Registered decisions in memory (e.g. [[feedback_pr_author_skill_required]] — "always apply the pr-author skill from refreshed PR context artifacts") are standing orders, not topics to re-prompt. Re-confirming wastes the user's time and signals that memory was not trusted.

**How to apply:** Before issuing a confirmation prompt, check whether the action is already covered by:
1. An entry in `.claude/agent-memory/orchestrator/MEMORY.md` or the underlying memory files.
2. A `decisions_confirmed_by_user` field in `artifacts/orchestration/orchestrator-state.json`.
3. A skill or rule contract under `.claude/skills/` or `.claude/rules/`.

If covered, execute. Only pause for confirmation when a decision is genuinely new (e.g. naming-pattern choice between two viable options the issue itself flags as needing a pick).
