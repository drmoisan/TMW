# Atomic Plan — Prompt A0: Establish Repository Foundation (Issue #1)

- Feature folder: `docs/features/active/2026-05-09-establish-repository-foundation-1/`
- Issue: 1
- Branch: `feature/establish-repository-foundation-1`
- Work Mode: full-feature
- Plan path (canonical, reused for every revision): `docs/features/active/2026-05-09-establish-repository-foundation-1/plan.md`

## Preamble

### Authoritative Decisions (non-negotiable, reflected in every applicable task)

1. **AD-1 (Black preserved):** Python formatting remains Black. The Python toolchain (Black + Ruff + Pyright + Pytest) is preserved across every rule, instruction, and skill file. No task in this plan replaces Black with `ruff format`.
2. **AD-2 (Uniform tier coverage):** Coverage thresholds are uniform across tiers T1 through T4: line coverage >= 85%, branch coverage >= 75%, no regression on changed lines. No tier-specific lower thresholds appear in any rule, instruction, skill, agent, or hook touched by this plan.

### Scope corrections from research artifact (`artifacts/research/2026-05-09-prompt-a0-foundation-baseline.md`)

- The Python contract tests that enforce `.codex/` and `.agents/` mirror parity live in `c:\Users\DanMoisan\repos\drm-copilot\` (a different repo). TMW is a downstream consumer. **This plan does NOT mirror `.claude/` edits into `.codex/` or `.agents/`.** Those trees are out of scope here.
- `.github/workflows/` does not exist; Phase 2f creates it from scratch.
- `package.json` has no test runner today. A0 references Vitest in rule prose but **does not** add Vitest as a dependency. Dependency installation is owned by Prompt B1.
- `CLAUDE.md` does not exist. Out of scope for A0.
- Branch protection rule application via `gh` CLI may not be possible in the executor session. AC #23 is satisfied by a documentation artifact (Phase 2g) plus a recorded manual follow-up.

### Mirror discipline

Every `.claude/rules/<name>.md` task is paired with a `.github/instructions/<name>-*.instructions.md` task in the same phase. New rule files create both `.claude/rules/<name>.md` and `.github/instructions/<name>.instructions.md` companions. No `.codex/` or `.agents/` mirror tasks appear in this plan (see scope correction above).

### Evidence location invariant

All evidence written by tasks in this plan resolves to `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/`. Allowed `<kind>` sub-paths used in this plan: `baseline/`, `qa-gates/`, `regression-testing/`, `other/`, `issue-updates/`. The non-canonical paths `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, `artifacts/evidence/` are forbidden.

### Acceptance Criteria coverage map (from `issue.md` lines 22–54)

| AC # | Phase(s) covering it |
|---|---|
| 1 | Phase 1a (quality-tiers) |
| 2 | Phase 1a (architecture-boundaries) |
| 3 | Phase 1c (TS rule trio Jest -> Vitest) |
| 4 | Phase 1c (TS rule trio VS Code -> Outlook) |
| 5 | Phase 1c (TS rule trio new subsections) |
| 6 | Phase 1c (TS Coverage Requirements) |
| 7 | Phase 1b (general-unit-test) |
| 8 | Phase 1b (general-code-change) |
| 9 | Phase 1d (atomic-executor) |
| 10 | Phase 1d (typescript-engineer.agent.md) |
| 11 | Phase 1d (feature-review.md) |
| 12 | Phase 1d (validate-feature-review-coverage.ps1) |
| 13 | Phase 1d (feature-review-workflow SKILL) |
| 14 | Phase 1d (python-qa-gate, powershell-qa-gate SKILLs) |
| 15 | Phase 1b (python.md trio) |
| 16 | Phase 1b (powershell.md trio) |
| 17 | Phase 2a (quality-tiers.yml + validator) |
| 18 | Phase 2b (lefthook) |
| 19 | Phase 2c (gitleaks) |
| 20 | Phase 2d (commitlint commit-msg) |
| 21 | Phase 2e (Renovate) |
| 22 | Phase 2f (workflows + composite actions) |
| 23 | Phase 2g (branch protection doc) |

### Toolchain gates per task

Markdown-only edits state `Gate: no toolchain gate (markdown only)`. PowerShell edits state `Gate: PSScriptAnalyzer + Pester (run via MCP)`. YAML/JSON edits state `Gate: yaml/json syntax check (Get-Content + ConvertFrom-* or actionlint where applicable)`. JavaScript edits state `Gate: node --check`.

---

### Phase 0 — Preflight & Baseline Capture

- [x] [P0-T1] Read `.claude/rules/general-code-change.md` in full. Record file presence and line count to `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/baseline/phase0-policy-read-general-code-change.md` with fields `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (line count + frontmatter present yes/no). Gate: no toolchain gate (markdown only).
- [x] [P0-T2] Read `.claude/rules/general-unit-test.md` in full. Record to `evidence/baseline/phase0-policy-read-general-unit-test.md` with the same four fields. Gate: no toolchain gate (markdown only).
- [x] [P0-T3] Read `.claude/rules/typescript.md` in full. Record to `evidence/baseline/phase0-policy-read-typescript.md`. Gate: no toolchain gate (markdown only).
- [x] [P0-T4] Read `.claude/rules/python.md` in full. Record to `evidence/baseline/phase0-policy-read-python.md`. Gate: no toolchain gate (markdown only).
- [x] [P0-T5] Read `.claude/rules/powershell.md` in full. Record to `evidence/baseline/phase0-policy-read-powershell.md`. Gate: no toolchain gate (markdown only).
- [x] [P0-T6] Read `.claude/rules/tonality.md` in full. Record to `evidence/baseline/phase0-policy-read-tonality.md`. Gate: no toolchain gate (markdown only).
- [x] [P0-T7] Read `artifacts/research/2026-05-09-prompt-a0-foundation-baseline.md` in full and confirm presence of: Section 2b table (file-creation frontmatter), Section 3a–3d (exact-quote excerpts), Section 5 (hygiene tooling research), Section 6 (validation matrix), Appendix C (No-COM Architecture rules). Record artifact to `evidence/baseline/phase0-research-artifact-presence.md` with `Output Summary:` listing present sections. Gate: no toolchain gate (markdown only).
- [x] [P0-T8] Read `docs/ci.research.md` lines 109–123 (gate threshold matrix). Record to `evidence/baseline/phase0-ci-research-matrix.md` with the matrix copy and a one-line note that AD-2 overrides tier-specific coverage floors. Gate: no toolchain gate (markdown only).
- [x] [P0-T9] Read `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` lines 595–703 (the source A0 prompt). Record to `evidence/baseline/phase0-source-prompt.md`. Gate: no toolchain gate (markdown only).
- [x] [P0-T10] Verify branch `feature/establish-repository-foundation-1` is checked out via `git rev-parse --abbrev-ref HEAD`. Record to `evidence/baseline/phase0-branch-check.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`. PASS only if branch name matches exactly. Gate: shell.
- [x] [P0-T11] Verify feature folder `docs/features/active/2026-05-09-establish-repository-foundation-1/` exists and contains `issue.md`. Record to `evidence/baseline/phase0-feature-folder-check.md`. PASS only if both checks succeed. Gate: shell.
- [x] [P0-T12] Run `git status --porcelain` and verify the only modified file outside the feature folder is `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (already on disk per repo state). Record full output to `evidence/baseline/phase0-git-status.md`. PASS only if no stray edits to `src/`, `package.json`, `.claude/`, or `.github/` are present. Gate: shell.
- [x] [P0-T13] Capture TypeScript baseline: run `npm run lint` and persist exit code + summary to `evidence/baseline/phase0-baseline-ts-lint.md` (`Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`). Note: A0 makes no `*.ts` edits; this baseline establishes pre-state. Gate: ESLint via repo script.
- [x] [P0-T14] Capture TypeScript typecheck baseline: `npm run typecheck`. Persist to `evidence/baseline/phase0-baseline-ts-typecheck.md` with the four fields. Gate: tsc via repo script.
- [x] [P0-T15] Capture PowerShell hook script baseline: invoke `mcp__drm-copilot__run_poshqc_analyze` against `.claude/hooks/validate-feature-review-coverage.ps1` (the only PS1 file edited in A0). Persist to `evidence/baseline/phase0-baseline-ps-analyze.md`. Note in `Output Summary:` whether any analyzer warnings are pre-existing. Gate: PSScriptAnalyzer via MCP.
- [x] [P0-T16] Capture PowerShell test baseline: invoke `mcp__drm-copilot__run_poshqc_test` (Pester) against any existing tests for `validate-feature-review-coverage.ps1`. If none exist, record `EXIT_CODE: NO_TESTS_PRESENT` and `Output Summary: no Pester tests for hook script in repo` in `evidence/baseline/phase0-baseline-ps-test.md`. Gate: Pester via MCP.
- [x] [P0-T17] Capture YAML lint baseline for new `.github/workflows/` directory: run `Get-ChildItem .github/workflows -ErrorAction SilentlyContinue` and confirm directory absence. Persist to `evidence/baseline/phase0-baseline-workflows-absence.md` with `Output Summary: directory does not exist (confirmed pre-state).` Gate: shell.
- [x] [P0-T18] PASS/FAIL gate: confirm tasks P0-T1 through P0-T17 each produced a complete artifact with all four schema fields. If any artifact is missing or incomplete, FAIL Phase 0 and halt. Record verdict to `evidence/baseline/phase0-gate.md`.

---

### Phase 1a — Create New Rule Files (quality-tiers + architecture-boundaries)

