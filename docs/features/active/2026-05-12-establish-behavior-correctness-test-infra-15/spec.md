# establish-behavior-correctness-test-infra — Spec

- **Issue:** #15
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-12
- **Status:** Draft
- **Version:** 0.1

## Overview

The repository's quality-tier policy (T1 = critical, mutation score >= 75%; T1/T2 = property tests required) has no tooling support. When classifier engines and the ToDo ID allocator arrive they must satisfy T1 gates immediately. This feature installs the required infrastructure now — property-based test packages, golden/snapshot test packages, mutation testing tools, corpus and generator directories, and the pre-merge CI workflow — using placeholder exercises so subsequent prompts can land T1 modules with a passing gate from day one.

No T1 module exists in the repository at the time this feature is implemented. Stryker stages are stubs; the `break: 75` threshold becomes enforcing when T1 source code is present.

---

## Behavior

### Property-based tests (TypeScript)

`fast-check` and `@fast-check/vitest@0.3.0` are installed as devDependencies. At least one test file in the TypeScript test suite uses `test.prop` from `@fast-check/vitest` against an existing pure helper. On test failure, the adapter prints the failing seed to Vitest output, enabling deterministic reproduction.

### Property-based tests (.NET)

`CsCheck` is already registered in `Directory.Packages.props` at version 4.6.2 and a property test (`UserSettingsPropertyTests.cs`) already exists. This feature extracts inline generators into a `Generators/UserSettingsGen.cs` class within `tests/TaskMaster.Application.Tests/`.

### Golden/snapshot tests (.NET)

`Verify.XunitV3` (version 31.16.3) is added to `Directory.Packages.props`. A new project `tests/TaskMaster.PlaceholderGolden.Tests/` is created. This project references `xunit.v3` (3.2.2) — not the existing `xunit` 2.9.3 — because `Verify.XunitV3` depends on `xunit.v3.extensibility.core >= 3.2.2`. The placeholder project contains one golden test that demonstrates the `.received`/`.verified` round-trip on a trivial pure function. Existing test projects (`TaskMaster.Application.Tests`, `TaskMaster.Api.Tests`, etc.) continue to use `xunit` 2.9.3 and are not modified.

### Mutation testing (.NET)

`dotnet-stryker` 4.14.1 is registered in `.config/dotnet-tools.json` as a local tool. A `stryker-config.json` skeleton is placed in `tests/TaskMaster.PlaceholderGolden.Tests/` with `break: 75`. The skeleton contains placeholder `project` and `mutate` fields that are filled in when a T1 source module arrives.

### Mutation testing (TypeScript)

`@stryker-mutator/core`, `@stryker-mutator/vitest-runner`, and `@stryker-mutator/typescript-checker` (all 9.6.1) are added as devDependencies. A `stryker.conf.json` skeleton is placed at the repository root with `break: 75` and placeholder `mutate` glob entries.

### Corpus directory

`corpus/README.md` is created documenting the contribution policy and Git LFS rules. The directory will hold versioned input fixtures for golden tests once T1 classifier modules arrive. The `README.md` describes required PR process, Git LFS file patterns, and directory layout conventions.

### Generator directories

`tests/generators/` (TypeScript) is created with at least one `fast-check` arbitrary exported as a barrel from `index.ts`. Files follow the `<domain-concept>-arb.ts` naming pattern.

`tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` (.NET) is created, extracting `Gen.Select` calls currently inlined in `UserSettingsPropertyTests.cs`.

### Pre-merge CI pipeline

A new workflow file `.github/workflows/pre-merge-pipeline.yml` is created with two jobs: `stage-8-mutation` and `stage-9-golden`. Both jobs run on `windows-latest`. The workflow is triggered by `on: merge_group` and, as an interim, by `on: workflow_dispatch`. Both jobs are stubs: they check out the repository and echo a message indicating no T1 module is present. The jobs are wired to depend on each other (stage-9 `needs: stage-8-mutation`) to establish the expected DAG shape for when T1 code arrives.

