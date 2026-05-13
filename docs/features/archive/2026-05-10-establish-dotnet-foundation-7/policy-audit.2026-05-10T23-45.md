# Policy Audit — Issue #7 (Prompt C1 — Establish .NET Foundation) — Post-Remediation Re-Audit (Pass 2)

- Timestamp: 2026-05-10T23-45
- Feature folder: `docs/features/active/2026-05-10-establish-dotnet-foundation-7/`
- Base branch: `origin/main`
- Merge-base SHA: `01d399c655629e9dd8974da4b00caf6e5a79bbea`
- HEAD SHA at re-audit: `f6118ef5f47224aa8327b23e891ef23c68e5c4f4`
- Work Mode (issue.md): `full-feature`
- Acceptance-criteria sources (work-mode contract): `spec.md` + `user-story.md`; reviewer also reconciles the 30-row `issue.md` `## Acceptance Criteria` table per executor `p14-acceptance-criteria-checkoff.md`.
- Pass type: post-remediation re-audit. Prior-pass artifacts: `policy-audit.2026-05-10T22-30.md`, `code-review.2026-05-10T22-30.md`, `feature-audit.2026-05-10T22-30.md`, `remediation-inputs.2026-05-10T22-30.md`, `remediation-plan.2026-05-10T22-30.md`.

## Re-Audit Scope

The re-audit verifies that the four findings raised in pass 1 (F1, F2, F3, F4) are resolved by the remediation phases R0-R6 executed under `remediation-plan.2026-05-10T22-30.md`, and that no new policy violations were introduced by the remediation work itself. The full branch diff vs `origin/main` remains in scope; the audit is not narrowed to the remediation patch.

## Rejected Scope Narrowing

No caller-supplied scope narrowing was detected. The orchestrator confirmed the same merge-base SHA and feature folder. The audit was performed against the full branch diff vs `origin/main`.

## Evidence Location Compliance

Reviewer scanned the branch diff for files written under non-canonical evidence roots (`artifacts/baselines/`, `artifacts/baseline/`, `artifacts/qa/`, `artifacts/qa-gates/`, `artifacts/evidence/`, `artifacts/coverage/`, `artifacts/post-change/`, `artifacts/regression-testing/`).

