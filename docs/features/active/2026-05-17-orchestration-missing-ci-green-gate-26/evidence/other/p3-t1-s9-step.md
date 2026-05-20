# P3-T1 — S9_ci_green step added

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\skills\orchestrate\SKILL.md
Section: "## Step S9 — CI Green Gate" (lines 108-120)

Diff hunk (added):
- New "## Step S9 — CI Green Gate" section placed after the Remediation Loop section and before the PR Creation Gate.
- States S9_ci_green runs after S8_create_pr and before any DONE transition and applies to every feature.
- Step 2 requires `gh pr checks --required --json bucket,name,state,link,workflow` (or equivalent JSON-emitting command) against the live PR head SHA; gh is the only sanctioned channel.
- Step 3 routes JSON through scripts/orchestration/Invoke-CiGateParser.ps1 to emit ci_gate and derive conclusion.
- Step 5 sets step9_status to passed only when conclusion == success AND ci_gate.head_sha == current head SHA.

Maps to spec.md AC1.
