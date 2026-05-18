# Code Review — Issue #22: metadata-schema-evolution-infra (Re-audit)

- **Timestamp:** 2026-05-16T14-45
- **Branch:** claude/youthful-banzai-a1dff3
- **Base:** origin/main @ 0134bbfcd9a89f9439bb7d8645515d74ecc5b403
- **Reviewer:** Feature Review Agent
- **Prior review:** code-review.2026-05-16T01-40.md

---

## Scope

This re-audit covers the full branch diff (70 files changed, 2929 insertions). The remediation commit (a24fb399) added the following files relevant to code quality assessment:

- `tools/schema-diff/SchemaDiffAnalyzer.cs` (new — 114 lines)
- `tools/schema-diff/Program.cs` (modified — refactored from 165 to 101 lines)
- `tests/TaskMaster.Schema.Tests/SchemaDiffBreakingChangeTests.cs` (new — 144 lines)
- `tests/TaskMaster.Schema.Tests/SchemaValidationExceptionTests.cs` (new — 60 lines)
- `tests/TaskMaster.Schema.Tests/SchemaCompatibilityTests.cs` (modified — `task-master-tag.schema.json` added to expected schemas)
- `tests/TaskMaster.Schema.Tests/UserSettingsSchemaTests.cs` (modified)
- `tests/TaskMaster.Infrastructure.Tests/SchemaValidationPropagationTests.cs` (new — 77 lines)
- `schemas/v1/task-master-tag.schema.json` (new — stub schema)

---

## Overall Assessment

The remediation commit addresses all three blocking findings from the first review. The refactoring of `Program.cs` into `SchemaDiffAnalyzer.cs` is well-executed: the extraction is clean, the `InternalsVisibleTo` assembly attribute is correctly placed, and the new unit tests directly exercise the extracted logic. The `SchemaValidationExceptionTests` class covers all four constructors. The `SchemaValidationPropagationTests` class confirms the `CollectErrors` branch is exercised in `PayloadSchemaValidator`.

The medium-severity concerns from the first review (CR-01, CR-06, CR-10) remain open — they were not in scope for the three remediation targets. They are retained below for tracking. No new code-quality issues are introduced by the remediation files.

---

## Remediation Files — Detailed Review

### `tools/schema-diff/SchemaDiffAnalyzer.cs` (new)

**Strengths:**

- Clean extraction from `Program.cs`. All diff logic is in one testable class; `Program.cs` retains only CLI wiring.
- `[assembly: InternalsVisibleTo("TaskMaster.Schema.Tests")]` is placed at the assembly level in this file — correct. The test project can call internal members directly.
- `IsStubSchema` uses `Contains("Stub schema", StringComparison.OrdinalIgnoreCase)` — consistent with the original logic and immune to case variations.
- The enum-narrowing check iterates only shared properties (`baselineProperties.Intersect(currentProperties)`) — correct. A property added only in `current` is not a narrowing.
- `GetPropertyEnum` extracts the `EnumKeyword` via `GetKeyword<EnumKeyword>()` — type-safe and consistent with the `Json.Schema` library API.
- `GetRequired` and `GetProperties` return empty `HashSet<string>` when the keyword is absent — defensive, avoids null reference in the intersection loop.
- `DetectBreakingChanges` produces human-readable change descriptions that name the affected property — supports actionable CI output.
- XML documentation on all public/internal members is present and accurate.

**Remaining concerns (none new):**

The check for `additionalProperties` and the required-field removal logic were already in the prior review and passed. No concerns specific to this file.

---

### `tools/schema-diff/Program.cs` (modified)

**Strengths:**

- Reduced from 165 to 101 lines after extracting `SchemaDiffAnalyzer`. All diff logic is delegated to `SchemaDiffAnalyzer.DetectBreakingChanges` and `SchemaDiffAnalyzer.IsStubSchema`.
- The stub-check logic (`IsStubSchema(baseline!) || IsStubSchema(current!)`) correctly exits 0 for stub schemas before any comparison — consistent with the first-review design.
- Error handling (`TryLoadSchema` with `IOException` / `JsonException` separation) is unchanged and remains correct.
- `#pragma warning disable CA1303` scoping is unchanged; minimal and justified.

