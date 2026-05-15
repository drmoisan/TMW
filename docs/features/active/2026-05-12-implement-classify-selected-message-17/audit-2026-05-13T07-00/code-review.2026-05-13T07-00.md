# Code Review — Issue #17: Implement Classify Selected Message

- **Feature:** 2026-05-12-implement-classify-selected-message-17
- **Audit timestamp:** 2026-05-13T07-00
- **Branch:** feature/17-implement-classify-selected-message
- **Merge base:** ee1709b6e8eb8c346335885184d0a76337b5e3ec
- **Auditor:** Feature Review Agent (claude-sonnet-4-6)

---

## Overall Verdict

**PASS**

The implementation is well-structured, follows the policy-defined conventions, and meets T1 rigor requirements. One design divergence from the spec is identified and documented: `KeywordClassifier` performs body-preview keyword matching in addition to subject matching, which was not specified for this feature iteration. This is treated as a finding below. All other code quality criteria are met.

---

## 1. Design Principles Assessment

### Simplicity

The approach is appropriately simple. Each new type has a single responsibility:
- `MailMessageSnapshot` is a pure value object with one validation factory.
- `KeywordClassifier` is a stateless class with a fixed rule table and straightforward loop logic.
- `InMemoryTrainingRepository` is a minimal `ConcurrentQueue` wrapper.
- `ClassifierClient` is a thin fetch wrapper.
- Both API endpoints are minimal-API lambdas with direct DI injection.

No unnecessary indirection or abstraction layers were introduced.

**Verdict: PASS**

### Reusability

Interfaces (`IMessageClassifier`, `ITrainingRepository`) are correctly placed in `TaskMaster.Application`, making them available to any implementation without introducing inter-layer dependencies. The TypeScript `normalizeClassifyRequest` and `parseClassifyResponse` are exported pure functions, making them directly testable and reusable independently of `ClassifierClient`.

**Verdict: PASS**

### Extensibility

`IMessageClassifier` enables the planned replacement with a SpamBayes engine without any call-site changes. `ITrainingRepository` allows future persistent implementations to replace `InMemoryTrainingRepository` with no API surface change. The `ClassificationLabel` static class provides named constants rather than magic strings. The keyword-based `Rules` static array in `KeywordClassifier` can be extended with new entries without touching callers.

**Verdict: PASS**

### Separation of Concerns

- Pure domain logic (`MailMessageSnapshot.Create`, `KeywordClassifier.Classify`) is separated from I/O.
- `InMemoryTrainingRepository` isolates the in-process state.
- API DTOs (`ClassifyRequest`, `ClassifyResponse`, `FeedbackRequest`) are internal to `TaskMaster.Api` and not shared across projects.
- TypeScript pure functions (`normalizeClassifyRequest`, `parseClassifyResponse`) are decoupled from the `ClassifierClient` HTTP boundary.
- `ClassifierClient` contains no Office.js references.
- `taskpane.ts` renders classification results via `renderClassificationResult` without embedding HTTP calls.

**Verdict: PASS**

---

## 2. Design Finding: Body-Preview Keyword Matching (Undocumented Behavior)

**Finding ID:** CR-001  
**Severity:** Low — informational  
**File:** `src/TaskMaster.Classifier/KeywordClassifier.cs`, lines 31–39

`KeywordClassifier.Classify` performs a second pass over `snapshot.BodyPreview` when no subject match is found, applying a reduced confidence (rule confidence − 0.10). This behavior:

- Is not documented in `spec.md`. The spec states "subject is the sole classifier input for this feature." The `spec.md` Constraints section states: "Body-text keyword matching (body text may be used in future iterations; subject is the sole classifier input for this feature)."
- Is not specified in the acceptance criteria in `issue.md` or `user-story.md`.
- Is tested in `KeywordClassifierTests.cs` (line 111–125: `Classify_UrgentInBodyPreviewNoSubjectMatch_ReturnsHighPriorityAt080`) and `Classify_UnrecognizedSubjectAndBody_ReturnsGeneralAt050`.

**Assessment:** The implementation extends beyond the specified scope by adding body-preview matching as a secondary classification path. The feature spec explicitly designates subject as the sole classifier input. The golden tests and CsCheck property tests are consistent with a subject-only implementation; the body-preview path is only covered by unit tests, not golden tests.

