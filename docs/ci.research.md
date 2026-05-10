# Optimal QC stack

Honest answer: no. What I described is the **mainstream default** stack, not the optimal one for a tightly QC'd environment with this complexity profile. For an architecture that's: (a) extracting a shell-and-core boundary that *must* not rot, (b) shipping ML classifiers where line coverage is misleading, (c) replacing MAPI/UDF persistence with Graph extended properties where data integrity matters, and (d) running two hosts in parallel during coexistence — the toolchain needs categories I left out entirely.

Here's what's actually missing and why each matters for *this* system specifically:

## Categories I should have included

**1. Architecture-boundary enforcement.** The entire migration thesis is "core libraries with no Outlook PIA references, host adapters at the edges." Without automated enforcement, that boundary erodes the moment someone adds a `using Microsoft.Office.Interop.Outlook;` to `TaskMaster.Domain` to fix a one-off bug. Need a tool category that fails the build when layer rules are violated — for both the .NET side (architecture-test framework) and the TS side (dependency-graph linter that enforces "task pane code can't import service code directly," etc.). This is non-negotiable for shell-and-core; without it, you re-create the `ApplicationGlobals` god-graph in a new shape within 18 months.

**2. Mutation testing.** For the classifier code (SpamBayes, Triage), line coverage is actively misleading — you can have 100% coverage and still not detect that a comparison flipped from `>` to `>=`. Mutation testing is the only objective signal that tests actually constrain behavior. This belongs in the gating set for the classifier modules specifically, not the whole codebase.

**3. Property-based / generative testing.** ToDo ID allocation, hierarchy ops, splits, the categories↔extended-properties mapping — these are exactly the shape of code where example-based tests miss the edge cases (empty hierarchies, ID collisions on rapid edits, unicode in tags, etc.). Generative tests are how you find them before users do.

**4. Contract / schema tests at the host↔service boundary.** The Office.js task pane and the .NET service drift independently. Without a producer/consumer contract test (or at minimum a generated-and-versioned schema both sides validate against), the boundary breaks silently in production. Same applies to the Graph extended-properties schema — version it, validate writes against it, and run schema-compatibility tests on every change.

**5. Golden/snapshot tests for classifier outputs.** Fix a corpus of representative emails, snapshot the classification output, and fail CI on unintended drift. This catches "model retrained, suddenly 12% of emails get a different category" before rollout.

**6. Stacked static analyzers, not one.** For complex .NET, a single analyzer set (whatever the brand) misses dispose-pattern bugs, async-void hazards, ConfigureAwait drift, threading violations — all of which the current codebase has. The tightly QC'd answer is "stack 2–3 analyzer packages with disjoint rule coverage and treat warnings as errors," not "pick one." Same for ESLint — type-aware rules (the slow ones most teams disable) catch the non-trivial bugs.

**7. Runtime boundary validation.** Compile-time types lie at I/O boundaries. Every Graph response, every Office.js callback payload, every settings-store read should be validated against a schema at runtime, with the schema being the source of truth for the static type. This is a *design choice* but it requires tooling support, so it belongs in the toolchain conversation.

**8. Performance/regression benchmarks.** QuickFiler's whole value prop is speed. The classifier hot paths and the queue pipeline need benchmark tests with regression gates, not just functional tests.

**9. Determinism enforcement for tests.** Flaky tests in an async-heavy add-in are inevitable without explicit fakes for time, randomness, and the scheduler. Need a category for "deterministic test infrastructure" — controllable clocks, virtual time schedulers, seed-controlled RNG — wired into the test base classes.

## What I'd actually keep from the first list

Format/style tools and basic test runners are commodities — those choices don't materially affect quality. The mistake in my first answer was treating the whole toolchain as commodity-level.

## The shape of the right answer

For a tightly QC'd build, the gating CI pipeline should have ~7 quality stages, not 3:

