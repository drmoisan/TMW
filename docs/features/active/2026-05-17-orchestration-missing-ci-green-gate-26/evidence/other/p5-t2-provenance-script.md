# P5-T2 — Test-BaselineProvenance.ps1 created

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\scripts\benchmarks\Test-BaselineProvenance.ps1 (114 lines)

Summary:
- Advanced function with two parameter sets: Path (reads baseline + sibling baseline.provenance.json from disk) and Content (pure-logic seam for unit tests; no temp files).
- Rejects HostEnvironmentInfo.ProcessorName == "Unknown processor".
- Rejects a baseline with no sibling baseline.provenance.json.
- When provenance content is supplied, also verifies required fields runner_class, host_signature, workflow_run_url.
- Returns [pscustomobject] { IsValid; Reasons }.
- Enforces .claude/rules/benchmark-baselines.md (spec.md AC11).

Maps to spec.md AC11.
