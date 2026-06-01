# Phase 0 — Policy Instructions Read

Timestamp: 2026-06-01T14-04

Policy Order:
1. CLAUDE.md (standing instructions, always loaded)
2. .claude/rules/general-code-change.md (cross-language code change policy)
3. .claude/rules/general-unit-test.md (cross-language unit test policy)
4. .claude/rules/ci-workflows.md (CI workflow authoring; pwsh exit-code rule)
5. .claude/rules/quality-tiers.md (T1-T4 module rigor tiers)

Files Read (explicit list):
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\CLAUDE.md (project instructions auto-loaded into context)
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\general-code-change.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\general-unit-test.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\ci-workflows.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\quality-tiers.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\benchmark-baselines.md (additional CI-adjacent policy, loaded)
- C:\Users\DanMoisan\repos\TMW-wt-2026-06-01-09-51\.claude\rules\tonality.md (loaded)

Output Summary: All five required policy files were read in the prescribed order.
The most relevant policy to this change is ci-workflows.md (deliberately-failing
nested command pwsh exit-code rule); it does not apply here because this change is
a needs:-graph-only edit that adds no inline pwsh step. No production code is
modified, so the seven-stage toolchain loop and coverage thresholds in
general-code-change.md / general-unit-test.md / quality-tiers.md are not triggered;
the applicable checks are actionlint/YAML validity and the unchanged Pester
regression anchor.
