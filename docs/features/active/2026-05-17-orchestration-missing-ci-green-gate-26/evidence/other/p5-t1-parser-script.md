# P5-T1 — Invoke-CiGateParser.ps1 created

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\scripts\orchestration\Invoke-CiGateParser.ps1 (112 lines)

Summary:
- Advanced function with CmdletBinding; parameters ChecksJson, HeadSha, RunId, RunUrl (all mandatory) plus an optional NowProvider clock seam for deterministic verified_at.
- Consumes `gh pr checks --required --json bucket,name,state,link,workflow` text; throws on malformed JSON and on empty checks list.
- Derives conclusion: failure if any check bucket is fail/cancel; pending if any check is pending/unknown; success when all pass/skipping.
- Emits the ci_gate object (head_sha, pr_pipeline_run_id, pr_pipeline_run_url, conclusion, verified_at) defined in P3-T2 / spec.md AC2.
- Invoked by S9 per .claude/skills/orchestrate/SKILL.md step 3 (AC9).

Maps to spec.md AC9.
