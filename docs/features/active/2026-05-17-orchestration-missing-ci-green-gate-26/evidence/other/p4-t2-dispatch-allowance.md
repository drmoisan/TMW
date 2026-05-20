# P4-T2 — workflow_dispatch allowance documented

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\skills\feature-review-workflow\SKILL.md
Section: "### modified-workflow-needs-green-run" (line 74)

Documented:
- "A green workflow_dispatch run against the branch head also satisfies the rule, not only a PR-context run."
- Stated rationale: mitigates the chicken-and-egg case where a feature must land its CI gate before the gate can run in PR context, per spec.md Risks & Mitigations.

Maps to spec.md Risks & Mitigations (chicken-and-egg mitigation) supporting AC6.
