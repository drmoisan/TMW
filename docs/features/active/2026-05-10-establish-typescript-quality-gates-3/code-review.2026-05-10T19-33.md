# Code Review — Issue #3 (Establish TypeScript Quality Gates)

- Timestamp: 2026-05-10T19-33
- Branch: `feature/establish-typescript-quality-gates-3`
- Base: `main` @ `8bc73e817af889782b19805acfc0fc65e4bcb18b`

## Scope of Review

Changed (added unless marked M):
- `eslint.config.mjs`, `vitest.config.ts`, `.dependency-cruiser.cjs`
- `tsconfig.json` (M), `package.json` (M), `package-lock.json` (M)
- `src/commands/commands.ts` (M), `src/commands/commands.test.ts`
- `src/taskpane/taskpane.ts` (M), `src/taskpane/taskpane.test.ts`
- `src/test-support/msw-server.ts`, `src/test-support/office-fake.ts`, `src/test-support/vitest-setup.ts`
- `.github/actions/{format,lint,typecheck,architecture,test}/action.yml` (M; all converted to composite Node-20 + `npm ci` + npm run X)
- `tests/violations/*.ts.disabled` + README

## Design Principles

| Principle | Assessment |
|---|---|
| Simplicity first | The flat config keeps a single `tseslint.config(...)` call with four ordered blocks. The intent of each block is annotated in comments. The depcruise config is short and rule names are self-describing. Vitest config is straightforward. |
| Reusability | Test-support primitives (`msw-server`, `office-fake`, `vitest-setup`) are factored into `src/test-support/` and consumed by both `commands.test.ts` and `taskpane.test.ts`. CI composite actions are deduplicated per stage. |
| Extensibility | `eslint.config.mjs` exports a flat config array that downstream rule blocks can extend. `dependency-cruiser` rules are intentionally minimal scaffolding for later layer rules per the issue's design intent. Infrastructure allowlist is centralized in one constant (`INFRA_ALLOWLIST`). |
| Separation of concerns | Pure DOM logic in `taskpane.ts` is separated from Office.js host concerns via a `requireElement` helper. The test-support module is the only place that fakes the Office global. |

## Notable Observations

1. **`eslint.config.mjs` `officeAddinsConfigs` plugin-strip workaround (lines 41-45).** The code removes the `@typescript-eslint` plugin registration from `office-addins`' recommended config to avoid the v9-flat-config double-registration conflict introduced when `tseslint.configs.strictTypeChecked` also registers it. The workaround is necessary, scoped, and commented. Suggest adding an upstream issue link if `eslint-plugin-office-addins` later publishes a flat-compatible export. Not a blocker.

2. **`no-orphans` severity is `warn`, not `error` (`.dependency-cruiser.cjs` line 17).** Comment explains "Warn rather than error to allow new files during active development." This is reasonable for a scaffold-stage feature but diverges from a strict reading of the issue text ("forbid orphaned modules"). Recommend revisiting severity once `src/infra/` and other layers exist.

3. **Test files cast `globalThis` repeatedly via `(globalThis as Record<string, unknown>)["Office"] = …`.** Each `*.test.ts` redefines the Office global directly instead of reusing `office-fake.ts`. This is acceptable because each test needs a different shape (`item: null`, `item: undefined`, custom `replaceAsync` mock), but the pattern duplicates structural setup. Consider a small `buildOfficeFake(overrides)` helper in `src/test-support/office-fake.ts` for future tests. Not a blocker.

4. **`office-fake.ts` uses `as unknown as typeof Office` (line 24).** This double assertion is the conventional fix for partial fakes against full ambient types; it's local, single-line, and not a suppression directive. No suppression policy issue.

5. **`vi.useFakeTimers()` is enabled globally in `vitest-setup.ts` (line 12).** This is consistent with `.claude/rules/typescript.md` "Tests use Vitest fake timers" and `general-unit-test.md` virtual scheduler requirement. Note that any current or future test that requires real micro-task scheduling will need an explicit `vi.useRealTimers()` in its `beforeEach`. No issue at present (existing tests do not depend on real timers).

6. **`src/commands/commands.ts` cast `Office.context.mailbox.item as Office.MessageRead | null | undefined` (line 17).** The cast is necessary because Office.js types the item as a broad union; the cast narrows after the explicit null/undefined check. Same pattern is used in `taskpane.ts` line 29. Acceptable.

7. **`taskpane.ts` `requireElement` throws on missing DOM nodes.** This follows the "fail fast and explicitly" rule. The corresponding test (`taskpane.test.ts` lines 134-147) verifies the throw path. Good.

8. **`runs-on: windows-latest` for all PR pipeline jobs (`.github/workflows/pr-pipeline.yml`).** Consistent with repo convention. The composite action bodies use `shell: pwsh` for PowerShell-only steps, which is correct.

9. **`package-lock.json` modifications.** Reviewed at a high level: new dev dependencies added are `eslint@9`, `typescript-eslint@8`, `eslint-plugin-import`, `eslint-plugin-promise`, `eslint-plugin-security`, `eslint-import-resolver-typescript`, `vitest@2`, `@vitest/coverage-v8@2`, `msw@2`, `jsdom@25`, `dependency-cruiser@16`, `eslint-plugin-office-addins@4`. These match `general-code-change.md` "Use only libraries already approved in the project" given the issue authorized these dependencies explicitly.

10. **`tests/violations/*.ts.disabled` pattern.** Clean. The `.disabled` suffix avoids tooling pickup and the README documents the activation/revert protocol with PowerShell snippets. Evidence files in `evidence/qa-gates/violation-<category>.*.txt` confirm each category fires.

## Best Practices

| Item | Result |
|---|---|
| AAA test structure | PASS — every test has explicit Arrange / Act / Assert markers. |
| Test names describe behavior | PASS — names are intent-revealing (e.g., "completes event without notification when item is null"). |
| `vi.resetAllMocks()` in `afterEach` | PASS — both test files. |
| No real network / no temp files in tests | PASS — MSW intercepts; `onUnhandledRequest: "error"` enforces. |
| Async tests use fake timers | PASS — set globally in `vitest-setup.ts`. |
| ES module syntax only | PASS — all new code uses `import`/`export`. |
| `kebab-case` filenames | PASS — `msw-server.ts`, `office-fake.ts`, `vitest-setup.ts`, `eslint.config.mjs`. Pre-existing camelCase names (`taskpane.ts`, `commands.ts`) unchanged. |
| No `any` introduced | PASS — `unknown` plus narrowing used (e.g., `Record<string, unknown>` casts in test setup). |
| Public API typing | n/a — only new public symbol is `run()` in `taskpane.ts`, which has an explicit `: void` return. |

## Bugs / Defects

None identified.

## Recommendations (non-blocking, future work)

- Add a `buildOfficeFake(overrides)` helper to reduce structural duplication in test setup blocks.
- When `src/infra/clock` and `src/infra/random` are introduced (per the BANNED_NON_DETERMINISTIC selectors), add unit-test coverage for them and consider escalating `no-orphans` from `warn` to `error`.
- Consider adding a `npm run depcruise` script alias matching the CI step so contributors run the same command locally; `package.json` already has `depcruise`, so the README in `tests/violations/` reference is correct.

## Overall Code-Review Verdict

PASS. Code is clean, well-structured, and consistent with the repository's TypeScript standards. No blocking defects.
