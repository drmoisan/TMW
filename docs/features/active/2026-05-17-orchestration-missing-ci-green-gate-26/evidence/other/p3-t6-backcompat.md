# P3-T6 — Backward compatibility documented

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\skills\orchestrate\SKILL.md
Section: "### Backward compatibility" (lines 152-154)

Documented:
- A checkpoint that predates this schema and has no ci_gate object (or no step9_status) is treated as step9_status: "pending".
- Missing CI-gate fields are never interpreted as passed; the gate fails closed.
- The orchestrator runs S9 to populate the fields before any DONE transition.

Maps to spec.md "Dependencies/Touchpoints" backward-compat requirement (treat missing ci_gate as pending).