1. format check
2. lint (style + type-aware + security rules, stacked)
3. typecheck (strict null + strict mode)
4. **architecture-boundary tests** ← missing from my first answer
5. unit + property tests
6. **mutation score gate** on critical modules ← missing
7. **contract/schema compatibility check** ← missing
8. integration + golden tests
9. E2E (separate, slower lane)
10. **benchmark regression gate** on hot paths ← missing

Each stage has a numeric gate, not just pass/fail. Mutation score < 75% on classifier code = block merge. Schema breaking change without a version bump = block merge. Boundary violation = block merge.

# Concrete Pipeline Spec

Below is a concrete pipeline spec keyed to the migration's architecture. Two ideas drive it: **rigor is per-module, not uniform**, and **gates ramp up across migration phases** so you're not paying for infrastructure before there's code to apply it to.

## 1. Module rigor tiers

Not every file gets every gate. Map every project/module to one of four tiers, written into a `quality-tiers.yml` at repo root that the CI reads.

| Tier | What's in it | Why this tier |
|---|---|---|
| **T1 — Critical** | Classifier engines (SpamBayes, Triage); ToDo ID allocator + hierarchy ops; Graph extended-properties adapter; auth/token handling; the host-agnostic command bus | Behavior bugs here cause silent data loss, model drift, or security holes. Worth the slowest gates. |
| **T2 — Core** | `TaskMaster.Domain`, `TaskMaster.Application`, mail-item DTOs, settings store abstraction, schema definitions | Bugs cause feature regressions but not data loss. Heavy unit + property testing, no mutation gate. |
| **T3 — Adapters & UI** | VSTO host adapter, web task pane UI, Office.js wrappers, Graph SDK wrappers, persistence I/O | Mostly glue around APIs you don't own. Architecture boundary + integration + E2E carry the weight; unit testing has diminishing returns. |
| **T4 — Scaffolding** | DI wiring, bootstrap, build scripts, dev tooling, generated code, manifests | Format + lint + typecheck + a smoke test that "the thing starts." That's it. |

The tier file is the single source of truth. Adding a project without classifying it = build fail.

## 2. Pipeline stages

Three pipelines, not one. Each has its own latency budget and triggers.

### PR pipeline (target: < 8 min p95)

Runs on every push to a PR. Fast feedback. All stages parallelized where possible.

| # | Stage | Scope | Gate | Latency budget |
|---|---|---|---|---|
| 1 | Format check | All files | Zero diff | 30s |
| 2 | Lint (stacked) | Changed files + dependents | Zero errors; warnings-as-errors on T1/T2 | 2 min |
| 3 | Typecheck (strict) | Whole TS project + whole .NET solution | Zero errors; zero `any`/`dynamic` in T1/T2 | 2 min |
| 4 | Architecture-boundary tests | Whole solution | Zero violations | 1 min |
| 5 | Unit + property tests | Changed projects + dependents | Pass; coverage ≥ tier threshold (see §3) | 4 min |
| 6 | Contract/schema compat | API + Graph schemas | No breaking change without version bump | 30s |
| 7 | Integration tests | Changed adapters | Pass | 3 min |

Stages 1–4 run in parallel; 5–7 fan out per project. PR can't merge if any fail.

### Pre-merge pipeline (target: < 25 min)

Runs after PR review on the merge queue. Slower, more thorough.

| # | Stage | Scope | Gate |
|---|---|---|---|
| 8 | Mutation testing | T1 modules only, on changed files + dependents | Mutation score ≥ 75% (T1), ≥ 60% (T2 if measured) |
| 9 | Golden/snapshot tests | Classifier output corpus | Zero unintended diff; updates require explicit `--update-snapshots` commit |
| 10 | Benchmark regression | T1 hot paths | p99 latency regression < 5%; allocations regression < 10% |
| 11 | E2E smoke | Critical user paths in task pane | 100% pass on smoke set |

Mutation testing on the *full* T1 set is too slow for pre-merge; use changed-file scope here and run the full set nightly.

### Nightly / main-branch pipeline

