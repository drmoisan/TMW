---
description: Route a request through budget-based orchestration and persist until the selected delivery path is complete
argument-hint: Provide objective, likely files, feature-or-bug hint, constraints, and any explicit initial opt-in for manual bootstrap; otherwise orchestration must remain fully automated
---

Spawn `orchestrator` to coordinate the current request from intake through completion.

Inputs to provide or infer:
- request summary and expected outcome
- likely affected production and test files, when known
- initial classification hint: `feature` or `bug`, when known
- constraints, preserved APIs, or forbidden changes
- whether the initial user request explicitly opted into manual bootstrap from the beginning

Required behavior:
- estimate change budget first and choose the correct small or large path
- maintain and resume from the canonical orchestration checkpoint
- use migrated Codex subagents when available
- route host-specific lifecycle automation through the shared adapter rules
- continue until planning, execution, validation, and review are complete for the selected path
- do not introduce manual bootstrap, human-operator validation, or any other manual handoff unless the initial user request explicitly opted in from the beginning

On completion, report the selected route, branch, key variables, `plan-path` when applicable, checkpoint path, created or updated artifact paths, and final readiness summary.
