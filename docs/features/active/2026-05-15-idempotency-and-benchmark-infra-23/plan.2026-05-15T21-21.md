# idempotency-and-benchmark-infra — Plan

- **Issue:** #23
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-15T21-40
- **Status:** Draft
- **Version:** 1.2
- **Revision Rationale:** Renumbered Phase 1 tasks strictly sequentially (T1–T7) to satisfy validator format `- [ ] [P#-T#] <Title>`. Former `[P1-T0]` (BenchmarkDotNet CPM registration) becomes `[P1-T1]`; former `[P1-T1.5]` (analyzer hygiene NoWarn) becomes `[P1-T3]`; remaining Phase 1 tasks shifted accordingly. AC traceability table updated for the renumbered Phase 1 IDs. Prior 1.1 revision rationale preserved: atomic-executor preflight required-changes (TargetFramework net10.0; CSharpier replaces dotnet format; BenchmarkDotNet under Central Package Management; analyzer hygiene NoWarn for benchmarks; xunit.v3 package set explicit; lint/contract action references replaced or scoped; contract gate removed because Prompt G1 introduces no OpenAPI surface change).
- **Work Mode:** full-feature
- **Feature Folder:** `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/`
- **Evidence Root:** `docs/features/active/2026-05-15-idempotency-and-benchmark-infra-23/evidence/`

## Required References

- Repo policy: `.claude/rules/general-code-change.md`
- Repo policy: `.claude/rules/general-unit-test.md`
- Repo policy: `.claude/rules/quality-tiers.md`
- Repo policy: `.claude/rules/csharp.md`
- Repo policy: `.claude/rules/tonality.md`
- Tier source of truth: `quality-tiers.yml`
- Inputs: `issue.md`, `spec.md`, `user-story.md` in the feature folder
- Research anchor: `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md` (Phase G / Prompt G1, Prompt D2 hot paths)
- CI taxonomy: `docs/ci.research.md`; existing workflows under `.github/workflows/`

All work must comply with these policies; do not duplicate their content here.

## Scope Summary

Gate-only infrastructure for Phase G:

1. New benchmark project `tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj` (BenchmarkDotNet) covering Prompt D2 classifier hot paths and a disabled delta-reconciliation placeholder.
2. Committed baseline `artifacts/benchmarks/baseline.json` plus schema notes.
3. Comparator script `scripts/benchmarks/compare-benchmarks.ps1` enforcing p99 > 5% (T1) and allocation > 10% thresholds.
4. PR-pipeline `stage-10-benchmark-regression` and `benchmark-gate-self-validation` jobs.
5. New worker-handler test project `tests/TaskMaster.Worker.Tests/TaskMaster.Worker.Tests.csproj` carrying `SubscriptionHandlerTestBase`, idempotency fixture, and delta-reconciliation property tests.
6. Two self-validation tests (latency regression fixture + non-idempotent handler) gated under category `benchmark-gate-self-validation`.
7. `quality-tiers.yml` entries for the two new projects.
8. Full toolchain QA loop with C# coverage evidence at `<FEATURE>/evidence/qa-gates/`.

## Implementation Plan (Atomic Tasks)

### Phase 0 — Compliance & Context

- [x] [P0-T1] Read `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/csharp.md`, and `.claude/rules/tonality.md` and record file list with timestamp
  - Acceptance: artifact `<FEATURE>/evidence/baseline/phase0-instructions-read.md` exists with `Timestamp:`, `Policy Order:`, explicit list of files read
- [x] [P0-T2] Read `issue.md`, `spec.md`, `user-story.md`, and the Prompt D2/G1 sections of `docs/TaskMaster-Modern-Architecture-Migrationresearch-NoCOM.md`
  - Acceptance: artifact `<FEATURE>/evidence/baseline/phase0-inputs-read.md` lists file paths, ranges read, and acceptance criteria AC1–AC8 transcribed verbatim
- [x] [P0-T3] Capture C# build baseline by running `dotnet build TaskMaster.sln -c Release --nologo`
  - Acceptance: artifact `<FEATURE>/evidence/baseline/baseline-dotnet-build.md` contains `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` (error/warning counts)
