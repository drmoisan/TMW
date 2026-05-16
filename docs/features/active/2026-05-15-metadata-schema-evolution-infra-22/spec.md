# metadata-schema-evolution-infra — Spec

- **Issue:** #22
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-15
- **Status:** Draft
- **Version:** 0.1

## Overview

TaskMaster's three currently implemented metadata payload types — `ClassificationResult`, `UserSettings`, and `TrainingFeedback` — have no JSON Schema definitions and no schema validation at their write paths. The sole durable write path (`JsonFileUserSettingsRepository.SaveAsync`) serializes `UserSettings` to disk with `System.Text.Json` and no pre-write validation. `InMemoryTrainingRepository.RecordAsync` writes `TrainingFeedback` to a volatile in-process queue. A developer can add, remove, or rename fields on any of these types and the change will reach production without any compatibility gate detecting the regression.

Five additional payload types identified in the architecture documents (`TodoItem`/`TaskMetadata`, `TaskMasterTag`, `ClassifierTrainingExample`, migration provenance) do not yet exist in the codebase, but their schemas must be defined before the corresponding write paths are implemented so those paths can validate at the point of introduction.

This feature establishes the schema directory layout, JSON Schema documents, write-path validation, a dedicated test project, and two CI gates: a PR-blocking schema-diff check integrated into stage 6, and a nightly schema-evolution stage.

## Behavior

### Schema directory

- `/schemas/v1/` holds one JSON Schema 2020-12 file per payload type. File naming convention: `<payload-kebab-case>.schema.json`.
- Initial files to create in v1:
  - `classification-result.schema.json` — `label` (string, enum `["HighPriority","Promotional","General"]`), `confidence` (number, minimum 0.0, maximum 1.0), both required, `additionalProperties: false`.
  - `user-settings.schema.json` — `userId` (string), `notificationsEnabled` (boolean), `triageEnabled` (boolean), `lastModifiedAt` (string, format `date-time`), all required, `additionalProperties: false`.
  - `training-feedback.schema.json` — `messageId` (string), `label` (string), `confirmed` (boolean), `recordedAt` (string, format `date-time`), all required, `additionalProperties: false`.
  - `task-metadata.schema.json` — stub schema with `$comment` noting the type is not yet implemented; `type: object`, `properties: {}`. Must exist in v1 so future addition does not require a new version directory.
  - `migration-provenance.schema.json` — stub schema with `$comment` noting the type is not yet implemented; `type: object`, `properties: {}`.
- When an intentional schema change breaks backward compatibility, a new `/schemas/v2/` directory is created containing the evolved files. The v1 files are frozen.
- Non-breaking additive changes (adding an optional field) may be made in-place within the current version directory. The schema-diff check in CI classifies this as non-breaking and does not require a version bump.
- `/schemas/v1/fixtures/` holds checked-in JSON fixture files used by forward- and backward-compat tests. One valid fixture file per payload type: `classification-result.valid.json`, `user-settings.valid.json`, `training-feedback.valid.json`.

### Write-path validation

- `JsonFileUserSettingsRepository.SaveAsync` validates the `UserSettings` object against `/schemas/v1/user-settings.schema.json` using `JsonSchema.Net` before serializing to disk. If validation fails, the method throws `SchemaValidationException` with the full list of validation errors. The write is not attempted.
- `InMemoryTrainingRepository.RecordAsync` validates `TrainingFeedback` against `/schemas/v1/training-feedback.schema.json` using `JsonSchema.Net` before enqueuing. If validation fails, the method throws `SchemaValidationException`. This is infrastructure validation in anticipation of a future durable write path; it does not change the volatile storage semantics.
- `ClassificationResult` is produced by the classifier, not by a write path that persists to external storage. Schema validation for `ClassificationResult` is enforced in the test project (see below) but not inserted into a runtime write path in this feature.
- Future write paths that persist any payload in `/schemas/v1/` to disk or Graph must validate against the corresponding schema before write. This is a convention enforced by test coverage, not a runtime registry.

