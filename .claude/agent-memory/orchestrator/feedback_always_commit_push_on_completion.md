---
name: always-commit-push-on-completion
description: This user wants completed work committed and pushed automatically, without being asked each time.
metadata:
  type: feedback
---

When a unit of work is complete (e.g. a remediation cycle exits clean, or a requested change passes its gates), commit and push the resulting changes without pausing to ask for permission.

**Why:** The user responded "Yes. Always" when asked whether to commit and push cycle-4 changes — establishing a standing preference for autonomous commit/push rather than per-change confirmation. This refines the repo-default "commit/push only when asked": for this user, the standing instruction *is* the ask.

**How to apply:** After work passes its quality gates and (in the remediation loop) the exit gate, commit with a clear conventional-commit message and push to the active feature branch / PR. Still branch first if on the default branch. Still never commit secrets; keep workflow-file changes inside the remediation loop. Surface what was committed afterward rather than gating on a prompt. If the working tree contains unrelated or unreviewed pre-existing changes, scope the commit deliberately and say what was included. Relates to [[ci-green-is-not-device-working]].