- [x] [P1a-T1] Create `.claude/rules/quality-tiers.md` with the full body shown below. Frontmatter per research §2b: `paths: ["**"]`. Maps AC #1. Gate: no toolchain gate (markdown only).

  Full file body:

  ```markdown
  ---
  paths:
    - "**"
  description: Module rigor tier system and uniform coverage thresholds.
  ---

  # Module Rigor Tiers

  This rule defines the T1–T4 module rigor tier system used by all CI gates in this repository. The tier system source of truth is `docs/ci.research.md` section 1; the file `quality-tiers.yml` at the repository root maps every project to a tier. Adding a project without a tier classification fails CI.

  ## Tiers

  - **T1 — Critical.** Behavior bugs cause silent data loss, model drift, or security holes. Examples (No-COM architecture): classifier engines (SpamBayes, Triage), ToDo ID allocator and hierarchy operations, Graph extended-properties adapter, auth/token handling, host-agnostic command bus.
  - **T2 — Core.** Bugs cause feature regressions but not data loss. Examples: `TaskMaster.Domain`, `TaskMaster.Application`, mail-item DTOs, settings store abstraction, schema definitions.
  - **T3 — Adapters & UI.** Glue around APIs the team does not own. Examples: Outlook task pane UI, Office.js wrappers, Microsoft Graph SDK wrappers, persistence I/O.
  - **T4 — Scaffolding.** Examples: DI wiring, bootstrap, build scripts, dev tooling, generated code, manifests.

  ## Source of Truth

  - `quality-tiers.yml` at repo root maps every project to one tier.
  - The CI pipeline's `tier-classification` stage validates that every project entry has a tier and that no unclassified project exists. Adding a project without a tier classification fails CI.

  ## Uniform-vs-Tier-Dependent Gate Matrix

  Per Authoritative Decision #2, line and branch coverage thresholds are uniform across all tiers. Other gates remain tier-dependent.

  ### Uniform across all tiers (T1–T4)

  - Format check: 100% pass.
  - Lint errors: 0.
  - Type errors: 0.
  - Architecture violations: 0.
  - Line coverage: >= 85%.
  - Branch coverage: >= 75%.
  - No regression on changed lines.

  ### Tier-dependent

  | Gate | T1 | T2 | T3 | T4 |
  |---|---|---|---|---|
  | Untyped escape hatches (`any`/`dynamic`) | 0 | 0 | <= 5 per file, justified | unlimited |
  | Property test density | >= 1 per pure function | >= 1 per pure function | none | none |
  | Mutation score | >= 75% | trend-only | none | none |
  | Contract breaking changes | major bump required | major bump required | n/a | n/a |
  | Benchmark p99 regression | < 5% | < 10% | none | none |
  | Determinism (retry rate) | < 0.5% | < 1% | < 2% | n/a |
  | Golden tests | required for classifier-output modules | optional | none | none |
  | Full E2E suite scope | all critical paths | core paths | adapter smoke | none |

  ## Rationale (uniform coverage thresholds)

  High test coverage is a fundamental quality-control design choice that enables autonomous agentic development and trust in the work product. For that reason, line coverage >= 85% and branch coverage >= 75% apply uniformly across T1–T4; tier-specific lower coverage floors are not used in this repository.
  ```

- [x] [P1a-T2] Create `.github/instructions/quality-tiers.instructions.md` mirroring the body of P1a-T1 with frontmatter per research §2b: `applyTo: "**"`, `description: "Module rigor tier system and uniform coverage thresholds."`, `name: quality-tiers-policy`. Body identical to P1a-T1 minus the frontmatter block. Maps AC #1. Gate: no toolchain gate (markdown only).
- [x] [P1a-T3] Create `.claude/rules/architecture-boundaries.md` with the full body shown below. Frontmatter: `paths: ["**/*.ts","**/*.cs"]`. Maps AC #2. Gate: no toolchain gate (markdown only).

  Full file body:

  ```markdown
  ---
  paths:
    - "**/*.ts"
    - "**/*.cs"
  description: Architecture boundary enforcement rules for the No-COM architecture.
  ---

  # Architecture Boundaries

  Architecture boundary enforcement is a uniform gate across all tiers (T1–T4). Violations block PRs.

  ## Enforcement Tools

  - **TypeScript:** `dependency-cruiser`. Configuration file pattern: `.dependency-cruiser.cjs`.
  - **.NET (when the backend exists):** `NetArchTest.Rules`. Test project naming pattern: `*.ArchitectureTests`.

  ## No-COM Architecture Rules (enforceable assertions)

  Production code in this repository must satisfy each of the following assertions. Each assertion is enforced by `dependency-cruiser` (TypeScript) or `NetArchTest.Rules` (.NET) where applicable; legacy import utilities, when added, must satisfy the same assertions.

  1. New runtime code must not reference VSTO APIs (`Microsoft.Office.Tools.*`).
  2. New runtime code must not reference Outlook desktop automation APIs (`Microsoft.Office.Interop.Outlook`).
  3. New runtime code must not expose COM-visible interfaces (`[ComVisible(true)]` attribute is banned in production code).
  4. New runtime code must not use Ribbon extensibility callbacks tied to the desktop object model.
  5. New runtime code must not depend on local Outlook event streams.
  6. New runtime code must not depend on Outlook user-defined fields as the primary state store.
  7. Mailbox data must be accessed only through Office.js or Microsoft Graph.
  8. Business behavior must be implemented in the backend or in host-neutral domain or application modules.
  9. Client UI must be implemented as web UI.
  10. Legacy integration, when required, must be limited to offline data import from files or exported data.

  ## Layer Boundary Assertions (TypeScript)

  - `src/taskpane/` and `src/commands/` must not import from backend internals.
  - Domain modules must not import from Office.js, Microsoft Graph SDK, or any infrastructure adapter.
  - Adapters may import from domain; domain must not import from adapters.

  ## Layer Boundary Assertions (.NET, applies once the backend exists)

  - `TaskMaster.Domain` must have zero references to Outlook PIA, VSTO, or Office.js types.
  - `TaskMaster.Application` may depend on `TaskMaster.Domain` only.
  - Adapter projects may depend on `TaskMaster.Domain` and `TaskMaster.Application`; domain may not depend on adapters.

  ## Enforcement Outcome

  Violations of any rule above are PR-blocking findings. CI runs the architecture-boundary stage on every PR; a non-zero violation count fails the stage and prevents merge.
  ```

- [x] [P1a-T4] Create `.github/instructions/architecture-boundaries.instructions.md` mirroring P1a-T3 with frontmatter: `applyTo: "**/*.ts,**/*.cs"`, `description: "Architecture boundary enforcement rules for the No-COM architecture."`, `name: architecture-boundaries-policy`. Body identical to P1a-T3 minus the frontmatter block. Maps AC #2. Gate: no toolchain gate (markdown only).
- [x] [P1a-T5] Verify all four files (P1a-T1..T4) exist on disk and contain valid YAML frontmatter (open delimiters `---` ... `---`). Record to `evidence/qa-gates/p1a-newfile-presence.md`. Gate: shell.

---

### Phase 1b — Update Existing Rule Files (coverage thresholds + general policies + python/powershell coverage prose)

#### general-unit-test pair (AC #7)

- [x] [P1b-T1] In `.claude/rules/general-unit-test.md`, replace lines 23–25 exactly. Pre-edit content (verbatim):

  ```
  - **Repository-wide line coverage must remain >= 80%.**
  - **Any new module, class, or method must target >= 90% coverage.**
  - Code changes or refactors must not reduce coverage for the lines that were changed.
  ```

  Post-edit content:

  ```
  - **Line coverage must remain >= 85% across all tiers (T1–T4).**
  - **Branch coverage must remain >= 75% across all tiers (T1–T4).**
  - Code changes or refactors must not reduce coverage for the lines that were changed.
  - Tier-specific lower coverage thresholds are not used in this repository. See `.claude/rules/quality-tiers.md` for the full tier system.
  ```

  Maps AC #7. Gate: no toolchain gate (markdown only).

- [x] [P1b-T2] In `.claude/rules/general-unit-test.md`, append a new section `## Test Categories` (after the existing `## Documentation` section) with the bullets specified by AC #7: unit tests (all tiers), property-based tests (T1/T2, >= 1 per pure function), golden/snapshot tests (T1 classifier outputs only, against a versioned corpus), contract/schema tests (host-service boundary), mutation tests (T1 only, >= 75% mutation score), integration tests. Maps AC #7. Gate: no toolchain gate (markdown only).
- [x] [P1b-T3] In `.claude/rules/general-unit-test.md`, append a new section `## Determinism Infrastructure` requiring: controllable clock (`Clock` for TS, `TimeProvider` for .NET); seeded RNG with seed printed on test failure; banned APIs in test code (`setTimeout`, `Thread.Sleep`, `Task.Delay`, real wall-clock waits, `Date.now()` outside the clock interface); virtual scheduler / fake timers / `FakeTimeProvider` for async tests. Maps AC #7. Gate: no toolchain gate (markdown only).
- [x] [P1b-T4] In `.github/instructions/general-unit-test.instructions.md`, replace the coverage-threshold prose (research §3c lines 38–43 of that file). Pre-edit content (verbatim):

  ```
    - Repository-wide line coverage must remain `>= 80%`.
    - Any new modules, classes, or methods added must target `>= 90%` coverage.
    - Code changes or refactors must not reduce coverage for the lines that were changed.
  ```

  Post-edit content:

  ```
    - Line coverage must remain `>= 85%` across all tiers (T1–T4).
    - Branch coverage must remain `>= 75%` across all tiers (T1–T4).
    - Code changes or refactors must not reduce coverage for the lines that were changed.
    - Tier-specific lower coverage thresholds are not used. See `.github/instructions/quality-tiers.instructions.md`.
  ```

  Maps AC #7. Gate: no toolchain gate (markdown only).