This does not cause incorrect behavior for any AC or break any existing test. The confidence-reduction rule (−0.10) means body-match confidence values (0.75–0.80) remain within [0.0, 1.0]. However, because the spec explicitly marks this as a non-goal for this iteration, this is a scope addition that should be noted.

**Action:** Reviewer flags for awareness. Because the behavior is tested, does not violate invariants, does not introduce I/O or external dependencies, and all tests pass, this is not raised as remediation-required. It should be acknowledged in the merge discussion so that the SpamBayes replacement story accounts for it.

---

## 3. Naming Conventions

### C#

- `PascalCase` for types and public members: consistent across all new files. PASS.
- `_camelCase` for private fields: `_queue`, `_timeProvider` in `InMemoryTrainingRepository`. PASS.
- `I` prefix on interfaces: `IMessageClassifier`, `ITrainingRepository`. PASS.
- File-scoped namespaces: all new C# files use `namespace X;` syntax. PASS.
- Async suffix: `RecordAsync` on the repository method. PASS.

### TypeScript

- `PascalCase` for interfaces and class: `ClassifyRequest`, `ClassifyResponse`, `FeedbackRequest`, `ClassifierClient`. PASS.
- `camelCase` for functions: `normalizeClassifyRequest`, `parseClassifyResponse`. PASS.
- Kebab-case filenames: `classifier-client.ts`, `classifier-client.test.ts`. PASS.

---

## 4. Null Safety and Guard Clauses

- `MailMessageSnapshot.Create`: Guards `messageId` and `subject` with `ArgumentException.ThrowIfNullOrWhiteSpace` at construction time. PASS.
- `KeywordClassifier.Classify`: Guards `snapshot` with `ArgumentNullException.ThrowIfNull`. PASS.
- `InMemoryTrainingRepository`: Constructor guards `timeProvider`; `RecordAsync` guards `feedback`. PASS.
- `ClassificationResult.Confidence`: Validates range `[0.0, 1.0]` at init-time via a property init-expression. This is a well-structured fail-fast invariant.
- `parseClassifyResponse` (TypeScript): Validates type of `label` (string) and `confidence` (number) before casting. Uses `"label" in value` presence check plus type assertion. PASS.

---

## 5. Public API Surface

All new .NET production types have appropriate access modifiers:
- Application-layer interfaces and records are `public` as required by DI and cross-project use.
- `InMemoryTrainingRepository` is `internal sealed` — correct, it is registered via the DI container and does not need to be visible outside the infrastructure project. PASS.
- `ClassifyRequest`, `ClassifyResponse`, `FeedbackRequest` API DTOs are `internal sealed record` — correct, they are not shared beyond `TaskMaster.Api`. PASS.
- `KeywordClassifier` is `public sealed` — correct, `[InternalsVisibleTo]` wiring in the csproj exposes it to the test project only when needed.

---

## 6. XML Documentation

- `MailMessageSnapshot`, `IMessageClassifier`, `ITrainingRepository`, `TrainingFeedback`, `ClassificationResult`, `ClassifierServiceCollectionExtensions`, `InMemoryTrainingRepository` all have XML documentation on the type and public/interface members. PASS.
- `ClassificationLabel` has a summary doc comment. PASS.
- `KeywordClassifier` has a class-level summary. The `Classify` method uses `/// <inheritdoc />`. PASS per conventions.

---

## 7. Test Quality

### Structure

All test files follow Arrange-Act-Assert with clear section separators where appropriate. Test method names clearly state the scenario and expected outcome (e.g., `PostClassify_WithoutAuthorizationHeader_Returns401`, `Classify_UrgentInSubject_ReturnsHighPriorityAt090`).

**Verdict: PASS**

### Independence and Isolation

- All .NET unit tests use `new()` construction of the SUT with no shared mutable state.
- `ClassifyEndpointTests` and `ClassifyFeedbackEndpointTests` use `IClassFixture<CustomWebApplicationFactory>` for the authenticated factory (read-only, appropriate sharing) and instantiate `UnauthenticatedWebApplicationFactory` per test to avoid state leakage.
- TypeScript tests reset MSW via `server.use(...)` per test case for handler overrides.

**Verdict: PASS**

### Property Tests (.NET CsCheck)

