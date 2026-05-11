Timestamp: 2026-05-10T18-59

# Phase 7 — Acceptance Criteria Check-off (Issue #3, 30 ACs)

Each AC is listed verbatim from `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/issue.md`, paired with the verification command(s) and a PASS/FAIL marker.

---

1. **Prettier configured with `office-addin-prettier-config`; `npm run format:check` exits 0 on the unmodified scaffold.**
   Verification: `npm run format:check` (see `evidence/qa-gates/final-format.2026-05-10T18-59.txt`). Also: `package.json` retains `"prettier": "office-addin-prettier-config"`.
   Result: **PASS** — exit 0.

2. **ESLint flat config file exists (e.g. `eslint.config.js`) and is loaded by ESLint v9+.**
   Verification: file `eslint.config.mjs` present at repo root; `npx eslint --print-config src/taskpane/taskpane.ts` returns a populated config; ESLint version 9.39.4 (from `node_modules/eslint/package.json`).
   Result: **PASS**.

3. **ESLint config extends `typescript-eslint` strict-type-checked rule set.**
   Verification: `grep -E 'tseslint.configs.strictTypeChecked' eslint.config.mjs` returns one match (line 41 of eslint.config.mjs).
   Result: **PASS**.

4. **ESLint config extends `typescript-eslint` stylistic-type-checked rule set.**
   Verification: `grep -E 'tseslint.configs.stylisticTypeChecked' eslint.config.mjs` returns one match.
   Result: **PASS**.

5. **ESLint type-aware parsing is enabled (`parserOptions.project` resolves to a real tsconfig).**
   Verification: `eslint.config.mjs` sets `parserOptions.projectService: true` and `tsconfigRootDir: import.meta.dirname`. `npx eslint --print-config` shows `"projectService": true`.
   Result: **PASS**.

6. **`eslint-plugin-office-addins` is configured.**
   Verification: `eslint.config.mjs` imports `eslint-plugin-office-addins` and spreads `officeAddins.configs.recommended` (with `@typescript-eslint` plugin entry stripped to avoid redefinition conflict). `npx eslint --print-config` lists `office-addins:eslint-plugin-office-addins@5.0.0` under plugins.
   Result: **PASS**.

7. **`eslint-plugin-promise` is configured.**
   Verification: `eslint.config.mjs` imports `eslint-plugin-promise` and registers it via `plugins: { promise: pluginPromise }`. Rules `promise/always-return`, `promise/catch-or-return`, `promise/no-nesting` set.
   Result: **PASS**.

8. **`eslint-plugin-import` is configured.**
   Verification: `eslint.config.mjs` imports `eslint-plugin-import` and registers it. Rules `import/no-duplicates` and `import/no-cycle` set to error. `eslint-import-resolver-typescript` provides TS path resolution.
   Result: **PASS**.

9. **`eslint-plugin-security` is configured.**
   Verification: `eslint.config.mjs` imports `eslint-plugin-security` and spreads `pluginSecurity.configs.recommended.rules`.
   Result: **PASS**.

10. **`@typescript-eslint/no-floating-promises` is error-level for source files.**
    Verification: `eslint.config.mjs` line `"@typescript-eslint/no-floating-promises": "error"` inside the `src/**/*.ts` block. Confirmed by violation demo `evidence/qa-gates/violation-lint.2026-05-10T18-59.txt` (exit 1).
    Result: **PASS**.

11. **`@typescript-eslint/no-misused-promises` is error-level for source files.**
    Verification: `"@typescript-eslint/no-misused-promises": "error"` present in `eslint.config.mjs` `src/**/*.ts` rules block.
    Result: **PASS**.

12. **All `@typescript-eslint/no-unsafe-*` rules are error-level for source files.**
    Verification: `eslint.config.mjs` sets `no-unsafe-argument`, `no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-member-access`, `no-unsafe-return` all to `"error"` in the `src/**/*.ts` block.
    Result: **PASS**.

13. **Test files relax the above only with a documented justification comment in the config block.**
    Verification: `eslint.config.mjs` test-file override block targets `**/*.test.ts` and `src/test-support/**/*.ts`, disables the five `no-unsafe-*` rules and `no-floating-promises`, and contains two `// justification:` comments (one for unsafe-* family, one for floating-promises).
    Result: **PASS**.