### Schema-diff CI gate (PR pipeline, stage 6 extension)

- A new composite action `.github/actions/schema-contract/action.yml` is added alongside the existing `.github/actions/contract/action.yml`.
- The action:
  1. Locates all `*.schema.json` files under `/schemas/` in the current commit.
  2. Extracts the corresponding baseline files from `origin/main` via `git show`.
  3. For each schema file that differs from baseline, runs a breaking-change analysis using `JsonSchema.Net`'s schema comparison API invoked from a small .NET tool (`tools/schema-diff/`).
  4. If any breaking change is detected and the schema's version directory has not been incremented (i.e., the file path still starts with the same `/schemas/vN/` prefix), the action exits with code 1 and prints a list of breaking changes.
  5. If the schema file is new (no baseline), the action passes — the first-PR pattern mirrors the existing oasdiff behavior in `action.yml`.
- Stage 6 in `pr-pipeline.yml` is extended to call `.github/actions/schema-contract/action.yml` after the existing OpenAPI contract steps.
- Breaking-change classification: field removal, required-field addition, type narrowing (e.g., `string` to `enum`), `additionalProperties` change from `true` to `false`. These are treated as breaking. Adding an optional field, widening a type, or loosening a constraint is treated as non-breaking.

### Nightly schema-evolution stage (stage 14)

- A new job `stage-14-schema-evolution` is added to `pre-merge-pipeline.yml` (or a separate nightly YAML if one exists; if not, to `pre-merge-pipeline.yml` running on schedule).
- The stage runs `dotnet test tests/TaskMaster.Schema.Tests` which exercises:
  - Forward-compat: each versioned fixture file in `/schemas/vN/fixtures/` is validated against the schema of the current (highest) version N.
  - Backward-compat: fixtures from the current version are validated against the N-1 schema.
  - Coverage spans the last three schema versions or all versions if fewer than three exist.
- The stage is blocking: a failure prevents the pre-merge pipeline from succeeding.

### Test project

- A new C# project `tests/TaskMaster.Schema.Tests` contains all schema-evolution tests.
- Tests use `JsonSchema.Net` for schema loading and validation, `FluentAssertions` for assertions, and `xunit` (aligned with the existing test stack).
- Test classes:
  - `ClassificationResultSchemaTests` — validates the schema file is well-formed; validates valid fixtures pass; validates intentionally invalid fixtures fail with specific error keywords.
  - `UserSettingsSchemaTests` — same pattern.
  - `TrainingFeedbackSchemaTests` — same pattern.
  - `SchemaCompatibilityTests` — forward- and backward-compat tests using fixtures from `/schemas/v1/fixtures/`.
- `quality-tiers.yml` must include an entry for `tests/TaskMaster.Schema.Tests` at tier T4 (test scaffolding).

## Inputs / Outputs

### Inputs

- Schema files: `/schemas/v1/*.schema.json` — JSON Schema 2020-12 documents defining each payload type.
- Fixture files: `/schemas/v1/fixtures/*.valid.json` — checked-in JSON documents used as test inputs.
- Baseline schema files from `origin/main` — extracted at CI time by the schema-contract action via `git show`.
- C# payload objects: `UserSettings`, `TrainingFeedback`, `ClassificationResult` from `TaskMaster.Application`.

### Outputs

- Validation errors: `SchemaValidationException` thrown by write-path validators; message includes the payload type name and the full `JsonSchema.Net` error list.
- CI gate result: exit code 0 (no breaking changes or version bumped) or exit code 1 (breaking changes detected without version bump), with a structured list of breaking changes written to stdout.
- Test results: xUnit XML output from `tests/TaskMaster.Schema.Tests` consumed by the CI test reporter.

### Config

