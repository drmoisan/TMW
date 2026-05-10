# Plan — Issue #3: Establish TypeScript Quality Gates (Prompt B1)

- Work Mode: full-feature
- Feature folder: `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/`
- Canonical issue: #3
- Evidence root: `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/`
- Research artifact: `artifacts/research/2026-05-10-prompt-b1-typescript-quality-gates.md` (adopted verbatim)
- Plan-path continuity: this file is updated in place across preflight revision loops.

Notes on conventions used throughout this plan:
- All evidence artifacts MUST be written under the canonical evidence root above per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. The forbidden `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, `artifacts/evidence/` locations MUST NOT be used.
- ISO-8601 timestamp format: `yyyy-MM-ddTHH-mm`. Substitute `<timestamp>` with the current value when executing.
- Every command-bearing task writes its evidence file with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` per the schema.
- The seven-stage toolchain order is: format → lint → typecheck → architecture (depcruise) → test → contract → integration. Stages 6 and 7 are out of scope for this issue; the per-phase restart gate runs stages 1–5 only.
- Per-task file budget: 1–3 production/config files plus their tests. Each `[P#-T#]` is a single binary outcome with one verifiable acceptance criterion.

---

### Phase 0 — Baseline Capture

- [x] [P0-T1] Read `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`, `.claude/rules/architecture-boundaries.md`, and `.claude/skills/evidence-and-timestamp-conventions/SKILL.md` in that exact order, then write `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/baseline/phase0-instructions-read.<timestamp>.md` containing `Timestamp:`, `Policy Order:` (the exact list above), and the explicit list of files read. PASS: artifact exists and contains all seven file paths.
- [x] [P0-T2] Read `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/issue.md` in full and `artifacts/research/2026-05-10-prompt-b1-typescript-quality-gates.md` in full; write `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/baseline/phase0-inputs-read.<timestamp>.md` listing both paths and confirming the 30 acceptance criteria count. PASS: artifact exists and references AC count = 30.
- [x] [P0-T3] Execute `npm ci --no-audit --no-fund` and capture stdout/stderr to `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/baseline/npm-ci.<timestamp>.txt` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. PASS: exit code recorded; package install state is the documented baseline.
- [x] [P0-T4] Run `npx prettier --check "src/**/*.ts"` and capture to `evidence/baseline/format-check-baseline.<timestamp>.txt` with the four required schema fields. PASS: artifact exists with EXIT_CODE recorded (baseline outcome, pass or fail, is informational).
- [x] [P0-T5] Run `npm run lint` and capture to `evidence/baseline/lint-baseline.<timestamp>.txt` with the four required schema fields. PASS: artifact exists with EXIT_CODE recorded.
- [x] [P0-T6] Run `npx tsc --noEmit` (no `typecheck` script yet) and capture to `evidence/baseline/typecheck-baseline.<timestamp>.txt` with the four required schema fields. PASS: artifact exists; Output Summary records the count of errors observed against the un-strict tsconfig.
- [x] [P0-T7] Confirm absence of `.dependency-cruiser.cjs` and absence of `vitest.config.ts`; write `evidence/baseline/tooling-absence.<timestamp>.md` listing `SearchScope:`, `SearchPatterns:`, `SearchResult:` for each path (none expected). PASS: artifact records `none` for both.
- [x] [P0-T8] Capture the current contents of `.github/actions/format/action.yml`, `.github/actions/lint/action.yml`, `.github/actions/typecheck/action.yml`, `.github/actions/architecture/action.yml`, `.github/actions/test/action.yml` into `evidence/baseline/ci-actions-baseline.<timestamp>.md` (raw concatenation with file headers) for diff reference. PASS: artifact contains all five action YAML files.
- [x] [P0-T9] Phase 0 toolchain restart gate: re-run format check, lint, and `npx tsc --noEmit` once more and record `evidence/baseline/phase0-restart-gate.<timestamp>.md` with all three commands' EXIT_CODE values. PASS: artifact written; phase closed.

---

### Phase 1 — Dependencies, npm scripts, and tsconfig strict flags

#### Dependency installation (one pinned package per task)