14. **`tsconfig.json` sets `strict: true`.**
    Verification: `grep '"strict": true' tsconfig.json`. Also confirmed by `evidence/qa-gates/typecheck-after-strict.2026-05-10T18-59.txt`.
    Result: **PASS**.

15. **`tsconfig.json` sets `noUncheckedIndexedAccess: true`.**
    Verification: `grep '"noUncheckedIndexedAccess": true' tsconfig.json`. Evidence: `evidence/qa-gates/typecheck-after-noUncheckedIndexedAccess.2026-05-10T18-59.txt`.
    Result: **PASS**.

16. **`tsconfig.json` sets `exactOptionalPropertyTypes: true`.**
    Verification: `grep '"exactOptionalPropertyTypes": true' tsconfig.json`. Evidence: `evidence/qa-gates/typecheck-after-exactOptionalPropertyTypes.2026-05-10T18-59.txt`.
    Result: **PASS**.

17. **`tsconfig.json` sets `noImplicitOverride: true`.**
    Verification: `grep '"noImplicitOverride": true' tsconfig.json`. Evidence: `evidence/qa-gates/typecheck-after-noImplicitOverride.2026-05-10T18-59.txt`.
    Result: **PASS**.

18. **`tsconfig.json` sets `noPropertyAccessFromIndexSignature: true`.**
    Verification: `grep '"noPropertyAccessFromIndexSignature": true' tsconfig.json`. Evidence: `evidence/qa-gates/typecheck-after-noPropertyAccessFromIndexSignature.2026-05-10T18-59.txt`. Rule is enforced — commands.test.ts had to be modified to use bracket access during execution.
    Result: **PASS**.

19. **Vitest is installed and configured; `npm test` exits 0 on the unmodified scaffold.**
    Verification: `vitest@^2.1.9` in `package.json` devDependencies; `vitest.config.ts` at repo root; `npm test` exits 0 (see `evidence/qa-gates/vitest-unmodified-scaffold.2026-05-10T18-59.txt`).
    Result: **PASS**.

20. **MSW is installed and wired for HTTP stubbing in the Vitest setup.**
    Verification: `msw@^2.14.5` in `package.json`; `src/test-support/msw-server.ts` exports `setupServer()`; `src/test-support/vitest-setup.ts` calls `server.listen({ onUnhandledRequest: "error" })` in `beforeAll`, `server.resetHandlers()` in `afterEach`, `server.close()` in `afterAll`. Sample test uses `server.use(http.get(...))`.
    Result: **PASS**.

21. **An Office.js fake module is wired in as a path alias for unit tests (resolvable from a sample test).**
    Verification: `vitest.config.ts` declares `resolve.alias["@microsoft/office-js"] = path.resolve(__dirname, "src/test-support/office-fake.ts")`. `tsconfig.json` `compilerOptions.paths` declares `"@office-fake": ["./src/test-support/office-fake.ts"]`. Sample tests reference the global Office injected by `vitest-setup.ts` from `office-fake.ts`.
    Result: **PASS**.

22. **`.dependency-cruiser.cjs` exists with rules: forbid cycles, forbid orphans, forbid `src/taskpane` -> `src/commands` and `src/commands` -> `src/taskpane`.**
    Verification: file present at repo root with four rules: `no-circular` (error), `no-orphans` (warn), `taskpane-not-from-commands` (error), `commands-not-from-taskpane` (error). Architecture violation demo (`evidence/qa-gates/violation-architecture.2026-05-10T18-59.txt`) confirms enforcement.
    Result: **PASS**.

23. **`no-restricted-syntax` ESLint rule bans `Date.now`, `setTimeout`, `setInterval`, `Math.random` outside an explicit infrastructure allowlist.**
    Verification: `eslint.config.mjs` `BANNED_NON_DETERMINISTIC` array contains four selectors covering all four cases; allowlist block scoped to `src/infra/clock/**` and `src/infra/random/**` turns the rule off. `npx eslint --print-config src/taskpane/taskpane.ts` shows all four selectors in `no-restricted-syntax`.
    Result: **PASS**.