- Schema directory root: `/schemas/` (repository root, not configurable at runtime; path is compile-time constant in the test project).
- Schema version: encoded in the directory name (`v1`, `v2`, …). No runtime configuration key.

## API / CLI Surface

### `SchemaValidationException` (C#)

```csharp
public sealed class SchemaValidationException : Exception
{
    public string PayloadType { get; }
    public IReadOnlyList<string> ValidationErrors { get; }

    public SchemaValidationException(
        string payloadType,
        IReadOnlyList<string> validationErrors);
}
```

Thrown by `JsonFileUserSettingsRepository.SaveAsync` and `InMemoryTrainingRepository.RecordAsync` when the payload fails schema validation. Callers are not expected to catch this in normal operation; it indicates a programmer error (wrong payload shape).

### `PayloadSchemaValidator` (C#)

```csharp
public static class PayloadSchemaValidator
{
    public static void Validate(object payload, string schemaFilePath);
}
```

Pure static helper used by write-path implementations. Loads the schema from `schemaFilePath` (absolute path resolved relative to the repository root at startup), evaluates the `System.Text.Json` serialized form of `payload` against the schema, and throws `SchemaValidationException` on failure.

This is an internal infrastructure helper, not a public API surface of `TaskMaster.Application` or `TaskMaster.Infrastructure`.

### Schema-diff tool (`tools/schema-diff/`)

Invoked by the CI action. No direct developer-facing CLI is required in this feature. The action calls `dotnet run --project tools/schema-diff -- --current <path> --baseline <path>` and interprets the exit code.

Example action invocation (internal, not developer-facing):

```
dotnet run --project tools/schema-diff -- \
  --current schemas/v1/user-settings.schema.json \
  --baseline /tmp/baseline/schemas/v1/user-settings.schema.json
```

Exit codes: 0 = no breaking changes, 1 = breaking changes detected, 2 = tool error.

## Data & State

### Schema versioning

- Schema version is encoded solely in the directory name: `/schemas/v1/`, `/schemas/v2/`, etc.
- All files within a version directory are considered a coherent schema set for that version.
- Once a version directory is merged to `main`, files within it are frozen. No in-place breaking changes are permitted.
- Non-breaking additive changes (new optional field) may be applied in-place to the highest current version directory.

### Fixture organization

```
/schemas/
  v1/
    classification-result.schema.json
    user-settings.schema.json
    training-feedback.schema.json
    task-metadata.schema.json
    migration-provenance.schema.json
    fixtures/
      classification-result.valid.json
      user-settings.valid.json
      training-feedback.valid.json
```

When v2 is introduced, a new `/schemas/v2/fixtures/` directory is created alongside the v2 schemas. The v1 fixtures remain in place and continue to be exercised by forward-compat tests.

### Baseline snapshot mechanism

The schema-contract CI action does not maintain a separate committed artifact snapshot (unlike `artifacts/openapi/current.json`). It extracts the baseline directly from `origin/main` via `git show`. This is consistent with the existing oasdiff integration and requires no additional commit step on schema update.

When a version bump is intentional, the developer creates `/schemas/v2/` and the action sees new file paths with no baseline match — it passes per the first-PR pattern.

### Migration provenance

No runtime migration-provenance type exists. The `/schemas/v1/migration-provenance.schema.json` stub reserves the schema slot. The stub schema must be replaced with a concrete schema before any migration-provenance payload is written to storage.

## Constraints & Risks

### C1 — `JsonSchema.Net` NuGet must be approved before use

`JsonSchema.Net` (gregsdennis, MIT license, targets `System.Text.Json` natively) is not present in `Directory.Packages.props`. It must be added to `Directory.Packages.props` with an explicit version pin before any C# code referencing it is merged. This is a prerequisite; no write-path validation or schema test code compiles without it.

Justification for selection over alternatives: `NJsonSchema` targets Newtonsoft by default, which conflicts with the repository's exclusive use of `System.Text.Json`. Rolling a custom structural validator is insufficient for the forward/backward compat comparison logic required by the test suite.