- [x] [P1-T1] Add `eslint@^9.39.4` to `package.json` devDependencies via `npm install --save-dev --save-exact=false eslint@^9.39.4`; verify `node_modules/eslint/package.json` version. Evidence: `evidence/baseline/dep-eslint.<timestamp>.txt`. PASS: package.json contains the pinned range and exit code 0.
- [x] [P1-T2] Add `typescript-eslint@^8.8.1` via `npm install --save-dev typescript-eslint@^8.8.1`. Evidence: `evidence/baseline/dep-typescript-eslint.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T3] Pin `eslint-plugin-office-addins@^4.0.7` (upgrade from `^4.0.3`) via `npm install --save-dev eslint-plugin-office-addins@^4.0.7`. Evidence: `evidence/baseline/dep-office-addins.<timestamp>.txt`. PASS: package.json updated to `^4.0.7`, exit code 0.
- [x] [P1-T4] Add `eslint-plugin-promise@^7.2.1` via `npm install --save-dev eslint-plugin-promise@^7.2.1`. Evidence: `evidence/baseline/dep-eslint-plugin-promise.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T5] Add `eslint-plugin-import@^2.31.0` via `npm install --save-dev eslint-plugin-import@^2.31.0`. Evidence: `evidence/baseline/dep-eslint-plugin-import.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T6] Add `eslint-import-resolver-typescript@^3.7.0` via `npm install --save-dev eslint-import-resolver-typescript@^3.7.0`. Evidence: `evidence/baseline/dep-eslint-import-resolver-typescript.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T7] Add `eslint-plugin-security@^3.0.1` via `npm install --save-dev eslint-plugin-security@^3.0.1`. Evidence: `evidence/baseline/dep-eslint-plugin-security.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T8] Add `vitest@^2.1.8` via `npm install --save-dev vitest@^2.1.8`. Evidence: `evidence/baseline/dep-vitest.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T9] Add `@vitest/coverage-v8@^2.1.8` via `npm install --save-dev @vitest/coverage-v8@^2.1.8`. Evidence: `evidence/baseline/dep-vitest-coverage-v8.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T10] Add `jsdom@^25.0.1` via `npm install --save-dev jsdom@^25.0.1`. Evidence: `evidence/baseline/dep-jsdom.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T11] Add `msw@^2.6.4` via `npm install --save-dev msw@^2.6.4`. Evidence: `evidence/baseline/dep-msw.<timestamp>.txt`. PASS: package.json updated, exit code 0.
- [x] [P1-T12] Add `dependency-cruiser@^16.8.0` via `npm install --save-dev dependency-cruiser@^16.8.0`. Evidence: `evidence/baseline/dep-dependency-cruiser.<timestamp>.txt`. PASS: package.json updated, exit code 0.

#### npm scripts (one script per task)

- [x] [P1-T13] Add `"format": "prettier --write \"src/**/*.ts\""` to `package.json` scripts (preserve existing `prettier` script). Validate by running `npm run -s format --silent --if-present` then `Get-Content package.json | Select-String '"format":'`. PASS: script present in package.json; running it on the scaffold exits 0.
- [x] [P1-T14] Add `"format:check": "prettier --check \"src/**/*.ts\""` to `package.json` scripts. Validate with `npm run format:check`. PASS: script present; on the unmodified scaffold, exits 0.
- [x] [P1-T15] Verify the existing `lint` script (`office-addin-lint check`) is preserved unchanged and run `npm run lint --silent` (it will still use the bundled flat config until Phase 2 lands the project `eslint.config.mjs`). PASS: `package.json` still contains `"lint": "office-addin-lint check"`; command executes (exit code captured for record; non-zero is acceptable at this point).
- [x] [P1-T16] Add `"typecheck": "tsc --noEmit"` to `package.json` scripts. Validate with `npm run typecheck`. PASS: script present; command runs to completion (exit code may be non-zero pre-strict-flag flips).
- [x] [P1-T17] Add `"test": "vitest run"` to `package.json` scripts. PASS: script present; do NOT execute yet (vitest config not authored). Evidence: diff of package.json captured to `evidence/baseline/script-test.<timestamp>.txt`.
- [x] [P1-T18] Add `"test:coverage": "vitest run --coverage"` to `package.json` scripts. PASS: script present in package.json.
- [x] [P1-T19] Add `"depcruise": "depcruise --config .dependency-cruiser.cjs src"` to `package.json` scripts. PASS: script present in package.json.

