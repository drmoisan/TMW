# Phase 0 — Policy / Instructions Read Evidence

- Timestamp: 2026-05-19T22-42
- Task: [P0-T1]
- Issue: #35

## Policy Order

Files read in the required order:

1. `CLAUDE.md` (standing instructions; loaded into session context)
2. `.claude/rules/general-code-change.md` (cross-language code change policy)
3. `.claude/rules/general-unit-test.md` (cross-language unit test policy)
4. `.claude/rules/quality-tiers.md` (T1–T4 module rigor tiers + uniform coverage gates)
5. `.claude/rules/typescript.md` (TypeScript toolchain + coding standards)
6. `.claude/rules/typescript-suppressions.md` (pre-authorized suppression patterns)
7. `.claude/rules/architecture-boundaries.md` (No-COM architecture boundary rules)
8. `.claude/rules/tonality.md` (required professional tone)

## Files Read (explicit list)

- C:\Users\DanMoisan\repos\TMW\CLAUDE.md (via loaded project instructions)
- C:\Users\DanMoisan\repos\TMW\.claude\rules\general-code-change.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\general-unit-test.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\quality-tiers.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\typescript.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\typescript-suppressions.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\architecture-boundaries.md
- C:\Users\DanMoisan\repos\TMW\.claude\rules\tonality.md

## Key Constraints Acknowledged

- Mandatory seven-stage toolchain loop (format → lint → type-check → architecture → unit → contract → integration); restart on any failure or auto-fix.
- File size limit: 500 lines for production/test/reusable script files.
- Coverage thresholds (uniform T1–T4): line >= 85%, branch >= 75%; no regression on changed lines.
- TypeScript: avoid `any`, ES modules only, fail-fast error handling, suppressions only per authorized patterns.
- Architecture: No-COM, Office.js-only mailbox access; `src/taskpane` and `src/commands` must not import backend internals.
- Evidence under `docs/features/active/2026-05-19-outlook-mobile-ios-parity-35/evidence/<kind>/` only.
- Professional tone for all authored content.
