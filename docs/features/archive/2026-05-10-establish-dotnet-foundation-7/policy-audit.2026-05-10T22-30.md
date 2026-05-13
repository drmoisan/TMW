# Policy Audit — Issue #7 (Prompt C1 — Establish .NET Foundation)

- Timestamp: 2026-05-10T22-30
- Feature folder: `docs/features/active/2026-05-10-establish-dotnet-foundation-7/`
- Base branch: `origin/main`
- Merge-base SHA: `01d399c655629e9dd8974da4b00caf6e5a79bbea`
- Work Mode (issue.md): `full-feature`
- Acceptance-criteria sources (work-mode contract): `spec.md` + `user-story.md`
  - Note: issue.md also carries an explicit `## Acceptance Criteria` section that enumerates 30 criteria. Although the work-mode contract for `full-feature` reads `spec.md` + `user-story.md` rather than `issue.md`, the executor `p14-acceptance-criteria-checkoff.md` is keyed to the 30 issue.md criteria. The feature audit (companion artifact) honors the work-mode contract for evaluation while also reporting on the executor's issue.md table for traceability.

## Scope

Branch diff vs `origin/main` (merge-base `01d399c6`): 129 changed files. Material non-evidence changes include:

- C# production code: `src/TaskMaster.Api/{Program.cs,HealthResponse.cs,*.csproj,*.http,Properties/launchSettings.json,appsettings*.json}`, `src/TaskMaster.Domain/{AssemblyMarker.cs,*.csproj}`.
- C# test code: `tests/TaskMaster.ArchitectureTests/{NoComArchitectureTests.cs,*.csproj}`.
- Solution + central build: `TaskMaster.sln`, `Directory.Build.props`, `Directory.Packages.props`, `BannedSymbols.txt`, `.editorconfig`, `.config/dotnet-tools.json`, `quality-tiers.yml`, `.gitignore`.
- CI: `.github/workflows/pr-pipeline.yml`, four new `.github/actions/dotnet-*` composite actions.
- Rule / instruction / skill / agent prose: `.claude/rules/csharp.md`, `.claude/skills/{csharp-qa-gate,invoke-csharp-engineer,feature-review-workflow}/SKILL.md`, `.claude/agents/csharp-typed-engineer.md`, `.github/skills/feature-review-workflow/SKILL.md`, `.github/agents/csharp-typed-engineer.agent.md`, `.github/instructions/csharp-{code-change,unit-test}.instructions.md`.

Languages with changed files in the branch diff (coverage scope): **C#** (production + tests), **YAML** (GitHub Actions, gitleaks config), **JSON** (manifests, settings), **Markdown** (rules/instructions/skills). Only C# requires a code-coverage verdict per the workflow contract.

## Rejected Scope Narrowing

No caller-supplied scope narrowing was detected in the orchestrator prompt. The orchestrator stated "Scope determination is your responsibility per the SKILL contract." The audit was performed against the full branch diff vs `origin/main`.

## Policy Reading Order

1. `CLAUDE.md` (standing instructions, always loaded).
2. `.claude/rules/general-code-change.md`.
3. `.claude/rules/general-unit-test.md`.
4. `.claude/rules/quality-tiers.md`.
5. `.claude/rules/architecture-boundaries.md`.
6. `.claude/rules/csharp.md`.
7. `.claude/rules/tonality.md`.

## Evidence Location Compliance

The reviewer scanned the branch diff for files written under non-canonical evidence roots (`artifacts/baselines/`, `artifacts/qa/`, `artifacts/evidence/`, `artifacts/coverage/`).

