# Remediation Inputs — Issue #22: metadata-schema-evolution-infra

- **Timestamp:** 2026-05-16T01-40
- **Branch:** claude/youthful-banzai-a1dff3
- **Produced by:** Feature Review Agent

---

## Artifacts

- policy-audit: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/policy-audit.2026-05-16T01-40.md`
- code-review: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/code-review.2026-05-16T01-40.md`
- feature-audit: `docs/features/active/2026-05-15-metadata-schema-evolution-infra-22/feature-audit.2026-05-16T01-40.md`

---

## Required Remediations (blocking merge)

### REM-01: Add tag-set stub schema

**Source:** Feature audit, AC1 (PARTIAL)
**File to create:** `schemas/v1/task-master-tag.schema.json`
**Required content:** Stub schema following the same pattern as `task-metadata.schema.json` and `migration-provenance.schema.json`:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "$comment": "Stub schema — TaskMasterTag is not yet implemented. Replace with concrete schema before any TaskMasterTag payload is written to storage.",
  "properties": {}
}
```
**Also update:** `SchemaCompatibilityTests.SchemaFilesExist_ForAllV1Types` to include `"schemas/v1/task-master-tag.schema.json"` in `expectedSchemas`.

---

### REM-02: Implement type-narrowing detection in `schema-diff` tool

**Source:** Feature audit, AC5 (PARTIAL), AC7 (PARTIAL); code review CR-07 (High)
**File to modify:** `tools/schema-diff/Program.cs`
**Required change:** Extend `DetectBreakingChanges` to detect when a property's `enum` keyword is added (string constrained to a specific set of values) or when the `type` keyword is narrowed (e.g., `["string", "null"]` to `"string"`). At minimum, implement enum-addition detection per the spec's explicit example.

Suggested approach — add a check inside `DetectBreakingChanges`:
```csharp
// For each property in both baseline and current, compare enum constraints.
foreach (var prop in baselineProperties.Intersect(currentProperties))
{
    var baselineEnum = GetPropertyEnum(baseline, prop);
    var currentEnum = GetPropertyEnum(current, prop);
    if (baselineEnum is null && currentEnum is not null)
    {
        changes.Add($"Property '{prop}' type narrowed: enum constraint added.");
    }
}
```
**Also required:** Add unit tests for `DetectBreakingChanges` covering the type-narrowing case, to prevent future regressions.

---

### REM-03: Remediate C# branch coverage regression in TaskMaster.Infrastructure.Tests

**Source:** Policy audit, F1 (FAIL — regression)
**Context:** Branch coverage in `TaskMaster.Infrastructure.Tests` regressed from 54.54% (baseline) to 36.11% (post-feature). This is a direct regression on a project whose production files (`InMemoryTrainingRepository.cs`, `JsonFileUserSettingsRepository.cs`) were modified in this branch.
**Required action:** Add tests to `tests/TaskMaster.Infrastructure.Tests/` that exercise the new validation branch (the `SaveAsync`/`RecordAsync` path when `PayloadSchemaValidator.Validate` throws `SchemaValidationException`) and any other uncovered branches introduced by this feature.

---

## Recommended Remediations (non-blocking, should be addressed before shipping)

### REM-04: Add coverage for new production files

**Source:** Policy audit, F4; code review CR-09
**Files affected:** `PayloadSchemaValidator.cs`, `SchemaValidationException.cs`, `tools/schema-diff/Program.cs`
**Required action:** Add tests covering the untested constructors of `SchemaValidationException` and the `CollectErrors` fallback path in `PayloadSchemaValidator`. Add unit tests for `schema-diff`'s `DetectBreakingChanges` internal logic.

---

### REM-05: Resolve synchronous file I/O in async write paths

**Source:** Code review CR-01 (Medium)
**File affected:** `src/TaskMaster.Infrastructure/Validation/PayloadSchemaValidator.cs`
**Recommended action:** Either (a) add a `ValidateAsync` overload using `File.ReadAllTextAsync`, or (b) cache parsed schemas in a `ConcurrentDictionary<string, JsonSchema>` to eliminate per-call disk reads.

---

### REM-06: Add existence assertion for schema paths

**Source:** Code review CR-06, CR-10 (Medium)
**Files affected:** `InMemoryTrainingRepository.cs`, `JsonFileUserSettingsRepository.cs`, all `TaskMaster.Schema.Tests` test classes
**Recommended action:** Before passing a schema path to `PayloadSchemaValidator.Validate`, assert that the file exists and throw a descriptive error if not (e.g., `throw new InvalidOperationException($"Schema file not found: {path}")`). Same guard in test helper `SchemaPath` methods.

---

### REM-07: Remove unused imports from `UserSettingsSchemaTests.cs`

**Source:** Code review CR-12 (Low)
**File affected:** `tests/TaskMaster.Schema.Tests/UserSettingsSchemaTests.cs`
**Required action:** Remove `using Microsoft.Extensions.Options;` and `using NSubstitute;` — neither is used in the file. Confirm no analyzer suppression is masking an IDE warning for these.