#### tsconfig flag flips (one flag per task; tsc clean between flips)

- [x] [P1-T20] Edit `src/taskpane/taskpane.ts` to add a `requireElement(id: string): HTMLElement` helper that throws if `document.getElementById(id)` returns null, and replace each unsafe `getElementById` call site with `requireElement(...)`; also add a null guard `if (item === null) return;` before `item.subject` access. PASS: `npx tsc --noEmit` exits 0 with current (pre-strict) tsconfig.
- [x] [P1-T21] Edit `src/commands/commands.ts` to add `const item = Office.context.mailbox.item; if (item === null) { event.completed(); return; }` before any `item.notificationMessages` usage. PASS: `npx tsc --noEmit` exits 0.
- [x] [P1-T22] Edit `tsconfig.json` to add `"strict": true`. Run `npm run typecheck` and capture to `evidence/qa-gates/typecheck-after-strict.<timestamp>.txt`. PASS: exit code 0.
- [x] [P1-T23] Edit `tsconfig.json` to add `"noUncheckedIndexedAccess": true`. Run `npm run typecheck` and capture to `evidence/qa-gates/typecheck-after-noUncheckedIndexedAccess.<timestamp>.txt`. PASS: exit code 0.
- [x] [P1-T24] Edit `tsconfig.json` to add `"exactOptionalPropertyTypes": true`. Run `npm run typecheck` and capture to `evidence/qa-gates/typecheck-after-exactOptionalPropertyTypes.<timestamp>.txt`. PASS: exit code 0.
- [x] [P1-T25] Edit `tsconfig.json` to add `"noImplicitOverride": true`. Run `npm run typecheck` and capture to `evidence/qa-gates/typecheck-after-noImplicitOverride.<timestamp>.txt`. PASS: exit code 0.
- [x] [P1-T26] Edit `tsconfig.json` to add `"noPropertyAccessFromIndexSignature": true`. Run `npm run typecheck` and capture to `evidence/qa-gates/typecheck-after-noPropertyAccessFromIndexSignature.<timestamp>.txt`. PASS: exit code 0.
- [x] [P1-T27] Edit `tsconfig.json` to add `"paths": { "@office-fake": ["./src/test-support/office-fake.ts"] }` under `compilerOptions` (and confirm `baseUrl` remains `.`). Run `npm run typecheck`. PASS: exit code 0.

#### Phase 1 restart gate

