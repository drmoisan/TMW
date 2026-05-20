# P2-T1 — .claude/rules/benchmark-baselines.md created

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\benchmark-baselines.md (35 lines, new file)

Content summary (maps to spec.md AC7):
- Requires runner-environment parity for performance baselines.
- Explicitly rejects baselines whose HostEnvironmentInfo.ProcessorName == "Unknown processor".
- Requires a sibling baseline.provenance.json recording runner_class, host_signature, and workflow_run_url.
- Names the enforcing validator (scripts/benchmarks/Test-BaselineProvenance.ps1) and cross-references the modified-workflow-needs-green-run policy rule.

git status: new file (mode 100644), 0000000..6df931f.
