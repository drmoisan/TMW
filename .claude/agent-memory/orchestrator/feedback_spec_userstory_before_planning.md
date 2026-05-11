---
name: Run prd-feature before atomic-planner
description: Always produce spec.md and user-story.md via the prd-feature subagent before delegating to atomic-planner; never skip to plan.md from issue.md alone.
type: feedback
---

For every feature folder, the orchestrator must delegate to the `prd-feature` subagent to produce `feature-document.md`, `spec.md`, and `user-story.md` (matching the structure visible in `docs/features/active/2026-05-10-establish-dotnet-foundation-7/`) before delegating to `atomic-planner`. The plan depends on a written spec and an articulated user story; skipping ahead produces plans that drift from intent.

**Why:** User correction during Prompt C2 orchestration. The orchestrator delegated to `atomic-planner` directly after research, with no spec or user-story produced. User flagged this as a workflow violation. Reference folders (`2026-05-10-establish-dotnet-foundation-7/`) consistently contain `spec.md` and `user-story.md` as separate artifacts authored before `plan.md`.

**How to apply:** After S2 research completes and any user-facing decisions are locked, the next delegation is always `prd-feature`, not `atomic-planner`. `atomic-planner` runs only after spec.md and user-story.md exist on disk in the active feature folder.
