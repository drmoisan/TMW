# Phase 0 — Instructions Read Evidence

Timestamp: 2026-06-04T20-29

Policy Order:
1. CLAUDE.md (standing instructions, always loaded)
2. .claude/rules/general-code-change.md (cross-language code change policy)
3. .claude/rules/general-unit-test.md (cross-language unit test policy)
4. Language/domain-specific rules for files in scope:
   - .claude/rules/typescript.md
   - .claude/rules/typescript-suppressions.md
   - .claude/rules/architecture-boundaries.md
   - .claude/rules/csharp.md
5. .claude/rules/quality-tiers.md
6. .claude/rules/tonality.md

Files Read (explicit list, in order):
- CLAUDE.md — NOT PRESENT on disk (verified by glob `**/CLAUDE.md` returning no files). Standing instructions are auto-loaded by Claude Code via path-scoped frontmatter in `.claude/rules/` rather than a root `CLAUDE.md` file, consistent with the `policy-compliance-order` skill. The standing-instruction content was loaded into session context.
- C:\Users\DanMoisan\repos\TMW\.claude\rules\general-code-change.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\general-unit-test.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\typescript.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\typescript-suppressions.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\architecture-boundaries.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\csharp.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\quality-tiers.md — READ
- C:\Users\DanMoisan\repos\TMW\.claude\rules\tonality.md — READ

Notes:
- Primary scope is TypeScript per the remediation plan and inputs; C# is verification-only (no code change) this cycle, so csharp.md is read for the backend-verification task (P6-T1).
- Coverage policy applies: line >= 85%, branch >= 75%, no regression on changed lines; no production file excluded from coverage.
- File-size cap 500 lines (manifests and Markdown exempt); TypeScript suppression policy enforced.
- MSAL import boundary: @azure/msal-browser may be imported only by the new host-bound naa-token-acquirer.ts module; not by pure modules or the Office-free bootstrap seam.