| # | Stage | Scope | Gate |
|---|---|---|---|
| 12 | Full mutation testing | All T1 + T2 modules | Score trend, not absolute gate (alerts on drop > 3 pts) |
| 13 | Full E2E suite | All migrated workflows in real Outlook test tenants (web + new desktop + classic) | Flake budget: < 2% retry rate per test |
| 14 | Schema-evolution tests | Graph extended-properties storage | Forward + backward compat against last 3 versions |
| 15 | Dependency audit | All packages | Zero known CVEs above "moderate"; license compliance |

## 3. Gate thresholds (concrete numbers)

| Gate | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| Format | 100% | 100% | 100% | 100% |
| Lint errors | 0 | 0 | 0 | 0 |
| Type errors | 0 | 0 | 0 | 0 |
| Untyped escape hatches (`any`/`dynamic`) | 0 | 0 | ≤ 5 per file, justified | unlimited |
| Architecture violations | 0 | 0 | 0 | 0 |
| Line coverage | ≥ 85% | ≥ 75% | ≥ 50% (integration) | none |
| Branch coverage | ≥ 75% | ≥ 65% | none | none |
| Property test count | ≥ 1 per pure function | ≥ 1 per pure function | none | none |
| Mutation score | ≥ 75% | trend-only | none | none |
| Contract breaking changes | major-bump required | major-bump required | n/a | n/a |
| Benchmark p99 regression | < 5% | < 10% | none | none |
| Determinism (no flaky tests) | retry rate < 0.5% | < 1% | < 2% | n/a |

Coverage is a *floor*, not a goal. Mutation score is the real signal for T1.

## 4. Determinism infrastructure (foundational, not optional)

The current codebase has flakiness baked in (re-entrancy guards in `ToDoEvents`, `IdleAsyncQueue` ordering hazards). For the new code to meet the flake-rate gates above, the test base must provide:

- **Controllable clock** — every `DateTime.UtcNow` / `Date.now()` flows through an injected `IClock` / `Clock` interface. Tests use a virtual clock; production uses the real one. No exceptions.
- **Seeded RNG** — same pattern. Tests get a deterministic seed printed in failure output so flakes are reproducible from the seed alone.
- **Virtual scheduler** — async tests use a controllable scheduler (TS: a fake event loop; .NET: a `TestScheduler`-equivalent) so "wait for next tick" never depends on wall clock.
- **Fake Office.js + fake Graph** — hand-rolled or generated from the schema, never real network calls in unit/integration tier.
- **Zero `Thread.Sleep` / `setTimeout` in tests** — lint rule, not convention. Build fails if it appears.

Without this layer, the gates in §3 are unenforceable — you'll spend more time chasing flakes than fixing real bugs.

## 5. Test corpus & data management

Classifier golden tests need a stable, versioned input corpus. Treat it as a first-class artifact:

- Corpus lives in a separate repo or LFS-tracked subdir, versioned independently.
- Each classifier release pins a corpus version.
- Corpus updates require a separate PR with diff review (so "the model improved" vs "the corpus was rewritten to make a bad model pass" is auditable).
- Synthetic data generators for property tests live alongside, also versioned.

For the Graph extended-properties migration: capture a representative slice of real UDF data into anonymized fixtures, then run forward-migration + roundtrip tests against it on every change to the schema or adapter.

## 6. Phased rollout (which gates light up when)

Applying all of this from day one is wasted effort — most stages have nothing to gate against until the core is extracted. Map gates onto the migration phases from the research doc:

