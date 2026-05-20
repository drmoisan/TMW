# Phase 0 — Instructions Read (P0-T1)

Timestamp: 2026-05-19T10-15

Policy Order: CLAUDE.md -> .claude/rules/general-code-change.md -> .claude/rules/general-unit-test.md -> .claude/rules/quality-tiers.md -> .claude/rules/powershell.md -> .claude/rules/tonality.md

Files read (absolute paths):
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\CLAUDE.md (standing instructions, auto-loaded)
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\general-code-change.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\general-unit-test.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\quality-tiers.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\powershell.md
- C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\tonality.md

Output Summary: All six policy files read in the required compliance order. Key constraints noted for this changeset: PowerShell toolchain runs format -> analyze -> test via PoshQC MCP functions (no type-check stage); external executables (gh, git) must be wrapped in a function seam and the wrapper mocked in tests, never the executable directly; production/test/script files must remain under 500 lines; line coverage >= 85% and branch coverage >= 75% uniform across tiers; professional evidence-first tone with no hyperbole or humor.