- [x] [P0-T4] Capture C# test baseline by running `dotnet test TaskMaster.sln -c Release --collect:"XPlat Code Coverage" --results-directory artifacts/csharp/baseline --nologo`
  - Acceptance: artifact `<FEATURE>/evidence/baseline/baseline-dotnet-test.md` records `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` with passed/failed counts and headline `line=<pct>` / `branch=<pct>` coverage values from the merged Cobertura output
- [x] [P0-T5] Capture format and lint baselines by running `dotnet csharpier check .` and `dotnet build TaskMaster.sln -c Release -warnaserror` locally for C# (per `.claude/rules/csharp.md`: CSharpier is mandatory; `dotnet format` is prohibited; `./.github/actions/lint` composite action existence is not verified, so the equivalent `dotnet build -warnaserror` lint signal is used)
  - Acceptance: artifact `<FEATURE>/evidence/baseline/baseline-format-lint.md` records both commands with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
- [x] [P0-T6] Capture quality-tier validation baseline by running `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1`
  - Acceptance: artifact `<FEATURE>/evidence/baseline/baseline-tier-classification.md` records `EXIT_CODE: 0` and notes that the two yet-to-be-added projects will require tier entries

### Phase 1 — Benchmarks Project Skeleton & Tier Registration

- [x] [P1-T1] Add `<PackageVersion Include="BenchmarkDotNet" Version="0.14.0" />` to `Directory.Packages.props` so the new project can consume BenchmarkDotNet under Central Package Management (CPM); without this, NU1008 will block the versionless `<PackageReference>` in `[P1-T2]`
  - Acceptance: `Directory.Packages.props` contains the new `PackageVersion` entry; `dotnet restore TaskMaster.sln` exits 0; log at `<FEATURE>/evidence/other/p1-pkg-version-add.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
- [x] [P1-T2] Create `tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj` targeting `net10.0` (aligned with `Directory.Build.props` and `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj`), `OutputType=Exe`, with a versionless `<PackageReference Include="BenchmarkDotNet" />` (version managed centrally via `Directory.Packages.props`; supplying a `Version=` attribute is forbidden under CPM and triggers NU1008) and a ProjectReference to `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj`
  - Acceptance: file exists; `dotnet build tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj -c Release` exits 0; build log saved to `<FEATURE>/evidence/other/p1-benchmarks-build.md`
- [x] [P1-T3] Configure project-scoped `<NoWarn>` in `tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj` to permit BenchmarkDotNet benchmark-method shapes that conflict with the solution-wide `TreatWarningsAsErrors=true`. Candidate IDs (final set is the executor's choice within this scope): `CA1822` (instance-method that could be static — BenchmarkDotNet requires instance benchmark methods), `CA1707` (underscores in benchmark identifiers when used), `CA1515` (public-type internal visibility — BenchmarkDotNet discovers public types), `MA0051` (method length for benchmark bodies). Each suppressed ID must be justified in the rationale artifact.
  - Acceptance: project builds with `dotnet build tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj -c Release -warnaserror` exit 0; rationale artifact at `<FEATURE>/evidence/other/p1-analyzer-justification.md` lists each suppressed analyzer ID with a one-line justification linking it to BenchmarkDotNet's required shape
- [x] [P1-T4] Add `tests/TaskMaster.Benchmarks/Program.cs` invoking `BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args)`
  - Acceptance: file exists; `dotnet run -c Release --project tests/TaskMaster.Benchmarks -- --list flat` exits 0 with empty benchmark list; log at `<FEATURE>/evidence/other/p1-benchmarks-list.md`
- [x] [P1-T5] Add `tests/TaskMaster.Benchmarks/BenchmarkConfig.cs` defining a deterministic short-iteration `ManualConfig` (fixed seed, `Job.ShortRun`, `MemoryDiagnoser`, `JsonExporter.Full`) used by all benchmark classes
  - Acceptance: file exists; class is `public` and decorated with `[Config(typeof(BenchmarkConfig))]` consumable by benchmark classes
- [x] [P1-T6] Add the project to `TaskMaster.sln` via `dotnet sln TaskMaster.sln add tests/TaskMaster.Benchmarks/TaskMaster.Benchmarks.csproj`
  - Acceptance: `dotnet sln TaskMaster.sln list` includes the new project; log saved to `<FEATURE>/evidence/other/p1-sln-add.md`
- [x] [P1-T7] Register `TaskMaster.Benchmarks` in `quality-tiers.yml` as tier `t4` with rationale referencing benchmark/test-infrastructure role
  - Acceptance: `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1` exits 0; output saved to `<FEATURE>/evidence/qa-gates/p1-tier-validate.md`

### Phase 2 — Classifier Hot-Path Benchmarks & Disabled Placeholder

- [x] [P2-T1] Add `tests/TaskMaster.Benchmarks/ClassifierBenchmarks.cs` with `[Benchmark]` methods for the Prompt D2 classifier hot paths: classify-command, input-normalization edge path, training-state update path, sourcing inputs from in-memory fixtures only (no I/O)
  - Acceptance: file exists; `dotnet run -c Release --project tests/TaskMaster.Benchmarks -- --list flat` lists exactly three benchmark IDs; list log saved to `<FEATURE>/evidence/other/p2-benchmark-list.md`
- [x] [P2-T2] Add `tests/TaskMaster.Benchmarks/DeltaReconciliationBenchmarks.cs` with one `[Benchmark]` method annotated `[BenchmarkCategory("g2-pending")]` and gated by `#if ENABLE_G2_BENCHMARK ... #else throw new NotSupportedException("Disabled; awaiting Prompt G2"); #endif`, including a `// TODO(G2): enable once delta-reconciliation handler exists` comment
  - Acceptance: file exists; `--list` output excludes this benchmark by default (filter excludes `g2-pending`); presence of `TODO(G2)` marker verified by `Select-String -Pattern "TODO\(G2\)"` log at `<FEATURE>/evidence/other/p2-todo-g2-marker.md`