`pr-pipeline.yml` is not modified. Stages 8 and 9 are not added to it.

### .gitignore additions

The following entries are appended to `.gitignore`:

```
# Verify snapshot received files (temporary, never committed)
*.received.*
*.received/
```

`.verified.*` files are committed to source control.

### Verify diff tool documentation

`docs/verify-difftools.md` is created documenting the recommended local diff tool setup (WinMerge, VS Code, Beyond Compare) for reviewing Verify snapshot diffs. This document is advisory; CI does not require a diff tool and Verify auto-skips tool launch when `CI=true`.

### quality-tiers.yml entry

`quality-tiers.yml` is updated with an entry for `TaskMaster.PlaceholderGolden.Tests` at tier **t4** (test scaffolding). This is required because CI's `tier-classification` stage fails if any project directory containing a `.csproj` is unregistered.

---

## Inputs / Outputs

### Inputs

| Input | Description |
|---|---|
| `package.json` | Receives new devDependency entries for fast-check and StrykerJS packages |
| `Directory.Packages.props` | Receives new `PackageVersion` entries for `xunit.v3`, `xunit.v3.runner.visualstudio`, and `Verify.XunitV3` |
| `.config/dotnet-tools.json` | Receives a new entry for `dotnet-stryker` 4.14.1 |
| `quality-tiers.yml` | Receives a new project entry for `TaskMaster.PlaceholderGolden.Tests` |
| `.gitignore` | Receives two new entries for Verify received files |

### Outputs / New Files

| Path | Description |
|---|---|
| `tests/generators/index.ts` | Barrel exporting TypeScript fast-check arbitraries |
| `tests/generators/<domain>-arb.ts` | One or more domain arbitrary modules |
| `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs` | CsCheck generator class for `UserSettings` |
| `tests/TaskMaster.PlaceholderGolden.Tests/` | New xunit.v3 + Verify.XunitV3 placeholder project |
| `tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj` | Project file referencing xunit.v3 and Verify.XunitV3 |
| `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.cs` | One golden test exercising the snapshot round-trip |
| `tests/TaskMaster.PlaceholderGolden.Tests/VerifyInit.cs` | `ModuleInitializer` configuring `VerifierSettings.UseStrictJson()` |
| `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json` | Stryker.NET config skeleton with `break: 75` |
| `stryker.conf.json` | StrykerJS config skeleton at repo root with `break: 75` |
| `corpus/README.md` | Contribution policy and Git LFS rules for the corpus directory |
| `.github/workflows/pre-merge-pipeline.yml` | Pre-merge workflow with stage-8 and stage-9 stub jobs |
| `docs/verify-difftools.md` | Advisory documentation for local Verify diff tool setup |

---

## Package Versions

### TypeScript (devDependencies in `package.json`)

| Package | Version | Constraint |
|---|---|---|
| `fast-check` | `4.8.0` | Framework-agnostic; no peer constraint with Vitest |
| `@fast-check/vitest` | `0.3.0` | **Pinned.** 0.4.x requires Vitest 4.x; repo uses Vitest `^2.1.9`. Do not upgrade until Vitest is upgraded to 4.x. |
| `@stryker-mutator/core` | `9.6.1` | All three Stryker packages must share the same version |
| `@stryker-mutator/vitest-runner` | `9.6.1` | Peer requires `vitest >=2.0.0`; satisfied by `^2.1.9` |
| `@stryker-mutator/typescript-checker` | `9.6.1` | Must match core version |

### .NET (new entries in `Directory.Packages.props`)

| Package | Version | Notes |
|---|---|---|
| `xunit.v3` | `3.2.2` | Required by `Verify.XunitV3`. Used only in `TaskMaster.PlaceholderGolden.Tests`. Existing projects continue to reference `xunit` 2.9.3. |
| `xunit.v3.runner.visualstudio` | `3.2.2` | Runner counterpart for xunit.v3; used only in the placeholder project |
| `Verify.XunitV3` | `31.16.3` | Snapshot testing engine; compatible with net10.0 |

