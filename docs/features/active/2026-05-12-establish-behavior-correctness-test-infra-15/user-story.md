# establish-behavior-correctness-test-infra — User Story

- Issue: #15
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-12

## Story Statements

- As a developer contributing to a T1 or T2 module, I want a property-based test framework available in both TypeScript and .NET, so that I can write `test.prop` / `Gen.Select` tests that automatically generate counter-examples and report the failing seed.
- As a developer working on a T1 classifier module, I want a golden/snapshot test framework available in .NET, so that I can verify classifier output against committed reference snapshots and detect regressions automatically.
- As a developer or CI operator, I want Stryker mutation tools registered and configured in both TypeScript and .NET, so that when a T1 module lands it is subject to mutation scoring immediately without additional setup.
- As a developer adding corpus fixtures or golden test snapshots, I want clear contribution policies and an appropriate `.gitignore` configuration, so that temporary `.received.*` files are never accidentally committed.
- As a CI operator, I want a separate pre-merge pipeline with stage-8 (mutation) and stage-9 (golden) jobs, so that expensive mutation runs and golden test gates do not degrade per-PR feedback latency.

---

## Problem / Why

The repository's quality-tier policy requires mutation testing (>= 75% score) and property tests for T1 modules, and golden tests for T1 classifier-output modules. No tooling infrastructure exists to satisfy these gates. When classifier engines and the ToDo ID allocator arrive, retrofitting the infrastructure at that point introduces friction and risk of gate failures on first introduction. Establishing the infrastructure now — against placeholder exercises — allows subsequent T1 modules to pass gates from day one.

Additionally: no corpus directory exists for golden test inputs, no generator directories exist for reusable domain arbitraries, and CI pipeline stages 8 and 9 are absent.

---

## Personas & Scenarios

### Persona: Application Developer (TypeScript)

- A developer writing or modifying TypeScript logic in a T1 or T2 module.
- Familiar with Vitest and TypeScript. May not have used property-based testing before.
- Needs clear examples to understand how `test.prop` differs from `test`.
- Constrained by the existing Vitest 2.x installation; cannot upgrade to Vitest 4.x without broader impact.

**Scenario: Writing a first property test in TypeScript**

1. Developer identifies a pure helper function to test (e.g., a string transformation or data normalization function).
2. Developer opens an existing test file or creates a new one.
3. Developer imports `test` from `@fast-check/vitest` and `fc` from `fast-check`.
4. Developer writes `test.prop([fc.string()])("invariant description", (s) => { ... })`.
5. Developer runs `npx vitest run`. The test runs with many generated inputs.
6. If the function is correct, all inputs pass. If a bug exists, Vitest prints the failing input and seed for reproduction.

### Persona: Application Developer (.NET)

- A developer writing or modifying C# logic in a T1 or T2 module.
- Familiar with xUnit, NSubstitute, and FluentAssertions. Has seen CsCheck in the existing `UserSettingsPropertyTests.cs` but has not yet used the centralized generators.
- Constrained to use `xunit` 2.9.3 in existing test projects; must use `xunit.v3` only in the new golden test project.

**Scenario: Writing a property test in .NET using a centralized generator**

1. Developer identifies a pure function in `TaskMaster.Application` to test.
2. Developer opens `tests/TaskMaster.Application.Tests/`.
3. Developer references `UserSettingsGen.cs` from the `Generators/` folder to obtain a `Gen<UserSettings>` instance rather than writing inline `Gen.Select` calls.
4. Developer adds a new `[Fact]` or CsCheck sample-based assertion using the generator.
5. Developer runs `dotnet test`. CsCheck generates samples and reports any counter-examples with their seed.

**Scenario: Writing a golden test in .NET**

1. Developer creates a new test class in `tests/TaskMaster.PlaceholderGolden.Tests/` (or a future T1 golden test project).
2. Developer decorates the class with `[UsesVerify]` and calls `await Verify(result)` in a `[Fact]` method.
3. Developer runs `dotnet test` for the first time. The test fails and creates a `.received.txt` file containing the serialized output.
4. Developer inspects the `.received.txt` file, confirms the output is correct, and renames or copies it to `.verified.txt`.
5. Developer commits `.verified.txt` to source control.
6. On all subsequent runs, `dotnet test` passes as long as the function output matches the committed snapshot.
7. If the function output changes (intentional or accidental), the test fails and a new `.received.txt` is created for review.