- `git diff --name-only 01d399c6...HEAD` returns **zero** files under `artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or `artifacts/evidence/`.
- All executor evidence is recorded under the canonical feature path: `docs/features/active/2026-05-10-establish-dotnet-foundation-7/evidence/{baseline,qa-gates,regression-testing}/`.
- Verdict: **PASS**.

## Toolchain Coverage Verdicts (per-language)

The reviewer did not re-run language toolchains in this environment; the verdicts below cite the existing executor evidence under `evidence/qa-gates/` (timestamp `2026-05-10T20-14`).

### C# — changed files present

| Stage | Evidence | Result | Verdict |
|---|---|---|---|
| Formatting (`dotnet csharpier check .`) | `evidence/qa-gates/p5-t6-csharpier-check.2026-05-10T20-14.txt`, `p14-t2-csharpier.2026-05-10T20-14.txt` | Exit 0; "Formatted ... in place" / "Checked ... files. ... were already formatted" | **PASS** |
| Lint / Build w/ analyzers (`dotnet build`) | `evidence/qa-gates/p6-t4-dotnet-build.2026-05-10T20-14.txt`, `p7-t6-build.2026-05-10T20-14.txt`, `p14-t2-build.2026-05-10T20-14.txt` | Exit 0; zero warnings (TreatWarningsAsErrors=true) | **PASS** |
| Type check (nullable) | Centralized in `Directory.Build.props` (`<Nullable>enable</Nullable>`); enforced via `dotnet build`. Same evidence as Lint. | Zero nullable warnings | **PASS** |
| Architecture (`dotnet test` against `TaskMaster.ArchitectureTests`) | `evidence/qa-gates/p8-t2-archtests.2026-05-10T20-14.txt`, `p12-t4-architecture.2026-05-10T20-14.txt`, `p14-t2-architecture.2026-05-10T20-14.txt` | 3/3 facts passed (No-Outlook, No-legacy-namespaces, Domain-vs-Infra) | **PASS** |
| Unit tests (`dotnet test --collect:"XPlat Code Coverage"`) | `evidence/qa-gates/p12-t5-test-coverage.2026-05-10T20-14.txt`, `p14-t2-coverage.2026-05-10T20-14.txt` | Exit 0; 3/3 tests passed (architecture facts only — no unit tests for production code) | PASS (test execution) |
| Coverage (uniform tier rule per `quality-tiers.md`) | `evidence/qa-gates/p14-t2-coverage.2026-05-10T20-14.txt` (cobertura headline) | `line-rate=1`, `branch-rate=1`, `lines-valid=0`, `branches-valid=0`. The 100% headline is a divide-by-zero artifact: no assembly was actually exercised by a unit test. New production files `Program.cs`, `HealthResponse.cs`, `AssemblyMarker.cs` have effective line coverage of 0% and branch coverage of 0% against the uniform tier rule (line >= 85%, branch >= 75%). | **FAIL** |

C# coverage canonical artifact: the workflow contract names `artifacts/csharp/coverage.xml` as the canonical artifact path. That file is **absent** from the repository. The executor emitted `TestResults/<run-guid>/coverage.cobertura.xml` (not committed). Per the workflow contract, coverage artifacts are mandatory for every language with changed files; absence of the canonical artifact is a separate **FAIL**.

### Non-C# languages

- TypeScript, Python, PowerShell: **no changed source files** in the branch diff outside documentation. Coverage verdict not applicable.
- YAML/JSON: not subject to a coverage rule.

## Mandatory Seven-Stage Loop (`.claude/rules/general-code-change.md`)

Per `general-code-change.md`, the seven-stage loop is: Format → Lint → Type check → Architecture → Unit tests → Contract/schema → Integration.

| Stage | C# Result | Evidence |
|---|---|---|
| 1 Format | PASS | `p14-t2-csharpier.2026-05-10T20-14.txt` |
| 2 Lint | PASS | `p14-t2-build.2026-05-10T20-14.txt` |
| 3 Type check | PASS | `p14-t2-build.2026-05-10T20-14.txt` (nullable warnings-as-errors) |
| 4 Architecture | PASS | `p14-t2-architecture.2026-05-10T20-14.txt` |
| 5 Unit tests | PASS (execution); FAIL (coverage for new production files) | `p14-t2-coverage.2026-05-10T20-14.txt` |
| 6 Contract / schema | PARTIAL | `evidence/qa-gates/p9-t4-openapi-emit.2026-05-10T20-14.txt`: `artifacts/openapi/current.json` was hand-authored; NSwag.MSBuild target is wired with `ContinueOnError="true"` but the live NSwag launcher throws at net10.0 build time. Documented as deviation #4 in `p14-acceptance-criteria-checkoff.md`. |
| 7 Integration | UNVERIFIED | No integration tests exist yet (empty skeleton; non-goal per `spec.md`). Verdict UNVERIFIED rather than FAIL because no integration target is in scope for this feature. |

## Architecture Boundaries (`.claude/rules/architecture-boundaries.md`)

| Assertion | Mechanism | Status |
|---|---|---|
| No project depends on `Microsoft.Office.Interop.Outlook` | `NoProjectDependsOnOutlookInterop` in `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs` | PASS (test green; see `p8-t2-archtests`) |
| No project depends on `System.Windows.Forms`, `System.Web`, `Microsoft.VisualBasic` | `NoProjectDependsOnForbiddenLegacyNamespaces` | PASS |
| `TaskMaster.Domain` types do not depend on `TaskMaster.Infrastructure*` | `DomainProjectDoesNotDependOnInfrastructure` | PASS (test green); however executor recorded deviation #6: NetArchTest 1.3.2 did not catch a typed reference probe during demonstration. Recorded as a follow-up risk; the fact is wired and would catch namespace-typed dependencies; the test corpus is currently empty of Infrastructure projects so the assertion is not negatively challenged on this feature. |

## Quality Tier Compliance

`quality-tiers.yml` registers the three new .NET projects:

- `TaskMaster.Domain` → T2 (core domain, currently empty).
- `TaskMaster.Api` → T3 (adapter glue around ASP.NET Core / OpenAPI).
- `TaskMaster.ArchitectureTests` → T4 (test scaffolding).

Coverage gates per the uniform tier rule (>= 85% line / >= 75% branch) apply uniformly. `Program.cs` and `HealthResponse.cs` live in a T3 project; `AssemblyMarker.cs` in a T2 project. Neither has any unit test exercising it; coverage verdict is FAIL above.

## Banned APIs and Determinism Infrastructure

- `BannedSymbols.txt` at solution root bans `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, `Task.Delay`. Wired via `<AdditionalFiles>` in `Directory.Build.props`. Verified by reading both files; PASS.
- `Microsoft.CodeAnalysis.BannedApiAnalyzers` referenced with `PrivateAssets="all"` in the shared analyzer ItemGroup. PASS.
- `Microsoft.Extensions.TimeProvider.Testing` pinned at 9.5.0 in `Directory.Packages.props` and referenced in `TaskMaster.ArchitectureTests.csproj`. PASS.
- Representative banned-API violation demonstrated (`P:System.Random.Shared` in lieu of `T:System.DateTime.UtcNow` per executor deviation #5; the underlying analyzer wiring is exercised). Evidence: `evidence/regression-testing/p13-t2-banned-api-build.2026-05-10T20-14.txt`. PASS.

## Determinism (`.claude/rules/general-unit-test.md`)

The only test code in this feature is `NoComArchitectureTests.cs`. It uses xUnit `[Fact]`, FluentAssertions, and `NetArchTest.Rules` — no clocks, no randomness, no sleeps, no `Task.Delay`. Determinism requirements are vacuously satisfied. PASS.

## File Size Limit (`general-code-change.md`)

- Largest changed C# file: `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs` at 88 lines. All other production files are < 30 lines. PASS.

## Tonality (`.claude/rules/tonality.md`)

Reviewer authored content uses professional tone; no humor, hyperbole, or decorative metaphor. PASS.

## Findings Summary

| ID | Severity | Area | Finding |
|---|---|---|---|
| F1 | **FAIL (blocking)** | C# coverage | New production files `src/TaskMaster.Api/Program.cs`, `src/TaskMaster.Api/HealthResponse.cs`, `src/TaskMaster.Domain/AssemblyMarker.cs` have effective 0% line coverage and 0% branch coverage. The cobertura headline `line-rate=1, branch-rate=1` is a divide-by-zero artifact (`lines-valid=0`). Uniform tier rule requires line >= 85% and branch >= 75% for new files. |
| F2 | **FAIL** | Coverage artifact location | Canonical C# coverage artifact `artifacts/csharp/coverage.xml` is absent. Executor emitted `TestResults/<run-guid>/coverage.cobertura.xml`, which is not committed and not at the canonical path required by the workflow contract. |
| F3 | PARTIAL | Contract/schema (Stage 6) | `artifacts/openapi/current.json` was hand-authored rather than emitted by NSwag.MSBuild at build time due to NSwag launcher incompatibility with net10.0. Target is wired but suppressed by `ContinueOnError="true"`. Acknowledged as deviation #4. |
| F4 | INFO | Architecture-rule demo | Executor deviation #6 (Domain-vs-Infrastructure NetArchTest probe). The fact is wired; the negative-test demonstration substituted a different fact. No active regression, but the assertion is unproven against a concrete Infrastructure type. |
| F5 | INFO | NSwag suppression risk | `ContinueOnError="true"` + `IgnoreExitCode="true"` on the NSwag MSBuild target means future NSwag failures will silently fall back to the committed JSON file. Consider adding a CI check that re-emits the file and diffs against the committed copy once NSwag publishes a net10-compatible launcher. |

## Appendix B — Command Reference

Commands recorded in executor evidence (not re-run by reviewer):

- `dotnet csharpier check .` — `evidence/qa-gates/p14-t2-csharpier.2026-05-10T20-14.txt`
- `dotnet build TaskMaster.sln` — `evidence/qa-gates/p14-t2-build.2026-05-10T20-14.txt`
- `dotnet test TaskMaster.sln --no-build` (architecture) — `evidence/qa-gates/p14-t2-architecture.2026-05-10T20-14.txt`
- `dotnet test TaskMaster.sln --no-build --collect:"XPlat Code Coverage" --results-directory TestResults/` — `evidence/qa-gates/p14-t2-coverage.2026-05-10T20-14.txt`
- `git diff --name-only 01d399c655629e9dd8974da4b00caf6e5a79bbea...HEAD` — used by reviewer to determine scope.

## Overall Verdict

**FAIL — remediation required.** Two FAIL findings (F1 coverage shortfall on new files; F2 missing canonical coverage artifact) and one PARTIAL (F3 NSwag emission). All other policy gates are PASS or vacuously satisfied for the empty-skeleton scope.
