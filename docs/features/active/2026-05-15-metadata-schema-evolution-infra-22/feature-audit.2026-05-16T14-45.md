# Feature Audit — Issue #22: metadata-schema-evolution-infra (Re-audit)

- **Timestamp:** 2026-05-16T14-45
- **Branch:** claude/youthful-banzai-a1dff3
- **Base:** origin/main @ 0134bbfcd9a89f9439bb7d8645515d74ecc5b403
- **Auditor:** Feature Review Agent
- **Work Mode:** full-feature
- **AC Sources:** `spec.md` and `user-story.md`
- **Prior audit:** feature-audit.2026-05-16T01-40.md

---

## Summary

| Acceptance Criterion | Prior Verdict | Re-audit Verdict |
|---|---|---|
| AC1: `/schemas/v1/` contains JSON Schema files for: classification result, task metadata, tag set, training-state reference, migration provenance | PARTIAL | PASS |
| AC2: Backend write paths reject payloads that fail schema validation (test coverage required) | PASS | PASS |
| AC3: Forward-compat tests: v1 fixtures are readable by v1 code (baseline); on introduction of v2, v1 fixtures are readable by v2 code | PASS | PASS |
| AC4: Backward-compat tests: payloads written by current code pass the N-1 schema | PASS (vacuous) | PASS (vacuous) |
| AC5: PR pipeline stage 6 blocks merge on a breaking schema change without a version bump | PARTIAL | PASS |
| AC6: Nightly pipeline stage 14 runs schema-evolution tests against the last three schema versions | PASS | PASS |
| AC7: An incompatible schema change without a version bump is detected and blocks the build (validation scenario) | PARTIAL | PASS |
| AC8: A version bump combined with the appropriate compat fixture passes (validation scenario) | PASS | PASS |

**Overall Feature Verdict: PASS** — All eight acceptance criteria are satisfied. The three previously partial/failing criteria (AC1, AC5, AC7) have been remediated.

---

## Assumptions

1. "Tag set" in AC1 refers to `TaskMasterTag`. Spec constraint C3 confirms stub schemas for `task-metadata` and `migration-provenance` are explicitly planned; the spec defers stubs for `TaskMasterTag`, `ClassifierTrainingExample`, and `FilingDestination`. The AC text lists "tag set" explicitly, and the remediation provides a stub for it.
2. "Training-state reference" in AC1 is interpreted as `training-feedback` / `TrainingFeedback` — the only training-related schema in v1. This interpretation is consistent with the prior review.
3. The backward-compat vacuous pass is accepted per the spec's own definition: "skipped (vacuous pass) when only one version exists."
4. "Type narrowing detected" in AC5/AC7 includes the `enum`-constraint case specified in the spec; it does not require detection of every possible JSON Schema narrowing. The remediation addresses the specific case called out in the spec.

---

## Criterion-by-Criterion Evaluation

### AC1: `/schemas/v1/` contains JSON Schema files for: classification result, task metadata, tag set, training-state reference, migration provenance

**Verdict: PASS**

**Evidence (updated):**

The following files are present in the branch diff under `schemas/v1/`:

| File | Type | Present | Status |
|---|---|---|---|
| `classification-result.schema.json` | Full schema | Yes (initial commit) | PASS |
| `task-metadata.schema.json` | Stub schema | Yes (initial commit) | PASS |
| `task-master-tag.schema.json` | Stub schema | Yes (remediation commit) | PASS |
| `training-feedback.schema.json` | Full schema | Yes (initial commit) | PASS |
| `migration-provenance.schema.json` | Stub schema | Yes (initial commit) | PASS |
| `user-settings.schema.json` | Full schema | Yes (initial commit) | PASS (not listed in AC but present) |

