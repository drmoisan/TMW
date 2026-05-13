# establish-behavior-correctness-test-infra — Plan

- **Issue:** #15
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-12T21-39
- **Status:** Draft
- **Version:** 0.1
- **Work Mode:** full-feature

## Required References

- General Code Change Policy: `.claude/rules/general-code-change.md`
- General Unit Test Policy: `.claude/rules/general-unit-test.md`
- TypeScript Standards: `.claude/rules/typescript.md`
- TypeScript Suppressions: `.claude/rules/typescript-suppressions.md`
- C# Standards: `.claude/rules/csharp.md`
- Quality Tiers: `.claude/rules/quality-tiers.md`
- Architecture Boundaries: `.claude/rules/architecture-boundaries.md`

**All work must comply with these policies. Do not duplicate their content here.**

## Evidence Root

`docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/`

---

## Implementation Plan (Atomic Tasks)

### Phase 0 — Baseline Capture

- [x] [P0-T1] Read policy files in required order: `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`, `.claude/rules/csharp.md`, `.claude/rules/quality-tiers.md`, `.claude/rules/architecture-boundaries.md`
  - Files affected: none (read-only)
  - Acceptance: All seven files confirmed read; evidence artifact written to `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/baseline/phase0-instructions-read.2026-05-12T21-39.md` with fields `Timestamp:`, `Policy Order:`, and explicit list of files read

- [x] [P0-T2] Capture TypeScript baseline — run `npm run test:coverage` from repo root and record results
  - Files affected: `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/baseline/ts-test-baseline.2026-05-12T21-39.md`
  - Command: `npm run test:coverage`
  - Acceptance: Artifact written with fields `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric line-coverage and branch-coverage percentages; all pre-existing tests pass

- [x] [P0-T3] Capture .NET baseline — run `dotnet test --collect:"XPlat Code Coverage"` from repo root and record results
  - Files affected: `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/baseline/dotnet-test-baseline.2026-05-12T21-39.md`
  - Command: `dotnet test --collect:"XPlat Code Coverage"`
  - Acceptance: Artifact written with fields `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric coverage headline; all pre-existing tests pass

**Phase 0 gate:** Both baseline artifacts exist with required fields and numeric coverage values. All pre-existing tests pass. No implementation may begin until this gate clears.

---

### Phase 1 — TypeScript Property-Based Testing

- [x] [P1-T1] Add `fast-check` and `@fast-check/vitest` to devDependencies in `package.json`
  - Files affected: `package.json`
  - Exact values: `"fast-check": "4.8.0"`, `"@fast-check/vitest": "0.3.0"` (pinned — 0.4.x requires Vitest 4.x; repo uses Vitest `^2.1.9`)
  - Acceptance: Both entries appear in `devDependencies` block with the specified versions; `@fast-check/vitest` is pinned to exactly `0.3.0`

- [x] [P1-T2] Run `npm install` to lock in new devDependencies and update `package-lock.json`
  - Files affected: `package-lock.json`
  - Command: `npm install`
  - Acceptance: `npm install` exits 0; `fast-check` and `@fast-check/vitest@0.3.0` appear in `node_modules`; no peer-dependency warnings about Vitest version conflict

- [x] [P1-T3] Create `tests/generators/task-arb.ts` exporting a `fast-check` arbitrary for a placeholder Task object
  - Files affected: `tests/generators/task-arb.ts` (new file)
  - Content: Exports `taskArbitrary` using `fc.record({ id: fc.uuid(), title: fc.string(), completed: fc.boolean() })`
  - Acceptance: File exists; exports a named `taskArbitrary` symbol; file is <= 500 lines; follows kebab-case filename convention

- [x] [P1-T4] Create `tests/generators/index.ts` as a barrel re-exporting all arbitraries
  - Files affected: `tests/generators/index.ts` (new file)
  - Content: `export { taskArbitrary } from "./task-arb";`
  - Acceptance: File exists and re-exports `taskArbitrary` from `./task-arb`; no import cycles; file is <= 500 lines

- [x] [P1-T5] Create `src/taskpane/taskpane.property.test.ts` with at least one `test.prop` using `@fast-check/vitest` on a pure helper exported from `taskpane.ts`
  - Files affected: `src/taskpane/taskpane.property.test.ts` (new file)
  - Content: Imports `test` from `@fast-check/vitest`, `fc` from `fast-check`; calls `test.prop([fc.string()])` against `renderItem` or another pure string-manipulating helper already exported from `taskpane.ts`; includes a docstring explaining the property invariant
  - Acceptance: File exists; `test.prop` is used at least once; test is deterministic; file is <= 500 lines; follows `*.test.ts` naming convention

