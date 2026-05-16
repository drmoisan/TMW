# Policy Audit — boundary-contract-and-e2e-infra (Issue #19)

- Timestamp: 2026-05-15T03-15
- Base branch: `main` @ `7a9c036505b6908727d6e373f5d1505bf5334950`
- Head branch: `feature/boundary-contract-and-e2e-infra-19` @ `fdbc1509a68c364a5fafa4fb0e105426edc1ec10`
- Work Mode: `full-feature` (sourced from `issue.md`)
- AC sources: `spec.md` and `user-story.md`

## Scope (Full Branch Diff vs Base)

- 56 files changed, +4706/-173.
- Languages with changed files in the branch diff: C# (`.cs`, `.csproj`, `.props`), TypeScript (`.ts`, `.mjs`), YAML/CI (`.yml`, `.yaml`), JSON (`.json`).
- PowerShell: no changed `.ps1` files in the branch diff.
- Python: no changed `.py` files in the branch diff.

## Rejected Scope Narrowing

None. Caller prompt did not attempt narrowing beyond the documented full-branch scope.

## Policy Reading Order Applied

1. `CLAUDE.md` (always loaded).
2. `.claude/rules/general-code-change.md`.
3. `.claude/rules/general-unit-test.md`.
4. Language-specific: `.claude/rules/csharp.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`.
5. Cross-cutting: `.claude/rules/architecture-boundaries.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/tonality.md`.

## Toolchain Loop — Evidence

| Stage | Language | Evidence | Result |
|---|---|---|---|
| 1. Format | C# | `evidence/qa-gates/final-csharp-format.md` (`dotnet csharpier check .`, EXIT 0) | PASS |
| 1. Format | TS | `evidence/qa-gates/final-ts-format.md` (`npm run format:check`, EXIT 0) | PASS |
| 2. Lint | C# (analyzers in build) | `evidence/qa-gates/final-csharp-build.md` (`dotnet build TaskMaster.sln`, EXIT 0) | PASS |
| 2. Lint | TS | `evidence/qa-gates/final-ts-lint.md` (`npm run lint`, EXIT 0) | PASS |
| 3. Type-check | C# (nullable in build) | `evidence/qa-gates/final-csharp-build.md` (EXIT 0) | PASS |
| 3. Type-check | TS | `evidence/qa-gates/final-ts-typecheck.md` (`npm run typecheck`, EXIT 0) | PASS |
| 4. Architecture | C# | `evidence/qa-gates/final-csharp-architecture.md` (`dotnet test tests/TaskMaster.ArchitectureTests/...`, EXIT 0) | PASS |
| 4. Architecture | TS | `evidence/qa-gates/final-ts-depcruise.md` (`npm run depcruise`, EXIT 0) | PASS |
| 5. Unit Tests | C# | `evidence/qa-gates/final-csharp-test.md` (`dotnet test ... --collect:"XPlat Code Coverage"`, EXIT 0) | PASS |
| 5. Unit Tests | TS | `evidence/qa-gates/final-ts-test.md` (`npm run test:coverage`, EXIT 0; 31 tests) | PASS |
| 6. Contract / schema | OpenAPI | `evidence/qa-gates/final-spectral-openapi.md` (Spectral EXIT 0); `evidence/regression-testing/validation-oasdiff-breaking.md` (oasdiff EXIT 1 on synthetic break, message names offending field `label`); `evidence/regression-testing/validation-oasdiff-bypass.md` (EXIT 0 with version bump) | PASS |
| 7. Integration | — | Covered by `stage-7-integration` in `pr-pipeline.yml` and the host-test surface in `TaskMaster.Api.Tests`; E2E lane separately validated in `evidence/regression-testing/validation-e2e-smoke.md` (fail-closed verified locally; CI invocation path documented). | PASS |

Note: PowerShell stages are not exercised by this feature; no PowerShell production code changed.

## Coverage Verification

### TypeScript

- Coverage artifact: `coverage/lcov.info` — EXISTS.
- Repo-wide: line 99.27%, branch 95.55% (source: `evidence/qa-gates/final-ts-test.md`, corroborated by `evidence/qa-gates/coverage-delta.md`). Both exceed the uniform 85% line / 75% branch thresholds.
- New files: `src/api-client/v1.ts` is auto-generated, type-only, excluded from coverage by `vitest.config.ts`. `src/api-client/eslint-guard.test.ts` is a test file (excluded). `tests/e2e/*.ts` are E2E specs (excluded). `playwright.config.ts` is config (excluded). No new production runtime files require coverage uplift.
- Modified files: `src/taskpane/classifier-client.ts` 100% line / 100% branch (no regression). `src/taskpane/taskpane.ts` 98.61% line / 92.85% branch (+0.04 pp line / +0.55 pp branch — improvement).
- Verdict: PASS.

### C#