### C2 — No schema-diff npm package is present

`json-schema-diff-validator` and `ajv` are both absent from `package.json`. Rather than introduce a new npm dependency, the schema-diff analysis is implemented as a small .NET tool (`tools/schema-diff/`) using `JsonSchema.Net`'s comparison API. This keeps the toolchain uniform and avoids a Node.js dependency for a server-side concern.

### C3 — Five payload types are absent from the codebase

`TaskMetadata`, `TaskMasterTag`, `ClassifierTrainingExample`, `FilingDestination`, and `AuditEvent` are not implemented. Stub schemas for `task-metadata` and `migration-provenance` are checked in as placeholders. Stub schemas for the remaining three types are deferred until the types are implemented. The CI gate skips validation for stub schemas (those with empty `properties` and a `$comment` indicating deferral) to avoid false failures.

### C4 — `TrainingFeedback` write path is volatile

`InMemoryTrainingRepository.RecordAsync` writes to a `ConcurrentQueue` that does not survive process restart. Schema validation is applied to this path now as infrastructure preparation for a future durable adapter. The validation does not change the storage semantics. If `TrainingFeedback` schemas evolve before the durable adapter is built, the compat tests still run against the in-memory path.

### C5 — `quality-tiers.yml` entry is mandatory

Adding `tests/TaskMaster.Schema.Tests` without a corresponding `quality-tiers.yml` entry fails the `tier-classification` CI stage. The entry must be present in the same PR that introduces the test project.

### C6 — Graph write path does not yet exist

No Graph open extension adapter is implemented. Schemas for `ClassificationResult` and future Graph-persisted types are defined now so that the write path can validate against them when implemented. No runtime validation is wired to a Graph write path in this feature.

## Implementation Strategy

### New files to create

| Path | Description |
|---|---|
| `/schemas/v1/classification-result.schema.json` | JSON Schema 2020-12 for `ClassificationResult` |
| `/schemas/v1/user-settings.schema.json` | JSON Schema 2020-12 for `UserSettings` |
| `/schemas/v1/training-feedback.schema.json` | JSON Schema 2020-12 for `TrainingFeedback` |
| `/schemas/v1/task-metadata.schema.json` | Stub schema for `TaskMetadata` (not yet implemented) |
| `/schemas/v1/migration-provenance.schema.json` | Stub schema for migration provenance (not yet implemented) |
| `/schemas/v1/fixtures/classification-result.valid.json` | Valid `ClassificationResult` fixture |
| `/schemas/v1/fixtures/user-settings.valid.json` | Valid `UserSettings` fixture |
| `/schemas/v1/fixtures/training-feedback.valid.json` | Valid `TrainingFeedback` fixture |
| `src/TaskMaster.Infrastructure/SchemaValidationException.cs` | Exception type for write-path validation failures |
| `src/TaskMaster.Infrastructure/PayloadSchemaValidator.cs` | Static helper; loads schema and validates payload |
| `tests/TaskMaster.Schema.Tests/TaskMaster.Schema.Tests.csproj` | New xUnit test project |
| `tests/TaskMaster.Schema.Tests/ClassificationResultSchemaTests.cs` | Schema well-formedness and fixture tests |
| `tests/TaskMaster.Schema.Tests/UserSettingsSchemaTests.cs` | Schema well-formedness and fixture tests |
| `tests/TaskMaster.Schema.Tests/TrainingFeedbackSchemaTests.cs` | Schema well-formedness and fixture tests |
| `tests/TaskMaster.Schema.Tests/SchemaCompatibilityTests.cs` | Forward- and backward-compat tests |
| `tools/schema-diff/schema-diff.csproj` | .NET tool for schema breaking-change analysis |
| `tools/schema-diff/Program.cs` | Entry point; CLI args `--current`, `--baseline`; exit codes 0/1/2 |
| `.github/actions/schema-contract/action.yml` | Composite action wrapping the schema-diff tool |