`task-master-tag.schema.json` content confirms the stub pattern:
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "$comment": "Stub schema — TaskMasterTag is not yet implemented. Replace with concrete schema before any TaskMasterTag payload is written to storage.",
  "properties": {}
}
```

The `SchemaCompatibilityTests.SchemaFilesExist_ForAllV1Types` test enumerates all six schema paths (including `task-master-tag.schema.json`) and passes per `rem-schema-files-exist.md` (EXIT_CODE 0).

**AC check-off:** This item is verified PASS. Already marked `[x]` in `user-story.md`.

---

### AC2: Backend write paths reject payloads that fail schema validation (test coverage required)

**Verdict: PASS**

**Evidence (unchanged from prior audit; confirmation via new tests):**

- `JsonFileUserSettingsRepository.SaveAsync` calls `PayloadSchemaValidator.Validate` before serialization. If validation fails, `SchemaValidationException` is thrown and no disk write is attempted.
- `InMemoryTrainingRepository.RecordAsync` calls `PayloadSchemaValidator.Validate` before enqueuing.
- `UserSettingsSchemaTests.Validate_ThrowsSchemaValidationException_WhenRequiredFieldMissing` exercises the user-settings write path.
- `TrainingFeedbackSchemaTests.Validate_ThrowsSchemaValidationException_WhenPayloadMissingMessageId` exercises the training-feedback write path.
- New: `SchemaValidationPropagationTests.SaveAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException` — confirms `PayloadType` and `ValidationErrors` are populated, directly exercising `CollectErrors`.
- New: `SchemaValidationPropagationTests.RecordAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException` — same for training path.
- All tests pass per `rem-dotnet-test-coverage.md` (EXIT_CODE 0, 94 total tests).

**AC check-off:** Already marked `[x]` in `user-story.md`. Confirmed PASS.

---

### AC3: Forward-compat tests: v1 fixtures are readable by v1 code (baseline); on introduction of v2, v1 fixtures are readable by v2 code

**Verdict: PASS**

**Evidence (unchanged from prior audit):**

- `SchemaCompatibilityTests.V1Fixture_PassesV1Schema` is a `[Theory]` with `[InlineData]` for `classification-result`, `user-settings`, and `training-feedback`. Each loads the v1 schema and v1 fixture and asserts `result.IsValid == true`.
- All three cases pass per `schema-tests-initial-run.md` and `rem-dotnet-test-coverage.md`.
- The "on introduction of v2" half is satisfied by infrastructure: fixture files are in `schemas/v1/fixtures/`, and the test design supports v2 fixture files alongside v2 schema files without code changes.

**AC check-off:** Already marked `[x]` in `user-story.md`. Confirmed PASS.

---

### AC4: Backward-compat tests: payloads written by current code pass the N-1 schema

**Verdict: PASS (vacuous)**

**Evidence (unchanged from prior audit):**

- `SchemaCompatibilityTests.BackwardCompatibility_SingleVersion_VacuousPass` explicitly documents that backward-compat testing is a harness placeholder while only v1 exists.
- The spec's Definition of Done states: "skipped (vacuous pass) when only one version exists."
- This matches the current state.

**AC check-off:** Already marked `[x]` in `user-story.md`. Confirmed PASS (vacuous).

---

### AC5: PR pipeline stage 6 blocks merge on a breaking schema change without a version bump

**Verdict: PASS**

**Evidence (updated):**

The prior verdict was PARTIAL because the `schema-diff` tool did not detect type-narrowing (enum-constraint addition).

After remediation:

- `SchemaDiffAnalyzer.DetectBreakingChanges` now checks the `enum` keyword for all shared properties. When a property had no `enum` in the baseline and has one in the current schema, a breaking change is reported.
- `SchemaDiffBreakingChangeTests.DetectBreakingChanges_EnumConstraintAdded_ReturnsBreaking` directly confirms the detection works. Test passes per `rem-schema-diff-tests.md` (EXIT_CODE 0).
- The CI action (`.github/actions/schema-contract/action.yml`) invokes `dotnet run --project tools/schema-diff -- --current <path> --baseline <path>` and exits 1 when the tool returns exit code 1. This propagation is unchanged from the initial commit.
- The action is wired into stage 6 of `pr-pipeline.yml`.

**Spec-listed breaking change types verified:**
- Field removal from `required` array: detected (unchanged from initial commit; `DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking` PASS).
- New required field addition: detected (unchanged; logic in `currentRequired.Where(f => !baselineRequired.Contains(f) && !baselineProperties.Contains(f))`).
- Type narrowing (string to enum): detected (remediated; `DetectBreakingChanges_EnumConstraintAdded_ReturnsBreaking` PASS).
- `additionalProperties` change from `true` to `false`: detected (unchanged from initial commit).

**AC check-off:** This item was previously unchecked. Independent verification confirms PASS. Checking off in `user-story.md`.

---

### AC6: Nightly pipeline stage 14 runs schema-evolution tests against the last three schema versions

**Verdict: PASS**

**Evidence (unchanged from prior audit):**

- `stage-14-schema-evolution` job is present in `.github/workflows/pre-merge-pipeline.yml`. The job runs on `windows-latest`, depends on `stage-10-e2e`, and executes `dotnet test tests/TaskMaster.Schema.Tests/TaskMaster.Schema.Tests.csproj`.
- The `SchemaCompatibilityTests` class iterates all fixture/schema combinations in the repository. With only v1 present, all versions are covered. When v2 and v3 are added, the parametric test design accommodates them without code changes.

**AC check-off:** Already marked `[x]` in `user-story.md`. Confirmed PASS.

---

### AC7: An incompatible schema change without a version bump is detected and blocks the build (validation scenario)

**Verdict: PASS**

**Evidence (updated):**

The prior verdict was PARTIAL because the type-narrowing case was not detected.

After remediation:

- `SchemaDiffBreakingChangeTests.DetectBreakingChanges_EnumConstraintAdded_ReturnsBreaking` establishes that adding an `enum` constraint to a previously unconstrained property is detected as a breaking change. This is the exact type-narrowing scenario listed in the spec.
- `SchemaDiffBreakingChangeTests.DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking` confirms the field-removal case.
- The spec's Definition of Done maps this criterion to "tools/schema-diff unit test `SchemaBreakingChangeDetected_WhenRequiredFieldRemoved`." The test `DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking` provides equivalent coverage; the function name is descriptive and the scenario matches.
- The smoke test `schema-diff-smoke-breaking-detected.md` (EXIT_CODE 1 for a breaking change) also provides functional evidence.

**Assumption:** The spec's Definition of Done names `SchemaBreakingChangeDetected_WhenRequiredFieldRemoved` specifically. The test exists under the name `DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking`. The naming convention differs but the scenario is identical. This is accepted as satisfying the spec-specified verification path.

**AC check-off:** This item was previously unchecked. Independent verification confirms PASS. Checking off in `user-story.md`.

---

### AC8: A version bump combined with the appropriate compat fixture passes (validation scenario)

**Verdict: PASS**

**Evidence (unchanged from prior audit):**

- The schema-contract action exits 0 for a schema file with no baseline in `origin/main` (first-PR pattern: `if [ -z "$baseline_content" ]; then echo "No baseline... skipping."; continue; fi`).
- `schema-diff-smoke-no-change.md` (EXIT_CODE 0) confirms the no-change path works.
- A new `schemas/v2/` directory would contain files with no baseline match, all of which are skipped — functionally equivalent to a version-bump pass.

**AC check-off:** Already marked `[x]` in `user-story.md`. Confirmed PASS.

---

## Spec Deviations — Updated Assessment

| Deviation | Spec Reference | Status |
|---|---|---|
| `task-master-tag.schema.json` (tag set) was absent | spec.md §Schema directory, AC1 | RESOLVED — stub schema added in remediation commit. |
| Type-narrowing detection absent from `schema-diff` tool | spec.md §Schema-diff CI gate | RESOLVED — `SchemaDiffAnalyzer` now detects enum-constraint addition; unit test covers this case. |
| Test name `SchemaBreakingChangeDetected_WhenRequiredFieldRemoved` vs. `DetectBreakingChanges_RequiredFieldRemoved_ReturnsBreaking` | spec.md §Definition of Done table | MINOR — name differs from spec-specified name, but scenario and coverage are equivalent. Acceptable. |
| `SchemaNewVersionDirectory_PassesWithNoBaseline` unit test absent | spec.md §Definition of Done table | STILL OPEN — the action's first-PR logic provides equivalent evidence; no dedicated unit test exists. Acceptable (functional verification present). |
| Vacuous backward-compat test (`BackwardCompatibility_SingleVersion_VacuousPass`) | CR-11 from code review | STILL OPEN (by design; placeholder for v2). |

---

## Acceptance Criteria Status

- **Source files:** `spec.md` and `user-story.md` (full-feature mode)
- **Total AC items:** 8
- **Checked off (delivered and verified):** 8
- **Remaining (unchecked):** 0

**All AC items are satisfied.**

---

## Newly Checked Off Items (this review)

The following AC items were verified as PASS in this re-audit and are checked off in `user-story.md`:

- `- [x] PR pipeline stage 6 blocks merge on a breaking schema change without a version bump.` (was unchecked; type-narrowing detection gap resolved by REM-02)
- `- [x] An incompatible schema change without a version bump is detected and blocks the build (validation scenario).` (was unchecked; same resolution)

The AC for `/schemas/v1/` containing a tag set schema (`task-master-tag.schema.json`) was already marked `[x]` in `user-story.md` by the executor; this re-audit confirms the file is present and the test passes.