### .NET local tool (`.config/dotnet-tools.json`)

| Tool | Version |
|---|---|
| `dotnet-stryker` | `4.14.1` |

---

## Configuration File Formats

### stryker-config.json (Stryker.NET skeleton)

Path: `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json`

```json
{
  "stryker-config": {
    "solution": "../../TaskMaster.sln",
    "project": "TaskMaster.PlaceholderGolden.Tests.csproj",
    "reporters": ["html", "json", "progress"],
    "thresholds": {
      "high": 80,
      "low": 75,
      "break": 75
    },
    "mutate": [
      "**/*.cs",
      "!**/*Tests*.cs",
      "!**/*.g.cs"
    ]
  }
}
```

Note: The `project` field references the placeholder test project. When the first real T1 test project is created, a separate `stryker-config.json` is placed in that project's directory referencing the T1 source project. The placeholder config's `break: 75` is inactive until there is meaningful source code to mutate.

### stryker.conf.json (StrykerJS skeleton)

Path: `stryker.conf.json` (repository root)

```json
{
  "$schema": "https://raw.githubusercontent.com/stryker-mutator/stryker-js/master/packages/core/schema/stryker-schema.json",
  "testRunner": "vitest",
  "checkers": ["typescript"],
  "mutate": [
    "src/**/*.ts",
    "!src/**/*.test.ts",
    "!src/**/*.d.ts"
  ],
  "typescriptChecker": {
    "prioritizePerformanceOverAccuracy": false
  },
  "thresholds": {
    "high": 80,
    "low": 75,
    "break": 75
  },
  "reporters": ["html", "json", "progress"],
  "htmlReporter": {
    "fileName": "mutation-report/index.html"
  },
  "coverageAnalysis": "perTest"
}
```

When the first T1 TypeScript module exists, narrow the `mutate` array to the T1 module's source path (e.g., `src/classifiers/**/*.ts`).

---

## New Project: TaskMaster.PlaceholderGolden.Tests

### Critical: xunit.v3 requirement

`TaskMaster.PlaceholderGolden.Tests` **must** reference `xunit.v3` (not `xunit` 2.9.3). `Verify.XunitV3` depends on `xunit.v3.extensibility.core >= 3.2.2`. Referencing the legacy `xunit` package causes a build error. All existing test projects (`TaskMaster.Application.Tests`, `TaskMaster.Api.Tests`, `TaskMaster.ArchitectureTests`, `TaskMaster.Infrastructure.Tests`) continue to reference `xunit` 2.9.3 and must not be modified.

### Project file structure

The `.csproj` references:
- `xunit.v3` (version from `Directory.Packages.props`)
- `xunit.v3.runner.visualstudio` (version from `Directory.Packages.props`)
- `Verify.XunitV3` (version from `Directory.Packages.props`)
- `Microsoft.NET.Test.Sdk`
- `coverlet.collector`
- Analyzer stack packages (consistent with other test projects)

Target framework: `net10.0` (consistent with the solution).

### VerifyInit.cs

```csharp
using System.Runtime.CompilerServices;
using VerifyTests;

public static class VerifyInit
{
    [ModuleInitializer]
    public static void Init() =>
        VerifierSettings.UseStrictJson();
}
```

### PlaceholderGoldenTests.cs

The test calls `Verify()` on the return value of a trivial pure function (e.g., a static helper that formats a string or returns a value object). On the first run the test creates a `.received.txt` file and fails. After the developer reviews and promotes it to `.verified.txt`, subsequent runs pass. The `.verified.txt` file is committed to source control.

---

## pre-merge-pipeline.yml Structure

Path: `.github/workflows/pre-merge-pipeline.yml`