**Phase 1 gate:** Run `npm run format:check && npm run lint && npm run typecheck && npm run test`. All four commands exit 0. The new property test appears in Vitest output and passes.

---

### Phase 2 — TypeScript Mutation Tooling

- [x] [P2-T1] Add `@stryker-mutator/core`, `@stryker-mutator/vitest-runner`, and `@stryker-mutator/typescript-checker` to devDependencies in `package.json`
  - Files affected: `package.json`
  - Exact values: all three at `"9.6.1"` (monorepo requirement — all three must share the same version)
  - Acceptance: All three entries appear in `devDependencies` at version `9.6.1`; `@stryker-mutator/vitest-runner` peer requirement `vitest >=2.0.0` is satisfied by the existing `^2.1.9`

- [x] [P2-T2] Run `npm install` to lock in Stryker devDependencies
  - Files affected: `package-lock.json`
  - Command: `npm install`
  - Acceptance: `npm install` exits 0; all three `@stryker-mutator/*` packages appear in `node_modules`

- [x] [P2-T3] Create `stryker.conf.json` at repo root with the StrykerJS skeleton configuration
  - Files affected: `stryker.conf.json` (new file at `C:\Users\DanMoisan\source\repos\TMW\stryker.conf.json`)
  - Content: `testRunner: "vitest"`, `checkers: ["typescript"]`, `mutate: ["src/**/*.ts", "!src/**/*.test.ts", "!src/**/*.d.ts"]`, `typescriptChecker: { prioritizePerformanceOverAccuracy: false }`, `thresholds: { high: 80, low: 75, break: 75 }`, `reporters: ["html", "json", "progress"]`, `htmlReporter: { fileName: "mutation-report/index.html" }`, `coverageAnalysis: "perTest"`, `$schema` pointing to the Stryker schema URL specified in spec.md
  - Acceptance: File exists; JSON is syntactically valid; `break` threshold is `75`; `testRunner` is `"vitest"`

- [x] [P2-T4] Add `mutation-report/` to `.gitignore`
  - Files affected: `.gitignore`
  - Acceptance: The line `mutation-report/` appears in `.gitignore`

**Phase 2 gate:** Run `npx stryker run --dryRun` (or verify JSON parses without error). `stryker.conf.json` is syntactically valid. `npm run format:check && npm run lint && npm run typecheck && npm run test` all exit 0.

---

### Phase 3 — .NET Generator Extraction

- [x] [P3-T1] Create `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` extracting inline CsCheck `Gen.Select` into a static `Gen<UserSettings>` property
  - Files affected: `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` (new file)
  - Content: `public static class UserSettingsGen` with a `public static Gen<UserSettings> Arbitrary` property that returns `Gen.Select(Gen.String, Gen.Bool, Gen.Bool, Gen.DateTimeOffset, (userId, notif, triage, ts) => new UserSettings(userId ?? string.Empty, notif, triage, ts))`; file-scoped namespace `TaskMaster.Application.Tests`; uses CsCheck types already in the project
  - Acceptance: File exists; class is `public static`; property is named `Arbitrary`; return type is `Gen<UserSettings>`; file is <= 500 lines; CSharpier-formatted

- [x] [P3-T2] Update `tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs` to use `UserSettingsGen.Arbitrary` instead of the inline `Gen.Select(Gen.String, Gen.Bool, Gen.Bool, Gen.DateTimeOffset)` call
  - Files affected: `tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs`
  - Change: Replace the inline `Gen.Select(Gen.String, Gen.Bool, Gen.Bool, Gen.DateTimeOffset)` expression with `UserSettingsGen.Arbitrary`; the `.Sample(...)` call and all assertions remain identical
  - Acceptance: File compiles; the inline `Gen.Select` call is removed; `UserSettingsGen.Arbitrary` is referenced; test behavior is identical to before the change

**Phase 3 gate:** Run `dotnet csharpier check .` (exits 0), then `dotnet build` (exits 0, zero warnings), then `dotnet test --collect:"XPlat Code Coverage"` (exits 0, all existing tests pass including the refactored property test).

---

### Phase 4 — .NET Golden Test Project and Verify.XunitV3