**Retained concerns (not in scope for this remediation):**

- **CR-08 (Low):** `TryParseArgs` index loop with a trailing `--current` (no value) returns `null` silently. Acceptable for a dev-internal tool; no change in this remediation.

---

### `tests/TaskMaster.Schema.Tests/SchemaDiffBreakingChangeTests.cs` (new)

**Strengths:**

- Four `[Fact]` tests covering the four primary branches of `DetectBreakingChanges`: identical schemas (empty), required-field removed, enum constraint added, stub schema.
- `DetectBreakingChanges_EnumConstraintAdded_ReturnsBreaking` directly exercises the new enum-narrowing check: baseline has `"type": "string"`, current adds `"enum": ["a", "b"]`. The assertion checks `result[0].Should().Contain("type narrowed", ...)` and `result[0].Should().Contain("status", ...)` — both match the message format in `SchemaDiffAnalyzer`.
- `DetectBreakingChanges_StubSchema_ReturnsEmptyAndExitZero` verifies `IsStubSchema` returns true for a `$comment: "Stub schema — not yet implemented."` schema, and that two stub schemas produce no breaking changes. This is the correct behavior for stub schemas in CI.
- All tests follow Arrange–Act–Assert structure with descriptive failure messages in FluentAssertions `.Should().BeX(reason)` calls.
- The `_ = normalJson;` discard pattern for the unused variable in the stub test is acceptable (the variable is defined to document intent but not passed to `DetectBreakingChanges`).

**Observations (no issues):**

- The test class is `sealed` — correct per the project's convention (no subclassing expected).
- Imports are minimal: only `FluentAssertions`, `Json.Schema`, and `SchemaDiff`. No unused imports.

---

### `tests/TaskMaster.Schema.Tests/SchemaValidationExceptionTests.cs` (new)

**Strengths:**

- Covers all four constructors of `SchemaValidationException`: parameterless, `(string message)`, `(string message, Exception inner)`, and the domain `(string payloadType, IEnumerable<string> validationErrors)`.
- `Constructor_Default_CreatesInstanceWithEmptyPayloadTypeAndErrors` verifies that `PayloadType == string.Empty` and `ValidationErrors` is empty — matches the `SchemaValidationException` implementation which defaults both to safe values.
- `Constructor_MessageAndInner_SetsMessageAndInnerException` verifies the inner exception reference — correct.
- `Constructor_PayloadTypeAndErrors_SetsPropertiesAndMessage` checks `PayloadType`, `ValidationErrors.Count`, and that `Message` contains the payload type name — all three observable properties of the domain constructor.
- FluentAssertions used consistently.

**Prior CR-04 assessment:** The prior review flagged these constructors as untested and the type as `public` when `internal` would suffice. The constructors are now tested; the `public` visibility concern remains a low-severity observation (see retained concerns below).

---

### `tests/TaskMaster.Schema.Tests/SchemaCompatibilityTests.cs` (modified)

The only change is adding `"schemas/v1/task-master-tag.schema.json"` to the `expectedSchemas` array in `SchemaFilesExist_ForAllV1Types`. The array now contains six paths. The test passes per `rem-schema-files-exist.md` (EXIT_CODE 0). No other changes to this file.

---

### `tests/TaskMaster.Infrastructure.Tests/SchemaValidationPropagationTests.cs` (new)

**Strengths:**

- Two `[Fact]` tests, one per write-path (`SaveAsync` via `PayloadSchemaValidator.Validate` with the user-settings schema, `RecordAsync` via `PayloadSchemaValidator.Validate` with the training-feedback schema).
- Each test uses an anonymous object missing a required property, calls `PayloadSchemaValidator.Validate` directly, and asserts both `PayloadType` (non-empty) and `ValidationErrors` (non-empty). This directly exercises the `CollectErrors` code branch in `PayloadSchemaValidator`.
- The `SchemaPath` helper matches the pattern in `TaskMaster.Schema.Tests` — consistent.
- FluentAssertions `.Should().Throw<SchemaValidationException>().Which` pattern is used for exception inspection — correct and idiomatic.