- [x] [P2-T3] Execute the benchmark project and capture baseline output to `artifacts/benchmarks/baseline.json` using `dotnet run -c Release --project tests/TaskMaster.Benchmarks -- --filter "*ClassifierBenchmarks*" --exporters JSON --artifacts artifacts/benchmarks/run` then copy the `*-report-full.json` to `artifacts/benchmarks/baseline.json`
  - Acceptance: `artifacts/benchmarks/baseline.json` exists and contains, per benchmark id, fields `FullName`, `Statistics.Percentiles.P99`, and `Memory.BytesAllocatedPerOperation`; capture log at `<FEATURE>/evidence/other/p2-baseline-capture.md`
- [x] [P2-T4] Add `artifacts/benchmarks/README.md` documenting the consumed schema fields (`p99-latency-ns`, `allocated-bytes`, mapping from BenchmarkDotNet JSON), rebaselining policy, and stage-10 thresholds (p99 > 5% T1, allocation > 10%)
  - Acceptance: file exists with explicit schema field list; saved review log at `<FEATURE>/evidence/other/p2-schema-readme.md`

### Phase 3 — Benchmark Regression Comparator

- [x] [P3-T1] Create `scripts/benchmarks/compare-benchmarks.ps1` accepting `-BaselinePath`, `-CurrentPath`, `-T1BenchmarkIdPattern`, `-LatencyThresholdPercent` (default 5), `-AllocationThresholdPercent` (default 10); exits 0 on pass, 1 on regression
  - Acceptance: file exists; `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath artifacts/benchmarks/baseline.json` exits 0; log at `<FEATURE>/evidence/other/p3-comparator-self.md`
- [x] [P3-T2] Implement per-benchmark-id parsing in the comparator that emits a structured diff line per benchmark: `id, p99_baseline_ns, p99_current_ns, p99_delta_pct, alloc_baseline_b, alloc_current_b, alloc_delta_pct, verdict`
  - Acceptance: comparator stdout for self-comparison contains one diff row per benchmark id and all `verdict=PASS`; captured to `<FEATURE>/evidence/other/p3-comparator-self-rows.md`
- [x] [P3-T3] Add `tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json` representing a synthetic +10% p99 regression on one T1 benchmark id and verify comparator exits 1
  - Acceptance: `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath tests/TaskMaster.Benchmarks/Fixtures/SyntheticLatencyRegressionFixture.json` exits 1; output captured to `<FEATURE>/evidence/regression-testing/p3-comparator-synthetic-fail.md`
- [x] [P3-T4] Add `tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json` representing a +10.5% allocation regression and verify comparator exits 1
  - Acceptance: comparator invocation exits 1; output captured to `<FEATURE>/evidence/regression-testing/p3-comparator-alloc-fail.md`

