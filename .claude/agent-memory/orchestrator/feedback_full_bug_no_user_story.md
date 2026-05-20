---
name: full-bug-no-user-story
description: For full-bug work mode, do not produce or include user-story.md; spec.md and feature-document.md still apply.
metadata:
  type: feedback
---

For the `full-bug` work mode, the prd-feature deliverable set must NOT include `user-story.md`. Produce `feature-document.md` and `spec.md` only.

**Why:** User correction during issue #26 orchestration. After switching the work mode from minor-audit to full-bug, the user stated "User story should not be included for a full bug." A bug fix is framed by the defect and its acceptance criteria, not a user story.

**How to apply:** When delegating to `prd-feature` for a `full-bug` feature, request only `feature-document.md` and `spec.md`. If a `user-story.md` already exists in a folder being reconciled to full-bug, delete it. The general rule [[Run prd-feature before atomic-planner]] still applies for spec.md, but the user-story requirement in that memory is specific to feature/refactor modes, not full-bug.