- [x] [P1-T28] Phase 1 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck` in order. If any fails or autofixes files, loop the relevant tasks above and repeat the gate. Record outcomes to `evidence/qa-gates/phase1-restart-gate.<timestamp>.md` with each command's EXIT_CODE. PASS: format:check exit 0 and typecheck exit 0 in a single pass (lint may still be non-zero pending Phase 2 config).

---

### Phase 2 — ESLint flat config

- [x] [P2-T1] Create `eslint.config.mjs` at the repository root exactly per Research §1, including: `tseslint.config(...)` wrapper; spread `...officeAddins.configs.recommended` as the first block; a second block targeting `src/**/*.ts` that extends `tseslint.configs.strictTypeChecked` and `tseslint.configs.stylisticTypeChecked`, sets `parserOptions.projectService: true` and `tsconfigRootDir: import.meta.dirname`, registers `promise`, `import`, `security` plugins, configures `import/resolver` with `typescript: { project: "./tsconfig.json" }`, and sets the rules block exactly as shown (no-floating-promises, no-misused-promises, no-unsafe-argument, no-unsafe-assignment, no-unsafe-call, no-unsafe-member-access, no-unsafe-return at error; promise/always-return, promise/catch-or-return at error; promise/no-nesting at warn; import/no-duplicates and import/no-cycle at error; spread `pluginSecurity.configs.recommended.rules`); and a third infra-allowlist block targeting `src/infra/clock/**` and `src/infra/random/**` that turns `no-restricted-syntax` off. PASS: file exists and `npm run lint -- --print-config src/taskpane/taskpane.ts` resolves without configuration errors.
- [x] [P2-T2] Add to `eslint.config.mjs` the `no-restricted-syntax` block in the `src/**/*.ts` rules section containing the four bans (Date.now MemberExpression call, setTimeout call, setInterval call, Math.random MemberExpression) with messages exactly as Research §1. PASS: `npm run lint -- --print-config src/taskpane/taskpane.ts | Select-String 'no-restricted-syntax'` shows the four selectors.
- [x] [P2-T3] Add the test-file override block in `eslint.config.mjs` targeting `**/*.test.ts` and `src/test-support/**/*.ts`, extending `tseslint.configs.disableTypeChecked`, disabling the five `no-unsafe-*` rules and `no-floating-promises`, with two `// justification:` comments in the config source (one for the unsafe family, one for floating promises) per Research §1. PASS: the override block exists; comments are present in the file; `npm run lint -- --print-config src/taskpane/taskpane.test.ts` shows the disabled rules.
- [x] [P2-T4] Run `npm run lint` on the unmodified scaffold (post-Phase 1 edits). Capture to `evidence/qa-gates/lint-unmodified-scaffold.<timestamp>.txt` with the four schema fields. PASS: EXIT_CODE 0.
- [x] [P2-T5] Phase 2 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck`. Capture to `evidence/qa-gates/phase2-restart-gate.<timestamp>.md`. PASS: all three exit 0 in a single pass; if any fails or autofixes, loop the relevant Phase 2 task and re-run.

---

### Phase 3 — Vitest + MSW + Office.js fake

- [x] [P3-T1] Create `vitest.config.ts` at repository root per Research §3: `environment: "jsdom"`, `globals: true`, `setupFiles: ["./src/test-support/vitest-setup.ts"]`, `include: ["**/*.test.ts"]`, `exclude: ["node_modules", "dist", "lib"]`, coverage block with `provider: "v8"`, reporters `["text", "lcov", "json-summary"]`, exclusions list exactly as Research §3, thresholds `lines: 85, branches: 75, functions: 85, statements: 85`, and `resolve.alias["@microsoft/office-js"]` pointing to `src/test-support/office-fake.ts`. PASS: file exists; `npx vitest --help` resolves the config without error.
- [x] [P3-T2] Create `src/test-support/office-fake.ts` per Research §3 (minimal `onReady`, `HostType.Outlook`, `context.mailbox.item = null`, `MailboxEnums.ItemNotificationMessageType.InformationalMessage`, `actions.associate`) and `export default officeFake as unknown as typeof Office`. PASS: file exists; `npx tsc --noEmit` exit 0.
- [x] [P3-T3] Create `src/test-support/msw-server.ts` exporting `export const server = setupServer();` imported from `msw/node` per Research §3. PASS: file exists; `npx tsc --noEmit` exit 0.
- [x] [P3-T4] Create `src/test-support/vitest-setup.ts` per Research §3: `beforeAll` assigning `(globalThis as Record<string, unknown>)["Office"] = officeFake;`, `beforeAll(() => server.listen({ onUnhandledRequest: "error" }))`, `afterEach(() => server.resetHandlers())`, `afterAll(() => server.close())`, and enable fake timers by default via `vi.useFakeTimers()` in a `beforeAll`. PASS: file exists; `npx tsc --noEmit` exit 0.
- [x] [P3-T5] Create `src/taskpane/taskpane.test.ts` as the sample passing test per Research §3 (arranges DOM, sets `Office.context.mailbox.item`, dynamically imports `./taskpane`, asserts `#item-subject` text contains `"Test Subject"`). PASS: file exists; `npm test` exits 0 with at least one passing test reported.
- [x] [P3-T6] Run `npm test` on the unmodified scaffold and capture to `evidence/qa-gates/vitest-unmodified-scaffold.<timestamp>.txt`. PASS: EXIT_CODE 0; Output Summary records the passing test count.
- [x] [P3-T7] Phase 3 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm test`. Capture to `evidence/qa-gates/phase3-restart-gate.<timestamp>.md`. PASS: all four exit 0 in a single pass; if any fails or autofixes, loop the relevant Phase 3 task and re-run.

---

### Phase 4 — dependency-cruiser

- [x] [P4-T1] Create `.dependency-cruiser.cjs` at repository root exactly per Research §4: `forbidden` array with four rules — `no-circular` (error), `no-orphans` (warn, `pathNot` excludes `\\.test\\.ts$`, `src/test-support/`, `\\.d\\.ts$`, `vitest\\.config\\.ts$`, `eslint\\.config\\.mjs$`), `taskpane-not-from-commands` (error; from `^src/commands/` to `^src/taskpane/`), `commands-not-from-taskpane` (error; from `^src/taskpane/` to `^src/commands/`); `options` block with `doNotFollow.path: "node_modules"`, `tsConfig.fileName: "tsconfig.json"`, `enhancedResolveOptions` per Research §4, and `reporterOptions.text.highlightFocused: true`. PASS: file exists; `node -e "require('./.dependency-cruiser.cjs')"` exit 0.
- [x] [P4-T2] Run `npx depcruise --config .dependency-cruiser.cjs src` and capture to `evidence/qa-gates/depcruise-unmodified-scaffold.<timestamp>.txt`. PASS: EXIT_CODE 0 (warnings on entry-point orphans permitted).
- [x] [P4-T3] Phase 4 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm run depcruise`, `npm test`. Capture to `evidence/qa-gates/phase4-restart-gate.<timestamp>.md`. PASS: all five exit 0 in a single pass.

