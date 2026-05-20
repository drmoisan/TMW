# P4-T1 — modified-workflow-needs-green-run policy rule added

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\skills\feature-review-workflow\SKILL.md
Section: "## Policy Rules" > "### modified-workflow-needs-green-run" (lines 66-76)

Added rule:
- Trigger paths: .github/workflows/**, scripts/benchmarks/**, .github/actions/** (all three globs present).
- Emits a Blocking finding unless green workflow-run evidence against the branch head is present in the remediation inputs.
- Cross-references the supporting validator scripts/feature-review/Test-ModifiedWorkflowNeedsGreenRun.ps1 and the orchestrator S9 gate.

Maps to spec.md AC6.