### Phase 4 — Worker Tests Project & Idempotency Base Class

- [x] [P4-T1] Create `tests/TaskMaster.Worker.Tests/TaskMaster.Worker.Tests.csproj` targeting `net10.0` (aligned with `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj` and `Directory.Build.props`). The xunit.v3 test framework package set is explicitly: `xunit.v3` + `xunit.runner.visualstudio` + `Microsoft.NET.Test.Sdk`. Do NOT include the classic `xunit` package — xunit.v3 supersedes it and `[Fact]` resolves to `Xunit.FactAttribute` from xunit.v3. Additional PackageReferences: `Microsoft.Extensions.TimeProvider.Testing`, `CsCheck`, `FluentAssertions`, coverage collector. All `<PackageReference>` entries must be versionless (versions live in `Directory.Packages.props`).
  - Acceptance: project builds via `dotnet build tests/TaskMaster.Worker.Tests -c Release` exit 0; log at `<FEATURE>/evidence/other/p4-worker-tests-build.md`; build log confirms no `xunit` (classic) package is resolved and `Xunit.FactAttribute` comes from `xunit.v3.core`
- [x] [P4-T2] Register `TaskMaster.Worker.Tests` in `quality-tiers.yml` as tier `t4` and add to `TaskMaster.sln` via `dotnet sln add`
  - Acceptance: `validate-quality-tiers.ps1` exits 0 and `dotnet sln TaskMaster.sln list` includes the project; output at `<FEATURE>/evidence/qa-gates/p4-tier-validate.md`
- [x] [P4-T3] Add `tests/TaskMaster.Worker.Tests/Subscriptions/SubscriptionHandlerTestBase.cs` defining abstract `Task ArrangeAsync()`, `Task ActAsync(TNotification notification)`, `Task<TState> CaptureStateAsync()`, and protected `FakeTimeProvider Clock` and `int ReplayCount = 3`
  - Acceptance: file exists and compiles; type is `public abstract class SubscriptionHandlerTestBase<THandler, TNotification, TState>`; build log at `<FEATURE>/evidence/other/p4-base-build.md`
- [x] [P4-T4] Add built-in `[Fact] public async Task Idempotency_RepeatedDelivery_ProducesSinglePostState()` method on the base class that calls `ArrangeAsync`, captures single-run reference state, re-runs `ActAsync` N=`ReplayCount` (default 5 per plan, configurable down to 3) under `FakeTimeProvider` with a deterministic message-id seed, and asserts equality via `FluentAssertions.BeEquivalentTo`
  - Acceptance: method exists on base class; presence verified by `Select-String` log saved to `<FEATURE>/evidence/other/p4-base-fact-marker.md`
- [x] [P4-T5] Add `tests/TaskMaster.Worker.Tests/Subscriptions/SampleIdempotentHandlerTests.cs` (positive scenario) deriving from the base with a deterministic in-memory state store; running `dotnet test --filter "FullyQualifiedName~SampleIdempotentHandlerTests"` exits 0
  - Acceptance: test green; log at `<FEATURE>/evidence/regression-testing/p4-sample-idempotent-pass.md`

### Phase 5 — Delta-Reconciliation Property Tests & Self-Validation Negatives

- [x] [P5-T1] Add `tests/TaskMaster.Worker.Tests/Reconciliation/DeltaReconciliationPropertyTests.cs` covering out-of-order, duplicate, and missing events using CsCheck with explicit seed and `[Fact]`-based properties; on failure the seed is printed via `CsCheck`'s default failure formatter
  - Acceptance: file contains three named properties (`OutOfOrder_ProducesSameState`, `Duplicates_AreIdempotent`, `Missing_EventsAreDetected`); `dotnet test --filter "FullyQualifiedName~DeltaReconciliationPropertyTests"` exits 0; log at `<FEATURE>/evidence/regression-testing/p5-property-tests-pass.md`
- [x] [P5-T2] Add `tests/TaskMaster.Worker.Tests/Subscriptions/NonIdempotentHandlerNegativeTests.cs` containing a deliberately non-idempotent handler test class derived from the base, decorated with `[Trait("Category","benchmark-gate-self-validation")]` so it is excluded from the normal lane
  - Acceptance: file exists; default `dotnet test --filter "Category!=benchmark-gate-self-validation"` excludes it (log at `<FEATURE>/evidence/regression-testing/p5-self-validation-excluded.md`); explicit `dotnet test --filter "Category=benchmark-gate-self-validation"` shows the test failing as expected [expect-fail], log at `<FEATURE>/evidence/regression-testing/p5-self-validation-failing-as-expected.md`