- [x] [P4-T1] Add `xunit.v3`, `xunit.v3.runner.visualstudio`, and `Verify.XunitV3` version entries to `Directory.Packages.props`
  - Files affected: `Directory.Packages.props`
  - Exact values: `xunit.v3` at `3.2.2`, `xunit.v3.runner.visualstudio` at `3.2.2`, `Verify.XunitV3` at `31.16.3`
  - Note: These new entries do not affect existing projects; existing `xunit` 2.9.3 entry is not modified
  - Acceptance: Three `<PackageVersion>` elements are present in `Directory.Packages.props` with the exact versions above; the existing `xunit 2.9.3` entry is unchanged

- [x] [P4-T2] Create `tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj`
  - Files affected: `tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj` (new file)
  - Content: `TargetFramework net10.0`; `ImplicitUsings enable`; `IsPackable false`; `PackageReference` entries for `xunit.v3`, `xunit.v3.runner.visualstudio`, `Verify.XunitV3`, `Microsoft.NET.Test.Sdk`, `coverlet.collector`; analyzer stack packages (`Meziantou.Analyzer`, `SonarAnalyzer.CSharp`, `Roslynator.Analyzers`, `AsyncFixer`, `SecurityCodeScan.VS2019`, `Microsoft.CodeAnalysis.BannedApiAnalyzers`) each with `PrivateAssets="all"`, consistent with other test projects; no `ProjectReference` to production code (this is a standalone placeholder)
  - Acceptance: File exists; does not reference `xunit` 2.9.3; references `xunit.v3` and `Verify.XunitV3`; `dotnet build` on this project exits 0

- [x] [P4-T3] Create `tests/TaskMaster.PlaceholderGolden.Tests/VerifyInit.cs` with the `[ModuleInitializer]` calling `VerifierSettings.UseStrictJson()`
  - Files affected: `tests/TaskMaster.PlaceholderGolden.Tests/VerifyInit.cs` (new file)
  - Content: Exactly as specified in spec.md — `using System.Runtime.CompilerServices; using VerifyTests;` with `public static class VerifyInit` and `[ModuleInitializer] public static void Init() => VerifierSettings.UseStrictJson();`; file-scoped namespace matching the project
  - Acceptance: File exists; compiles without errors; `[ModuleInitializer]` attribute is applied to `Init()`

- [x] [P4-T4] Create `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.cs` with one `[Fact]` using `[UsesVerify]` and `await Verify(...)`
  - Files affected: `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.cs` (new file)
  - Content: `[UsesVerify] public sealed class PlaceholderGoldenTests` with one `[Fact] public Task VerifyPlaceholder()` that calls `return Verify(new { Name = "test", Value = 42 })`; file-scoped namespace; `using VerifyXunit;`
  - Acceptance: File exists; class decorated with `[UsesVerify]`; test method returns `Task`; calls `Verify()`; file is <= 500 lines

- [x] [P4-T5] Create `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.PlaceholderGoldenTests_VerifyPlaceholder.verified.json` — the committed `.verified.json` reference file
  - Files affected: `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.PlaceholderGoldenTests_VerifyPlaceholder.verified.json` (new file)
  - Content: JSON representation matching `{ Name = "test", Value = 42 }` as Verify serializes it with `UseStrictJson()` — expected content: `{"Name": "test","Value": 42}`
  - Note: The file naming convention Verify uses is `<ClassName>.<MethodName>.verified.json`; the exact filename must match what Verify generates at runtime
  - Acceptance: File exists; JSON is syntactically valid; content matches what `Verify(new { Name = "test", Value = 42 })` produces with `UseStrictJson()`; committed to source control (not in `.gitignore`)

- [x] [P4-T6] Add `tests/TaskMaster.PlaceholderGolden.Tests` project reference to `TaskMaster.sln`
  - Files affected: `TaskMaster.sln`
  - Command: `dotnet sln TaskMaster.sln add tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj`
  - Acceptance: `TaskMaster.sln` contains a project entry for `TaskMaster.PlaceholderGolden.Tests`; `dotnet build TaskMaster.sln` exits 0

- [x] [P4-T7] Add `quality-tiers.yml` entry for `TaskMaster.PlaceholderGolden.Tests` at tier `t4`
  - Files affected: `quality-tiers.yml`
  - Content: New entry with `name: TaskMaster.PlaceholderGolden.Tests`, `path: tests/TaskMaster.PlaceholderGolden.Tests`, `language: csharp`, `tier: t4`, and rationale as specified in spec.md
  - Acceptance: Entry is present; tier is `t4`; CI `tier-classification` stage logic would accept it (path matches the `.csproj` directory)