| Migration phase | Gates that go live |
|---|---|
| **Phase A** — Baseline & seams | Stages 1–3 (format, lint, typecheck) on the existing solution. Determinism infrastructure stub (start injecting `IClock`). Architecture-boundary tests with empty rules — just so the wiring exists. |
| **Phase B** — Core contracts | Stages 4 (architecture rules now have content: "Domain has no Outlook PIA refs"), 5 (property tests on Domain), 6 (schema/contract for the new core API). Mutation testing on Domain. |
| **Phase C** — VSTO refactor to core | Stage 7 (integration tests with VSTO adapter), determinism layer fully required for new tests. Coverage gates start enforcing on changed files. |
| **Phase D** — Web add-in MVP | Stages 9–11 (golden, benchmark, E2E) light up. Contract tests gate the task pane ↔ service boundary. |
| **Phase E** — Feature expansion | Full mutation testing on T1. Schema-evolution tests on Graph extended properties. |
| **Phase F** — VSTO retirement | Drop classic-only test lanes; fold their coverage into web add-in E2E. |

## 7. What this costs

Honest tradeoffs:

- **Setup time**: ~2–3 weeks of focused tooling work spread across phases A–D. Front-loaded in A (determinism + architecture-boundary skeleton).
- **Per-PR time tax**: ~5–8 min on average PR; 15–25 min on PRs touching T1.
- **Maintenance**: the corpus and golden tests need owners. Without a designated owner, golden tests become "rubber-stamp the diff" within 6 months.
- **Where this is overkill**: if the project stays single-developer, stages 8 (mutation), 12 (full mutation nightly), and 14 (schema evolution) carry too much weight for the value. A solo dev can drop those and keep everything else.
- **Where this is *under*-kill**: if you ever take payments or handle PII directly in the service, add SAST + secret scanning + dependency-supply-chain (SBOM + signature verification) as stages 16–18.

The single highest-leverage gate in this list, given the architecture's specific risks, is **stage 4 (architecture-boundary tests)**. Without it, "shell-and-core" decays back into a god-graph regardless of how good the other gates are. If you implement only one thing from this spec before Phase B starts, make it that one.

Want me to draft the actual `quality-tiers.yml` schema and a starter architecture-rules file (in tool-agnostic pseudocode) so you have something concrete to point at when Phase A starts?

# CI Tooling Recommendations for No-COM TaskMaster Architecture

The No-COM architecture has three implementation surfaces:

- **TypeScript / Office.js** — task pane in this repo (already a scaffold).
- **.NET** — backend API (ASP.NET Core), Graph adapter, classifier orchestration, background workers.
- **Optional Python** — if the classifier service is implemented in Python rather than .NET.

Tools are chosen against three criteria: (1) they cover the gate categories from the CI spec, (2) they work well in a small-team / single-developer context, (3) they're stable enough to bet on for a multi-year migration. Where I recommend a less-popular tool, the rationale is called out.

## 1. Tool map by stage

