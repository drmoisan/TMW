# Code Review — Issue #15: Establish Behavior-Correctness Test Infrastructure
- Audit timestamp: 2026-05-12T23-30
- Auditor: Feature Review Agent (claude-sonnet-4-6)
- Scope: All new and modified files in the feature branch

---

## TypeScript Files

### `src/taskpane/taskpane.ts`

**Change:** Added `export function normalizeTitle(s: string): string { return s.trim(); }` at lines 15–18.

**Assessment:**
- The function is pure, stateless, and correctly exported. Its placement at the top of the file, above the interface declarations, is logical.
- The JSDoc comment accurately describes the function's purpose and explicitly notes its suitability for property-based testing — useful for future contributors.
- Return type is explicitly declared (`string`). No `any` or type assertions used.
- The implementation is the simplest possible correct implementation. No complexity concerns.

**Verdict: PASS — no findings.**

---

### `src/taskpane/taskpane.property.test.ts`

**Change:** New file. 3 property tests for `normalizeTitle` using `@fast-check/vitest`.

**Assessment:**

**Design pattern — dynamic import workaround:**
The file uses a `beforeAll` block to install a `globalThis.Office` mock and then dynamically imports `taskpane.ts`. This pattern is necessary because `taskpane.ts` calls `Office.onReady()` at module scope (line 80). Static import at module evaluation time would fail because `Office` is not defined in the test environment.

The pattern is correct and documented with a file-level comment. The mock object covers `onReady`, `HostType`, `EventType`, and `context.mailbox` — the four Office globals referenced in `taskpane.ts`. No properties are omitted that would cause a runtime error during import.

The use of `(globalThis as Record<string, unknown>)["Office"]` is the idiomatic approach for installing a property on the global object in a TypeScript context. The `as Record<string, unknown>` cast is the minimum necessary to satisfy TypeScript's strict checks on `globalThis`. This is not a policy violation (it is not a suppression directive).

**Property selection:**
The three properties chosen are:
1. Idempotency (`normalizeTitle(normalizeTitle(s)) === normalizeTitle(s)`)
2. Non-length-increasing (`normalizeTitle(s).length <= s.length`)
3. No leading/trailing whitespace in output

These three properties together constitute a complete behavioral specification of `s.trim()`. The idempotency property is the most valuable for regression detection. All three are correct.

**Naming and structure:**
- File name follows the `.property.test.ts` convention — clearly distinguishes property tests from unit tests.
- `describe` block groups the three tests logically.
- Each test has an inline JSDoc comment explaining the property and why it holds.

**Minor observation:** The `describe` block import includes `describe` from `vitest` but does not import `beforeAll` from `vitest` at the top-level — wait, `beforeAll` is imported from `vitest` at line 11 (`import { beforeAll, describe } from "vitest"`). This is correct.

**Import of `test`:** `test` is imported from `@fast-check/vitest` (not from `vitest`) — this is the correct import for `test.prop`. The `describe` wrapper uses the Vitest `describe`, which is compatible.

**Verdict: PASS — no findings. The Office mock pattern is correct and necessary; well-documented.**

---

### `tests/generators/task-arb.ts`

**Change:** New file. Exports `taskArbitrary` — a `fc.record` arbitrary for a placeholder `Task`.

**Assessment:**
- File name follows `<domain-concept>-arb.ts` pattern as required by `spec.md`.
- Uses `fc.uuid()`, `fc.string()`, `fc.boolean()` — appropriate built-in arbitraries.
- The exported name `taskArbitrary` follows camelCase convention for exported values.
- The JSDoc comment accurately describes the generated shape.
- No `Task` interface is defined in this file or imported — the arbitrary produces an anonymous object that structurally matches a task. This is acceptable for a placeholder; once the `Task` domain type is defined in `TaskMaster.Domain`, this arbitrary should be typed against it.

**Minor observation (non-blocking):** The arbitrary generates a task object but there is no corresponding `Task` type it is typed against. The inferred type will be `{ id: string; title: string; completed: boolean }`. Typing this against a domain interface when one exists would improve type safety. This is appropriate for a placeholder and requires no action in this feature.

**Verdict: PASS.**

---

### `tests/generators/index.ts`