**Phase 4 gate:** Run `dotnet build TaskMaster.sln` (exits 0, zero errors, zero warnings), then `dotnet test tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj --collect:"XPlat Code Coverage"` (exits 0, the placeholder golden test passes, `.verified.json` file matched). All existing tests in other projects continue to pass via `dotnet test TaskMaster.sln`.

---

### Phase 5 — Stryker.NET Tooling

- [x] [P5-T1] Register `dotnet-stryker` version `4.14.1` in `.config/dotnet-tools.json`
  - Files affected: `.config/dotnet-tools.json`
  - Change: Add `"dotnet-stryker": { "version": "4.14.1", "commands": ["dotnet-stryker"], "rollForward": false }` entry under `tools`
  - Acceptance: Entry is present with correct version and `commands` array; existing `csharpier` entry is unchanged; JSON is syntactically valid

- [x] [P5-T2] Run `dotnet tool restore` to verify `dotnet-stryker` installs without error
  - Files affected: none (tool cache only)
  - Command: `dotnet tool restore`
  - Acceptance: `dotnet tool restore` exits 0; output confirms `dotnet-stryker 4.14.1` was restored; no error messages

- [x] [P5-T3] Create `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json` skeleton with `break: 75` and `mutate` glob entries
  - Files affected: `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json` (new file)
  - Content: Exactly as specified in spec.md — `solution: "../../TaskMaster.sln"`, `project: "TaskMaster.PlaceholderGolden.Tests.csproj"`, `reporters: ["html", "json", "progress"]`, `thresholds: { high: 80, low: 75, break: 75 }`, `mutate: ["**/*.cs", "!**/*Tests*.cs", "!**/*.g.cs"]`
  - Acceptance: File exists; JSON is syntactically valid; `break` is `75`; `solution` path is relative to the file location (`../../TaskMaster.sln`)

**Phase 5 gate:** `dotnet tool restore` exits 0. `stryker-config.json` is valid JSON (parseable by `dotnet stryker --help` from the project directory without error on config loading).

---

### Phase 6 — Corpus Directory and Documentation

- [x] [P6-T1] Create `corpus/classifiers/.gitkeep` as a placeholder for the classifiers subdirectory
  - Files affected: `corpus/classifiers/.gitkeep` (new file)
  - Acceptance: File exists; directory `corpus/classifiers/` is tracked in git via the `.gitkeep`

- [x] [P6-T2] Create `corpus/README.md` documenting the contribution policy and Git LFS rules
  - Files affected: `corpus/README.md` (new file)
  - Content: Documents all five contribution rules from spec.md: separate PR required, explicit diff review, Git LFS for binary files with the `.eml`/`.bin` patterns, directory layout convention, no generated content without `.meta.json` sidecar; includes the two Git LFS `.gitattributes` patterns
  - Acceptance: File exists; covers all five policies from spec.md; Git LFS pattern section present; file is <= 500 lines (Markdown documentation exception applies per policy, but remain concise)

- [x] [P6-T3] Update `.gitattributes` with Git LFS tracking rules for corpus binary files
  - Files affected: `.gitattributes` (existing file — create if absent)
  - Content: Append `corpus/**/*.eml filter=lfs diff=lfs merge=lfs -text` and `corpus/**/*.bin filter=lfs diff=lfs merge=lfs -text`
  - Note: Do NOT add the `corpus/**/*.json` LFS rule — spec.md states text fixtures under 1 MB use regular Git; only the `.eml` and `.bin` patterns are required now
  - Acceptance: Both LFS lines are present in `.gitattributes`; existing entries are unchanged

- [x] [P6-T4] Append `*.received.*` and `*.received/` entries to `.gitignore`
  - Files affected: `.gitignore`
  - Content: Append the block from spec.md: `# Verify snapshot received files (temporary, never committed)`, `*.received.*`, `*.received/`
  - Acceptance: Both pattern lines are present in `.gitignore`; existing entries are unchanged

- [x] [P6-T5] Create `docs/verify-difftools.md` documenting local Verify diff tool setup
  - Files affected: `docs/verify-difftools.md` (new file)
  - Content: Covers: how Verify auto-detects diff tools (Beyond Compare, WinMerge, VS Code, Rider, Visual Studio); how to set preferred tool via `VerifierSettings.RegisterFrontend(...)` or `DiffEngine_Disabled=true`; confirmation that CI is unaffected when `CI=true`; a table of common tools and detection behavior per spec.md
  - Acceptance: File exists; covers auto-detection, explicit configuration, and CI behavior; file is a Markdown documentation file (exempt from 500-line limit per policy)