**Retained concerns (CR-06, CR-10 — path traversal fragility):** The five-level `".."` traversal from `AppContext.BaseDirectory` is unchanged. The pattern works in the standard `dotnet test` layout. The concern is retained from the prior review; it is not a regression.

---

### `schemas/v1/task-master-tag.schema.json` (new)

Content:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "$comment": "Stub schema — TaskMasterTag is not yet implemented. Replace with concrete schema before any TaskMasterTag payload is written to storage.",
  "properties": {}
}
```

Consistent with the stub schema pattern used by `task-metadata.schema.json` and `migration-provenance.schema.json`. The `$comment` value contains "Stub schema" which is correctly matched by `SchemaDiffAnalyzer.IsStubSchema`. No `additionalProperties` is specified (the stub has empty properties; adding `additionalProperties: false` would break the stub pattern as it would flag any payload with extra properties). The omission is intentional.

---

## Prior-Review Issues — Status Update

| ID | File | Severity | Prior status | Re-audit status |
|---|---|---|---|---|
| CR-07 | `tools/schema-diff/` | High | FAIL — type-narrowing not detected | **RESOLVED** — `SchemaDiffAnalyzer.DetectBreakingChanges` now detects enum-constraint addition; unit test covers this case. |
| CR-01 | `PayloadSchemaValidator.cs` | Medium | Open | **STILL OPEN** — synchronous `File.ReadAllText` in async write path, schema re-parsed on every call. Not addressed in remediation scope. |
| CR-06 | `InMemoryTrainingRepository.cs`, `JsonFileUserSettingsRepository.cs` | Medium | Open | **STILL OPEN** — five-level `AppContext.BaseDirectory` traversal, no existence assertion before use. Not addressed in remediation scope. |
| CR-10 | All `TaskMaster.Schema.Tests` test classes | Medium | Open | **STILL OPEN** — same fragile path traversal as CR-06. Consistent with infrastructure code; not addressed. |
| CR-04 | `SchemaValidationException.cs` | Low | Open | **PARTIALLY RESOLVED** — all four constructors now have tests. The `public` vs. `internal` observation remains; the type is callable by test projects, which is an intended use. |
| CR-11 | `SchemaCompatibilityTests.cs` | Low | Open | **STILL OPEN** — `BackwardCompatibility_SingleVersion_VacuousPass` remains a no-op test. Acceptable as a placeholder. |
| CR-12 | `UserSettingsSchemaTests.cs` | Low | Open | **STILL OPEN** — unused `Microsoft.Extensions.Options` and `NSubstitute` imports. Not addressed. |
| CR-13 | `action.yml` | Low | Open | **STILL OPEN** — no `trap` for temp file cleanup on interruption. Not addressed. |
| CR-14 | `action.yml` | Low | Open | **STILL OPEN** — zero-schema edge case is implicit. Not addressed. |
| CR-15 | `pre-merge-pipeline.yml` | Low | Open | **STILL OPEN** — `windows-latest` with `Path.Combine` slash normalization. Functionally safe. |

---

## Design Assessment (Updated)

The refactoring of `SchemaDiffAnalyzer` out of `Program.cs` improves testability without over-engineering the design. The class is `internal static` (no public surface, no state), which is appropriate for a tool-internal helper. The `InternalsVisibleTo` approach is the standard .NET pattern for enabling unit tests of internal members without changing access modifiers.

The `SchemaValidationExceptionTests` class adequately covers `SchemaValidationException`'s constructors, resolving the untested API surface concern.

The `SchemaValidationPropagationTests` class provides direct evidence that the `CollectErrors` branch in `PayloadSchemaValidator` is reached in a real validation failure scenario — this was the key coverage gap for the `Infrastructure.Tests` project.

**No new design concerns are introduced by the remediation commit.**