- [x] [P1b-T5] In `.github/instructions/general-unit-test.instructions.md`, append `## Test Categories` and `## Determinism Infrastructure` sections that mirror the body added in P1b-T2 and P1b-T3. Maps AC #7. Gate: no toolchain gate (markdown only).

#### general-code-change pair (AC #8)

- [x] [P1b-T6] In `.claude/rules/general-code-change.md`, replace the `## Mandatory Toolchain Loop` section (lines 27–36) with a seven-stage loop. Pre-edit content (verbatim from current file lines 27–36):

  ```
  ## Mandatory Toolchain Loop

  Run the full toolchain in this exact order and repeat until all steps pass in a single pass:

  1. **Formatting** (e.g., Black, Prettier, CSharpier, Invoke-Formatter)
  2. **Linting** (e.g., Ruff, ESLint, PSScriptAnalyzer, .NET analyzers)
  3. **Type checking** (e.g., Pyright, TSC, nullable analysis; skip for PowerShell)
  4. **Testing** (e.g., Pytest, Jest, MSTest, Pester)

  **Restart from step 1** if any step fails or auto-fixes any files. Do not stop the loop until all four steps complete without errors in a single pass.
  ```

  Post-edit content:

  ```
  ## Mandatory Toolchain Loop

  Run the full seven-stage toolchain in this exact order and repeat until all stages pass in a single pass:

  1. **Formatting** (e.g., Black, Prettier, CSharpier, Invoke-Formatter)
  2. **Linting** (e.g., Ruff, ESLint, PSScriptAnalyzer, .NET analyzers)
  3. **Type checking** (e.g., Pyright, TSC, nullable analysis; skip for PowerShell)
  4. **Architecture-boundary tests** (e.g., dependency-cruiser, NetArchTest.Rules)
  5. **Unit tests** (e.g., Pytest, Vitest, MSTest, Pester) including property-based tests where applicable per `quality-tiers.md`
  6. **Contract / schema compatibility checks** (e.g., oasdiff, schema-snapshot diff)
  7. **Integration tests**

  **Restart from step 1** if any stage fails or auto-fixes any files. Do not stop the loop until all seven stages complete without errors in a single pass.

  Mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines, not the per-commit loop.
  ```

  Maps AC #8. Gate: no toolchain gate (markdown only).

- [x] [P1b-T7] In `.claude/rules/general-code-change.md`, insert a `## Module Rigor Tiers` section immediately before `## Mandatory Toolchain Loop`. Body: `Module rigor tiers (T1–T4) and the uniform-versus-tier-dependent gate matrix are defined in `.claude/rules/quality-tiers.md`. Every project must be classified in `quality-tiers.yml` at repo root.` Maps AC #8. Gate: no toolchain gate (markdown only).
- [x] [P1b-T8] In `.github/instructions/general-code-change.instructions.md`, apply the same Mandatory Toolchain Loop expansion (4 stages -> 7 stages) and add `## Module Rigor Tiers` section pointing to `.github/instructions/quality-tiers.instructions.md`. Pre-edit/post-edit text mirrors P1b-T6/P1b-T7 with the file's existing wording. Maps AC #8. Gate: no toolchain gate (markdown only).

#### python coverage prose trio (AC #15)

- [x] [P1b-T9] In `.claude/rules/python.md`, replace line 16 (toolchain entry 4). Pre-edit content (verbatim):

  ```
  4. **Testing — Pytest**: All tests use Pytest. New logic must have test coverage >= 90%. Command: `poetry run pytest --cov --cov-report=term-missing`
  ```

  Post-edit content:

  ```
  4. **Testing — Pytest**: All tests use Pytest. Coverage thresholds are uniform across tiers per `.claude/rules/quality-tiers.md` (>= 85% line, >= 75% branch). Command: `poetry run pytest --cov --cov-branch --cov-report=term-missing`
  ```

  Maps AC #15. Gate: no toolchain gate (markdown only).

- [x] [P1b-T10] In `.claude/rules/python.md`, replace lines 88–90 (Pytest Rules block). Pre-edit content (verbatim):

  ```
  - Repository-wide line coverage must remain >= 80%.
  - Any new module, class, or method must reach >= 90% coverage.
  - Coverage regression on changed lines is a blocking finding.
  ```

  Post-edit content:

  ```
  - Line coverage must remain >= 85% across all tiers (T1–T4) per `.claude/rules/quality-tiers.md`.
  - Branch coverage must remain >= 75% across all tiers (T1–T4).
  - Coverage regression on changed lines is a blocking finding.
  ```

  Black, Ruff, Pyright, and Pytest references elsewhere in the file remain unchanged (AD-1). Maps AC #15. Gate: no toolchain gate (markdown only).

- [x] [P1b-T11] In `.github/instructions/python-code-change.instructions.md`, add a one-paragraph note in the Testing section confirming that coverage thresholds defer to the unit test policy and the uniform tier rule (`>= 85%` line, `>= 75%` branch). Do not modify Black/Ruff/Pyright/Pytest tool references. Maps AC #15. Gate: no toolchain gate (markdown only).
- [x] [P1b-T12] In `.github/instructions/python-unit-test.instructions.md`, replace the coverage-related sentence near line 26 with explicit prose: `All new Python logic must be covered by Pytest tests with line coverage >= 85% and branch coverage >= 75%, uniform across all tiers per `.github/instructions/quality-tiers.instructions.md`. Coverage regression on changed lines is a blocking finding.` Maps AC #15. Gate: no toolchain gate (markdown only).

#### powershell coverage prose trio (AC #16)

- [x] [P1b-T13] In `.claude/rules/powershell.md`, replace lines 63–65 (Testing Standards). Pre-edit content (verbatim):

  ```
  - Repository-wide line coverage must remain >= 80%.
  - Any new module, class, or method must reach >= 90% coverage.
  - Coverage regression on changed lines is a blocking finding.
  ```

  Post-edit content:

  ```
  - Line coverage must remain >= 85% across all tiers (T1–T4) per `.claude/rules/quality-tiers.md`.
  - Branch coverage must remain >= 75% across all tiers (T1–T4).
  - Coverage regression on changed lines is a blocking finding.
  ```

  Invoke-Formatter, PSScriptAnalyzer, and Pester references elsewhere in the file remain unchanged. Maps AC #16. Gate: no toolchain gate (markdown only).

- [x] [P1b-T14] In `.github/instructions/powershell-code-change.instructions.md`, append a paragraph noting that coverage thresholds follow the uniform tier rule (`>= 85%` line, `>= 75%` branch). Do not modify formatter/analyzer/test runner references. Maps AC #16. Gate: no toolchain gate (markdown only).
- [x] [P1b-T15] In `.github/instructions/powershell-unit-test.instructions.md`, add explicit prose: `All new PowerShell logic must be covered by Pester tests with line coverage >= 85% and branch coverage >= 75%, uniform across all tiers per `.github/instructions/quality-tiers.instructions.md`. Coverage regression on changed lines is a blocking finding.` Maps AC #16. Gate: no toolchain gate (markdown only).

---

### Phase 1c — TypeScript Rule Trio Updates (AC #3, #4, #5, #6)

The trio: `.claude/rules/typescript.md`, `.github/instructions/typescript-code-change.instructions.md`, `.github/instructions/typescript-unit-test.instructions.md`. Source quotations are taken from research §3a, §3b, §3c, §3d.

#### Jest -> Vitest (AC #3)

- [x] [P1c-T1] In `.claude/rules/typescript.md` line 16, replace `4. **Testing — Jest**: All TypeScript unit tests must use Jest. Command: \`npm run test:unit\`` with `4. **Testing — Vitest**: All TypeScript unit tests must use Vitest. Command: \`npm run test\``. Note: `package.json` script wiring is owned by Prompt B1; this rule states the eventual command name. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T2] In `.claude/rules/typescript.md` line 34, replace `- Use **Jest** as the test framework.` with `- Use **Vitest** as the test framework.`. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T3] In `.claude/rules/typescript.md` line 39, replace `- Use \`jest.spyOn\` or \`jest.mock\` for targeted mocking; reset mocks with \`afterEach(() => { jest.resetAllMocks(); })\`.` with `- Use \`vi.spyOn\` or \`vi.mock\` for targeted mocking; reset mocks with \`afterEach(() => { vi.resetAllMocks(); })\`.`. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T4] In `.claude/rules/typescript.md` line 35, confirm the `*.test.ts` filename convention is preserved verbatim (`- Name test files \`*.test.ts\`.`). No edit if already present; this task is a presence check. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T5] In `.github/instructions/typescript-code-change.instructions.md` line 49, replace the Jest block (research §3a lines 93–96 of research artifact). Pre-edit content (verbatim):

  ```
  4. **Testing — Jest**

     - TypeScript unit tests must pass Jest.
     - Approved command: `npm run test:unit`
  ```

  Post-edit content:

  ```
  4. **Testing — Vitest**

     - TypeScript unit tests must pass Vitest.
     - Approved command: `npm run test`
  ```

  Maps AC #3. Gate: no toolchain gate (markdown only).

- [x] [P1c-T6] In `.github/instructions/typescript-unit-test.instructions.md` lines 24–27 (the Framework and Scope opening), replace `All TypeScript unit tests must use **Jest**.` with `All TypeScript unit tests must use **Vitest**.`. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T7] In `.github/instructions/typescript-unit-test.instructions.md` lines 82–89 (Mocking guidance / Resetting mocks), replace `jest.spyOn(obj, 'method')` -> `vi.spyOn(obj, 'method')`, `jest.mock('module')` -> `vi.mock('module')`, `afterEach(() => { jest.resetAllMocks(); });` -> `afterEach(() => { vi.resetAllMocks(); });`. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T8] In `.github/instructions/typescript-unit-test.instructions.md` lines 92–95 (Time and timers), replace `jest.useFakeTimers()` with `vi.useFakeTimers()`. Maps AC #3. Gate: no toolchain gate (markdown only).
- [x] [P1c-T9] In `.github/instructions/typescript-unit-test.instructions.md` lines 107–111 (Required Commands), replace `npm run test:unit` with `npm run test`. Maps AC #3. Gate: no toolchain gate (markdown only).