---

### Phase 5 — CI workflow composite actions

Each task edits one composite action file and validates its YAML.

- [x] [P5-T1] Replace the body of `.github/actions/format/action.yml` with the Research §5 stage-1 definition: `name: Format`, composite steps `actions/setup-node@v4` (node-version `"20"`, cache `"npm"`), `npm ci --no-audit --no-fund` (pwsh), `npm run format:check` (pwsh). Validate locally: `pwsh -NoProfile -c "Get-Content .github/actions/format/action.yml | Select-String 'format:check'"` returns one match; `pwsh -NoProfile -c "Get-Content .github/actions/format/action.yml | Select-String 'actions/setup-node@v4'"` returns one match. Evidence: `evidence/qa-gates/ci-format-action.<timestamp>.md` (file diff). PASS: both Select-String matches present; YAML still parses (`python -c "import yaml; yaml.safe_load(open('.github/actions/format/action.yml'))"` or equivalent — if Python unavailable use `pwsh ConvertFrom-Yaml` from `powershell-yaml` if installed; otherwise rely on `actionlint` if available; if no validator is available, record the absence and rely on CI-side validation).
- [x] [P5-T2] Edit `.github/actions/lint/action.yml` to add `actions/setup-node@v4` (node 20, npm cache) and `npm ci --no-audit --no-fund` steps before the existing `npm run lint` step. Validate as in P5-T1. Evidence: `evidence/qa-gates/ci-lint-action.<timestamp>.md`. PASS: setup-node and `npm ci` lines both present; `npm run lint` line preserved.
- [x] [P5-T3] Edit `.github/actions/typecheck/action.yml` to add `actions/setup-node@v4` and `npm ci --no-audit --no-fund` steps before the existing typecheck step, and ensure the run step is exactly `npm run typecheck`. Evidence: `evidence/qa-gates/ci-typecheck-action.<timestamp>.md`. PASS: three required lines (`setup-node@v4`, `npm ci`, `npm run typecheck`) all present.
- [x] [P5-T4] Edit `.github/actions/architecture/action.yml` to add `actions/setup-node@v4` and `npm ci --no-audit --no-fund` steps before the depcruise invocation, and ensure the run step is exactly `npx depcruise --config .dependency-cruiser.cjs src`. Evidence: `evidence/qa-gates/ci-architecture-action.<timestamp>.md`. PASS: three required lines present.
- [x] [P5-T5] Replace the body of `.github/actions/test/action.yml` with `actions/setup-node@v4`, `npm ci --no-audit --no-fund`, and `npm run test:coverage` per Research §5. Evidence: `evidence/qa-gates/ci-test-action.<timestamp>.md`. PASS: three required lines present; `Select-String 'test:coverage'` returns one match.
- [x] [P5-T6] Confirm `.github/workflows/pr-pipeline.yml` already wires jobs `stage-1-format` through `stage-5-test` on `pull_request` and that no edit to the workflow file is required. Write `evidence/qa-gates/ci-workflow-confirmation.<timestamp>.md` containing the relevant excerpt and the conclusion `NO EDIT REQUIRED`. PASS: artifact written; workflow file unchanged.
- [x] [P5-T7] Phase 5 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm run depcruise`, `npm test`. Capture to `evidence/qa-gates/phase5-restart-gate.<timestamp>.md`. PASS: all five exit 0 in a single pass.

---

### Phase 6 — Violation demonstrations

Each violation task: (a) places the violation file at its target path, (b) runs the gate command, (c) captures stdout/stderr + EXIT_CODE to evidence, (d) reverts by removing the violation file, (e) re-runs the gate to confirm green. Each evidence file MUST contain `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.