- [x] [P5-T3] Add a self-validation latency-regression test `tests/TaskMaster.Benchmarks/SelfValidation/LatencyRegressionGateTests.cs` (xUnit test inside benchmarks project or a small companion test project) that invokes the comparator on `SyntheticLatencyRegressionFixture.json` and asserts non-zero exit; trait `Category=benchmark-gate-self-validation`
  - Acceptance: test passes when running `dotnet test --filter "Category=benchmark-gate-self-validation"`; output at `<FEATURE>/evidence/regression-testing/p5-latency-gate-self-test.md`
- [x] [P5-T4] Verify banned APIs (`Thread.Sleep`, `Task.Delay`, `DateTime.UtcNow`, `TimeProvider.System`) are absent in `tests/TaskMaster.Worker.Tests/**`
  - Acceptance: `Select-String` scan output saved at `<FEATURE>/evidence/qa-gates/p5-banned-api-scan.md` shows zero matches

### Phase 6 — Pipeline Stage 10 and Self-Validation Job

- [x] [P6-T1] Add job `stage-10-benchmark-regression` to `.github/workflows/pr-pipeline.yml`: runs after `stage-7-integration` (or final existing stage), checks out repo, sets up .NET, runs `dotnet run -c Release --project tests/TaskMaster.Benchmarks -- --filter "*ClassifierBenchmarks*" --exporters JSON --artifacts artifacts/benchmarks/run` then `pwsh -NoProfile -File scripts/benchmarks/compare-benchmarks.ps1 -BaselinePath artifacts/benchmarks/baseline.json -CurrentPath artifacts/benchmarks/run/results/*-report-full.json -T1BenchmarkIdPattern "ClassifierBenchmarks"`
  - Acceptance: YAML parses (`pwsh -Command "(Get-Content .github/workflows/pr-pipeline.yml -Raw) | ConvertFrom-Yaml"` or `actionlint` equivalent); diff and parse log saved at `<FEATURE>/evidence/other/p6-stage10-yaml.md`
- [x] [P6-T2] Add job `benchmark-gate-self-validation` to the same workflow running `dotnet test --filter "Category=benchmark-gate-self-validation"` and asserting both self-validation tests' inner assertions pass (i.e., the synthetic regression is caught and the non-idempotent handler is detected); the job runs in parallel to stage 10
  - Acceptance: YAML parses; job step list saved at `<FEATURE>/evidence/other/p6-self-validation-job.md`
- [x] [P6-T3] Verify both new jobs are referenced as required checks for the PR (documented in `<FEATURE>/evidence/other/p6-required-checks.md`); no other workflow files are modified
  - Acceptance: `git diff --name-only` after Phase 6 shows only `.github/workflows/pr-pipeline.yml` modified; log at `<FEATURE>/evidence/other/p6-workflow-diff.md`

### Phase 7 — Full QA Loop, Coverage Evidence, and AC Checkoff

- [x] [P7-T1] Run `dotnet csharpier check .` (per `.claude/rules/csharp.md`: CSharpier is the mandatory formatter; `dotnet format` is prohibited); if CSharpier reports any unformatted files, run `dotnet csharpier format .` to fix and re-run the loop from step 1
  - Acceptance: `dotnet csharpier check .` exits 0 in a clean pass; log at `<FEATURE>/evidence/qa-gates/p7-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`