| Stage | TypeScript (client) | .NET (backend) | Python (classifier, optional) |
|---|---|---|---|
| **Format** | Prettier (already in place via `office-addin-prettier-config`) | CSharpier + `.editorconfig` | Ruff (`ruff format`) |
| **Lint — style** | ESLint flat config + `eslint-config-prettier` | Roslyn analyzers (built-in, set `<AnalysisLevel>latest-recommended</AnalysisLevel>`) | Ruff |
| **Lint — type-aware** | `typescript-eslint` with type-aware rules enabled | (handled by analyzers below) | (handled by Pyright) |
| **Lint — security** | `eslint-plugin-security` | `SecurityCodeScan.VS2019` | Ruff S-rules + `bandit` |
| **Lint — async/threading** | `eslint-plugin-promise`, `eslint-plugin-no-floating-promise` | **Meziantou.Analyzer** + **AsyncFixer** *(critical for this codebase)* | (n/a) |
| **Lint — quality / smells** | `eslint-plugin-unicorn` (selective rules) | **SonarAnalyzer.CSharp** + **Roslynator.Analyzers** | Ruff (PL/PT rule families) |
| **Lint — Office-specific** | `eslint-plugin-office-addins` | (n/a) | (n/a) |
| **Lint — import boundaries** | `eslint-plugin-import` (basic) | (handled by architecture stage) | (n/a) |
| **Typecheck** | `tsc --noEmit` with strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes` | `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` + `<Nullable>enable</Nullable>` | Pyright (strict mode) |
| **Architecture-boundary tests** | **dependency-cruiser** (richer than eslint-plugin-boundaries; emits SVG dependency graphs) | **NetArchTest.Rules** (fluent C# rules in a dedicated `*.ArchitectureTests` project) | `import-linter` |
| **Unit tests** | **Vitest** | **xUnit** + **FluentAssertions** + **NSubstitute** | **pytest** |
| **Property-based tests** | **fast-check** (integrates with Vitest) | **CsCheck** *(better shrinking than FsCheck and works without F# deps)* | **Hypothesis** |
| **Mutation testing** | **StrykerJS** | **Stryker.NET** | **mutmut** or **cosmic-ray** |
| **Snapshot / golden tests** | Vitest built-in snapshots | **Verify.Xunit** *(gold standard for .NET — diff-tool integration, handles any object graph)* | **syrupy** |
| **Contract / schema** | `openapi-typescript` or **orval** for client gen; `oasdiff` for breaking-change detection | **NSwag** for OpenAPI generation; **Spectral** for OpenAPI linting; **Verify.Http** for response snapshots | (consumes API; same tools) |
| **Integration tests** | Vitest + **MSW** (Mock Service Worker) for Graph stubs | xUnit + **WireMock.Net** (Graph) + `Microsoft.AspNetCore.Mvc.Testing` (in-process host) + **Testcontainers** (real SQL) | pytest + `responses` |
| **E2E** | **Playwright** against Outlook on the web (test M365 tenant); **@microsoft/teams-toolkit** sideload for desktop | (covered by client E2E + backend integration) | (n/a) |
| **Benchmark regression** | **tinybench** or Vitest's `bench` API | **BenchmarkDotNet** (the reference tool; export JSON for CI comparison) | **pytest-benchmark** |
| **Determinism — clock** | `@sinonjs/fake-timers` (or `vi.useFakeTimers`) + injected `Clock` | **`Microsoft.Extensions.TimeProvider.Testing`** (official, .NET 8+) | `freezegun` |
| **Determinism — RNG** | `pure-rand` (seedable, deterministic) | `Random` with explicit seed + analyzer banning `Random.Shared` in production code | numpy/pytest with explicit seeds |
| **Determinism — scheduler** | Vitest fake timers + `await flushPromises()` helpers | `TestScheduler` from System.Reactive (if reactive); else fake `TimeProvider` | `asyncio` event loop control |
| **Determinism — banned APIs** | ESLint `no-restricted-syntax` rule banning `setTimeout`/`Date.now`/`Math.random` in test files | Custom Roslyn analyzer or `BannedApiAnalyzers` | Ruff custom rules |
| **Dependency audit — CVEs** | `npm audit` (basic) + **Trivy** (more comprehensive, scans lockfile) | `dotnet list package --vulnerable` + Trivy | `pip-audit` + Trivy |
| **Dependency audit — licenses** | `license-checker` | `dotnet-project-licenses` | `pip-licenses` |
| **SBOM generation** | `@cyclonedx/cyclonedx-npm` | `Microsoft.Sbom.Targets` (official MS tool) | `cyclonedx-py` |
| **Schema evolution (Graph extended properties)** | (consumed via API) | **Verify.Json** for snapshots; custom forward/backward-compat tests in xUnit; schemas as versioned JSON Schema files in `/schemas/v{n}/` | (n/a) |
| **Test corpus storage** | Git LFS or **DVC** (Data Version Control) for ML-style artifacts in a separate corpus subdir or sibling repo | (same) | (same) |

## 2. Cross-cutting / orchestration tools

| Concern | Tool | Why |
|---|---|---|
| CI orchestration | **GitHub Actions** | Free for private repos at this scale; matrix builds for the three language stacks; reusable workflows for the three pipeline tiers (PR / pre-merge / nightly). |
| Pipeline reusability | **Reusable workflows** + composite actions | One workflow per stage, called from the three pipeline tiers with different scope inputs. |
| Pre-commit hooks | **lefthook** | Single Go binary; runs both `prettier` on `.ts` and `csharpier` on `.cs` from one config. Beats husky+lint-staged when you have multiple languages. |
| Secret scanning | **gitleaks** (pre-commit + CI) | Catches accidental commits of Graph client secrets, connection strings. |
| Dependency updates | **Renovate** (not Dependabot) | Single config covers npm + NuGet + GitHub Actions + Docker; better grouping rules for monorepos. |
| Conventional commits | **commitlint** + **commitizen** | Drives changelog generation; required if you want SemVer-aware contract-breaking checks. |
| Changelog / versioning | **Changesets** (TS-friendly) or **MinVer** (.NET) | Pick one based on which side ships first; align eventually. |
| Coverage reporting | **Codecov** (PR comments) | Free for OSS, cheap for private. Aggregates TS + .NET + Python into one report. |
| Architecture diagrams | **dependency-cruiser** SVG output (TS) + **D2** for the higher-level system diagram, generated from the same YAML that drives the architecture rules | Diagrams stay in sync with the rules — they're generated from the same source. |
| Logs / correlation in CI | GitHub Actions step summaries + **dorny/test-reporter** | Test results inline in PR; mutation scores and benchmark deltas posted as PR comments. |

## 3. The stacked-analyzer set for .NET (the most important detail)

For the No-COM backend, the analyzer stack is the single highest-leverage decision. The legacy codebase's failure modes (re-entrancy in `ToDoEvents`, async-void in event handlers, ConfigureAwait drift) all map to known analyzer rules. The stack:

```xml
<ItemGroup>
  <PackageReference Include="Meziantou.Analyzer" PrivateAssets="all" />
  <PackageReference Include="SonarAnalyzer.CSharp" PrivateAssets="all" />
  <PackageReference Include="Roslynator.Analyzers" PrivateAssets="all" />
  <PackageReference Include="AsyncFixer" PrivateAssets="all" />
  <PackageReference Include="SecurityCodeScan.VS2019" PrivateAssets="all" />
  <PackageReference Include="Microsoft.CodeAnalysis.BannedApiAnalyzers" PrivateAssets="all" />