- `git diff --name-only 01d399c6...HEAD` shows the only `artifacts/...` paths produced are `artifacts/csharp/coverage.xml` (product output, the canonical C# coverage artifact required by the workflow contract) and `artifacts/openapi/current.json` (product output, the OpenAPI contract artifact). Both are allowed per the remediation-plan conventions section.
- All remediation evidence is recorded under the canonical feature path: `docs/features/active/2026-05-10-establish-dotnet-foundation-7/evidence/{baseline,qa-gates,regression-testing,remediation-baseline,other}/`.
- Verdict: **PASS**.

## Prior-Pass Finding Disposition

### F1 — Coverage on new C# production files (Blocker → RESOLVED)

- Prior verdict: FAIL (blocking). Effective 0% line/0% branch on `Program.cs`, `HealthResponse.cs`, `AssemblyMarker.cs`; cobertura `lines-valid=0` divide-by-zero artifact.
- Remediation: Phase R1 (PR1-T1..PR1-T14) created `tests/TaskMaster.Api.Tests/` (xUnit + Microsoft.AspNetCore.Mvc.Testing + FluentAssertions + NSubstitute + coverlet.collector), added `InternalsVisibleTo("TaskMaster.Api.Tests")` on the API csproj, registered the test project in `quality-tiers.yml` at tier T4, and authored eight passing tests: `HealthEndpointTests` (2 facts), `HealthResponseTests` (4 facts via record-equality + Status + ToString), `AssemblyMarkerTests` (2 facts).
- Post-remediation evidence:
  - `evidence/qa-gates/pr1-t14-per-file-coverage.2026-05-10T22-30.md`: Program.cs 100% line / 100% branch; HealthResponse.cs 100% / 100%; AssemblyMarker.cs vacuously compliant (const-only, no instrumentable lines, verified behavior via two direct unit tests).
  - `evidence/qa-gates/pr5-t5-test-coverage.2026-05-10T22-30.txt`: 11/11 tests pass (3 architecture + 8 API). Per-file numbers reconfirmed.
- Re-audit verdict: **PASS**. The uniform tier rule (line >= 85%, branch >= 75%) is met on every new production file.
- Note on overall headline: the cobertura headline `line-rate=0.0379, branch-rate=0.0096` is dominated by `Microsoft.AspNetCore.OpenApi` source-generated infrastructure attributed to the `TaskMaster.Api` package. The uniform rule applies to changed files in the feature branch; all three audited new files meet the threshold. The source-generator-attributed code is not in-scope for the changed-files coverage rule.

### F2 — Canonical C# coverage artifact (Blocker → RESOLVED)

- Prior verdict: FAIL. `artifacts/csharp/coverage.xml` absent.
- Remediation: Phase R2. `.github/actions/dotnet-test/action.yml` extended with a final PowerShell step that copies the newest `TestResults/*/coverage.cobertura.xml` to `artifacts/csharp/coverage.xml` and fails when no cobertura file is found. `.claude/skills/csharp-qa-gate/SKILL.md` documents the same local copy step. `.gitignore` updated.
- Post-remediation evidence:
  - `evidence/qa-gates/pr2-t1-action-edit-grep.2026-05-10T22-30.txt` (action.yml updated).
  - `evidence/qa-gates/pr2-t2-skill-grep.2026-05-10T22-30.txt` (skill updated).
  - `evidence/qa-gates/pr2-t5-canonical-coverage-emit.2026-05-10T22-30.txt` and `pr5-t6-canonical-coverage.2026-05-10T22-30.txt`: `Test-Path artifacts/csharp/coverage.xml` returns True; XML parse succeeds.
  - Reviewer verified the file exists in the working tree via `Glob artifacts/csharp/*` returning `artifacts/csharp/coverage.xml`.
- Re-audit verdict: **PASS**.

### F3 — NSwag emission silent suppression (Major / PARTIAL → RESOLVED)

- Prior verdict: PARTIAL. `<Target Name="GenerateOpenApi">` used `ContinueOnError="true"` + `IgnoreExitCode="true"`, silently swallowing NSwag failures.
- Remediation: Phase R3. `src/TaskMaster.Api/TaskMaster.Api.csproj` now declares `<EnableNSwagEmission Condition="'$(EnableNSwagEmission)' == ''">false</EnableNSwagEmission>`; the target carries `Condition="'$(EnableNSwagEmission)' == 'true'"`; both suppression attributes are removed; a TODO comment documents the interim hand-authored OpenAPI document and references the upstream NSwag net10 launcher issue.
- Post-remediation evidence:
  - `evidence/qa-gates/pr3-t1-csproj-edit.2026-05-10T22-30.txt`: required patterns present; forbidden suppression attributes absent.
  - `evidence/qa-gates/pr3-t2-build-default.2026-05-10T22-30.txt`: default build (NSwag off) clean.
  - `evidence/regression-testing/pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`: build with `-p:EnableNSwagEmission=true` fails loudly (MSB3073, NSwag launcher exception); EXIT_CODE 1.
  - `evidence/other/pr3-t4-openapi-source-of-truth.2026-05-10T22-30.md`: interim source-of-truth documented.
  - Reviewer spot-check of `src/TaskMaster.Api/TaskMaster.Api.csproj` confirms the property guard and absence of `ContinueOnError`/`IgnoreExitCode`.
- Re-audit verdict: **PASS**. The "do not silently ignore errors" requirement from `general-code-change.md` is satisfied: NSwag failures now fail the build when the feature is enabled. The interim hand-authored OpenAPI is documented and AC24 remains satisfied as PASS in the AC table.

### F4 — Domain-vs-Infrastructure architecture fact not negative-tested (Major / INFO → RESOLVED)

- Prior verdict: PARTIAL/INFO. `DomainProjectDoesNotDependOnInfrastructure` fact was wired but not proven to fire on a real violation; the executor demonstration substituted the Microsoft.VisualBasic fact (P13-T5).
- Remediation: Phase R4. PR4-T1..T6 introduced a temporary `TaskMaster.Infrastructure.Probe` project plus a typed reference from `TaskMaster.Domain.InfraDependencyProbe` into the probe, ran `dotnet test` against `TaskMaster.ArchitectureTests`, captured the failing-types list (which included `TaskMaster.Domain.InfraDependencyProbe`), and reverted the probe and all references cleanly. Post-revert all three architecture facts pass.
- Post-remediation evidence:
  - `evidence/qa-gates/pr4-t1-probe-introduce.2026-05-10T22-30.txt`, `pr4-t2-domain-leak-introduce.2026-05-10T22-30.txt`, `pr4-t3-arch-rewrite-grep.2026-05-10T22-30.txt`.
  - `evidence/regression-testing/pr4-t4-domain-infra-expect-fail.2026-05-10T22-30.txt`: EXIT_CODE 1; failing fact `DomainProjectDoesNotDependOnInfrastructure`; failing-types list references `TaskMaster.Domain.InfraDependencyProbe`.
  - `evidence/qa-gates/pr4-t5-revert.2026-05-10T22-30.txt`, `pr4-t6-post-revert-arch.2026-05-10T22-30.txt`: probe removed; 3/3 facts pass.
- Distinct-from-P13-T5: P13-T5 used `NoProjectDependsOnForbiddenLegacyNamespaces` with Microsoft.VisualBasic; PR4 used `DomainProjectDoesNotDependOnInfrastructure` with a typed Domain→Infrastructure reference. Confirmed by reviewer reading both evidence files.
- Re-audit verdict: **PASS**.

## Minor / Info Deferrals (R5-R8)

Phase R6 (PR6-T1) records explicit deferrals for the four minor / info items raised in `remediation-inputs.2026-05-10T22-30.md`:

- R5 — Redundant `<ImplicitUsings>enable</ImplicitUsings>` in three csproj files. Deferred. Reviewer confirms the redundancy is still present (e.g., `src/TaskMaster.Api/TaskMaster.Api.csproj` line 4). Cost low, blocker risk none. Tracked.
- R6 — Empty `stage-3-dotnet-typecheck` pipeline job. Deferred. Tracked.
- R7 — `--no-build` flag in `.github/actions/dotnet-test/action.yml` may fail in CI when jobs do not share build output. Deferred. Tracked.
- R8 — Plan/spec narrative `T:` vs `P:` mismatch for `Random.Shared`. Deferred. The file is correct; only narrative wording is off.

Evidence: `evidence/other/pr6-t1-minor-deferrals.2026-05-10T22-30.md`. Re-audit verdict: ACCEPTED (defer-acceptable per remediation-plan and remediation-inputs).

## Toolchain Coverage Verdicts (per-language)

The reviewer did not re-run language toolchains in this environment; the verdicts below cite executor remediation evidence under `evidence/qa-gates/` (timestamp `2026-05-10T22-30`).

### C# — changed files present

| Stage | Evidence | Result | Verdict |
|---|---|---|---|
| 1 Formatting (`dotnet csharpier check .`) | `evidence/qa-gates/pr5-t1-format.2026-05-10T22-30.txt` | Exit 0 (after one auto-fix iteration; final pass clean) | **PASS** |
| 2 Lint / Build w/ analyzers (`dotnet build`) | `evidence/qa-gates/pr5-t2-build.2026-05-10T22-30.txt` | Exit 0; 0 warnings, 0 errors; TreatWarningsAsErrors active | **PASS** |
| 3 Type check (nullable) | Same build log; `pr5-t3-typecheck.2026-05-10T22-30.txt` records zero nullable warnings | **PASS** |
| 4 Architecture (`dotnet test` on `TaskMaster.ArchitectureTests`) | `evidence/qa-gates/pr5-t4-architecture.2026-05-10T22-30.txt` | 3/3 facts pass | **PASS** |
| 5 Unit tests (`dotnet test --collect:"XPlat Code Coverage"`) | `evidence/qa-gates/pr5-t5-test-coverage.2026-05-10T22-30.txt` | Exit 0; 11/11 pass (3 arch + 8 API) | **PASS** |
| 6 Coverage (uniform tier rule) | `evidence/qa-gates/pr1-t14-per-file-coverage.2026-05-10T22-30.md` and `pr5-t5-test-coverage.2026-05-10T22-30.txt` | Program.cs 100%/100%; HealthResponse.cs 100%/100%; AssemblyMarker.cs vacuous (const-only) | **PASS** |
| 7 Canonical coverage artifact | `evidence/qa-gates/pr5-t6-canonical-coverage.2026-05-10T22-30.txt`; reviewer verified `artifacts/csharp/coverage.xml` present on disk | File exists; XML parses | **PASS** |
| 8 Contract/schema (NSwag) | `evidence/regression-testing/pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`; `evidence/other/pr3-t4-openapi-source-of-truth.2026-05-10T22-30.md` | Loud-fail when enabled; interim hand-authored OpenAPI documented | **PASS** (resolution of prior F3 PARTIAL) |
| 9 Integration | No integration target in scope for the empty-skeleton feature | n/a | UNVERIFIED (vacuous — non-goal) |

### Non-C# languages

- TypeScript, Python, PowerShell: no changed source files in the branch diff. No coverage verdict required.
- YAML/JSON/Markdown: not subject to coverage rule.

## Mandatory Seven-Stage Loop (`.claude/rules/general-code-change.md`)

Per `general-code-change.md`, the seven-stage loop is: Format → Lint → Type check → Architecture → Unit tests → Contract/schema → Integration.

| Stage | C# Result (post-remediation) | Evidence |
|---|---|---|
| 1 Format | PASS | `pr5-t1-format.2026-05-10T22-30.txt` |
| 2 Lint | PASS | `pr5-t2-build.2026-05-10T22-30.txt` |
| 3 Type check | PASS | `pr5-t2-build.2026-05-10T22-30.txt` (nullable warnings-as-errors) |
| 4 Architecture | PASS | `pr5-t4-architecture.2026-05-10T22-30.txt` |
| 5 Unit tests | PASS | `pr5-t5-test-coverage.2026-05-10T22-30.txt` (11/11) |
| 6 Contract / schema | PASS (resolved) | `pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`; `pr3-t4-openapi-source-of-truth.2026-05-10T22-30.md` |
| 7 Integration | UNVERIFIED (vacuous — non-goal for empty skeleton) | n/a |

Single-pass closure: `evidence/qa-gates/phase-r5-restart-gate.2026-05-10T22-30.md` records all six final-QA EXIT_CODE values as 0 in the same pass (after one csharpier auto-fix iteration earlier in the loop).

## Architecture Boundaries (`.claude/rules/architecture-boundaries.md`)

| Assertion | Mechanism | Status |
|---|---|---|
| No project depends on `Microsoft.Office.Interop.Outlook` | `NoProjectDependsOnOutlookInterop` | PASS |
| No project depends on `System.Windows.Forms`, `System.Web`, `Microsoft.VisualBasic` | `NoProjectDependsOnForbiddenLegacyNamespaces` | PASS (P13-T5 negative-test) |
| `TaskMaster.Domain` types do not depend on `TaskMaster.Infrastructure*` | `DomainProjectDoesNotDependOnInfrastructure` | PASS (PR4-T4 negative-test demonstrates the fact fires on a typed violation) |

The prior-pass concern that this fact might not detect typed references is now resolved: `evidence/regression-testing/pr4-t4-domain-infra-expect-fail.2026-05-10T22-30.txt` shows the fact reports `TaskMaster.Domain.InfraDependencyProbe` in the failing-types list when a Domain→Infrastructure typed reference exists.

## Quality Tier Compliance

`quality-tiers.yml` registers all four .NET projects:

- `TaskMaster.Domain` → T2 (core domain).
- `TaskMaster.Api` → T3 (adapter glue).
- `TaskMaster.ArchitectureTests` → T4 (test scaffolding).
- `TaskMaster.Api.Tests` → T4 (test scaffolding; added in Phase R1).

Coverage gates per the uniform tier rule apply. All audited new production files meet line >= 85% / branch >= 75% per `pr1-t14-per-file-coverage.2026-05-10T22-30.md`.

## Banned APIs and Determinism Infrastructure

Unchanged from pass 1. All PASS:

- `BannedSymbols.txt` bans the five required APIs; wired via `<AdditionalFiles>` in `Directory.Build.props`.
- `Microsoft.CodeAnalysis.BannedApiAnalyzers` referenced with `PrivateAssets="all"`.
- `Microsoft.Extensions.TimeProvider.Testing` pinned in `Directory.Packages.props`.
- Representative banned-API violation demonstrated (deviation #5 documented; analyzer wiring exercised).

## Determinism (`.claude/rules/general-unit-test.md`)

Post-remediation test code in this feature:

- `HealthEndpointTests.cs`: uses `WebApplicationFactory<Program>` via `IClassFixture<T>`, FluentAssertions, no clocks, no randomness, no sleeps, no `Task.Delay`. Deterministic.
- `HealthResponseTests.cs`, `AssemblyMarkerTests.cs`: pure assertions on a record and a const string. Deterministic.
- `NoComArchitectureTests.cs`: unchanged; deterministic.

PASS.

## File Size Limit (`general-code-change.md`)

Reviewer confirms all changed C# files (production + test) remain under 500 lines. Largest test file is `HealthEndpointTests.cs` (well under 500); largest test code file is `NoComArchitectureTests.cs` at 88 lines.

PASS.

## Tonality (`.claude/rules/tonality.md`)

Reviewer-authored content uses professional tone; no humor, hyperbole, or decorative metaphor. PASS.

## Findings Summary (Pass 2)

| ID | Severity | Status | Disposition |
|---|---|---|---|
| F1 (pass 1) | Blocker | **RESOLVED** | Phase R1 added test project; per-file coverage meets uniform tier rule. Evidence: `pr1-t14-per-file-coverage.2026-05-10T22-30.md`, `pr5-t5-test-coverage.2026-05-10T22-30.txt`. |
| F2 (pass 1) | Blocker | **RESOLVED** | Phase R2 emits canonical `artifacts/csharp/coverage.xml`. Evidence: `pr5-t6-canonical-coverage.2026-05-10T22-30.txt`; reviewer verified file on disk. |
| F3 (pass 1) | Major (PARTIAL) | **RESOLVED** | Phase R3 removed silent suppression; gated emission; loud-fail demonstrated. Evidence: `pr3-t1-csproj-edit.2026-05-10T22-30.txt`, `pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`. |
| F4 (pass 1) | Major (INFO) | **RESOLVED** | Phase R4 executable negative test demonstrates fact fires on Domain→Infrastructure typed reference. Evidence: `pr4-t4-domain-infra-expect-fail.2026-05-10T22-30.txt`. |
| F5 (pass 1) | INFO | **RESOLVED** | Superseded by F3 resolution; silent fallback removed. |
| New pass-2 findings | — | **NONE** | No new policy violations introduced by remediation. |

## Overall Verdict (Pass 2)

**PASS — remediation complete.** All four prior-pass blocking and major findings are verifiably resolved with executor evidence and reviewer spot-checks. Minor / info items R5-R8 are deferred per the documented deferral protocol. No new blocking findings.