#### VS Code extension -> Outlook (AC #4)

- [x] [P1c-T10] In `.claude/rules/typescript.md` line 28 (Separation of concerns), replace `- **Separation of concerns**: Keep pure logic separate from VS Code extension APIs, filesystem/network I/O, and UI wiring.` with `- **Separation of concerns**: Keep pure logic separate from Office.js, Microsoft Graph SDK, and other host-bound APIs, filesystem/network I/O, and UI wiring.`. Maps AC #4. Gate: no toolchain gate (markdown only).
- [x] [P1c-T11] In `.claude/rules/typescript.md` line 36, replace `- Unit tests must not require the VS Code extension host.` with `- Unit tests must not require the Outlook host runtime.`. Maps AC #4. Gate: no toolchain gate (markdown only).
- [x] [P1c-T12] In `.github/instructions/typescript-code-change.instructions.md` lines 74–79 (Separation of concerns block), replace pre-edit content (research §3b):

  ```
  4. **Separation of concerns**

     - Keep pure logic separate from:
       - VS Code extension APIs
       - filesystem/network I/O
       - UI/presentation wiring
     - Write core logic so it can be unit tested without VS Code host processes.
  ```

  with:

  ```
  4. **Separation of concerns**

     - Keep pure logic separate from:
       - Office.js, Microsoft Graph SDK, and other host-bound APIs
       - filesystem/network I/O
       - UI/presentation wiring
     - Write core logic so it can be unit tested without the Outlook host runtime.
  ```

  Maps AC #4. Gate: no toolchain gate (markdown only).

- [x] [P1c-T13] In `.github/instructions/typescript-code-change.instructions.md` line 185 (section heading), replace `## 9. UI/UX and Lifecycle Hygiene (VS Code Extension Context)` with `## 9. UI/UX and Lifecycle Hygiene (Outlook Add-in Lifecycle)`. Maps AC #4. Gate: no toolchain gate (markdown only).
- [x] [P1c-T14] In `.github/instructions/typescript-unit-test.instructions.md` lines 28–30, replace `Unit tests must not require launching the VS Code extension host or depending on a live VS Code environment.` with `Unit tests must not require launching the Outlook host runtime or depending on a live Outlook web add-in context.`. Maps AC #4. Gate: no toolchain gate (markdown only).

#### New TS subsections (AC #5)

- [x] [P1c-T15] In `.claude/rules/typescript.md`, append a new subsection `## ESLint Stack` after `## Coding Standards`. Body: requires `typescript-eslint` strict-type-checked + stylistic-type-checked; type-aware parsing (`parserOptions.project = true`); `eslint-plugin-office-addins`, `eslint-plugin-promise`, `eslint-plugin-security`, `eslint-plugin-import`; error-level `no-floating-promises`, `no-misused-promises`, `no-unsafe-*`; `no-restricted-syntax` rule banning `Date.now`, `setTimeout`, `setInterval`, `Math.random` outside an explicit infrastructure allowlist. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T16] In `.claude/rules/typescript.md`, append `## Architecture Boundaries` referencing `.claude/rules/architecture-boundaries.md` as the source of layer rules and naming `dependency-cruiser` with `.dependency-cruiser.cjs` as the enforcement tool. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T17] In `.claude/rules/typescript.md`, append `## Property-Based and Mutation Testing`. Body: `fast-check` provides property-based tests; T1 and T2 modules require >= 1 property test per pure function. `StrykerJS` provides mutation testing; T1 modules require mutation score >= 75%. Both run in pre-merge or nightly pipelines per `general-code-change.md`. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T18] In `.claude/rules/typescript.md`, append `## Golden Tests`. Body: T1 classifier modules require golden-output snapshots tested against a versioned corpus; the existing `Avoid snapshot tests unless stable and intentional` guidance remains in force for all other scenarios but is softened to permit classifier-output and schema-evolution snapshots when those are explicitly versioned. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T19] In `.claude/rules/typescript.md`, append `## Runtime Determinism`. Body: `Date`, `Math.random`, and `setTimeout` access must flow through an injected `Clock` / `Random` interface; tests use Vitest fake timers (`vi.useFakeTimers()`); prefer `await flushPromises()` over `setTimeout(0)` for awaiting micro-tasks. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T20] In `.github/instructions/typescript-code-change.instructions.md`, mirror P1c-T15 (ESLint stack), P1c-T16 (Architecture boundaries), and P1c-T19 (Runtime determinism) as new sections. Maps AC #5. Gate: no toolchain gate (markdown only).
- [x] [P1c-T21] In `.github/instructions/typescript-unit-test.instructions.md`, mirror P1c-T17 (Property-based and mutation testing), P1c-T18 (Golden tests), and P1c-T19 (Runtime determinism) as new sections. Maps AC #5. Gate: no toolchain gate (markdown only).

#### TS Coverage Requirements update (AC #6)

- [x] [P1c-T22] In `.claude/rules/typescript.md`, replace lines 42–45 (research §3c). Pre-edit content (verbatim):

  ```
  - Repository-wide line coverage must remain >= 80%.
  - Any new module, class, or method must reach >= 90% coverage.
  - Coverage command: `npm run test:unit:coverage`
  - Coverage regression on changed lines is a blocking finding.
  ```

  Post-edit content:

  ```
  - Coverage thresholds follow the uniform tier rule defined in `.claude/rules/quality-tiers.md`: line coverage >= 85% and branch coverage >= 75% across all tiers (T1–T4).
  - Coverage command: `npm run test:coverage` (the script is wired in Prompt B1 alongside the Vitest dependency).
  - Coverage regression on changed lines is a blocking finding.
  ```

  Maps AC #6. Gate: no toolchain gate (markdown only).

- [x] [P1c-T23] In `.github/instructions/typescript-unit-test.instructions.md`, replace any coverage threshold prose with the same uniform tier rule and reference `.github/instructions/quality-tiers.instructions.md`. Maps AC #6. Gate: no toolchain gate (markdown only).
- [x] [P1c-T24] In `.github/instructions/typescript-code-change.instructions.md`, replace any coverage threshold prose with the uniform tier rule reference. Maps AC #6. Gate: no toolchain gate (markdown only).

---

### Phase 1d — Operational Artifact Updates (AC #9, #10, #11, #12, #13, #14)

#### atomic-executor (AC #9)

- [x] [P1d-T1] In `.claude/agents/atomic-executor.md` lines 16–17 (tools allowlist), replace `"Bash(npx jest *)"` with `"Bash(npx vitest *)"`. Maps AC #9. Gate: no toolchain gate (markdown only).
- [x] [P1d-T2] In `.claude/agents/atomic-executor.md` line 78 (toolchain reference table), replace `- **TypeScript**: \`npx prettier\`, \`npx eslint\`, \`npx tsc\`, \`npx jest\`` with `- **TypeScript**: \`npx prettier\`, \`npx eslint\`, \`npx tsc\`, \`npx vitest\``. Maps AC #9. Gate: no toolchain gate (markdown only).

#### typescript-engineer.agent.md (AC #10)

- [x] [P1d-T3] In `.github/agents/typescript-engineer.agent.md` line 8 (TDD Red Phase handoff), replace `Write the smallest failing Jest test(s)` with `Write the smallest failing Vitest test(s)`. Maps AC #10. Gate: no toolchain gate (markdown only).
- [x] [P1d-T4] In `.github/agents/typescript-engineer.agent.md` line 29 (separation of concerns), replace pre-edit content (research §3b):

  ```
  - Keep VS Code API usage behind thin adapters.
  - Put pure logic in modules that can be unit tested under Jest without the extension host.
  ```

  with:

  ```
  - Keep Office.js and Microsoft Graph SDK usage behind thin adapters.
  - Put pure logic in modules that can be unit tested under Vitest without the Outlook host runtime.
  ```

  Maps AC #10. Gate: no toolchain gate (markdown only).

- [x] [P1d-T5] In `.github/agents/typescript-engineer.agent.md` line 34, replace `- Deterministic Jest unit tests that do not require the VS Code extension host` with `- Deterministic Vitest unit tests that do not require the Outlook host runtime`. Maps AC #10. Gate: no toolchain gate (markdown only).
- [x] [P1d-T6] In `.github/agents/typescript-engineer.agent.md` line 100 (Unit test boundary), replace `Unit tests MUST NOT launch the VS Code extension host.` with `Unit tests MUST NOT launch the Outlook host runtime.`. Maps AC #10. Gate: no toolchain gate (markdown only).
- [x] [P1d-T7] In `.github/agents/typescript-engineer.agent.md` line 135, replace `- Deterministic Jest unit tests that do not require the VS Code extension host` (second occurrence) with `- Deterministic Vitest unit tests that do not require the Outlook host runtime`. Maps AC #10. Gate: no toolchain gate (markdown only).
- [x] [P1d-T8] In `.github/agents/typescript-engineer.agent.md` line 136 (section heading) and lines 137–138 (body), replace pre-edit content (research §3a):

  ```
  ## Jest unit test standards

  - Use `afterEach(() => { jest.resetAllMocks(); })` for isolation.
  - Use fake timers or injected clocks when time is involved.
  ```

  with:

  ```
  ## Vitest unit test standards

  - Use `afterEach(() => { vi.resetAllMocks(); })` for isolation.
  - Use Vitest fake timers (`vi.useFakeTimers()`) or injected clocks when time is involved.
  ```

  Maps AC #10. Gate: no toolchain gate (markdown only).