### Files to modify

| Path | Change |
|---|---|
| `src/TaskMaster.Infrastructure/JsonFileUserSettingsRepository.cs` | Add `PayloadSchemaValidator.Validate` call in `SaveAsync` before serialization |
| `src/TaskMaster.Infrastructure/InMemoryTrainingRepository.cs` | Add `PayloadSchemaValidator.Validate` call in `RecordAsync` before enqueue |
| `.github/workflows/pr-pipeline.yml` | Extend stage 6 to invoke `.github/actions/schema-contract/action.yml` |
| `pre-merge-pipeline.yml` (or nightly workflow) | Add `stage-14-schema-evolution` job running `dotnet test tests/TaskMaster.Schema.Tests` |
| `Directory.Packages.props` | Add `JsonSchema.Net` with explicit version pin |
| `quality-tiers.yml` | Add `tests/TaskMaster.Schema.Tests: T4` |
| `TaskMaster.sln` (or equivalent project list) | Add `tests/TaskMaster.Schema.Tests` and `tools/schema-diff` |

### No breaking changes to existing APIs

`JsonFileUserSettingsRepository.SaveAsync` and `InMemoryTrainingRepository.RecordAsync` retain their existing signatures. The validation call is added internally. Callers that pass valid payloads are unaffected. Callers that pass invalid payloads now receive `SchemaValidationException` instead of silently persisting corrupt data — this is the intended behavior change.

### Dependency addition

`JsonSchema.Net` (gregsdennis) — required for schema loading, validation, and the breaking-change analysis in the schema-diff tool. No other new NuGet or npm packages are introduced.

## Definition of Done

Each acceptance criterion from `issue.md` is mapped below to its verification artifact.

| Acceptance Criterion | Verification |
|---|---|
| `/schemas/v1/` contains JSON Schema files for classification result, task metadata, tag set, training-state reference, migration provenance | File existence check in `SchemaCompatibilityTests.SchemaFilesExist` |
| Backend write paths reject payloads that fail schema validation | `UserSettingsSchemaTests.SaveAsync_ThrowsSchemaValidationException_WhenPayloadInvalid` and `TrainingFeedbackSchemaTests.RecordAsync_ThrowsSchemaValidationException_WhenPayloadInvalid` |
| Forward-compat tests: v1 fixtures are readable by v1 code | `SchemaCompatibilityTests.V1Fixture_PassesV1Schema` for each payload type |
| Backward-compat tests: payloads written by current code pass the N-1 schema | `SchemaCompatibilityTests.CurrentFixture_PassesPreviousVersionSchema` — skipped (vacuous pass) when only one version exists |
| PR pipeline stage 6 blocks merge on a breaking schema change without a version bump | `.github/actions/schema-contract/action.yml` integration; verified by a negative test in `tools/schema-diff` unit tests |
| Nightly pipeline stage 14 runs schema-evolution tests against the last three schema versions | `stage-14-schema-evolution` job in the pipeline YAML; confirmed by `SchemaCompatibilityTests` covering all present versions |
| An incompatible schema change without a version bump is detected and blocks the build | `tools/schema-diff` unit test `SchemaBreakingChangeDetected_WhenRequiredFieldRemoved` |
| A version bump combined with the appropriate compat fixture passes | `tools/schema-diff` unit test `SchemaNewVersionDirectory_PassesWithNoBaseline` |

## Seeded Test Conditions

- [x] Valid payload passes schema validation
- [x] Invalid payload (missing required field) is rejected
- [x] Prior-version fixture is accepted by current reader (forward compat)
- [x] Current-version payload passes N-1 schema (backward compat)
- [x] Breaking schema change without version bump fails CI
- [x] Non-breaking schema change passes CI without version bump requirement
- [x] Version bump with compat fixture passes CI