- Coverage artifact: `tests/TaskMaster.Api.Tests/TestResults/.../coverage.cobertura.xml` — EXISTS (the artifact path mapping in the skill cites `artifacts/csharp/coverage.xml`, but the canonical evidence-locations skill places per-project cobertura files under each test project's `TestResults/`; both `final-csharp-test.md` and `coverage-delta.md` parse those files and report repo-wide numbers for `TaskMaster.Api`).
- `TaskMaster.Api` package: line 23.18% (was 18.97% baseline, +4.21 pp); branch 6.14% (was 4.12%, +2.02 pp).
- Changed lines: no regression. Coverage improved on changed lines (the host-integration tests in `TaskMaster.Api.Tests` exercise +29 of the +40 added valid lines).
- Repo-wide `TaskMaster.Api` line/branch coverage remains below the uniform 85%/75% thresholds. This is a pre-existing baseline gap recorded in `baseline-csharp-test.md` (the project is mostly ASP.NET host wiring exercised partially). Issue #19 did not cause the gap; it materially improved it.
- Verdict: PARTIAL. Per the uniform-tier rule in `.claude/rules/quality-tiers.md`, the `TaskMaster.Api` package fails the absolute 85% line / 75% branch thresholds. The "no regression on changed lines" half is met (coverage improved). The "meets thresholds" half is not met in absolute terms; the gap is pre-existing.

### PowerShell / Python

- No changed files in scope. Verdict: N/A (legitimate — zero changed files for each language on the branch).

## File Size Limit (500 lines)

| File | Lines | Status |
|---|---|---|
| `src/api-client/v1.ts` | 202 | PASS (also generated, exempt by spirit; under limit anyway) |
| `artifacts/openapi/current.json` | 212 | PASS (generated artifact; under limit) |
| `tests/e2e/smoke.spec.ts` | 124 | PASS |
| `tests/e2e/auth.setup.ts` | 117 | PASS |
| `src/taskpane/classifier-client.ts` | 107 | PASS |
| `.github/actions/contract/action.yml` | 101 | PASS |
| `eslint.config.mjs` | 165 | PASS |

All other touched files are under 500 lines.

## Determinism / Banned APIs

- C#: `BannedSymbols.txt` enforced via analyzers in build. `final-csharp-build.md` EXIT 0 implies no banned-API hits.
- TypeScript: `eslint.config.mjs` retains the `no-restricted-syntax` ban on `Date.now`/`setTimeout`/`setInterval`/`Math.random` for `src/**/*.ts`. The new `src/api-client/v1.ts` is type-only and contains no runtime calls. `tests/e2e/auth.setup.ts` calls `fetch` (allowed; not on the ban list); no real `setTimeout`/`sleep`/`Date.now()` are introduced.
- Playwright `timeout`/`expect.timeout` literals (`30_000`, `10_000`) are framework configuration, not test wait hacks; permitted.
- Verdict: PASS.

## Architecture Boundaries

- C#: `evidence/qa-gates/final-csharp-architecture.md` (NetArchTest project) EXIT 0.
- TypeScript: `evidence/qa-gates/final-ts-depcruise.md` (dependency-cruiser) EXIT 0.
- No new COM/VSTO/Interop references introduced. The new `tests/e2e/` and `src/api-client/` modules do not import host-bound APIs into domain code.
- Verdict: PASS.

## Suppression Policy (TypeScript)

- No `// eslint-disable-next-line` or `// @ts-expect-error` suppressions introduced in the new TS code (verified by inspection of `tests/e2e/`, `src/api-client/`, and modified `src/taskpane/classifier-client.ts`).
- The `eslint.config.mjs` file disables `@typescript-eslint/consistent-indexed-object-style` for `src/api-client/v1.ts` with a justification comment. This is configuration-level scoping, not a code-level disable comment, and is acceptable for generated output.
- Verdict: PASS.

## Quality Tiers / Project Classification

- `evidence/other/quality-tiers-scope-check.md` confirms no new projects were added, so no `quality-tiers.yml` entries were required. Existing entries unchanged.
- Verdict: PASS.

## Secrets / Configuration

- `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `E2E_API_BASE_URL` are read from environment variables in `tests/e2e/auth.setup.ts` and supplied via `${{ secrets.* }}` in both workflows. No secret values are committed.
- Auth setup fails closed with an explicit error naming missing variables (validated in `validation-e2e-smoke.md` run 1).
- Verdict: PASS.

## Evidence Location Compliance

- Scanned branch diff for `artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, `artifacts/coverage/` writes: none. The two changed paths under `artifacts/` are `artifacts/openapi/current.json` (the canonical OpenAPI snapshot — required by spec) and `artifacts/pr_context.*` (PR context regen). Neither is an evidence kind covered by the canonical `<FEATURE>/evidence/<kind>/` rule.
- All evidence artifacts for this feature are correctly placed under `docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/evidence/<kind>/`.
- Verdict: PASS.

## Tonality

- Reviewed artifacts use measured, evidence-first wording. No hyperbole or humor present.
- Verdict: PASS.

## Overall Policy Verdict

PARTIAL.

- All toolchain stages PASS.
- Architecture and determinism gates PASS.
- TypeScript coverage PASS with material headroom; no regression on changed lines.
- C# coverage PARTIAL: `TaskMaster.Api` absolute line (23.18%) and branch (6.14%) coverage are below the uniform 85%/75% thresholds. The gap is pre-existing baseline state, not introduced by Issue #19; coverage improved on both axes during this feature. The pre-existing gap is recorded but does not block this feature per the "no regression on changed lines" half of the gate.

## Remediation Triggers

1. `TaskMaster.Api` repo-wide coverage below uniform thresholds (pre-existing; not introduced by this feature). Recorded in `remediation-inputs.<timestamp>.md` for visibility; not a blocking finding for issue #19 merge.