**Phase 6 gate:** `corpus/README.md`, `corpus/classifiers/.gitkeep`, `.gitattributes` LFS entries, `.gitignore` Verify entries, and `docs/verify-difftools.md` all exist with correct content. No TypeScript or .NET build errors introduced.

---

### Phase 7 — Pre-Merge CI Pipeline

- [x] [P7-T1] Create `.github/workflows/pre-merge-pipeline.yml` with `stage-8-mutation` stub and `stage-9-golden` concrete job
  - Files affected: `.github/workflows/pre-merge-pipeline.yml` (new file)
  - Content: Exactly as specified in spec.md — name `Pre-Merge Pipeline`; triggers `on: merge_group` and `on: workflow_dispatch`; `permissions: contents: read`; two jobs: `stage-8-mutation` (stub that echoes a no-T1-module message, includes checkout, setup-dotnet, setup-node, dotnet tool restore, npm ci) and `stage-9-golden` (runs actual `dotnet test tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj --no-restore --collect:"XPlat Code Coverage"` after checkout and dotnet restore, with `needs: [stage-8-mutation]`); all `run:` steps use `shell: pwsh`
  - Acceptance: File exists; YAML is syntactically valid; `stage-9-golden` has `needs: [stage-8-mutation]`; both jobs run on `windows-latest`; `stage-8-mutation` exits 0 as a stub; `stage-9-golden` runs the placeholder golden test project; `pr-pipeline.yml` is not modified

**Phase 7 gate:** `pre-merge-pipeline.yml` is valid YAML (verify with `npx js-yaml .github/workflows/pre-merge-pipeline.yml` or equivalent parse). `pr-pipeline.yml` is unchanged. `dotnet build TaskMaster.sln` exits 0 (no changes broke the build).

---

### Phase 8 — Full Toolchain Validation

- [x] [P8-T1] Run `npm run format:check` and auto-format any TypeScript files that fail the check
  - Files affected: any `src/**/*.ts` files that require formatting
  - Command: `npm run format:check`; if non-zero exit: `npm run format` then rerun `npm run format:check`
  - Acceptance: `npm run format:check` exits 0 with no files modified

- [x] [P8-T2] Run `npm run lint` and fix any ESLint errors in TypeScript source files
  - Files affected: any `src/**/*.ts` files with lint errors
  - Command: `npm run lint`
  - Acceptance: `npm run lint` exits 0 with zero errors

- [x] [P8-T3] Run `npm run typecheck` and resolve any TypeScript type errors
  - Files affected: any `src/**/*.ts` with type errors
  - Command: `npm run typecheck`
  - Acceptance: `npm run typecheck` exits 0 with zero type errors

- [x] [P8-T4] Run `npm run test:coverage` and confirm all TypeScript tests pass including the new property test; record coverage
  - Files affected: `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/qa-gates/ts-test-final.2026-05-12T21-39.md`
  - Command: `npm run test:coverage`
  - Acceptance: All tests pass (exit 0); the new `taskpane.property.test.ts` property test appears in output; numeric line-coverage and branch-coverage are recorded in the artifact; line coverage >= 85% and branch coverage >= 75%; no regression vs. Phase 0 baseline

- [x] [P8-T5] Run `dotnet tool restore` to confirm all .NET local tools restore without error
  - Files affected: none (tool cache only)
  - Command: `dotnet tool restore`
  - Acceptance: Exits 0; both `csharpier` and `dotnet-stryker` are confirmed restored in output

- [x] [P8-T6] Run `dotnet csharpier check .` and auto-format any C# files that fail the check
  - Files affected: any C# source files requiring formatting
  - Command: `dotnet csharpier check .`; if non-zero exit: `dotnet csharpier .` then rerun `dotnet csharpier check .`
  - Acceptance: `dotnet csharpier check .` exits 0 with no files modified

- [x] [P8-T7] Run `dotnet build TaskMaster.sln` and confirm zero errors and zero warnings
  - Files affected: none (build artifacts only)
  - Command: `dotnet build TaskMaster.sln`
  - Acceptance: Exits 0; zero build errors; zero build warnings (all warnings-as-errors policy enforced via `Directory.Build.props`)

