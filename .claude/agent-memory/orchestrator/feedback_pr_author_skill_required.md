---
name: feedback-pr-author-skill-required
description: Always use the pr-author skill with refreshed PR context artifacts to produce the canonical PR body before creating or editing a PR. Never manually compose the body.
metadata:
  type: feedback
---

Always apply the `pr-author` skill — reading `artifacts/pr_context.summary.txt` and `artifacts/pr_context.appendix.txt` — to produce the PR body before calling `gh pr create` or `gh pr edit`.

**Why:** Manually composed PR bodies omit required sections (Why, Architecture, Verification table, Risks, Review Guide, Follow-ups, auto-close line) and do not follow the canonical structure the user expects. The pr-author skill produces all 11 required sections from verified context only.

**How to apply:**
1. After the pre-review commit, run `mcp__drm-copilot__collect_pr_context` to refresh artifacts.
2. Delegate to an agent (or apply the skill directly) to produce the body from `artifacts/pr_context.summary.txt` + `artifacts/pr_context.appendix.txt`.
3. Write the body to a temp file (e.g., `artifacts/pr_body_<issue>.md`) and pass it to `gh pr create --body-file` or `gh pr edit --body-file`.
4. Never call `gh pr create` with an inline `--body` string composed from memory.
