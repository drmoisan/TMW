# Establish Repository Foundation (Prompt A0)

- Work Mode: full-feature
- Promotion Type: feature
- Issue Number: 1
- Short Name: establish-repository-foundation
- Created: 2026-05-09
- Bootstrap: manual (drm-copilot MCP tools not bound to orchestrator session; promotion executed by manual feature-folder creation following feature-promotion-lifecycle conventions)

## Summary

Establish the repository-wide rule baseline, hygiene controls, and tier infrastructure that all subsequent migration prompts (A1, B1, ...) will be checked against. Two tightly coupled phases delivered together so the rule prose and enforcement artifacts agree from the first commit:

- Phase 1: Update repository rule and instruction files to reflect the No-COM toolchain decisions (Vitest replaces Jest; Office.js / Outlook host runtime replaces VS Code extension framing; uniform coverage thresholds across tiers T1-T4).
- Phase 2: Install hygiene controls (lefthook, gitleaks, conventional-commits commit-msg hook, Renovate, baseline GitHub Actions workflow with composite stages, branch-protection requirement) and the `quality-tiers.yml` source of truth at repo root.

## Authoritative Decisions (non-negotiable)

1. Python formatting remains Black. The existing Python toolchain (Black + Ruff + Pyright + Pytest) is preserved across all rule updates. Ruff format does not replace Black anywhere.
2. Coverage thresholds are uniform across all tiers (T1 through T4): line coverage >= 85%, branch coverage >= 75%, no regression on changed lines. No tier-specific lower thresholds anywhere in the rule set. Justification recorded in rule prose: high test coverage is a fundamental quality-control design choice that enables autonomous agentic development and trust in the work product.

## Acceptance Criteria

### Phase 1 — Rule baseline (mirror discipline: every `.claude/rules/<name>.md` change lands in the matching `.github/instructions/<name>-*.instructions.md` file in the same delivery)

1. `.claude/rules/quality-tiers.md` and `.github/instructions/quality-tiers.instructions.md` exist with frontmatter matching existing rule conventions, define T1-T4 tiers per `docs/ci.research.md`, name `quality-tiers.yml` at repo root as the source of truth, document the uniform-vs-tier-dependent gate matrix, and list per-tier examples drawn from the No-COM architecture.
2. `.claude/rules/architecture-boundaries.md` and `.github/instructions/architecture-boundaries.instructions.md` exist with frontmatter matching existing rule conventions, name `dependency-cruiser` (TS) and `NetArchTest.Rules` (.NET) as enforcement tools and `.dependency-cruiser.cjs` and `*.ArchitectureTests` as enforcement file patterns, codify the No-COM architecture rules as enforceable assertions, and state that violations block PRs.
3. `.claude/rules/typescript.md`, `.github/instructions/typescript-code-change.instructions.md`, and `.github/instructions/typescript-unit-test.instructions.md` no longer reference Jest in active text; all mocking syntax is converted to Vitest (`vi.spyOn`, `vi.mock`, `vi.useFakeTimers`, `vi.resetAllMocks`); `npm run test:unit` is converted to `npm run test`; the `*.test.ts` filename convention is preserved.
4. The same three TypeScript files no longer use "VS Code extension" framing; references are replaced with "Office.js APIs", "Outlook host runtime", or "Outlook web add-in context" as appropriate; the separation-of-concerns rule reads "keep pure logic separate from Office.js, Microsoft Graph SDK, and other host-bound APIs."
5. `.claude/rules/typescript.md` (and its mirror) gain the following subsections: ESLint stack (typescript-eslint strict-type-checked + stylistic-type-checked, type-aware parsing, `eslint-plugin-office-addins`, `eslint-plugin-promise`, `eslint-plugin-security`, `eslint-plugin-import`, error-level `no-floating-promises`/`no-misused-promises`/`no-unsafe-*`, `no-restricted-syntax` bans on `Date.now`/`setTimeout`/`setInterval`/`Math.random` outside an explicit infrastructure allowlist); Architecture boundaries (referencing `architecture-boundaries.md`); Property-based and mutation testing (`fast-check` >= 1 property test per pure function on T1/T2; StrykerJS mutation score >= 75% on T1); Golden tests (T1 classifier-output snapshots against a versioned corpus; existing avoid-snapshot-tests guidance softened, not removed, to apply except for classifier-output and schema-evolution scenarios); Runtime determinism (Date/Math.random/setTimeout via injected Clock/Random interface; Vitest fake timers; `await flushPromises()` over `setTimeout(0)`).
6. The same TypeScript Coverage Requirements references `quality-tiers.md` and applies the uniform tier rule (line >= 85%, branch >= 75%, no regression on changed lines).
7. `.claude/rules/general-unit-test.md` and `.github/instructions/general-unit-test.instructions.md` replace the existing >= 80% repo / >= 90% new-module rule with the uniform tier rule; add a "Test Categories" section listing unit (all tiers), property-based (T1/T2 >= 1 per pure function), golden/snapshot (T1 classifier outputs only against a versioned corpus), contract/schema (host-service boundary), mutation (T1 only >= 75%), and integration tests; add a "Determinism Infrastructure" section requiring controllable clock (`Clock` for TS, `TimeProvider` for .NET), seeded RNG with seed printed on test failure, banned APIs in test code (`setTimeout`, `Thread.Sleep`, `Task.Delay`, real wall-clock waits, `Date.now()` outside the clock interface), and virtual scheduler / fake timers / `FakeTimeProvider` for async tests.
8. `.claude/rules/general-code-change.md` and `.github/instructions/general-code-change.instructions.md` add a "Module Rigor Tiers" section pointing to `quality-tiers.md` and expand the "Mandatory Toolchain Loop" from four stages to seven, in this order: formatting, linting, type checking, architecture-boundary tests, unit tests (with property tests where applicable), contract / schema compatibility checks, integration tests; mutation testing, golden tests, and benchmark regression are explicitly noted to run in pre-merge or nightly pipelines, not the per-commit loop; the "restart from step 1 if any step fails or auto-fixes files" rule applies to the full seven-stage loop.

