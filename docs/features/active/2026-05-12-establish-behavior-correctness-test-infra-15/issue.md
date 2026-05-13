# 2026-05-12-establish-behavior-correctness-test-infra (Issue #15)

- Date captured: 2026-05-12
- Author: Dan Moisan
- Status: Active
- Issue: #15
- Issue URL: https://github.com/drmoisan/TMW/issues/15
- Last Updated: 2026-05-12
- Work Mode: full-feature

## Problem / Why

The repository's quality-tier policy (T1 = critical, mutation score >= 75%; T1/T2 = property tests required) has no tooling support yet. When classifier engines and the ToDo allocator arrive they must satisfy the T1 gates immediately; retrofitting the infrastructure at that point adds friction and risk. Standing up property-based tests, snapshot (golden) tests, and mutation testing scaffolding now — against placeholder pure helpers — lets subsequent prompts land T1 modules with a passing gate from day one.

Additionally, no corpus location exists for golden test input fixtures, no generator directories exist for reusable domain arbitraries, and CI pipeline stages 8 (mutation) and 9 (golden) are absent.

## Proposed Behavior

- `fast-check` and `@fast-check/vitest@0.3.0` added to devDependencies; an example property test uses `test.prop` on any existing pure TS helper.
- `CsCheck` is already in Directory.Packages.props; an example property test in `TaskMaster.Application.Tests` using `Gen.Select` is confirmed working (one exists: `UserSettingsPropertyTests.cs`).
- `Verify.XunitV3` added to Directory.Packages.props; a placeholder golden test project (`TaskMaster.PlaceholderGolden.Tests`) demonstrates snapshot round-trip on a trivial pure function. The project uses `xunit.v3` (compatible with Verify.XunitV3).
- `dotnet-stryker` registered in `.config/dotnet-tools.json`; a `stryker-config.json` skeleton placed in the placeholder test project with `break: 75`.
- StrykerJS packages (`@stryker-mutator/core`, `@stryker-mutator/vitest-runner`, `@stryker-mutator/typescript-checker`) added to devDependencies; `stryker.conf.json` skeleton at repo root.
- `corpus/` directory created with a `README.md` documenting the contribution policy and Git LFS rules.
- `tests/generators/` (TS) created with an example arbitrary exporting a `fast-check` arbitrary for any domain type.
- `tests/TaskMaster.Application.Tests/Generators/` (.NET) created with a `UserSettingsGen.cs` generator class.
- A separate `pre-merge-pipeline.yml` workflow created with stage-8-mutation and stage-9-golden stubs that run only when T1 labels or file paths match.
- `.gitignore` updated with `*.received.*` and `*.received/` entries.
- `docs/verify-difftools.md` created documenting local diff tool setup for Verify.

## Acceptance Criteria

- [ ] `fast-check` and `@fast-check/vitest@0.3.0` appear in `package.json` devDependencies.
- [ ] At least one property test using `test.prop` exists and passes via `npx vitest run`.
- [ ] `Verify.XunitV3` version appears in `Directory.Packages.props`.
- [ ] `xunit.v3` version appears in `Directory.Packages.props` (required by Verify.XunitV3).
- [ ] A placeholder golden test exists and passes via `dotnet test`.
- [ ] `dotnet-stryker` is registered in `.config/dotnet-tools.json` and restores without error.
- [ ] `stryker-config.json` skeleton exists in the placeholder test project directory with `break: 75`.
- [ ] StrykerJS packages appear in `package.json` devDependencies.
- [ ] `stryker.conf.json` skeleton exists at repo root with `break: 75`.
- [ ] `corpus/README.md` exists and documents the contribution policy and Git LFS rules.
- [ ] `tests/generators/` directory exists with at least one exported `fast-check` arbitrary.
- [ ] `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` exists.
- [ ] `pre-merge-pipeline.yml` exists with stage-8 and stage-9 stub jobs.
- [ ] `.gitignore` contains `*.received.*` and `*.received/` entries.
- [ ] `docs/verify-difftools.md` exists documenting local diff tool setup.
- [ ] All existing tests continue to pass (`dotnet test` and `npx vitest run` green).
- [ ] `quality-tiers.yml` updated with the new placeholder golden test project entry.
- [ ] `dotnet build` passes with zero errors and zero warnings.

## Constraints & Risks

- `Verify.XunitV3` requires `xunit.v3` (v3); the placeholder golden test project must be a new project using `xunit.v3`, not modifying the existing projects that use `xunit` 2.9.3.
- `@fast-check/vitest@0.3.0` is pinned to Vitest 2.x compatibility; upgrading to 0.4.x requires Vitest 4.x.
- Stryker stages are stubs only (no T1 module exists yet); the `break: 75` threshold becomes enforcing when T1 code arrives.
- The placeholder golden test project must be registered in `quality-tiers.yml` or CI fails.

## Test Conditions to Consider

- [ ] Property test executes and fails with a clear seed when given a broken function
- [ ] Snapshot test creates `.received` file on first run and compares on subsequent runs
- [ ] Stryker.NET config file is syntactically valid (parseable by dotnet-stryker)
- [ ] StrykerJS config file is syntactically valid
- [ ] Pre-merge workflow YAML is syntactically valid (verified by GitHub Actions lint)
- [ ] All existing xUnit tests (using xunit 2.9.3) still compile and pass