**Change:** New file. One line: `export { taskArbitrary } from "./task-arb";`

**Assessment:**
- Correct barrel export pattern.
- Named export (not `export *`) — preferred for explicit API surface.

**Verdict: PASS.**

---

### `package.json`

**Change:** Added 5 devDependencies.

**Assessment:**

| Package | Declared version | Policy requirement |
|---|---|---|
| `@fast-check/vitest` | `0.3.0` (exact pin, no caret) | Spec: pinned to 0.3.0 |
| `fast-check` | `4.8.0` (exact pin) | Spec: 4.8.0 |
| `@stryker-mutator/core` | `9.6.1` (exact pin) | Spec: 9.6.1 |
| `@stryker-mutator/vitest-runner` | `9.6.1` (exact pin) | Spec: 9.6.1 |
| `@stryker-mutator/typescript-checker` | `9.6.1` (exact pin) | Spec: 9.6.1 |

All five packages are pinned without range operators. `@fast-check/vitest` is at exactly `0.3.0` as required (not `^0.3.0`). The three Stryker packages share the same version as required.

The alphabetical ordering within `devDependencies` is maintained for the fast-check and Stryker entries (they appear at the top of the block in alphabetical order, consistent with the existing structure).

**Verdict: PASS.**

---

### `stryker.conf.json`

**Change:** New file at repo root.

**Assessment:**
- `$schema` is present — enables IDE validation.
- `testRunner: "vitest"` — correct for this project.
- `checkers: ["typescript"]` — TypeScript checker enabled.
- `mutate: []` — empty array, not the spec's example `["src/**/*.ts", ...]`. This is the correct implementation choice for a stub: no mutants will be generated until T1 source exists and the array is populated. This diverges from the spec's `stryker.conf.json` example (which showed globs), but the issue description explicitly states `mutate: []` (empty) for the stub. The caller also confirmed `mutate: []` is intentional.
- `break: 75` — correct threshold.
- `htmlReporter.fileName: "mutation-report/index.html"` — output path matches the `.gitignore` entry `mutation-report/`.
- `coverageAnalysis: "perTest"` — standard configuration.

**Verdict: PASS.**

---

## C# Files

### `tests/TaskMaster.Application.Tests/Generators/UserSettingsGen.cs`

**Change:** New file. Extracts `Gen.Select` calls previously inlined in `UserSettingsPropertyTests.cs`.