- [x] [P7-T2] Run lint via `dotnet build TaskMaster.sln -c Release -warnaserror` (the composite action `./.github/actions/lint` is not verified to exist in this repository; the `-warnaserror` build is the equivalent enforced lint signal for C#)
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-lint.md`
- [x] [P7-T3] Run type-check via `dotnet build TaskMaster.sln -c Release -warnaserror`
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-typecheck.md`
- [x] [P7-T4] Run architecture tests `dotnet test tests/TaskMaster.ArchitectureTests --no-build`
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-architecture.md`
- [x] [P7-T5] Run unit + integration tests with coverage: `dotnet test TaskMaster.sln -c Release --filter "Category!=benchmark-gate-self-validation" --collect:"XPlat Code Coverage" --results-directory artifacts/csharp/post-change --nologo`
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-test.md` with `Output Summary:` containing passed/failed counts and headline `line=<pct>` / `branch=<pct>` from merged Cobertura
- [x] [P7-T6] Run quality-tier validator `pwsh -NoProfile -File .github/scripts/validate-quality-tiers.ps1` (the contract gate is intentionally omitted: Prompt G1 is gate-only infrastructure with no OpenAPI surface change, so `oasdiff` / the `./.github/actions/contract` step has no applicable input and is not part of this plan)
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-tier-validate.md`
- [x] [P7-T7] Run benchmark comparator end-to-end against a freshly produced current report and `artifacts/benchmarks/baseline.json`
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-stage10-local.md`
- [x] [P7-T8] Run explicit self-validation suite `dotnet test --filter "Category=benchmark-gate-self-validation"` and confirm both negative-path assertions pass (synthetic latency caught; non-idempotent handler caught)
  - Acceptance: exits 0; log at `<FEATURE>/evidence/qa-gates/p7-self-validation.md`
- [x] [P7-T9] Compare baseline vs. post-change coverage: produce `<FEATURE>/evidence/qa-gates/p7-coverage-comparison.md` with baseline line/branch, post-change line/branch, delta, and per-language thresholds (line >= 85%, branch >= 75%, no regression on changed lines)
  - Acceptance: artifact exists, contains both numeric values, and asserts `PASS` against repo policy thresholds
- [x] [P7-T10] Update `<FEATURE>/evidence/qa-gates/p14-acceptance-criteria-checkoff.md` mapping AC1–AC8 to evidence artifacts produced above (paths only; no copy-paste of results)
  - Acceptance: file exists with one row per AC, each row citing at least one artifact under `<FEATURE>/evidence/`
- [x] [P7-T11] Refresh PR-context artifact at `<FEATURE>/evidence/issue-updates/issue-23.<timestamp>.md` summarizing the change set, evidence paths, and `PostedAs: body` placeholder for orchestrator posting
  - Acceptance: file exists with `Timestamp:`, exact intended issue-body text, and list of evidence artifact paths

## Test Plan

- Unit: classifier benchmarks build and list; `SampleIdempotentHandlerTests` passes; comparator self-comparison passes.
- Property: `DeltaReconciliationPropertyTests` (out-of-order, duplicates, missing) with reported seed on failure.
- Integration: stage-10 job + benchmark-gate-self-validation job in `.github/workflows/pr-pipeline.yml`.
- Negative (expect-fail under category gate): `NonIdempotentHandlerNegativeTests`, `LatencyRegressionGateTests`; both must fail the inner assertion when the gate is bypassed and pass the outer self-validation assertion when invoked through the self-validation job.
- Coverage evidence:
  - Baseline: `<FEATURE>/evidence/baseline/baseline-dotnet-test.md`
  - Post-change: `<FEATURE>/evidence/qa-gates/p7-test.md`
  - Comparison: `<FEATURE>/evidence/qa-gates/p7-coverage-comparison.md`

## Acceptance Criteria Traceability

- AC1 → P1-T2, P1-T4, P2-T1
- AC2 → P2-T3
- AC3 → P3-T1, P3-T2, P6-T1
- AC4 → P4-T3, P4-T4, P4-T5
- AC5 → P5-T1
- AC6 → P4-T4 (base-class default `[Fact]`)
- AC7 → P3-T3, P5-T3, P6-T2, P7-T8
- AC8 → P5-T2, P6-T2, P7-T8

## Open Questions / Notes

- BenchmarkDotNet `JsonExporter.Full` produces `*-report-full.json`; the comparator parses BenchmarkDotNet JSON directly. If the schema diverges from `artifacts/benchmarks/README.md`, update both in the same PR.
- The delta-reconciliation benchmark is intentionally disabled and marked `TODO(G2)`. Re-enabling is the responsibility of Prompt G2.
- `ReplayCount` default per spec is `N >= 3`; this plan uses 5 in the base-class default for stronger detection, configurable down to 3 in derived classes.

## Preflight Signal

This plan is submitted for `DIRECTIVE: PREFLIGHT VALIDATION ONLY` against the canonical evidence scheme.