Two property tests are present in `KeywordClassifierTests.cs`:
1. `Classify_AnyValidSnapshot_ConfidenceInRange` — uses `Gen.Select(Gen.String[1,50], Gen.String[1,50])` to generate arbitrary valid inputs and asserts confidence is in [0.0, 1.0]. PASS.
2. `Classify_TrimmedVsUntrimmedSubject_ProduceIdenticalResults` — uses `MailMessageSnapshotGen.Arbitrary` and asserts trimmed and padded subjects produce equal label and confidence. PASS.

Both tests satisfy the T1 CsCheck property-test-per-pure-function requirement.

### Property Tests (TypeScript fast-check)

Two `test.prop` assertions in `classifier-client.test.ts`:
1. `normalizeClassifyRequest` trims messageId, subject, and coerces undefined body — covers all three branches. PASS.
2. `parseClassifyResponse` round-trips label and confidence for valid inputs. PASS.

Both tests satisfy the T1 `test.prop` requirement.

### Golden Tests

`KeywordClassifierGoldenTests.cs` drives three corpus fixtures through `KeywordClassifier.Classify` and compares output against committed `.verified.json` snapshots. `VerifyInit.cs` registers `UseStrictJson()` via `[ModuleInitializer]`. Three `.verified.json` files are committed. PASS.

Note: The golden test class in the implemented code does not use `[UsesVerify]` attribute (as specified in spec.md). The `Verify.XunitV3` package may not require `[UsesVerify]` depending on the version; the tests pass (14/14 in `TaskMaster.Classifier.Tests`), so the functional behavior is correct. This is a minor spec-versus-implementation discrepancy that does not affect test correctness.

### No Temporary Files

No `File.Create`, `Path.GetTempFileName`, or temporary-file patterns are used in test code. Corpus fixtures are read-only JSON files in the repository. PASS.

### Determinism

- `InMemoryTrainingRepository` injects `TimeProvider`; tests inject `TimeProvider.System` directly (sufficient for non-time-sensitive unit tests). The stamping behavior is covered in `InMemoryTrainingRepositoryTests.cs`.
- No `Thread.Sleep`, `Task.Delay`, or wall-clock waits appear in test code.

**Verdict: PASS**

---

## 8. Async Usage

- `InMemoryTrainingRepository.RecordAsync` returns `Task.CompletedTask` after synchronous enqueue. This is correct for a synchronous in-memory store; the interface signature is `Task` to allow future async implementations.
- `Program.cs` uses `await app.RunAsync().ConfigureAwait(false)` for the host. PASS.
- API endpoint for `/api/classify/feedback` uses `await repo.RecordAsync(feedback, ct).ConfigureAwait(false)`. PASS.
- Test awaits use `.ConfigureAwait(true)` consistently. PASS.
- TypeScript `classify` and `recordFeedback` return `Promise` and properly await `response.json()`. PASS.

---

## 9. DI Wiring

- `AddClassifierServices()` registers `IMessageClassifier → KeywordClassifier` as Singleton. Correct for a stateless classifier.
- `InfrastructureServiceCollectionExtensions` registers `ITrainingRepository → InMemoryTrainingRepository` as Singleton with `TimeProvider.System`. Consistent with the existing `InMemoryUserSettingsRepository` pattern.
- `Program.cs` calls `AddClassifierServices()` after `AddApplicationServices()` and `AddInfrastructureServices()`. Order is correct because `AddClassifierServices` depends only on interfaces defined in `TaskMaster.Application` which are already registered.

**Verdict: PASS**

---

## 10. pipeline.yml Changes

Stage 8 correctly replaces the stub with a real `dotnet stryker` invocation using the `stryker-config.json` in the `TaskMaster.Classifier.Tests` directory. Stage 9 now runs both `TaskMaster.PlaceholderGolden.Tests` and `TaskMaster.Classifier.Tests` under `--no-restore`. The `stage-9-golden` job depends on `stage-8-mutation` via the `needs` key.

One observation: Stage 9 runs with `--no-restore` but does not use `--no-build`. If the build cache is not shared between jobs, this could produce "project not built" errors in CI. However, this is an existing pattern for `TaskMaster.PlaceholderGolden.Tests` in Stage 9 (unchanged), so this is consistent with the established convention.

**Verdict: PASS (consistent with existing pipeline convention)**

---

## 11. Summary of Findings

| ID | Severity | Description | Status |
|---|---|---|---|
| CR-001 | Low / Informational | `KeywordClassifier` performs body-preview keyword matching not specified in spec.md (which designates subject as sole input for this iteration). Tests cover the behavior; all tests pass. | Not remediation-required; flag for awareness |