```yaml
name: Pre-Merge Pipeline
on:
  merge_group:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  stage-8-mutation:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: 10.0.x
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"
      - name: Restore local tools
        shell: pwsh
        run: dotnet tool restore
      - name: Install npm dependencies
        shell: pwsh
        run: npm ci --no-audit --no-fund
      - name: Stub — no T1 module present
        shell: pwsh
        run: |
          Write-Host "Stage 8 (mutation): no T1 module exists yet. This step becomes active when a T1 source module is introduced. break: 75 threshold is configured in stryker-config.json and stryker.conf.json."

  stage-9-golden:
    runs-on: windows-latest
    needs: [stage-8-mutation]
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: 10.0.x
      - name: Restore
        shell: pwsh
        run: dotnet restore TaskMaster.sln
      - name: Run placeholder golden tests
        shell: pwsh
        run: |
          dotnet test tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj --no-restore --collect:"XPlat Code Coverage"
```

The `stage-8-mutation` job is a stub until T1 code arrives. The `stage-9-golden` job runs the placeholder golden test project, which is a concrete gate from day one.

---

## corpus/ Contribution Policy

`corpus/README.md` documents the following rules:

1. **Separate PR required.** Corpus updates must be submitted as a dedicated PR, not bundled with source code changes. The PR description must state which classifier's corpus is changing and why.
2. **Explicit diff review.** The project lead reviews all corpus changes via CODEOWNERS (entry: `corpus/** @drmoisan`).
3. **Git LFS for binary files.** Files matching `corpus/**/*.eml`, `corpus/**/*.bin`, and `corpus/**/*.json` (when large) are tracked via Git LFS using the patterns below. Text fixtures under 1 MB may use regular Git with `text eol=lf`.
4. **Directory layout.** Top-level subdirectories name the classifier (e.g., `corpus/classifiers/spam-samples/`, `corpus/classifiers/triage-samples/`). File names include a zero-padded sequence number (e.g., `sample-001.json`).
5. **No generated content.** Corpus files represent real or carefully curated inputs. Synthetically generated fixtures must be tagged as synthetic in a sidecar `.meta.json` file.

Git LFS patterns (to be added to `.gitattributes` when binary corpus files are introduced):

```
corpus/**/*.eml filter=lfs diff=lfs merge=lfs -text
corpus/**/*.bin filter=lfs diff=lfs merge=lfs -text
```

---

## generators/ Directory Layout

### TypeScript: `tests/generators/`

```
tests/generators/
  index.ts             # Barrel re-exporting all arbitraries
  task-arb.ts          # fast-check arbitrary for the Task domain type (placeholder)
```

`index.ts` example:

```typescript
export { taskArbitrary } from "./task-arb";
```

Files in this directory are not matched by the Vitest `include` pattern (`**/*.test.ts`) and do not require exclusion from `vitest.config.ts`.

### .NET: `tests/TaskMaster.Application.Tests/Generators/`

```
tests/TaskMaster.Application.Tests/Generators/
  UserSettingsGen.cs   # CsCheck Gen-returning static class for UserSettings
```

`UserSettingsGen.cs` exposes a static `Gen<UserSettings>` property (or method) that other property test classes in the same project can reference. This centralizes the `Gen.Select` calls currently inlined in `UserSettingsPropertyTests.cs`.

---

## .gitignore Additions

Add to `.gitignore`:

```
# Verify snapshot received files (temporary, never committed)
*.received.*
*.received/
```

These patterns prevent accidentally staging `.received.txt` files that Verify creates on first run or on output mismatch.

---

## docs/verify-difftools.md Content

The file documents the recommended approach for reviewing Verify snapshot diffs locally. It covers:

- How Verify selects a diff tool automatically (checks for Beyond Compare, WinMerge, VS Code, Rider, Visual Studio).
- How to set a preferred tool explicitly via `VerifierSettings.RegisterFrontend(...)` or environment variable `DiffEngine_Disabled=true` for headless runs.
- Confirmation that CI runs are unaffected: when `CI=true` or no diff tool is detected, Verify skips launching any external tool.
- A table of commonly available tools and their detection behavior.

---

## quality-tiers.yml Entry

Add the following entry under the `projects:` list:

