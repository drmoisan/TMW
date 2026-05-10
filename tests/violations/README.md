# Quality Gate Violation Demonstrations

This directory contains intentionally-broken `.ts.disabled` files used to prove that each of the five CI quality gates rejects the corresponding category of violation. The `.disabled` suffix prevents these files from being picked up by normal tooling.

To demonstrate detection, temporarily copy one file at a time to the matching active location, run the gate command, capture exit code + stderr, then remove the active copy to restore green state. Plan reference: `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/plan.md` (Phase 6). Evidence destination: `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/qa-gates/violation-<category>.<timestamp>.txt`.

## Activation / revert protocol (PowerShell)

### Format gate

```powershell
Copy-Item tests/violations/format-violation.ts.disabled src/format-violation.ts
npm run format:check    # expected: non-zero exit
Remove-Item src/format-violation.ts
npm run format:check    # expected: exit 0
```

### Lint gate

```powershell
Copy-Item tests/violations/lint-violation.ts.disabled src/lint-violation.ts
npm run lint            # expected: non-zero exit
Remove-Item src/lint-violation.ts
npm run lint            # expected: exit 0
```

### Typecheck gate

```powershell
Copy-Item tests/violations/typecheck-violation.ts.disabled src/typecheck-violation.ts
npm run typecheck       # expected: non-zero exit
Remove-Item src/typecheck-violation.ts
npm run typecheck       # expected: exit 0
```

### Architecture gate

```powershell
Copy-Item tests/violations/arch-violation.ts.disabled src/commands/arch-violation.ts
npm run depcruise       # expected: non-zero exit
Remove-Item src/commands/arch-violation.ts
npm run depcruise       # expected: exit 0
```

### Test gate

```powershell
Copy-Item tests/violations/test-violation.test.ts.disabled src/test-violation.test.ts
npm test                # expected: non-zero exit
Remove-Item src/test-violation.test.ts
npm test                # expected: exit 0
```