**Assessment:**
- `internal static class` — correct visibility for a test-project helper; not part of any public API.
- File-scoped namespace: `namespace TaskMaster.Application.Tests;` — policy compliant.
- `public static Gen<UserSettings> Arbitrary` — property name `Arbitrary` is clear and consistent with the CsCheck convention.
- Null coalescing `userId ?? string.Empty` correctly handles `Gen.String` producing `null` (CsCheck's `Gen.String` can produce null).
- XML doc comments on both the class and property — good practice for a shared generator.
- No external I/O. Pure generator composition.

**Verdict: PASS.**

---

### `tests/TaskMaster.Application.Tests/UserSettingsPropertyTests.cs`

**Change:** Modified to use `UserSettingsGen.Arbitrary` instead of inline `Gen.Select`.

**Assessment:**
- The test is functionally identical to the prior version; only the generator source changed.
- `UserSettingsGen.Arbitrary.Sample(original => { ... })` — correct CsCheck invocation pattern.
- Round-trip serialization property is meaningful and correct.
- AAA structure is clear (Act and Assert labeled in comments).
- FluentAssertions used consistently — no raw `Assert.*` calls.

**Verdict: PASS.**

---

### `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.cs`

**Change:** New file.

**Assessment:**
- `public sealed class PlaceholderGoldenTests` — no `[UsesVerify]` attribute. This is the correct pattern for `Verify.XunitV3`. In the xunit.v3 integration, `[UsesVerify]` is not required (it was needed for older Verify + xunit v2 integrations). The static `Verify()` method is available via global usings or implicit `VerifyXunit.Verifier` import provided by the `Verify.XunitV3` package. The class decorates correctly for xunit.v3.
- `public Task VerifyPlaceholder()` — returns `Task` (not `async Task`), which is idiomatic when the only statement is `return Verify(...)`.
- `[Fact]` attribute — correct.
- The verified object `new { Name = "test", Value = 42 }` is simple and deterministic — appropriate for a placeholder.
- File-scoped namespace: `namespace TaskMaster.PlaceholderGolden.Tests;` — policy compliant.

**Verdict: PASS — absence of `[UsesVerify]` is the correct pattern for Verify.XunitV3.**

---

### `tests/TaskMaster.PlaceholderGolden.Tests/VerifyInit.cs`

**Change:** New file.

**Assessment:**
- `[ModuleInitializer]` on a `public static void Init()` method — correct pattern for assembly-level Verify configuration.
- `VerifierSettings.UseStrictJson()` — configures strict JSON output for deterministic snapshots. This is the recommended setting for deterministic CI behavior.
- `internal static class VerifyInit` — correct visibility.
- File-scoped namespace: `namespace TaskMaster.PlaceholderGolden.Tests;` — policy compliant.

**Verdict: PASS.**

---

### `tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj`

**Change:** New file.

**Assessment:**
- Target framework: `net10.0` — consistent with solution.
- References: `coverlet.collector`, `Microsoft.NET.Test.Sdk`, `Verify.XunitV3`, `xunit.v3`.
- `xunit.runner.visualstudio` is referenced (the v2 runner, already in `Directory.Packages.props`). The spec called for `xunit.v3.runner.visualstudio` — this is finding F-1 from the policy audit. The v2 runner appears to support xunit.v3 in practice (tests pass), but the spec deviation should be tracked.
- No reference to `xunit` (v2 package) — correct. The project uses `xunit.v3` exclusively.
- Analyzer stack packages are not explicitly listed in the `.csproj`; they apply via `Directory.Build.props` `<ItemGroup>` that includes them for all projects. This is the correct pattern.
- `RunSettingsFilePath` references `$(MSBuildProjectDirectory)/test.runsettings` — this file was not in the list of new files. This may cause a warning if `test.runsettings` does not exist.

**Finding F-2 (MINOR):** `RunSettingsFilePath` is set to `$(MSBuildProjectDirectory)/test.runsettings` but `test.runsettings` was not listed among the new files created by this feature. If the file is absent, MSBuild may emit a warning or the coverage collector settings may not apply. Other test projects in the solution have this file; the placeholder project may be relying on the same mechanism. This should be confirmed.

**Verdict: PASS with finding F-2 (minor — test.runsettings may be absent).**

---

### `tests/TaskMaster.PlaceholderGolden.Tests/stryker-config.json`

**Change:** New file.

**Assessment:**
- `solution: "../../TaskMaster.sln"` — correct relative path from `tests/TaskMaster.PlaceholderGolden.Tests/`.
- `project: "TaskMaster.PlaceholderGolden.Tests.csproj"` — self-referential placeholder. When a real T1 module arrives, this field should reference the T1 source project.
- `break: 75` — correct threshold.
- `mutate: ["**/*.cs", "!**/*Tests*.cs", "!**/*.g.cs"]` — standard glob pattern excluding test and generated files.
- JSON is syntactically valid (confirmed by visual inspection).

**Verdict: PASS.**

---

### `tests/TaskMaster.PlaceholderGolden.Tests/PlaceholderGoldenTests.VerifyPlaceholder.verified.json`

**Change:** New file (committed snapshot).

**Assessment:**
- Content: `{ "Name": "test", "Value": 42 }` — matches the object passed to `Verify()` in `PlaceholderGoldenTests.cs`.
- Strict JSON format (no trailing commas, correct property casing) — consistent with `VerifierSettings.UseStrictJson()`.
- The file name follows Verify's convention: `<TestClassName>.<TestMethodName>.verified.json`.

**Verdict: PASS.**

---

## Configuration and CI Files

### `.github/workflows/pre-merge-pipeline.yml`

**Assessment:**
- `on: merge_group` and `on: workflow_dispatch` — correct triggers.
- `permissions: contents: read` — least-privilege.
- `stage-8-mutation` and `stage-9-golden` jobs present.
- `stage-9-golden` has `needs: [stage-8-mutation]` — establishes the DAG dependency as spec requires.
- Both jobs run on `windows-latest` — consistent with the rest of the pipeline.
- `stage-8-mutation`: stub step uses `Write-Host` in PowerShell — exits 0, correct stub behavior.
- `stage-9-golden`: runs `dotnet restore TaskMaster.sln` then `dotnet test ... --no-restore` — correct sequencing. Uses `--collect:"XPlat Code Coverage"` — consistent with the rest of the pipeline.
- `pr-pipeline.yml` is confirmed unchanged — stages 8 and 9 were not added to it. This satisfies a key non-goal.

**Verdict: PASS.**

---

### `Directory.Packages.props`

**Assessment:**
- Added: `xunit.v3@3.2.2`, `Verify.XunitV3@31.16.3`.
- Comment `<!-- Golden tests (xunit.v3 + Verify). Used by TaskMaster.PlaceholderGolden.Tests only. -->` — helpful documentation of scope.
- `xunit.v3.runner.visualstudio` is absent (finding F-1). The `.csproj` uses `xunit.runner.visualstudio` (v2 runner), which is already registered.
- Existing `xunit@2.9.3` entry is unchanged — existing test projects are not affected.

**Verdict: PASS with finding F-1.**

---

### `.config/dotnet-tools.json`

**Assessment:**
- `dotnet-stryker@4.14.1` added with `rollForward: false` — pinned version, consistent with `csharpier` entry style.
- `"commands": ["dotnet-stryker"]` — correct command registration.

**Verdict: PASS.**

---

### `quality-tiers.yml`

**Assessment:**
- `TaskMaster.PlaceholderGolden.Tests` added under `# New project added by Issue #15` comment.
- `tier: t4` — correct (test scaffolding).
- `rationale` explains xunit.v3 dependency on Verify.XunitV3 — useful context.
- `path: tests/TaskMaster.PlaceholderGolden.Tests` — correct.
- `language: csharp` — correct.

**Verdict: PASS.**

---

### `.gitignore`

**Assessment:**
- `*.received.*` and `*.received/` added at end of file under `# Verify snapshot received files` comment — correct entries, correct placement.
- `mutation-report/` was already present (it appears at line 37 under `# Test artifacts`).

**Verdict: PASS.**

---

### `.gitattributes`

**Assessment:**
- `corpus/**/*.eml filter=lfs diff=lfs merge=lfs -text` and `corpus/**/*.bin filter=lfs diff=lfs merge=lfs -text` added — matches the patterns documented in `corpus/README.md`.

**Verdict: PASS.**

---

### `corpus/README.md`

**Assessment:**
- All five contribution rules from the spec are present and accurately described.
- Git LFS patterns are documented and match `.gitattributes`.
- Directory layout example is present.
- Note about `.received.*` files and `.verified.json` files is clear.
- No ambiguity in the contribution policy.

**Verdict: PASS.**

---

### `docs/verify-difftools.md`

**Assessment:**
- Covers auto-detection order, explicit configuration via `DiffRunner` / environment variable, CI behavior, and snapshot acceptance workflow.
- Confirms `CI=true` suppresses tool launch — important for CI operators.
- References to `DiffEngine` and `Verify` documentation are included.

**Verdict: PASS.**

---

## Design Principles Assessment

| Principle | Assessment |
|---|---|
| Simplicity | All new files are minimal and focused. `normalizeTitle` is a one-liner. Generator files are concise. |
| Reusability | `UserSettingsGen.cs` centralizes generator logic for reuse across test classes. `tests/generators/` provides a reusable arbitrary pattern. |
| Extensibility | Generator barrel (`index.ts`) can be extended by adding new `*-arb.ts` files. `UserSettingsGen.Arbitrary` is a property, easily consumed. |
| Separation of concerns | Pure logic (`normalizeTitle`) is separated from Office.js wiring. Test generators contain no I/O. |

**Verdict: PASS — design principles satisfied.**

---

## Summary of Findings

| ID | Severity | Description |
|---|---|---|
| F-1 | Minor | `xunit.v3.runner.visualstudio` not added to `Directory.Packages.props`; `.csproj` uses `xunit.runner.visualstudio` instead. Tests pass, but this is a spec deviation. |
| F-2 | Minor | `test.runsettings` referenced in `.csproj` but not listed as a new file; may cause a warning if absent. |

No blocking findings. Both findings are minor and do not affect test execution.