- [x] [P6-T1] Create `tests/violations/format-violation.ts.disabled` with the content from Research §7 (missing semicolon, no spaces around operator). PASS: file exists.
- [x] [P6-T2] Create `tests/violations/lint-violation.ts.disabled` with the content from Research §7 (floating promise demo). PASS: file exists.
- [x] [P6-T3] Create `tests/violations/typecheck-violation.ts.disabled` with the content from Research §7 (`const x: number = "string"`). PASS: file exists.
- [x] [P6-T4] Create `tests/violations/arch-violation.ts.disabled` with the content from Research §7 (imports from `../taskpane/taskpane`). PASS: file exists.
- [x] [P6-T5] Create `tests/violations/test-violation.test.ts.disabled` with the content from Research §7 (`expect(1).toBe(2)`). PASS: file exists.
- [x] [P6-T6] Create `tests/violations/README.md` documenting the activation/revert protocol exactly as Research §7 (PowerShell `Copy-Item`/`Remove-Item` sequence per category), referencing this plan and the evidence destination. PASS: file exists with all five categories' commands listed.
- [x] [P6-T7] [expect-fail] Demonstrate the format gate: `Copy-Item tests/violations/format-violation.ts.disabled src/format-violation.ts`; run `npm run format:check`; capture stdout/stderr + EXIT_CODE to `evidence/qa-gates/violation-format.<timestamp>.txt`; `Remove-Item src/format-violation.ts`; re-run `npm run format:check` to confirm exit 0. PASS: artifact records EXIT_CODE non-zero during violation; post-revert format:check exits 0.
- [x] [P6-T8] [expect-fail] Demonstrate the lint gate: copy `tests/violations/lint-violation.ts.disabled` to `src/lint-violation.ts`; run `npm run lint`; capture to `evidence/qa-gates/violation-lint.<timestamp>.txt`; revert and confirm `npm run lint` exits 0. PASS: artifact records EXIT_CODE non-zero; post-revert lint exits 0.
- [x] [P6-T9] [expect-fail] Demonstrate the typecheck gate: copy `tests/violations/typecheck-violation.ts.disabled` to `src/typecheck-violation.ts`; run `npm run typecheck`; capture to `evidence/qa-gates/violation-typecheck.<timestamp>.txt`; revert and confirm `npm run typecheck` exits 0. PASS: artifact records EXIT_CODE non-zero; post-revert typecheck exits 0.
- [x] [P6-T10] [expect-fail] Demonstrate the architecture gate: copy `tests/violations/arch-violation.ts.disabled` to `src/commands/arch-violation.ts`; run `npm run depcruise`; capture to `evidence/qa-gates/violation-architecture.<timestamp>.txt`; revert and confirm `npm run depcruise` exits 0. PASS: artifact records EXIT_CODE non-zero with `commands-not-from-taskpane` (or `taskpane-not-from-commands`) rule fired; post-revert depcruise exits 0.
- [x] [P6-T11] [expect-fail] Demonstrate the test gate: copy `tests/violations/test-violation.test.ts.disabled` to `src/test-violation.test.ts`; run `npm test`; capture to `evidence/qa-gates/violation-test.<timestamp>.txt`; revert and confirm `npm test` exits 0. PASS: artifact records EXIT_CODE non-zero with the failed assertion in the output summary; post-revert test exits 0.
- [x] [P6-T12] Phase 6 restart gate: run `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm run depcruise`, `npm test`. Capture to `evidence/qa-gates/phase6-restart-gate.<timestamp>.md`. PASS: all five exit 0 in a single pass.