- [x] [P1d-T9] In `.github/agents/typescript-engineer.agent.md` lines 143–144, replace `Hand off the red phase to the **"TDD Red Phase - Write Failing Tests First"** agent (via the configured \`handoffs\` entry) and use the returned failing Jest test(s) + failure output as the spec.` with `Hand off the red phase to the **"TDD Red Phase - Write Failing Tests First"** agent (via the configured \`handoffs\` entry) and use the returned failing Vitest test(s) + failure output as the spec.`. Maps AC #10. Gate: no toolchain gate (markdown only).
- [x] [P1d-T10] In `.github/agents/typescript-engineer.agent.md`, sweep for any remaining `jest.spyOn`, `jest.mock`, `jest.useFakeTimers`, `jest.resetAllMocks` tokens not covered by P1d-T3..T9 and replace each with the `vi.*` equivalent. Maps AC #10. Gate: no toolchain gate (markdown only).

#### feature-review.md coverage (AC #11)

- [x] [P1d-T11] In `.claude/agents/feature-review.md` lines 109–112, replace pre-edit content (research §3c):

  ```
  ### Coverage Thresholds

  - **New code files** (files added in this feature, not previously existing): line coverage must be >= 90%.
  - **Modified files** (files that existed before and were changed): line coverage must show no regression relative to the baseline and must remain >= 80%.
  - **Repo-wide**: line coverage must remain >= 80% for each language.
  ```

  with:

  ```
  ### Coverage Thresholds

  Coverage thresholds follow the uniform tier rule (Authoritative Decision #2) defined in `.claude/rules/quality-tiers.md`:

  - **New code files** (files added in this feature, not previously existing): line coverage >= 85%, branch coverage >= 75%.
  - **Modified files** (files that existed before and were changed): line coverage >= 85%, branch coverage >= 75%, and no regression on changed lines relative to baseline.
  - **Repo-wide per language**: line coverage >= 85%, branch coverage >= 75%.

  Tier-specific lower thresholds are not used.
  ```

  Maps AC #11. Gate: no toolchain gate (markdown only).

#### validate-feature-review-coverage.ps1 (AC #12)

- [x] [P1d-T12] In `.claude/hooks/validate-feature-review-coverage.ps1` line 252, change the conditional `$RepoWidePct -lt 80.0` to `$RepoWidePct -lt 85.0`. Maps AC #12. Gate: PSScriptAnalyzer + Pester (run via MCP).
- [x] [P1d-T13] In `.claude/hooks/validate-feature-review-coverage.ps1` line 256, replace the message fragment `below the 80% floor` with `below the 85% line coverage floor`. Maps AC #12. Gate: PSScriptAnalyzer + Pester (run via MCP).
- [x] [P1d-T14] In `.claude/hooks/validate-feature-review-coverage.ps1`, add a new function `Get-LcovBranchCoverage` parallel to the existing `Get-LcovRepoCoverage`. The function parses LCOV `BRF:` (branches found) and `BRH:` (branches hit) lines and returns a percent. Add inline comment explaining the parser. Maps AC #12. Gate: PSScriptAnalyzer + Pester.
- [x] [P1d-T15] In `.claude/hooks/validate-feature-review-coverage.ps1`, extend `Test-LanguageCoverageRow` (or the appropriate parsing function) to call `Get-LcovBranchCoverage` for TS/Python and to read Jacoco `counter[@type="BRANCH"]` for C#/PowerShell. Add a hard-coded `$BranchFloor = 75.0` and an early `if ($null -ne $BranchPct -and $BranchPct -lt $BranchFloor) { return @{ Ok=$false; Reason=("{0} branch coverage is {1}% (below the 75% branch coverage floor)..." -f $Language, $BranchPct) } }`. The script must fail validation when either line or branch coverage is below the floor. Maps AC #12. Gate: PSScriptAnalyzer + Pester.
- [x] [P1d-T16] Verify the modified script still parses by running `Get-Command .\.claude\hooks\validate-feature-review-coverage.ps1 -Syntax` (or `Test-ScriptFileInfo` equivalent) and persist exit code to `evidence/qa-gates/p1d-validate-coverage-syntax.md`. Gate: PowerShell parser.

#### Skill files (AC #13, #14)

- [x] [P1d-T17] In `.claude/skills/feature-review-workflow/SKILL.md` lines 100–104, replace pre-edit content (research §3c):

  ```
          - Coverage thresholds:
            - New code files (added in this feature): line coverage must be >= 90%. Flag as FAIL otherwise.
            - Modified files (changed but previously existing): line coverage must show no regression relative to baseline and must remain >= 80%. Flag as FAIL otherwise.
            - Repo-wide line coverage must remain >= 80% per language. Flag as FAIL otherwise.
  ```

  with:

  ```
          - Coverage thresholds (uniform tier rule per quality-tiers.md):
            - New code files (added in this feature): line coverage >= 85% and branch coverage >= 75%. Flag as FAIL otherwise.
            - Modified files (changed but previously existing): line coverage >= 85%, branch coverage >= 75%, and no regression on changed lines relative to baseline. Flag as FAIL otherwise.
            - Repo-wide per language: line coverage >= 85% and branch coverage >= 75%. Flag as FAIL otherwise.
  ```

  Maps AC #13. Gate: no toolchain gate (markdown only).

- [x] [P1d-T18] In `.claude/skills/python-qa-gate/SKILL.md` line 47, replace `- **New modules, classes, or methods**: coverage >= 90% for each new unit introduced in the batch.` with `- **New modules, classes, or methods**: line coverage >= 85% and branch coverage >= 75% per the uniform tier rule (`.claude/rules/quality-tiers.md`). No tier-specific lower thresholds. No regression on changed lines.`. Maps AC #14. Gate: no toolchain gate (markdown only).
- [x] [P1d-T19] In `.claude/skills/powershell-qa-gate/SKILL.md` line 45, replace `- **New modules, classes, or methods**: coverage >= 90% for each new unit introduced in the batch.` with the same replacement as P1d-T18. Maps AC #14. Gate: no toolchain gate (markdown only).

---

### Phase 2a — quality-tiers.yml + validator (AC #17)

- [x] [P2a-T1] Create `quality-tiers.yml` at repo root with the body shown below. Maps AC #17. Gate: yaml syntax check (`Get-Content quality-tiers.yml | Out-Null` followed by a parse via `ConvertFrom-Yaml` if available or a simple existence + non-empty check).

  Full file body:

  ```yaml
  # quality-tiers.yml
  # Source of truth for module rigor tier classification across this repository.
  # Every project MUST be listed below with a tier value of t1, t2, t3, or t4.
  # Adding a project without a tier classification fails the CI tier-classification stage.
  # See .claude/rules/quality-tiers.md for tier definitions.

  schema_version: 1

  projects:
    # Current TypeScript scaffold (the Office add-in skeleton at the repo root).
    - name: tmw-taskpane-scaffold
      path: .
      language: typescript
      tier: t4
      rationale: |
        Scaffold-tier (T4): build wiring, manifest, and bootstrap only. Will be re-tiered
        when domain modules and classifier engines are introduced (Prompt B1+).

  # Validator behavior (read by .github/workflows/pr-pipeline.yml stage tier-classification):
  # - Every entry under projects MUST have name, path, language, tier.
  # - tier value MUST be one of: t1, t2, t3, t4.
  # - The validation script also confirms that every directory in the repo that contains a
  #   package.json, *.csproj, or pyproject.toml is represented by exactly one entry.
  ```