</ItemGroup>
```

Plus the built-in Roslyn analyzers via `<AnalysisLevel>latest-all</AnalysisLevel>` and `<AnalysisMode>All</AnalysisMode>` in `Directory.Build.props`. Then a `Directory.Build.targets` file that sets `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` for Tier 1/2 projects and downgrades that to `<WarningsAsErrors>nullable</WarningsAsErrors>` for Tier 3.

Suppress noisy rules in a checked-in `.editorconfig` with rationale comments — no inline `#pragma warning disable` without an issue link.

## 4. The TS lint config (high-leverage, often half-configured)

Default ESLint setups don't enable type-aware rules because they're slow. For Tier 1/2 TS code, you want them on:

```js
// eslint.config.js (sketch)
export default [
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  // type-aware rules require parserOptions.project
  { languageOptions: { parserOptions: { project: true } } },
  // ban floating promises, unsafe any, etc. on T1/T2
  { rules: { '@typescript-eslint/no-floating-promises': 'error',
             '@typescript-eslint/no-misused-promises': 'error',
             '@typescript-eslint/no-unsafe-*': 'error' } }
];
```

These three rule families catch the bulk of real bugs in async TypeScript.

## 5. Determinism infrastructure (concrete recipes)

The clock interface should look identical across the stack so test patterns transfer:

- **TS**: ship a `Clock` interface in the shared types package; production binds to `{ now: () => Date.now() }`; tests bind to `@sinonjs/fake-timers`. ESLint rule `no-restricted-globals` bans direct `Date.now()` outside the production binding.
- **.NET**: inject `TimeProvider` (the BCL abstraction since .NET 8); production gets `TimeProvider.System`; tests get `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`. `BannedApiAnalyzers` bans `DateTime.Now`/`DateTime.UtcNow` outside an allowlist of files.
- **Python** (if used): inject a `Clock` protocol; tests use `freezegun`; Ruff rule bans `datetime.datetime.now()` outside infra.

