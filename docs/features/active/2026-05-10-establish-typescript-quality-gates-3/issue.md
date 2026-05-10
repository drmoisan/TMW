# Issue #3 — Prompt B1: Establish TypeScript Quality Gates

## Goal

Stand up the TypeScript CI toolchain before any TaskMaster-specific task pane code is written, so Prompt B2 commits are validated against final-form gates from the first PR.

## Read First

- `package.json`
- `webpack.config.js`
- `manifest.json`
- `src/taskpane/taskpane.ts`
- `src/commands/commands.ts`

## Required Outcome

- Prettier retained with `office-addin-prettier-config`.
- ESLint flat config with `typescript-eslint` strict-type-checked and stylistic-type-checked rule sets, type-aware parsing enabled.
- `eslint-plugin-office-addins`, `eslint-plugin-promise`, `eslint-plugin-import`, and `eslint-plugin-security` configured.
- `no-floating-promises`, `no-misused-promises`, `no-unsafe-*` rules set to error for source files; relaxed only for tests with documented justification.
- `tsconfig.json` enables `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, and `noPropertyAccessFromIndexSignature`.
- Vitest configured with MSW for HTTP stubbing; an Office.js fake module is wired in as a path alias for unit tests.
- `dependency-cruiser` configured with skeleton rules: forbid cycles, forbid orphaned modules, forbid `src/taskpane` from importing `src/commands` and vice versa. Layer rules are stubs to be populated by later prompts.
- `no-restricted-syntax` rules ban `Date.now`, `setTimeout`, `setInterval`, and `Math.random` outside an explicit allowlist of infrastructure files.
- PR pipeline stages 1 (format), 2 (lint), 3 (typecheck), 4 (architecture), 5 (unit tests) execute on every PR push.
- All gates pass on the unmodified scaffold.

## Validation

- `npm run lint`, `npm run typecheck`, `npm test`, and `npx depcruise src` all pass.
- A representative violation introduced into each category is detected and blocks the build.

## Acceptance Criteria

1. Prettier configured with `office-addin-prettier-config`; `npm run format:check` exits 0 on the unmodified scaffold.
2. ESLint flat config file exists (e.g. `eslint.config.js`) and is loaded by ESLint v9+.
3. ESLint config extends `typescript-eslint` strict-type-checked rule set.
4. ESLint config extends `typescript-eslint` stylistic-type-checked rule set.
5. ESLint type-aware parsing is enabled (`parserOptions.project` resolves to a real tsconfig).
6. `eslint-plugin-office-addins` is configured.
7. `eslint-plugin-promise` is configured.
8. `eslint-plugin-import` is configured.
9. `eslint-plugin-security` is configured.
10. `@typescript-eslint/no-floating-promises` is error-level for source files.
11. `@typescript-eslint/no-misused-promises` is error-level for source files.
12. All `@typescript-eslint/no-unsafe-*` rules are error-level for source files.
13. Test files relax the above only with a documented justification comment in the config block.
14. `tsconfig.json` sets `strict: true`.
15. `tsconfig.json` sets `noUncheckedIndexedAccess: true`.
16. `tsconfig.json` sets `exactOptionalPropertyTypes: true`.
17. `tsconfig.json` sets `noImplicitOverride: true`.
18. `tsconfig.json` sets `noPropertyAccessFromIndexSignature: true`.
19. Vitest is installed and configured; `npm test` exits 0 on the unmodified scaffold.
20. MSW is installed and wired for HTTP stubbing in the Vitest setup.
21. An Office.js fake module is wired in as a path alias for unit tests (resolvable from a sample test).
22. `.dependency-cruiser.cjs` exists with rules: forbid cycles, forbid orphans, forbid `src/taskpane` -> `src/commands` and `src/commands` -> `src/taskpane`.
23. `no-restricted-syntax` ESLint rule bans `Date.now`, `setTimeout`, `setInterval`, `Math.random` outside an explicit infrastructure allowlist.
24. PR pipeline stage 1 (format) executes on every PR push.
25. PR pipeline stage 2 (lint) executes on every PR push.
26. PR pipeline stage 3 (typecheck) executes on every PR push.
27. PR pipeline stage 4 (architecture / dependency-cruiser) executes on every PR push.
28. PR pipeline stage 5 (unit tests) executes on every PR push.
29. All five stages pass on the unmodified scaffold in a CI run on the PR.
30. A representative violation in each category (format, lint, typecheck, architecture, test) is verified to fail the build, with the demonstration recorded in evidence.