- [x] [P2a-T2] Create `.github/scripts/validate-quality-tiers.ps1` (a small validator) with the body shown below. Maps AC #17. Gate: PSScriptAnalyzer.

  Full file body:

  ```powershell
  #Requires -Version 7.0
  <#
  .SYNOPSIS
    Validates quality-tiers.yml against the schema described in the file header.
  .DESCRIPTION
    Fails (exits non-zero) when any project entry is missing required fields or has an
    invalid tier value, or when the repo contains a project directory not represented in
    quality-tiers.yml. Invoked by the tier-classification stage of the PR pipeline.
  #>
  [CmdletBinding()]
  param(
      [string]$ConfigPath = (Join-Path $PSScriptRoot '..' '..' 'quality-tiers.yml')
  )

  $ErrorActionPreference = 'Stop'

  if (-not (Test-Path $ConfigPath)) {
      Write-Error "quality-tiers.yml not found at: $ConfigPath"
      exit 2
  }

  $raw = Get-Content -Raw -Path $ConfigPath
  if ([string]::IsNullOrWhiteSpace($raw)) {
      Write-Error "quality-tiers.yml is empty"
      exit 3
  }

  # Lightweight check that the projects: key exists. Full YAML parsing is deferred to a
  # future task once a YAML parser dependency is approved.
  if ($raw -notmatch '(?m)^projects:\s*$') {
      Write-Error "quality-tiers.yml is missing the required 'projects:' key"
      exit 4
  }

  $tierLines = ($raw -split "`n") | Where-Object { $_ -match '^\s*tier:\s*' }
  foreach ($line in $tierLines) {
      if ($line -notmatch '^\s*tier:\s*(t1|t2|t3|t4)\s*$') {
          Write-Error "Invalid tier value in line: $line"
          exit 5
      }
  }

  # Inventory project-bearing directories in the repo and verify each is represented.
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
  $declaredPaths = @()
  foreach ($line in (($raw -split "`n") | Where-Object { $_ -match '^\s*path:\s*' })) {
      if ($line -match '^\s*path:\s*(\S.*?)\s*$') { $declaredPaths += $Matches[1] }
  }

  $projectMarkers = @('package.json', '*.csproj', 'pyproject.toml')
  $foundProjectDirs = @()
  foreach ($marker in $projectMarkers) {
      $matches = Get-ChildItem -Path $repoRoot -Recurse -File -Filter $marker -ErrorAction SilentlyContinue |
          Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
          Select-Object -ExpandProperty Directory
      foreach ($d in $matches) {
          $rel = ($d.FullName.Substring($repoRoot.Length).TrimStart('\','/')).Replace('\','/')
          if ([string]::IsNullOrEmpty($rel)) { $rel = '.' }
          if ($foundProjectDirs -notcontains $rel) { $foundProjectDirs += $rel }
      }
  }

  $missing = @()
  foreach ($dir in $foundProjectDirs) {
      $hit = $declaredPaths | Where-Object { $_ -eq $dir -or $_ -eq './' + $dir }
      if (-not $hit) { $missing += $dir }
  }

  if ($missing.Count -gt 0) {
      Write-Error ("Unclassified project directories not present in quality-tiers.yml: " + ($missing -join ', '))
      exit 6
  }

  Write-Host "quality-tiers.yml validation PASSED: $($foundProjectDirs.Count) project(s) classified."
  exit 0
  ```

- [x] [P2a-T3] Verify `quality-tiers.yml` and `.github/scripts/validate-quality-tiers.ps1` exist and the validator runs cleanly against the current repo state. Persist `Timestamp/Command/EXIT_CODE/Output Summary` to `evidence/qa-gates/p2a-validator-clean-run.md`. Gate: PSScriptAnalyzer + execution.

---

### Phase 2b — Lefthook installation + config (AC #18, plus wiring for #19, #20)

- [x] [P2b-T1] Create `lefthook.yml` at repo root with the body shown below. Maps AC #18. Gate: yaml syntax check.

  Full file body:

  ```yaml
  # lefthook.yml
  # Pre-commit framework configuration. Install lefthook locally via:
  #   npm install --save-dev @evilmartians/lefthook
  #   npx lefthook install
  # On Windows the runner shell is pwsh; commands below are pwsh-compatible.
  # Set LEFTHOOK=0 in CI to skip these hooks (CI runs the equivalent stages directly).

  pre-commit:
    parallel: true
    commands:
      gitleaks-staged:
        run: gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml

  commit-msg:
    commands:
      conventional-commits:
        run: pwsh -NoProfile -File .githooks/check-conventional-commit.ps1 -MessageFile {1}

  pre-push:
    commands:
      placeholder:
        run: pwsh -NoProfile -Command "Write-Host 'pre-push placeholder: stage-specific gates wired in later prompts.'"
  ```

- [x] [P2b-T2] Create `docs/lefthook-setup.md` documenting installation and Windows pwsh notes (drawn from research §5 lefthook). Maps AC #18. Gate: no toolchain gate (markdown only).
- [x] [P2b-T3] Verify `lefthook.yml` exists and parses (`Get-Content lefthook.yml | Out-Null`). Persist to `evidence/qa-gates/p2b-lefthook-presence.md`. Gate: shell.

---

### Phase 2c — gitleaks config (AC #19)

- [x] [P2c-T1] Create `.gitleaks.toml` at repo root with the body shown below. Maps AC #19. Gate: toml syntax check (`Get-Content .gitleaks.toml | Out-Null` plus simple presence check).

  Full file body:

  ```toml
  # .gitleaks.toml
  # Repository-specific overlay on top of the gitleaks default rules. The default rules are
  # implicitly extended unless [extend].useDefault = false. We extend them to add Office.js
  # and Microsoft Graph specific patterns that are not in the default rule set.

  [extend]
  useDefault = true

  [[rules]]
  id = "graph-client-secret"
  description = "Microsoft Graph application client secret pattern"
  regex = '''(?i)(graph[_-]?client[_-]?secret|graph[_-]?app[_-]?secret)\s*[=:]\s*['"]?[A-Za-z0-9~._\-]{20,}['"]?'''
  tags = ["secret", "graph"]

  [[rules]]
  id = "office-addin-shared-key"
  description = "Office add-in shared key or token literal"
  regex = '''(?i)(office[_-]?addin[_-]?(?:shared[_-]?)?(?:key|token))\s*[=:]\s*['"]?[A-Za-z0-9._\-]{16,}['"]?'''
  tags = ["secret", "office-addin"]

  [allowlist]
  description = "Allowlist for documentation and test fixtures"
  paths = [
    '''(?i)docs/.*\.md''',
    '''(?i)\.gitleaks\.toml''',
    '''(?i)docs/features/.*'''
  ]
  ```

- [x] [P2c-T2] Verify `.gitleaks.toml` exists, is non-empty, and contains both extension rules. Persist to `evidence/qa-gates/p2c-gitleaks-presence.md`. Gate: shell.

---

### Phase 2d — Conventional Commits commit-msg hook (AC #20)

- [x] [P2d-T1] Create `.githooks/check-conventional-commit.ps1` with the body shown below. Maps AC #20. Gate: PSScriptAnalyzer.

  Full file body:

  ```powershell
  #Requires -Version 7.0
  <#
  .SYNOPSIS
    Conventional Commits commit-msg hook.
  .DESCRIPTION
    Reads the staged commit message file and rejects messages that do not match the
    Conventional Commits format. Invoked by lefthook (commit-msg / conventional-commits).
  .PARAMETER MessageFile
    Path to the commit message file (lefthook substitutes {1}).
  #>
  [CmdletBinding()]
  param(
      [Parameter(Mandatory = $true)]
      [string]$MessageFile
  )

  $ErrorActionPreference = 'Stop'

  if (-not (Test-Path $MessageFile)) {
      Write-Error "Commit message file not found: $MessageFile"
      exit 2
  }

  $raw = Get-Content -Raw -Path $MessageFile
  $lines = $raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*#' }
  $firstLine = ($lines | Where-Object { $_ -ne '' } | Select-Object -First 1)

  if ([string]::IsNullOrWhiteSpace($firstLine)) {
      Write-Error "Commit message is empty."
      exit 3
  }

  # Conventional Commits subject pattern:
  # <type>(<scope>)?!?: <subject>
  # type ∈ {feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert}
  $pattern = '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([\w\-/. ]+\))?!?:\s.+'
  if ($firstLine -notmatch $pattern) {
      Write-Error @"
  Commit message does not match Conventional Commits format.
  First line: $firstLine
  Expected:   <type>(<optional scope>)?!?: <subject>
  Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
  Example:    feat(taskpane): add classifier seam
  "@
      exit 4
  }

  exit 0
  ```

- [x] [P2d-T2] Verify `.githooks/check-conventional-commit.ps1` parses (`Get-Command -Syntax`) and that PSScriptAnalyzer raises no errors. Persist to `evidence/qa-gates/p2d-commit-hook-analyze.md`. Gate: PSScriptAnalyzer.

---

### Phase 2e — Renovate config (AC #21)

- [x] [P2e-T1] Create `renovate.json` at repo root with the body shown below. Maps AC #21. Gate: json syntax check (`Get-Content renovate.json | ConvertFrom-Json | Out-Null`).

  Full file body:

  ```json
  {
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": ["config:recommended", ":semanticCommits"],
    "enabledManagers": ["npm", "nuget", "github-actions", "dockerfile"],
    "schedule": ["before 6am on Monday"],
    "labels": ["dependencies"],
    "rangeStrategy": "bump",
    "packageRules": [
      {
        "matchManagers": ["npm"],
        "groupName": "npm dependencies"
      },
      {
        "matchManagers": ["nuget"],
        "groupName": "nuget dependencies"
      },
      {
        "matchManagers": ["github-actions"],
        "groupName": "github-actions"
      },
      {
        "matchManagers": ["dockerfile"],
        "groupName": "docker base images"
      }
    ],
    "vulnerabilityAlerts": {
      "enabled": true,
      "labels": ["security"]
    }
  }
  ```

- [x] [P2e-T2] Verify `renovate.json` parses as JSON and lists the four managers (`npm`, `nuget`, `github-actions`, `dockerfile`). Persist to `evidence/qa-gates/p2e-renovate-presence.md`. Gate: shell + JSON parse.

---

### Phase 2f — GitHub Actions baseline workflow + composite actions (AC #22)

- [x] [P2f-T1] Create directory `.github/workflows/` (by creating the workflow file inside it). Maps AC #22. Gate: shell.
- [x] [P2f-T2] Create `.github/workflows/pr-pipeline.yml` with the body shown below. Maps AC #22. Gate: yaml syntax check (`Get-Content` parse + actionlint when available).

  Full file body:

  ```yaml
  name: PR Pipeline
  on:
    pull_request:
      branches: [main]

  permissions:
    contents: read

  jobs:
    tier-classification:
      runs-on: windows-latest
      steps:
        - uses: actions/checkout@v4
        - shell: pwsh
          run: pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1
    stage-1-format:
      runs-on: windows-latest
      needs: [tier-classification]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/format
    stage-2-lint:
      runs-on: windows-latest
      needs: [stage-1-format]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/lint
    stage-3-typecheck:
      runs-on: windows-latest
      needs: [stage-2-lint]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/typecheck
    stage-4-architecture:
      runs-on: windows-latest
      needs: [stage-3-typecheck]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/architecture
    stage-5-test:
      runs-on: windows-latest
      needs: [stage-4-architecture]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/test
    stage-6-contract:
      runs-on: windows-latest
      needs: [stage-5-test]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/contract
    stage-7-integration:
      runs-on: windows-latest
      needs: [stage-6-contract]
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/integration
  ```

- [x] [P2f-T3] Create `.github/actions/format/action.yml` (composite, no-op stub scoped to existing files). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Format
  description: Repository format check stage. Currently scoped to existing TS scaffold (Prettier).
  runs:
    using: composite
    steps:
      - name: Prettier check (existing TS files only)
        shell: pwsh
        run: |
          if (Test-Path package.json) {
            npm ci --no-audit --no-fund
            npx prettier --check "**/*.ts" "**/*.json" "**/*.md" --ignore-path .gitignore
          } else {
            Write-Host "Format stage: no package.json present; skipping (no-op)."
          }
  ```

- [x] [P2f-T4] Create `.github/actions/lint/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Lint
  description: Repository lint stage. Scoped to existing scaffold; full ESLint config lights up in Prompt B1.
  runs:
    using: composite
    steps:
      - name: ESLint (scaffold only)
        shell: pwsh
        run: |
          if (Test-Path package.json) {
            npm ci --no-audit --no-fund
            if ((Get-Content package.json -Raw) -match '"lint"\s*:') {
              npm run lint
            } else {
              Write-Host "Lint stage: no lint script defined yet; skipping (no-op)."
            }
          } else {
            Write-Host "Lint stage: no package.json present; skipping (no-op)."
          }
  ```

- [x] [P2f-T5] Create `.github/actions/typecheck/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Typecheck
  description: TypeScript type-check stage. Scoped to existing tsconfig; .NET nullable analysis added when backend exists.
  runs:
    using: composite
    steps:
      - name: tsc --noEmit
        shell: pwsh
        run: |
          if (Test-Path tsconfig.json) {
            npm ci --no-audit --no-fund
            if ((Get-Content package.json -Raw) -match '"typecheck"\s*:') {
              npm run typecheck
            } else {
              npx tsc --noEmit
            }
          } else {
            Write-Host "Typecheck stage: no tsconfig.json; skipping (no-op)."
          }
  ```

- [x] [P2f-T6] Create `.github/actions/architecture/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Architecture
  description: Architecture-boundary tests stage. Wires dependency-cruiser (TS) and NetArchTest.Rules (.NET) when configs exist.
  runs:
    using: composite
    steps:
      - name: dependency-cruiser (when configured)
        shell: pwsh
        run: |
          if (Test-Path .dependency-cruiser.cjs) {
            npm ci --no-audit --no-fund
            npx depcruise --config .dependency-cruiser.cjs src
          } else {
            Write-Host "Architecture stage: no .dependency-cruiser.cjs yet; skipping (no-op)."
          }
  ```

- [x] [P2f-T7] Create `.github/actions/test/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Test
  description: Unit + property test stage. Vitest wiring added in Prompt B1.
  runs:
    using: composite
    steps:
      - name: Vitest (when wired)
        shell: pwsh
        run: |
          if ((Test-Path package.json) -and ((Get-Content package.json -Raw) -match '"test"\s*:')) {
            npm ci --no-audit --no-fund
            npm test
          } else {
            Write-Host "Test stage: no test script wired yet; skipping (no-op)."
          }
  ```

- [x] [P2f-T8] Create `.github/actions/contract/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Contract
  description: Contract / schema compatibility stage. Wires oasdiff or schema-snapshot diff when API specs exist.
  runs:
    using: composite
    steps:
      - name: Contract checks (placeholder)
        shell: pwsh
        run: Write-Host "Contract stage: no API specs in repo yet; skipping (no-op)."
  ```

- [x] [P2f-T9] Create `.github/actions/integration/action.yml` (composite stub). Maps AC #22. Gate: yaml syntax check.

  Full file body:

  ```yaml
  name: Integration
  description: Integration tests stage. Lights up in later prompts when adapter and backend code exists.
  runs:
    using: composite
    steps:
      - name: Integration (placeholder)
        shell: pwsh
        run: Write-Host "Integration stage: no integration tests in repo yet; skipping (no-op)."
  ```

- [x] [P2f-T10] Verify all eight new YAML files (workflow + 7 composite actions) parse with `Get-Content` + a YAML well-formedness check. Persist to `evidence/ci/p2f-yaml-presence.md` (under `evidence/qa-gates/` since `ci/` is not a canonical subpath in the conventions skill — use `evidence/qa-gates/`). Gate: shell.

---

### Phase 2g — Branch protection documentation (AC #23)

- [x] [P2g-T1] Create `docs/branch-protection.md` with the body shown below. Maps AC #23. Gate: no toolchain gate (markdown only).

  Full file body:

  ```markdown
  # Branch Protection Requirements

  This document records the branch protection rule that must be active on the `main` branch.
  Application of the rule via the GitHub API is recorded as a manual follow-up because the
  executor session does not have authenticated `gh` CLI access.

  ## Required status checks

  The following status checks (job names from `.github/workflows/pr-pipeline.yml`) must pass
  before a pull request can merge to `main`:

  - `tier-classification`
  - `stage-1-format`
  - `stage-2-lint`
  - `stage-3-typecheck`
  - `stage-4-architecture`
  - `stage-5-test`
  - `stage-6-contract`
  - `stage-7-integration`

  Additional protection rule settings:

  - Require pull request reviews before merging: 1 approving review.
  - Dismiss stale reviews on new commits.
  - Require linear history.
  - Require branches to be up to date before merging.
  - Restrict who can push to matching branches: empty allowlist (no direct pushes).

  ## Manual application command (gh CLI)

  The following command applies the rule once `gh auth login` is complete:

  ```bash
  gh api -X PUT repos/{owner}/{repo}/branches/main/protection \
    -F required_status_checks.strict=true \
    -F 'required_status_checks.contexts[]=tier-classification' \
    -F 'required_status_checks.contexts[]=stage-1-format' \
    -F 'required_status_checks.contexts[]=stage-2-lint' \
    -F 'required_status_checks.contexts[]=stage-3-typecheck' \
    -F 'required_status_checks.contexts[]=stage-4-architecture' \
    -F 'required_status_checks.contexts[]=stage-5-test' \
    -F 'required_status_checks.contexts[]=stage-6-contract' \
    -F 'required_status_checks.contexts[]=stage-7-integration' \
    -F enforce_admins=true \
    -F required_pull_request_reviews.required_approving_review_count=1 \
    -F required_pull_request_reviews.dismiss_stale_reviews=true \
    -F required_linear_history=true \
    -F restrictions=null
  ```

  ## Manual follow-up record

  Status: PENDING (manual). Owner: repo administrator. Apply once authenticated `gh` CLI
  access is available. Verification: re-run the command with `-X GET` and confirm each
  context appears in the response payload.
  ```

- [x] [P2g-T2] Append a `Manual follow-ups` section to `docs/features/active/2026-05-09-establish-repository-foundation-1/issue.md` listing branch-protection application as PENDING with reference to `docs/branch-protection.md`. Mirror the same note to `evidence/issue-updates/issue-1.<timestamp>.md` per the issue-update mirroring convention with fields `Timestamp:`, body text, `PostedAs: body`. Maps AC #23. Gate: no toolchain gate (markdown only).

---

### Phase 3 — Verification, validation, and final QA loop

#### Phase-1 grep-based validations (issue.md Validation section)

- [x] [P3-T1] Run `Select-String -Pattern 'jest' -CaseSensitive:$false -Path .claude/rules/typescript.md, .github/instructions/typescript-code-change.instructions.md, .github/instructions/typescript-unit-test.instructions.md, .claude/agents/atomic-executor.md, .github/agents/typescript-engineer.agent.md`. PASS only if zero matches. Persist to `evidence/qa-gates/p3-grep-jest.md`. Gate: shell.
- [x] [P3-T2] Run `Select-String -Pattern 'vs code extension|vscode extension' -CaseSensitive:$false -Path .claude/rules/typescript.md, .github/instructions/typescript-code-change.instructions.md, .github/instructions/typescript-unit-test.instructions.md, .github/agents/typescript-engineer.agent.md`. PASS only if zero matches. Persist to `evidence/qa-gates/p3-grep-vscode.md`. Gate: shell.
- [x] [P3-T3] Run `Test-Path` on `.claude/rules/quality-tiers.md`, `.claude/rules/architecture-boundaries.md`, `.github/instructions/quality-tiers.instructions.md`, `.github/instructions/architecture-boundaries.instructions.md`. PASS only if all four return True. For each, also confirm the file's first 10 lines contain a valid frontmatter block (lines 1 and final delimiter both `---`). Persist to `evidence/qa-gates/p3-newfile-presence.md`. Gate: shell.
- [x] [P3-T4] Run `Select-String -Pattern '>= 85% line, >= 75% branch' -Path .claude/rules/general-unit-test.md` (or the equivalent literal text per the post-edit content). PASS only if the file contains the uniform-tier coverage prose and zero remaining `>= 80%` / `>= 90%` strings tied to coverage thresholds. Persist to `evidence/qa-gates/p3-general-unit-test-coverage.md`. Gate: shell.
- [x] [P3-T5] Verify uniform tier coverage prose is present in each of: `.claude/rules/python.md`, `.claude/rules/powershell.md`, `.claude/skills/python-qa-gate/SKILL.md`, `.claude/skills/powershell-qa-gate/SKILL.md`, `.claude/skills/feature-review-workflow/SKILL.md`, `.claude/agents/feature-review.md`, `.claude/hooks/validate-feature-review-coverage.ps1`, plus the four `.github/instructions/` mirrors (general-unit-test, general-code-change, python-code-change, python-unit-test, powershell-code-change, powershell-unit-test, typescript-code-change, typescript-unit-test). Persist a presence report (one bullet per file with PASS/FAIL) to `evidence/qa-gates/p3-coverage-prose-uniform.md`. Gate: shell.
- [x] [P3-T6] Verify Python rules still reference Black: `Select-String -Pattern '\bBlack\b' -Path .claude/rules/python.md`. PASS only if at least one match. Persist to `evidence/qa-gates/p3-black-preserved.md`. Gate: shell.
- [x] [P3-T7] Verify mirror discipline: every `.claude/rules/*.md` file modified in Phases 1a–1c has a corresponding modified `.github/instructions/*.instructions.md` file. Compute via `git diff --name-only main...HEAD`. PASS only if for each `.claude/rules/<name>.md` modification there is at least one `.github/instructions/<name>*.instructions.md` modification (including new-file creations). Persist diff lists and pairing report to `evidence/qa-gates/p3-mirror-discipline.md`. Gate: shell.
- [x] [P3-T8] Verify the validate-feature-review-coverage hook script: line containing `$RepoWidePct -lt 85.0` is present (one match), `$RepoWidePct -lt 80.0` is absent, a `Get-LcovBranchCoverage` function definition is present, and a `BranchFloor` literal `75.0` appears in the script. Persist to `evidence/qa-gates/p3-hook-script-checks.md`. Gate: shell.

#### Phase-2 functional validations (issue.md Validation section)

- [x] [P3-T9] Construct a fake-secret commit to verify gitleaks rejection. Steps: write a temporary file `.gitleaks-test.txt` containing `graph_client_secret = "AKIAABCDEFGHIJKLMNOP"` then `git add .gitleaks-test.txt`, then run `gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml`. PASS only if the command exits non-zero AND the output references the staged file. Cleanup: `git restore --staged .gitleaks-test.txt; Remove-Item .gitleaks-test.txt`. Persist `Timestamp/Command/EXIT_CODE/Output Summary` to `evidence/qa-gates/p3-gitleaks-fake-secret.md`. Gate: shell.
- [x] [P3-T10] Verify the conventional-commits hook rejects a non-conformant commit message. Steps: create a temporary file `.commit-msg-test` containing the single line `fix stuff`, run `pwsh -NoProfile -File .githooks/check-conventional-commit.ps1 -MessageFile .commit-msg-test`. PASS only if exit code is non-zero (4) AND stderr contains `Conventional Commits format`. Cleanup: `Remove-Item .commit-msg-test`. Persist to `evidence/qa-gates/p3-commit-msg-bad.md`. Gate: shell.
- [x] [P3-T11] Verify the conventional-commits hook accepts a conformant message. Steps: write `.commit-msg-test` with `feat(scope): add classifier seam` and run the hook. PASS only if exit code is 0. Cleanup as above. Persist to `evidence/qa-gates/p3-commit-msg-good.md`. Gate: shell.
- [x] [P3-T12] Verify the quality-tiers validator rejects an unclassified project. Steps: create a temporary directory `temp-unclassified-project/` with a `package.json` containing `{ "name":"unclassified-temp" }`, run `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1`. PASS only if exit code is non-zero (6) AND stderr names `temp-unclassified-project` as missing. Cleanup: `Remove-Item temp-unclassified-project -Recurse -Force`. Persist to `evidence/qa-gates/p3-tier-validator-rejects.md`. Gate: shell.
- [x] [P3-T13] Verify the quality-tiers validator accepts the current classified state. Run `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1`. PASS only if exit code is 0. Persist to `evidence/qa-gates/p3-tier-validator-accepts.md`. Gate: shell.
- [x] [P3-T14] Verify the PR pipeline workflow yaml is well-formed: `Get-Content .github/workflows/pr-pipeline.yml | Out-Null`; if `actionlint` is available, run `actionlint .github/workflows/pr-pipeline.yml`. Confirm all eight job names are present (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`). Persist to `evidence/qa-gates/p3-workflow-yaml.md`. Gate: shell + optional actionlint.

#### Phase-3 final QA loop (per general-code-change seven-stage loop)

- [x] [P3-T15] Final QA stage 1 (Formatting): no production formatting commands run because A0 only edits Markdown, YAML, JSON, TOML, and one PS1 file. Record `Output Summary: stage 1 N/A for A0 file types (markdown / yaml / json / toml / ps1) — formatter run only against ps1 below.` to `evidence/qa-gates/p3-final-qa-stage1.md`. Gate: no toolchain gate (markdown / yaml / json / toml only).
- [x] [P3-T16] Final QA stage 1 (PowerShell formatting): run `mcp__drm-copilot__run_poshqc_format` against the modified `.claude/hooks/validate-feature-review-coverage.ps1`, the new `.githooks/check-conventional-commit.ps1`, and the new `.github/scripts/validate-quality-tiers.ps1`. Persist results to `evidence/qa-gates/p3-final-qa-stage1-ps.md`. Gate: Invoke-Formatter via MCP.
- [x] [P3-T17] Final QA stage 2 (PowerShell linting): `mcp__drm-copilot__run_poshqc_analyze` on the same three PS1 files. PASS only if zero error-level findings. Persist to `evidence/qa-gates/p3-final-qa-stage2-ps.md`. Gate: PSScriptAnalyzer via MCP.
- [x] [P3-T18] Final QA stage 2 (TypeScript linting): `npm run lint` against the unmodified TS scaffold. PASS only if exit code is 0 (matches baseline P0-T13). Persist to `evidence/qa-gates/p3-final-qa-stage2-ts.md`. Gate: ESLint.
- [x] [P3-T19] Final QA stage 3 (TypeScript typecheck): `npm run typecheck`. PASS only if exit code is 0. Persist to `evidence/qa-gates/p3-final-qa-stage3-ts.md`. Gate: tsc.
- [x] [P3-T20] Final QA stage 4 (Architecture-boundary tests): `dependency-cruiser` config does not yet exist in this repo (scaffold). Record `Output Summary: stage 4 deferred — .dependency-cruiser.cjs lights up in Prompt B1; no architecture violations possible against current scaffold.` to `evidence/qa-gates/p3-final-qa-stage4.md`. Gate: shell.
- [x] [P3-T21] Final QA stage 5 (Unit + property tests): no Vitest dependency installed (A0 owns rule prose only; B1 owns dependency installation). Persist `Output Summary: stage 5 deferred — Vitest dependency installed in Prompt B1; no unit tests in repo yet.` to `evidence/qa-gates/p3-final-qa-stage5.md`. Gate: shell.
- [x] [P3-T22] Final QA stage 5 (Pester for new PS1 hook scripts, where tests exist): if any `*.Tests.ps1` files exist for the three modified or new PS1 files, run `mcp__drm-copilot__run_poshqc_test`. If none exist, record `Output Summary: stage 5 N/A for new hook scripts — no Pester tests in repo for these files; A0 does not introduce Pester tests (rule prose change only).` Note: AD-2 coverage gate cannot be applied to PS1 changes lacking tests; this is recorded as a known gap and tracked as a follow-up per `issue.md` Validation bullet "Existing repository tests still pass against the new coverage thresholds, or any gap is recorded ...". Persist to `evidence/qa-gates/p3-final-qa-stage5-ps.md`. Gate: Pester via MCP.
- [x] [P3-T23] Final QA stage 6 (Contract / schema): no API specs in repo. Record `Output Summary: stage 6 N/A — no API specs in repo.` Persist to `evidence/qa-gates/p3-final-qa-stage6.md`. Gate: shell.
- [x] [P3-T24] Final QA stage 7 (Integration tests): no integration tests in repo. Record `Output Summary: stage 7 N/A — no integration tests in repo.` Persist to `evidence/qa-gates/p3-final-qa-stage7.md`. Gate: shell.
- [x] [P3-T25] Coverage delta verification: A0 introduces three new PS1 files / one modified PS1 file with no Pester tests. Record baseline coverage = N/A (no prior coverage measurement for these files), post-change coverage = N/A, new-code coverage = N/A. Record gap explicitly in `artifacts/orchestration/orchestrator-state.json` (or create a `evidence/qa-gates/p3-coverage-gap-followup.md` artifact when state file edits are out of scope) per the issue.md Validation clause that allows recording gaps with a remediation plan. Persist remediation plan: "Pester test scaffolding for hook + commit-msg + tier validator scripts is tracked as a Phase 1 follow-up; ticket to be opened post-A0." Gate: no toolchain gate (markdown only).

#### Acceptance criteria checkoff

- [x] [P3-T26] Create `evidence/acceptance/p23-acceptance-criteria-checkoff.md` (the canonical 23-item checkoff document) with each AC #1..#23 listed verbatim from `issue.md` and a PASS/FAIL verdict per AC, each citing the supporting evidence artifact path. Persist with `Timestamp:` and `Output Summary: <count> PASS / <count> FAIL`. PASS only if all 23 ACs are PASS. Note: per the evidence path invariant, `evidence/acceptance/` is not a canonical subpath; if the executor's hook rejects this path, fall back to `evidence/qa-gates/p23-acceptance-criteria-checkoff.md`. Gate: no toolchain gate (markdown only).

#### Final preflight gate

- [x] [P3-T27] Confirm every Phase 0–3 task above has a completed evidence artifact under `docs/features/active/2026-05-09-establish-repository-foundation-1/evidence/<kind>/` with all four schema fields populated. Record consolidated verdict to `evidence/qa-gates/p3-final-gate.md`. PASS only if every checkbox above this task is `[x]` and every artifact validates. Gate: shell.

---

## Plan-path continuity note

All revisions of this plan write back to `docs/features/active/2026-05-09-establish-repository-foundation-1/plan.md`. No timestamped sibling files are created during this planning cycle.

## Preflight signal

DIRECTIVE: PREFLIGHT VALIDATION ONLY

PREFLIGHT: ALL CLEAR