### Phase 1 (continued) — Operational artifact updates

9. `.claude/agents/atomic-executor.md`: `Bash(npx jest *)` is replaced by `Bash(npx vitest *)` in the tools allowlist, and the toolchain reference table uses `npx vitest` instead of `npx jest`.
10. `.github/agents/typescript-engineer.agent.md`: every Jest reference is replaced with Vitest (including `jest.resetAllMocks` -> `vi.resetAllMocks`, `jest.spyOn` -> `vi.spyOn`, `jest.mock` -> `vi.mock`, `jest.useFakeTimers` -> `vi.useFakeTimers`); every "VS Code extension host" reference is replaced with "Outlook host runtime"; "VS Code extension API" framing is replaced with "Office.js APIs".
11. `.claude/agents/feature-review.md`: coverage thresholds (>= 80% repo-wide, >= 80% modified files, >= 90% new files) are replaced with the uniform tier rule (line >= 85%, branch >= 75%, no regression on changed lines).
12. `.claude/hooks/validate-feature-review-coverage.ps1`: hard-coded line-coverage threshold updated from 80.0 to 85.0; a branch-coverage check at 75.0 added; the script fails validation when either threshold is violated.
13. `.claude/skills/feature-review-workflow/SKILL.md` coverage threshold prose uses the uniform tier rule.
14. `.claude/skills/python-qa-gate/SKILL.md` and `.claude/skills/powershell-qa-gate/SKILL.md` replace the >= 90% per-new-unit threshold with the uniform tier rule (>= 85% line, >= 75% branch across all tiers, no regression on changed lines).
15. `.claude/rules/python.md`, `.github/instructions/python-code-change.instructions.md`, and `.github/instructions/python-unit-test.instructions.md` update only the coverage-threshold prose per Authoritative Decision #2; Black, Ruff, Pyright, and Pytest remain unchanged.
16. `.claude/rules/powershell.md`, `.github/instructions/powershell-code-change.instructions.md`, and `.github/instructions/powershell-unit-test.instructions.md` update only the coverage-threshold prose per Authoritative Decision #2; Invoke-Formatter, PSScriptAnalyzer, and Pester remain unchanged.

### Phase 2 — Hygiene controls and tier definitions