- [x] [P8-T8] Run `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` and confirm all tests pass; record coverage
  - Files affected: `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/qa-gates/dotnet-test-final.2026-05-12T21-39.md`
  - Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
  - Acceptance: All tests pass (exit 0); the new placeholder golden test in `TaskMaster.PlaceholderGolden.Tests` passes; refactored `UserSettingsPropertyTests` passes; numeric coverage is recorded in the artifact; line coverage >= 85% and branch coverage >= 75% for all projects where applicable; no regression vs. Phase 0 baseline

- [x] [P8-T9] Verify no regression: compare post-change coverage against Phase 0 baseline for both TypeScript and .NET; record delta
  - Files affected: `docs/features/active/2026-05-12-establish-behavior-correctness-test-infra-15/evidence/qa-gates/coverage-delta.2026-05-12T21-39.md`
  - Acceptance: Artifact documents baseline values (from P0-T2 and P0-T3 artifacts), post-change values (from P8-T4 and P8-T8 artifacts), and confirms no regression on changed lines; if coverage dropped on any changed file, task fails and must be remediated before the phase is considered complete

**Phase 8 gate:** All nine tasks above exit 0 or produce artifacts confirming pass. Both TypeScript and .NET toolchain loops (format → lint/build → typecheck → test) complete in a single clean pass without any step restarting the loop. Coverage delta artifact shows no regression. This is the final acceptance gate for the feature.

---

## Test Plan Summary

### TypeScript

- Unit tests: existing `taskpane.test.ts` (maintained); new `taskpane.property.test.ts` (Phase 1)
- Property-based tests: `test.prop` in `taskpane.property.test.ts` using `@fast-check/vitest`
- Coverage command: `npm run test:coverage` (Vitest with `@vitest/coverage-v8`)
- Baseline artifact: `evidence/baseline/ts-test-baseline.2026-05-12T21-39.md`
- Final QA artifact: `evidence/qa-gates/ts-test-final.2026-05-12T21-39.md`
- Coverage delta: `evidence/qa-gates/coverage-delta.2026-05-12T21-39.md`

### .NET

- Unit/property tests: existing tests in `TaskMaster.Application.Tests` (maintained); `UserSettingsPropertyTests` refactored to use `UserSettingsGen.Arbitrary`; new `PlaceholderGoldenTests` in `TaskMaster.PlaceholderGolden.Tests`
- Coverage command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
- Baseline artifact: `evidence/baseline/dotnet-test-baseline.2026-05-12T21-39.md`
- Final QA artifact: `evidence/qa-gates/dotnet-test-final.2026-05-12T21-39.md`

### Infrastructure (no automated tests required)

- `stryker.conf.json` (repo root): verified syntactically valid JSON
- `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json`: verified syntactically valid JSON
- `.github/workflows/pre-merge-pipeline.yml`: verified syntactically valid YAML
- `quality-tiers.yml`: validated by CI `tier-classification` stage logic

---

## Open Questions / Notes

1. The `.verified.json` filename for `PlaceholderGoldenTests` (P4-T5) must exactly match Verify's generated name pattern. If the generated filename differs from the assumed pattern after first run, P4-T5 must be corrected before P8-T8 can pass. The filename `PlaceholderGoldenTests.PlaceholderGoldenTests_VerifyPlaceholder.verified.json` follows the Verify naming convention `<ClassName>.<MethodName>.verified.json` where the method name is the test method name.

2. `stryker.conf.json` at repo root has `mutate: ["src/**/*.ts", ...]` (non-empty). This means `npx stryker run` will attempt to mutate files in `src/**/*.ts`. Since no T1 TypeScript module exists yet, the mutation score result will reflect whatever score the existing T4 scaffold code produces. The `break: 75` threshold may or may not trigger depending on the current scaffold coverage. The Phase 7 pipeline stub bypasses this by echoing rather than running Stryker. If the threshold fires during local validation in Phase 8, the `mutate` array should be narrowed to exclude scaffold files. This is noted as a risk but the plan proceeds with the spec-specified configuration.

3. The `corpus/**/*.json` LFS rule from spec.md section "Corpus / Git LFS" is not added in P6-T3 because spec.md explicitly states "Text-format fixtures under 1 MB may use regular Git with `text eol=lf`" and reserves the JSON LFS rule for large JSON. Only `.eml` and `.bin` are added now.

4. `pr-pipeline.yml` is not modified at any point in this plan. Stages 8 and 9 belong exclusively in `pre-merge-pipeline.yml`.