For seeded RNG: same pattern with `IRandom` / `Random` interfaces.

## 6. Phased rollout — which tools light up when

Map tool adoption to the migration phases in the No-COM doc:

| Phase | Tools that go live |
|---|---|
| **B (Add-in scaffold hardening)** | TS: Prettier (already), ESLint flat config + type-aware rules + Office plugin, tsc strict mode, Vitest + MSW, dependency-cruiser with empty rules. lefthook + gitleaks. GitHub Actions PR pipeline (stages 1–3, plus stage 4 wiring). |
| **C (Backend & auth foundation)** | .NET: CSharpier, the analyzer stack, Nullable+TreatWarningsAsErrors, xUnit+FluentAssertions+NSubstitute, NetArchTest skeleton, Testcontainers for SQL, WireMock.Net for Graph, Microsoft.AspNetCore.Mvc.Testing. NSwag for OpenAPI gen. Renovate. |
| **D (Classification MVP)** | fast-check / CsCheck for property tests on the classifier domain. Verify (.NET) and Vitest snapshots for golden tests. **Stryker.NET** mutation testing on classifier modules only. Test corpus repo (LFS or DVC) created. |
| **E (Filing MVP)** | OpenAPI breaking-change detection (oasdiff) wired into PR pipeline. Pact or schema-snapshot contract tests for the task pane ↔ backend boundary. Playwright E2E smoke suite. |
| **F (Metadata & tags)** | Schema-evolution tests for Graph extended properties + open extensions. Versioned JSON Schema files in `/schemas`. |
| **G (Background automation)** | Idempotency property tests (fast-check / CsCheck). Subscription lifecycle integration tests with WireMock.Net + FakeTimeProvider. BenchmarkDotNet baseline for delta-reconciliation hot path. |
| **H (Legacy import)** | Verify-based snapshot tests on legacy file parsing; dry-run validation as a first-class CI artifact. |

## 7. What I'd deliberately *not* recommend

- **Jest** for the TS side. Vitest is faster, native ESM, same API surface; Jest's ESM story is still painful in 2026.
- **MSTest or NUnit** for the .NET side. xUnit's `[Fact]`/`[Theory]` model + parallelism + collection fixtures map better to the architecture being built; MSTest is fine in legacy projects but no reason to start there.
- **Moq** for new .NET test code. The Moq licensing controversy aside, NSubstitute's API is genuinely simpler and produces better failure messages for mocked async calls.
- **Biome / Rome / oxc** in production yet. Tempting (one tool replaces Prettier+ESLint), but the Office.js ESLint plugin doesn't exist for any of them, and that plugin catches real Office-specific bugs.
- **StyleCop** alongside the analyzer stack above. Redundant with CSharpier + .editorconfig; rules are mostly noisy.
- **Hangfire / Quartz** for background workers in the cloud-native version of this. Use the platform's native scheduler (Azure Functions, Hosted Services, etc.) so the background-worker tier doesn't carry its own framework.
- **Pact** unless you have a separate front-end and back-end team. For a small team, OpenAPI snapshot tests with `oasdiff` give you 80% of the value at 10% of the operational overhead.

## 8. Single highest-leverage call

If you set up exactly one thing now, before any backend code exists: **dependency-cruiser** in this TS repo with rules that encode the No-COM architecture's client-vs-backend boundary. That captures architectural intent in code from day one, and it's the rule set that ends up enforcing "the task pane never knows about Graph SDK details directly" — which is *the* invariant that distinguishes this clean rebuild from another shell-and-core regression.

Want me to set this stack up in the repo for the Phase B scope (TS toolchain + dependency-cruiser + Vitest + GitHub Actions PR pipeline + lefthook), with the .NET pieces deferred until Phase C creates a backend project to apply them to?