```yaml
  - name: TaskMaster.PlaceholderGolden.Tests
    path: tests/TaskMaster.PlaceholderGolden.Tests
    language: csharp
    tier: t4
    rationale: |
      Test scaffolding (T4): placeholder xunit.v3 + Verify.XunitV3 golden test project.
      Demonstrates the snapshot round-trip pattern before any T1 classifier module lands.
      Uses xunit.v3 (not xunit 2.9.3) because Verify.XunitV3 requires xunit.v3.extensibility.core >= 3.2.2.
```

---

## Constraints & Risks

| Constraint / Risk | Mitigation |
|---|---|
| `@fast-check/vitest@0.3.0` is the last version compatible with Vitest 2.x. `0.4.x` requires Vitest `^4.1.0`. | Pin to `0.3.0` in `package.json`. Do not upgrade until Vitest is upgraded to 4.x. |
| `Verify.XunitV3` is incompatible with `xunit` 2.9.3. | The placeholder golden test project is a new project using `xunit.v3`. Existing test projects are not touched. |
| All three `@stryker-mutator/*` packages must share the same version. | All three are pinned to `9.6.1` in `package.json`. |
| The placeholder project must appear in `quality-tiers.yml` or the `tier-classification` CI stage fails. | Entry is added in the same change as the project is created. |
| Stryker mutation stages are stubs; `break: 75` does not enforce until T1 source is present. | Config files have the correct threshold set so the gate activates automatically when T1 code arrives. |
| `dotnet-stryker` runs in `.config/dotnet-tools.json` as a local tool; `dotnet tool restore` must execute before `dotnet stryker`. | The existing `dotnet-format` action already runs `dotnet tool restore`; the pre-merge pipeline must include this step explicitly. |

---

## Implementation Strategy

### Scope

1. Update `package.json` devDependencies: add `fast-check`, `@fast-check/vitest@0.3.0`, and the three `@stryker-mutator/*` packages.
2. Update `Directory.Packages.props`: add `xunit.v3`, `xunit.v3.runner.visualstudio`, and `Verify.XunitV3`.
3. Update `.config/dotnet-tools.json`: add `dotnet-stryker` 4.14.1.
4. Create `tests/generators/` with `index.ts` and at least one `*-arb.ts` file.
5. Create `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs`.
6. Create `tests/TaskMaster.PlaceholderGolden.Tests/` project (csproj, test class, VerifyInit, `.verified.txt` fixture, stryker-config.json).
7. Add an example property test using `test.prop` to the TypeScript test suite.
8. Create `stryker.conf.json` at repo root.
9. Create `corpus/README.md`.
10. Create `.github/workflows/pre-merge-pipeline.yml`.
11. Append `*.received.*` and `*.received/` to `.gitignore`.
12. Create `docs/verify-difftools.md`.
13. Update `quality-tiers.yml` with the new project entry.

### No changes to existing test projects

`TaskMaster.Application.Tests`, `TaskMaster.Api.Tests`, `TaskMaster.ArchitectureTests`, and `TaskMaster.Infrastructure.Tests` are not modified. They continue to use `xunit` 2.9.3.

### No changes to pr-pipeline.yml

Stages 8 and 9 are placed in `pre-merge-pipeline.yml` only. The per-PR pipeline is unchanged.

---

## Definition of Done

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

Note: All items above are checked off as planned deliverables within this feature's implementation scope, not as post-implementation verification results. Verification occurs during plan execution.

## Seeded Test Conditions

- [ ] Property test executes and produces a clear seed in failure output when given a broken function
- [ ] Snapshot test creates `.received` file on first run and passes on subsequent runs when `.verified.txt` is committed
- [ ] `stryker-config.json` is syntactically valid (parseable by `dotnet stryker`)
- [ ] `stryker.conf.json` is syntactically valid (parseable by `npx stryker run`)
- [ ] `pre-merge-pipeline.yml` is syntactically valid GitHub Actions YAML
- [ ] All existing xUnit tests (using `xunit` 2.9.3) still compile and pass after the new project is added
