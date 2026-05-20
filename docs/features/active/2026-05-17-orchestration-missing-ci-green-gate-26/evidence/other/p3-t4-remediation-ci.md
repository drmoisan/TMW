# P3-T4 — Remediation-loop CI-failure handling documented

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\skills\orchestrate\SKILL.md
Section: "## Remediation Loop — CI-Failure Handling" (lines 156-164)

Documented flow:
- On step9_status == failed_remediation_required (failed required check or exhausted poll timeout), the failed-check log from `gh run view <run-id> --log-failed` is written as remediation-inputs.<timestamp>.md in the active feature folder.
- The failure is converted to a synthetic finding with severity Blocking identifying the failing check by name and the failing job by URL.
- The existing R1-R5 loop processes that finding; no new loop is introduced.

Maps to spec.md AC4.