17. `quality-tiers.yml` exists at repo root with tier mappings for every project that exists today (the TS scaffold), and the CI/validation pipeline fails when an unclassified project is added.
18. A pre-commit framework (lefthook or equivalent single-binary multi-language runner) is installed, configured at repo root, and required for local development.
19. Secret scanning (gitleaks) runs on every commit and blocks commits containing credentials. Verification is automated: `.github/scripts/install-gitleaks.ps1` provisions the gitleaks binary deterministically; a synthetic-secret fixture matching the `graph-client-secret` rule is staged; `gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml` is invoked against it; the run exits non-zero and emits a redacted match. Exit code, redacted finding, and the install script invocation are captured in `evidence/qa-gates/p3-gitleaks-fake-secret.md`. The CI workflow runs the same install script and a `gitleaks detect` step on PR diffs.
20. Conventional Commits is enforced via a commit-msg hook. A non-conformant commit message is rejected (verifiable in evidence).
21. A Renovate configuration exists covering npm, NuGet, GitHub Actions, and Docker in a single config.
22. A baseline GitHub Actions workflow exists at `.github/workflows/` with reusable composite actions for stages that will be filled in by later prompts (format, lint, typecheck, architecture, test, contract, integration). Stages are no-ops or scoped to existing files until the matching tooling lights up. The workflow runs and reports per-stage status.
23. Branch protection requirements that the PR pipeline must pass are documented in `docs/branch-protection.md` and applied programmatically via `.github/scripts/apply-branch-protection.ps1`, which calls `gh api -X PUT repos/drmoisan/TMW/branches/main/protection` with the eight required contexts (`tier-classification`, `stage-1-format`, `stage-2-lint`, `stage-3-typecheck`, `stage-4-architecture`, `stage-5-test`, `stage-6-contract`, `stage-7-integration`), `enforce_admins=true`, `required_pull_request_reviews.required_approving_review_count=1`, `required_pull_request_reviews.dismiss_stale_reviews=true`, `required_linear_history=true`, and `restrictions=null`. Verification: `gh api -X GET repos/drmoisan/TMW/branches/main/protection` returns each of the eight contexts and the live JSON is captured in `evidence/qa-gates/p23-branch-protection-live.md`.

### Out of scope

- No changes to `tonality.md`, `self-explanatory-code-commenting.md`, or `*-suppressions.md` rules and their mirrors.
- No changes to `python.md` or `powershell.md` (or their instructions mirrors) beyond the coverage-threshold prose update.
- No npm or NuGet dependency additions beyond what is required for lefthook/gitleaks/Renovate setup.
- No edits to `src/`, `tests/`, `manifest.json`, `webpack.config.js`, or `package.json` scripts beyond what hygiene tooling requires.
- No replacement of Black in any Python rule.
- No tier-specific lower coverage gates anywhere.
- No edits to `csharp-change-budget-router/SKILL.md`, `powershell-change-budget-router/SKILL.md`, or `feature-promotion-lifecycle/SKILL.md`.

## Validation

### Phase 1
- `grep -ri "jest" .claude/rules/typescript.md .github/instructions/typescript-code-change.instructions.md .github/instructions/typescript-unit-test.instructions.md .claude/agents/atomic-executor.md .github/agents/typescript-engineer.agent.md` returns no matches in active text.
- `grep -ri "vs code extension\|vscode extension" .claude/rules/typescript.md .github/instructions/typescript-code-change.instructions.md .github/instructions/typescript-unit-test.instructions.md .github/agents/typescript-engineer.agent.md` returns no matches.
- `.claude/rules/quality-tiers.md`, `.claude/rules/architecture-boundaries.md`, and their `.github/instructions/` mirrors exist with frontmatter matching the existing rule conventions.
- The coverage rule in `general-unit-test.md` reads ">= 85% line, >= 75% branch across all tiers" with no tier-specific lower thresholds anywhere in the rule set.
- Coverage thresholds in `.claude/rules/python.md`, `.claude/rules/powershell.md`, `.claude/skills/python-qa-gate/SKILL.md`, `.claude/skills/powershell-qa-gate/SKILL.md`, `.claude/skills/feature-review-workflow/SKILL.md`, `.claude/agents/feature-review.md`, and `.claude/hooks/validate-feature-review-coverage.ps1` (and all `.github/instructions/` mirrors) all use the uniform tier rule.
- Python rules still reference Black as the formatter.
- Every modified `.claude/rules/` file has a corresponding modified `.github/instructions/` file.
- Existing repository tests still pass against the new coverage thresholds, or any gap is recorded in `artifacts/orchestration/orchestrator-state.json` with a remediation plan and tracked as a follow-up task.

### Phase 2
- A test commit containing a fake secret is rejected.
- A non-conformant commit message is rejected.
- An unclassified project added to `quality-tiers.yml` causes CI / pre-commit validation to fail.
- The PR-pipeline workflow runs and reports per-stage status, even if individual stages are no-ops at this point.

## References

- `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (lines 595-707 = source prompt)
- `docs/ci.research.md` (T1-T4 tier system source of truth)
- `artifacts/research/2026-05-09-prompt-a0-foundation-baseline.md` (research findings, file-by-file inventory, exact quotes for replacement)