### Persona: CI Operator / Team Lead

- Responsible for maintaining the CI pipeline and ensuring quality gates are enforced.
- Needs mutation and golden stages to be present in CI without slowing per-PR feedback loops.
- Needs Stryker thresholds to be pre-configured so no additional setup is required when T1 code arrives.

**Scenario: Pre-merge pipeline runs mutation and golden gates**

1. A developer opens a PR touching a T1 module (once one exists).
2. The PR pipeline (`pr-pipeline.yml`) runs stages 1–7 as usual. Feedback is fast.
3. The developer queues the PR via the GitHub merge queue.
4. The `pre-merge-pipeline.yml` is triggered by `on: merge_group`.
5. `stage-8-mutation` runs `dotnet stryker` and `npx stryker run` against the T1 project. If mutation score < 75%, the stage fails and the merge is blocked.
6. `stage-9-golden` runs `dotnet test` against the golden test project. If any snapshot differs, the stage fails.
7. If both stages pass, the merge proceeds.

**Scenario: Mutation and golden stages run as stubs (current state — no T1 module)**

1. A PR is queued via the merge queue.
2. `stage-8-mutation` runs and outputs a message indicating no T1 module is present. The step exits 0.
3. `stage-9-golden` runs the placeholder golden test project. The test passes (the `.verified.txt` fixture is committed).
4. The merge proceeds.

---

## Acceptance Criteria

The following criteria are sourced from `issue.md` for this `full-feature` work mode. All criteria within this feature's implementation scope are marked checked; items requiring post-implementation verification remain unchecked until the implementation agent confirms them.

- [x] `fast-check` and `@fast-check/vitest@0.3.0` appear in `package.json` devDependencies.
- [x] At least one property test using `test.prop` exists and passes via `npx vitest run`.
- [x] `Verify.XunitV3` version appears in `Directory.Packages.props`.
- [x] `xunit.v3` version appears in `Directory.Packages.props` (required by Verify.XunitV3).
- [x] A placeholder golden test exists and passes via `dotnet test`.
- [x] `dotnet-stryker` is registered in `.config/dotnet-tools.json` and restores without error.
- [x] `stryker-config.json` skeleton exists in the placeholder test project directory with `break: 75`.
- [x] StrykerJS packages appear in `package.json` devDependencies.
- [x] `stryker.conf.json` skeleton exists at repo root with `break: 75`.
- [x] `corpus/README.md` exists and documents the contribution policy and Git LFS rules.
- [x] `tests/generators/` directory exists with at least one exported `fast-check` arbitrary.
- [x] `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` exists.
- [x] `pre-merge-pipeline.yml` exists with stage-8 and stage-9 stub jobs.
- [x] `.gitignore` contains `*.received.*` and `*.received/` entries.
- [x] `docs/verify-difftools.md` exists documenting local diff tool setup.
- [x] All existing tests continue to pass (`dotnet test` and `npx vitest run` green).
- [x] `quality-tiers.yml` updated with the new placeholder golden test project entry.
- [x] `dotnet build` passes with zero errors and zero warnings.

---

## Non-Goals

- **Migrating existing test projects to xunit.v3.** `TaskMaster.Application.Tests`, `TaskMaster.Api.Tests`, `TaskMaster.ArchitectureTests`, and `TaskMaster.Infrastructure.Tests` remain on `xunit` 2.9.3. Only the new placeholder project uses `xunit.v3`.
- **Upgrading Vitest from 2.x to 4.x.** `@fast-check/vitest@0.3.0` is chosen precisely to avoid this upgrade.
- **Implementing a T1 classifier module.** This feature establishes infrastructure only. No classifier source code is introduced.
- **Activating mutation thresholds against real T1 code.** The `break: 75` config is present but the mutation stages are stubs until T1 source code exists.
- **Adding corpus binary fixture files.** `corpus/README.md` documents the policy, but no actual corpus files are added. Corpus population occurs with the first T1 classifier.
- **Adding GitHub PR comment integration for Stryker results.** This is noted as a deferred concern in the research; it is not in scope for this feature.
- **Configuring CODEOWNERS for `corpus/`.** The `corpus/README.md` documents the expectation; a separate change adds the CODEOWNERS entry.
- **Adding stages 8 or 9 to `pr-pipeline.yml`.** These stages belong in `pre-merge-pipeline.yml` only.