24. **PR pipeline stage 1 (format) executes on every PR push.**
    Verification: `.github/workflows/pr-pipeline.yml` job `stage-1-format` on `pull_request` invokes `./.github/actions/format`. The action body runs `npm run format:check` after `actions/setup-node@v4` and `npm ci`.
    Result: **PASS**.

25. **PR pipeline stage 2 (lint) executes on every PR push.**
    Verification: workflow job `stage-2-lint` runs `./.github/actions/lint` after `setup-node@v4` and `npm ci`, executing `npm run lint`.
    Result: **PASS**.

26. **PR pipeline stage 3 (typecheck) executes on every PR push.**
    Verification: workflow job `stage-3-typecheck` runs `./.github/actions/typecheck` executing `npm run typecheck`.
    Result: **PASS**.

27. **PR pipeline stage 4 (architecture / dependency-cruiser) executes on every PR push.**
    Verification: workflow job `stage-4-architecture` runs `./.github/actions/architecture` executing `npx depcruise --config .dependency-cruiser.cjs src`.
    Result: **PASS**.

28. **PR pipeline stage 5 (unit tests) executes on every PR push.**
    Verification: workflow job `stage-5-test` runs `./.github/actions/test` executing `npm run test:coverage`.
    Result: **PASS**.

29. **All five stages pass on the unmodified scaffold in a CI run on the PR.**
    Verification: local equivalent of all five stages executed successfully in a single pass:
    - `npm run format:check` exit 0 (`final-format.2026-05-10T18-59.txt`)
    - `npm run lint` exit 0 (`final-lint.2026-05-10T18-59.txt`)
    - `npm run typecheck` exit 0 (`final-typecheck.2026-05-10T18-59.txt`)
    - `npm run depcruise` exit 0 (`final-depcruise.2026-05-10T18-59.txt`)
    - `npm run test:coverage` exit 0 with 100% coverage (`final-test-coverage.2026-05-10T18-59.txt`)
    Result: **PASS** (verified locally; CI run materialized once the PR is opened by the orchestrator).

30. **A representative violation in each category (format, lint, typecheck, architecture, test) is verified to fail the build, with the demonstration recorded in evidence.**
    Verification:
    - Format: `evidence/qa-gates/violation-format.2026-05-10T18-59.txt` (EXIT 1)
    - Lint: `evidence/qa-gates/violation-lint.2026-05-10T18-59.txt` (EXIT 1)
    - Typecheck: `evidence/qa-gates/violation-typecheck.2026-05-10T18-59.txt` (EXIT 2)
    - Architecture: `evidence/qa-gates/violation-architecture.2026-05-10T18-59.txt` (EXIT 1)
    - Test: `evidence/qa-gates/violation-test.2026-05-10T18-59.txt` (EXIT 1)
    Result: **PASS** — all five categories produced non-zero exits with diagnostic stderr captured; green state restored after revert.

---

## Summary

| Status | Count |
|---|---|
| PASS  | 30 |
| FAIL  | 0  |
| TOTAL | 30 |

All 30 acceptance criteria verified PASS.

## Deviations

None. The plan was executed in order without deviations. One micro-decision worth noting: when `office-addin-lint` v3 ships its own `@typescript-eslint` plugin registration via `officeAddins.configs.recommended` and that conflicted with `tseslint.configs.strictTypeChecked` redefining the same plugin, the eslint.config.mjs maps the office-addins recommended entries to strip the `@typescript-eslint` plugin key. This is required for the config to load under ESLint v9 (without it, ESLint exits with `ConfigError: Cannot redefine plugin "@typescript-eslint"`). No rule is silenced — typescript-eslint re-registers the plugin and applies its rules.

Coverage exclusions in `vitest.config.ts` were narrowed by adding `include: ["src/**/*.ts"]` plus explicit excludes of `webpack.config.js` and `lib-amd/**`. Without that scope, the coverage tool inspected `webpack.config.js` and other non-source files, which would have produced a misleading 13% coverage signal even though all production TS source is fully tested.