---

### Phase 7 — Final QA loop, coverage capture, and acceptance criteria check-off

- [x] [P7-T1] Final QA stage 1 — formatting: run `npm run format:check`; capture to `evidence/qa-gates/final-format.<timestamp>.txt` with all four schema fields. PASS: EXIT_CODE 0.
- [x] [P7-T2] Final QA stage 2 — linting: run `npm run lint`; capture to `evidence/qa-gates/final-lint.<timestamp>.txt`. PASS: EXIT_CODE 0.
- [x] [P7-T3] Final QA stage 3 — type checking: run `npm run typecheck`; capture to `evidence/qa-gates/final-typecheck.<timestamp>.txt`. PASS: EXIT_CODE 0.
- [x] [P7-T4] Final QA stage 4 — architecture: run `npm run depcruise`; capture to `evidence/qa-gates/final-depcruise.<timestamp>.txt`. PASS: EXIT_CODE 0.
- [x] [P7-T5] Final QA stage 5 — testing with coverage: run `npm run test:coverage`; capture to `evidence/qa-gates/final-test-coverage.<timestamp>.txt` with Output Summary including the numeric headline values for lines%, branches%, functions%, statements%. PASS: EXIT_CODE 0; recorded coverage values reflect post-change measurement (note: the sample-test scaffold may not yet hit 85/75 thresholds against production source; if vitest threshold failure occurs, record the numeric values and proceed to P7-T6 for delta verification).
- [x] [P7-T6] Coverage delta and threshold verification: write `evidence/qa-gates/coverage-delta.<timestamp>.md` containing `BaselineCoverage: n/a (no prior vitest baseline)`, `PostChangeCoverage:` (numeric values from P7-T5), `NewChangedCodeCoverage:` (numeric values from P7-T5 coverage report, since all changed code is new). Document threshold pass/fail per `quality-tiers.md` (line >= 85%, branch >= 75%). PASS: artifact written; if thresholds not met, mark the plan outcome `remediation-required` rather than `PASS`.
- [x] [P7-T7] If any of P7-T1..P7-T5 failed or autofixed files, return to the relevant phase task, repair, and restart the final QA loop from P7-T1. PASS: a single pass of P7-T1..P7-T5 completes with EXIT_CODE 0 across all five stages.
- [x] [P7-T8] Acceptance-criteria check-off: write `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/qa-gates/p7-acceptance-criteria-checkoff.md` listing all 30 acceptance criteria from `issue.md`, each annotated with the verification command (e.g., `npm run format:check`, `grep -E "strictTypeChecked" eslint.config.mjs`, `Select-String '"strict": true' tsconfig.json`, `Select-String 'no-floating-promises' eslint.config.mjs`, `npm run depcruise`, `npm test`, and references to the corresponding `evidence/qa-gates/violation-<category>.<timestamp>.txt` for AC 30) and a `PASS` or `FAIL` marker per AC. PASS: artifact lists 30 numbered entries and every AC is marked PASS.
- [x] [P7-T9] Mirror plan completion into issue update: write `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/issue-updates/issue-3.<timestamp>.md` with `Timestamp:`, the text of the planned issue comment summarizing the 30 AC verifications, `PostedAs: unknown` (or the actual value when posted), and a `POSTING BLOCKED` header only if posting was not attempted. PASS: artifact exists.

---

## Plan-Level Validation Contract

- Validator gate: this plan is unapproved until `mcp__drm-copilot__validate_orchestration_artifacts` returns success for `artifact_type: "plan"` and `artifact_path: docs/features/active/2026-05-10-establish-typescript-quality-gates-3/plan.md`.
- Preflight handoff signal: `PREFLIGHT: ALL CLEAR` or `PREFLIGHT: REVISIONS REQUIRED` — same file path is reused across iterations.
- Evidence location invariant: all evidence artifacts MUST be written under `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/{baseline,qa-gates,issue-updates,regression-testing,other,remediation-baseline}/`. No `artifacts/` subpath is permitted for evidence in this plan.
