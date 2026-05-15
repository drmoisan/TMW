# implement-classify-selected-message — Plan

- **Issue:** #17
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-13T00-38
- **Status:** Draft
- **Version:** 1.0
- **Work Mode:** full-feature

## Required References

- General Code Change Policy: `.claude/rules/general-code-change.md`
- General Unit Test Policy: `.claude/rules/general-unit-test.md`
- C# Standards: `.claude/rules/csharp.md`
- TypeScript Standards: `.claude/rules/typescript.md`
- TypeScript Suppressions: `.claude/rules/typescript-suppressions.md`
- Architecture Boundaries: `.claude/rules/architecture-boundaries.md`
- Quality Tiers: `.claude/rules/quality-tiers.md`

**All work must comply with these policies. Do not duplicate their content here.**

---

## Implementation Plan (Atomic Tasks)

### Phase 0 — Baseline Capture

- [x] [P0-T1] Read policy files in required order: `.claude/rules/general-code-change.md`, `.claude/rules/general-unit-test.md`, `.claude/rules/csharp.md`, `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`, `.claude/rules/architecture-boundaries.md`, `.claude/rules/quality-tiers.md`
  - Files: all policy files listed above
  - Acceptance: Evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/baseline/phase0-instructions-read.md` containing `Timestamp:`, `Policy Order:`, and explicit list of files read

- [x] [P0-T2] Capture TypeScript test baseline by running `npm run test:coverage` from the repo root
  - Files: `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/baseline/ts-baseline.md`
  - Command: `npm run test:coverage`
  - Acceptance: Artifact written containing `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` with numeric line and branch coverage values

- [x] [P0-T3] Capture .NET test baseline by running `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` from the repo root
  - Files: `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/baseline/dotnet-baseline.md`
  - Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
  - Acceptance: Artifact written containing `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` with numeric pass count and coverage headline values

**Phase 0 gate:** All three baseline artifacts exist and contain required fields before Phase 1 begins.

---

### Phase 1 — Application Layer Types

- [x] [P1-T1] Create `src/TaskMaster.Application/MailMessageSnapshot.cs` as a `sealed record` with positional parameters `MessageId`, `Subject`, `BodyPreview?`, and a static `Create(messageId, subject, bodyPreview)` factory that calls `ArgumentException.ThrowIfNullOrWhiteSpace` on `messageId` and `subject`, trims all string fields, and uses file-scoped namespace `TaskMaster.Application`
  - Files: `src/TaskMaster.Application/MailMessageSnapshot.cs` (new)
  - Acceptance: File exists; `Create(null, "s", null)` throws `ArgumentException`; `Create("  id  ", " s ", null)` returns snapshot with `MessageId == "id"` and `Subject == "s"`

- [x] [P1-T2] Create `src/TaskMaster.Application/ClassificationLabel.cs` as a `static class` with three `public const string` constants: `HighPriority = "HighPriority"`, `Promotional = "Promotional"`, `General = "General"`, using file-scoped namespace `TaskMaster.Application`
  - Files: `src/TaskMaster.Application/ClassificationLabel.cs` (new)
  - Acceptance: File exists; constants compile; no instance members

- [x] [P1-T3] Create `src/TaskMaster.Application/ClassificationResult.cs` as a `sealed record` with positional parameters `Label` (string) and `Confidence` (double), using file-scoped namespace `TaskMaster.Application`
  - Files: `src/TaskMaster.Application/ClassificationResult.cs` (new)
  - Acceptance: File exists; record is constructible with `("HighPriority", 0.9)`; positional deconstruction works

- [x] [P1-T4] Create `src/TaskMaster.Application/IMessageClassifier.cs` as an interface with a single synchronous method `ClassificationResult Classify(MailMessageSnapshot snapshot)`, using file-scoped namespace `TaskMaster.Application` and XML doc comment on the interface and method
  - Files: `src/TaskMaster.Application/IMessageClassifier.cs` (new)
  - Acceptance: File exists; interface compiles; method signature is exactly `ClassificationResult Classify(MailMessageSnapshot snapshot)`

- [x] [P1-T5] Create `src/TaskMaster.Application/TrainingFeedback.cs` as a `sealed record` with positional parameters `MessageId` (string), `Label` (string), `Confirmed` (bool), `RecordedAt` (DateTimeOffset), using file-scoped namespace `TaskMaster.Application` and XML doc comments
  - Files: `src/TaskMaster.Application/TrainingFeedback.cs` (new)
  - Acceptance: File exists; record is constructible; `with` expression works for `RecordedAt` override

- [x] [P1-T6] Create `src/TaskMaster.Application/ITrainingRepository.cs` as an interface with a single method `Task RecordAsync(TrainingFeedback feedback, CancellationToken ct = default)`, using file-scoped namespace `TaskMaster.Application` and XML doc comments
  - Files: `src/TaskMaster.Application/ITrainingRepository.cs` (new)
  - Acceptance: File exists; interface compiles; method signature exactly matches spec

- [x] [P1-T7] Verify `dotnet build src/TaskMaster.Application/TaskMaster.Application.csproj` passes with 0 errors and 0 analyzer warnings after all six new files are in place
  - Files: `src/TaskMaster.Application/` (all new files above)
  - Command: `dotnet build src/TaskMaster.Application/TaskMaster.Application.csproj`
  - Acceptance: Build exits 0; no errors or warnings in output

**Phase 1 gate:** `dotnet build TaskMaster.Application.csproj` exits 0 with 0 errors and 0 warnings.

---

### Phase 2 — Classifier Project (T1)

- [x] [P2-T1] Create `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj` targeting `net10.0` with `ImplicitUsings=enable`, `Nullable=enable`, `InternalsVisibleTo` for `TaskMaster.Classifier.Tests` and `DynamicProxyGenAssembly2`, and a single `ProjectReference` to `TaskMaster.Application.csproj`; include the standard analyzer `PackageReference` items with `PrivateAssets="all"` as used in other projects
  - Files: `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj` (new)
  - Acceptance: File exists; contains no reference to `TaskMaster.Infrastructure`, `TaskMaster.Domain`, or any COM/VSTO/Office assembly; `dotnet restore` on this project exits 0

- [x] [P2-T2] Create `src/TaskMaster.Classifier/KeywordClassifier.cs` implementing `IMessageClassifier`; implement a static rules array with four entries: `("urgent", HighPriority, 0.90)`, `("action required", HighPriority, 0.85)`, `("unsubscribe", Promotional, 0.90)`, `("newsletter", Promotional, 0.85)`; `Classify` iterates rules in order, matching against `snapshot.Subject` case-insensitively (first match wins), returning `General` at 0.50 for no match; calls `ArgumentNullException.ThrowIfNull(snapshot)` at entry; file-scoped namespace `TaskMaster.Classifier`
  - Files: `src/TaskMaster.Classifier/KeywordClassifier.cs` (new)
  - Acceptance: File exists; `Classify` returns `HighPriority` at 0.90 for subject containing "urgent"; returns `General` at 0.50 for unrecognized subject; does not throw for null-body snapshot

- [x] [P2-T3] Create `src/TaskMaster.Classifier/ClassifierServiceCollectionExtensions.cs` with a `public static IServiceCollection AddClassifierServices(this IServiceCollection services)` extension method that registers `IMessageClassifier` as `KeywordClassifier` with `AddSingleton`; file-scoped namespace `TaskMaster.Classifier`; includes XML doc comments
  - Files: `src/TaskMaster.Classifier/ClassifierServiceCollectionExtensions.cs` (new)
  - Acceptance: File exists; method compiles; calls `services.AddSingleton<IMessageClassifier, KeywordClassifier>()`

- [x] [P2-T4] Add `TaskMaster.Classifier` project to `TaskMaster.sln` under the existing `src` solution folder using `dotnet sln add`
  - Files: `TaskMaster.sln` (modified)
  - Command: `dotnet sln TaskMaster.sln add src/TaskMaster.Classifier/TaskMaster.Classifier.csproj`
  - Acceptance: `TaskMaster.sln` contains a `Project` entry for `TaskMaster.Classifier`; `dotnet build TaskMaster.sln` exits 0

- [x] [P2-T5] Add `TaskMaster.Classifier` entry to `quality-tiers.yml` at tier `t1` with required fields `name`, `path`, `language`, `tier`, and `rationale` matching the spec
  - Files: `quality-tiers.yml` (modified)
  - Acceptance: File contains entry with `name: TaskMaster.Classifier`, `tier: t1`; CI tier-classification stage will not fail

**Phase 2 gate:** `dotnet build TaskMaster.sln` exits 0 with 0 errors and 0 warnings; `quality-tiers.yml` contains `TaskMaster.Classifier` at `t1`.

---

### Phase 3 — Infrastructure Training Repository

- [x] [P3-T1] Create `src/TaskMaster.Infrastructure/InMemoryTrainingRepository.cs` as `internal sealed class` implementing `ITrainingRepository`; use `ConcurrentQueue<TrainingFeedback>` for thread-safe storage; inject `TimeProvider` via constructor with `ArgumentNullException.ThrowIfNull`; in `RecordAsync`, override `feedback.RecordedAt` with `_timeProvider.GetUtcNow()` using a `with` expression before enqueuing; file-scoped namespace `TaskMaster.Infrastructure`
  - Files: `src/TaskMaster.Infrastructure/InMemoryTrainingRepository.cs` (new)
  - Acceptance: File exists; class is `internal sealed`; constructor throws on null `TimeProvider`; `RecordAsync` enqueues feedback with stamped `RecordedAt`

- [x] [P3-T2] Update `src/TaskMaster.Infrastructure/InfrastructureServiceCollectionExtensions.cs` to register `ITrainingRepository` as `InMemoryTrainingRepository` (Singleton, injecting `TimeProvider.System`) immediately after the existing `IUserSettingsRepository` registration
  - Files: `src/TaskMaster.Infrastructure/InfrastructureServiceCollectionExtensions.cs` (modified)
  - Acceptance: File contains `services.AddSingleton<ITrainingRepository>(_ => new InMemoryTrainingRepository(TimeProvider.System))`; `dotnet build` exits 0

**Phase 3 gate:** `dotnet build TaskMaster.sln` exits 0; Infrastructure project compiles with `ITrainingRepository` registered.

---

### Phase 4 — API Endpoints

- [x] [P4-T1] Create `src/TaskMaster.Api/ClassifyRequest.cs` as `internal sealed record ClassifyRequest(string? MessageId, string? Subject, string? Body)` in file-scoped namespace `TaskMaster.Api`
  - Files: `src/TaskMaster.Api/ClassifyRequest.cs` (new)
  - Acceptance: File exists; record has exactly three nullable properties matching names in spec

- [x] [P4-T2] Create `src/TaskMaster.Api/ClassifyResponse.cs` as `internal sealed record ClassifyResponse(string Label, double Confidence)` in file-scoped namespace `TaskMaster.Api`
  - Files: `src/TaskMaster.Api/ClassifyResponse.cs` (new)
  - Acceptance: File exists; record has non-nullable `Label` and non-nullable `Confidence`

- [x] [P4-T3] Create `src/TaskMaster.Api/FeedbackRequest.cs` as `internal sealed record FeedbackRequest(string? MessageId, string? Label, bool Confirmed)` in file-scoped namespace `TaskMaster.Api`
  - Files: `src/TaskMaster.Api/FeedbackRequest.cs` (new)
  - Acceptance: File exists; record compiles; `Confirmed` is non-nullable `bool`

- [x] [P4-T4] Update `src/TaskMaster.Api/Program.cs` to add `using TaskMaster.Classifier;` and call `builder.Services.AddClassifierServices()` immediately after `builder.Services.AddInfrastructureServices(builder.Configuration)`
  - Files: `src/TaskMaster.Api/Program.cs` (modified)
  - Acceptance: File contains the new `using` directive and the `AddClassifierServices()` call; `dotnet build` exits 0

- [x] [P4-T5] Update `src/TaskMaster.Api/Program.cs` to add the `POST /api/classify` minimal API endpoint: validate `req.MessageId` and `req.Subject` with `string.IsNullOrWhiteSpace` returning `Results.UnprocessableEntity()` on failure; create a `MailMessageSnapshot` via `Create`; call `classifier.Classify(snapshot)`; return `Results.Ok(new ClassifyResponse(...))` on success; call `.RequireAuthorization()` on the endpoint
  - Files: `src/TaskMaster.Api/Program.cs` (modified)
  - Acceptance: Endpoint is registered at `POST /api/classify`; 422 branch exists for empty `messageId` or `subject`; handler injects `IMessageClassifier` via parameter list

- [x] [P4-T6] Update `src/TaskMaster.Api/Program.cs` to add the `POST /api/classify/feedback` minimal API endpoint: construct `TrainingFeedback` from request fields (with `RecordedAt: default`); call `await repo.RecordAsync(feedback, ct).ConfigureAwait(false)`; return `Results.NoContent()`; call `.RequireAuthorization()` on the endpoint
  - Files: `src/TaskMaster.Api/Program.cs` (modified)
  - Acceptance: Endpoint is registered at `POST /api/classify/feedback`; handler injects `ITrainingRepository` and `CancellationToken`; returns 204

- [x] [P4-T7] Verify `dotnet build TaskMaster.sln` passes with 0 errors and 0 warnings after all API changes
  - Files: `src/TaskMaster.Api/Program.cs`, `src/TaskMaster.Api/*.cs`
  - Command: `dotnet build TaskMaster.sln`
  - Acceptance: Build exits 0; no errors or warnings

**Phase 4 gate:** `dotnet build TaskMaster.sln` exits 0; both endpoints are registered with `RequireAuthorization()`.

---

### Phase 5 — TypeScript Client and UI

- [x] [P5-T1] Create `src/taskpane/classifier-client.ts` exporting interfaces `ClassifyRequest`, `ClassifyResponse`, `FeedbackRequest`; pure functions `normalizeClassifyRequest` (trims `messageId`, `subject`, coerces undefined `body` to `null`) and `parseClassifyResponse` (validates shape, throws `TypeError` with descriptive message on invalid shape); class `ClassifierClient` with constructor taking `baseUrl: string` and methods `classify(req, bearerToken): Promise<ClassifyResponse>` and `recordFeedback(req, bearerToken): Promise<void>`; each method sets `Authorization: Bearer <token>` header and throws on non-OK response
  - Files: `src/taskpane/classifier-client.ts` (new)
  - Acceptance: File exists; `normalizeClassifyRequest("  id  ", " s ")` returns `{ messageId: "id", subject: "s", body: null }`; `parseClassifyResponse({ label: "General", confidence: 0.5 })` returns correctly; `parseClassifyResponse(null)` throws `TypeError`

- [x] [P5-T2] Update `src/taskpane/taskpane.ts` to extend the `RenderDom` interface with four new optional properties: `classification: HTMLElement`, `classifyBtn: HTMLElement`, `confirmBtn: HTMLElement`, `rejectBtn: HTMLElement`; add pure functions `renderClassifying(dom: RenderDom): void` (sets status text to "Classifying...") and `renderClassificationResult(result: ClassifyResponse, dom: RenderDom): void` (writes label and confidence percentage to `dom.classification`, enables confirm/reject buttons); import `ClassifierClient` and `ClassifyResponse` from `./classifier-client`
  - Files: `src/taskpane/taskpane.ts` (modified)
  - Acceptance: File compiles; `RenderDom` interface has four new optional members; both new functions are exported and operate only on DOM parameters without Office.js calls

- [x] [P5-T3] Update `src/taskpane/taskpane.html` to add a classification panel containing a result `<div id="classification-result">`, a `<button id="classify-btn">`, a `<button id="confirm-btn">`, and a `<button id="reject-btn">`; use existing CSS classes from `taskpane.css` where available; add only the minimum new CSS class declarations in `taskpane.css` (or the inline style block) for any elements not covered by existing classes
  - Files: `src/taskpane/taskpane.html` (modified)
  - Acceptance: HTML file contains all four new elements with the IDs listed above; no new external CSS file is introduced

**Phase 5 gate:** `npm run typecheck` exits 0; all TypeScript files compile without errors.

---

### Phase 6 — .NET Unit and Property Tests (Application Layer)

- [x] [P6-T1] Create `tests/TaskMaster.Application.Tests/MailMessageSnapshotTests.cs` with unit tests for `MailMessageSnapshot.Create`: test null `messageId` throws `ArgumentException`; test whitespace-only `subject` throws `ArgumentException`; test that `Create("  id  ", "  s  ", null)` returns trimmed fields; test that `Create("id", "s", "  body  ")` trims body preview
  - Files: `tests/TaskMaster.Application.Tests/MailMessageSnapshotTests.cs` (new)
  - Acceptance: File exists; all four unit tests have `[Fact]` attribute; tests compile and pass under `dotnet test`

- [x] [P6-T2] Create `tests/TaskMaster.Application.Tests/Generators/MailMessageGen.cs` with a static class `MailMessageGen` containing a CsCheck `Gen<MailMessageSnapshot>` property that generates arbitrary non-empty-string pairs via `Gen.Select(Gen.String[1,50], Gen.String[1,50])` and wraps in `MailMessageSnapshot.Create`; file-scoped namespace `TaskMaster.Application.Tests.Generators`
  - Files: `tests/TaskMaster.Application.Tests/Generators/MailMessageGen.cs` (new)
  - Acceptance: File exists; generator compiles; produces valid `MailMessageSnapshot` instances

- [x] [P6-T3] Create `tests/TaskMaster.Application.Tests/ClassificationResultTests.cs` with unit tests for `ClassificationResult`: test construction with valid label and confidence 0.0; test construction with confidence 1.0; add a CsCheck property test using `Gen.Double[0.0, 1.0]` asserting that any in-range confidence round-trips correctly via the record's positional deconstruction
  - Files: `tests/TaskMaster.Application.Tests/ClassificationResultTests.cs` (new)
  - Acceptance: File exists; tests compile; property test generates at least 100 samples; all pass under `dotnet test`

**Phase 6 gate:** `dotnet test tests/TaskMaster.Application.Tests/TaskMaster.Application.Tests.csproj` passes; no new test failures.

---

### Phase 7 — Classifier Test Project

- [x] [P7-T1] Create `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj` targeting `net10.0` with `ImplicitUsings=enable`, `IsPackable=false`, `RunSettingsFilePath=$(MSBuildProjectDirectory)/test.runsettings`; reference packages `coverlet.collector`, `Microsoft.NET.Test.Sdk`, `Verify.XunitV3`, `xunit.runner.visualstudio`, `xunit.v3`, `FluentAssertions`, `NSubstitute`, `CsCheck`; project reference to `TaskMaster.Classifier.csproj`; must NOT reference `xunit` (2.x)
  - Files: `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj` (new)
  - Acceptance: File exists; contains `xunit.v3` reference; does NOT contain a `xunit` version 2.x reference; `dotnet restore` exits 0

- [x] [P7-T2] Create `tests/TaskMaster.Classifier.Tests/test.runsettings` using the same pattern as `tests/TaskMaster.PlaceholderGolden.Tests/test.runsettings` (configure DataCollectors for XPlat Code Coverage)
  - Files: `tests/TaskMaster.Classifier.Tests/test.runsettings` (new)
  - Acceptance: File exists; XML is valid; contains `DataCollector` configuration for code coverage

- [x] [P7-T3] Create `tests/TaskMaster.Classifier.Tests/VerifyInit.cs` with a `public static class VerifyInit` containing a `[ModuleInitializer]` method `Initialize` that calls `VerifierSettings.UseStrictJson()`; file-scoped namespace `TaskMaster.Classifier.Tests`
  - Files: `tests/TaskMaster.Classifier.Tests/VerifyInit.cs` (new)
  - Acceptance: File exists; `[ModuleInitializer]` attribute is used; `VerifierSettings.UseStrictJson()` is called

- [x] [P7-T4] Create `tests/TaskMaster.Classifier.Tests/Generators/MailMessageSnapshotGen.cs` with a static class `MailMessageSnapshotGen` providing a CsCheck generator that produces arbitrary `MailMessageSnapshot` instances using `Gen.String[1,50]` for `MessageId` and `Subject`; file-scoped namespace `TaskMaster.Classifier.Tests.Generators`
  - Files: `tests/TaskMaster.Classifier.Tests/Generators/MailMessageSnapshotGen.cs` (new)
  - Acceptance: File exists; generator produces valid `MailMessageSnapshot` instances without throwing

- [x] [P7-T5] Create `tests/TaskMaster.Classifier.Tests/KeywordClassifierTests.cs` with unit tests covering: "urgent" subject returns `HighPriority` at 0.90; "action required" subject returns `HighPriority` at 0.85; "unsubscribe" subject returns `Promotional` at 0.90; "newsletter" subject returns `Promotional` at 0.85; unrecognized subject returns `General` at 0.50; CsCheck property test `Classify_AnyValidSnapshot_ConfidenceInRange` using `Gen.Select(Gen.String[1,50], Gen.String[1,50], Gen.String.Null)` asserting confidence is in [0.0, 1.0]; CsCheck property test asserting trimmed and untrimmed identical subjects produce identical results
  - Files: `tests/TaskMaster.Classifier.Tests/KeywordClassifierTests.cs` (new)
  - Acceptance: File has at least 5 `[Fact]` tests and 2 property tests; all compile and pass under `dotnet test`

- [x] [P7-T6] Create corpus fixture `corpus/classifiers/keyword/urgent-meeting-001.json` with `{ "messageId": "msg-urgent-001@example.com", "subject": "URGENT: Action required by Friday", "bodyPreview": null }`
  - Files: `corpus/classifiers/keyword/urgent-meeting-001.json` (new)
  - Acceptance: File exists; valid JSON; `subject` contains "URGENT"; `bodyPreview` is `null`

- [x] [P7-T7] Create corpus fixture `corpus/classifiers/keyword/newsletter-promo-001.json` with `{ "messageId": "msg-promo-001@example.com", "subject": "Your weekly newsletter — unsubscribe", "bodyPreview": null }`
  - Files: `corpus/classifiers/keyword/newsletter-promo-001.json` (new)
  - Acceptance: File exists; valid JSON; `subject` contains "newsletter" and "unsubscribe"

- [x] [P7-T8] Create corpus fixture `corpus/classifiers/keyword/team-update-001.json` with `{ "messageId": "msg-general-001@example.com", "subject": "Team update for Q3 planning", "bodyPreview": null }`
  - Files: `corpus/classifiers/keyword/team-update-001.json` (new)
  - Acceptance: File exists; valid JSON; `subject` contains no keyword matching any rule

- [x] [P7-T9] Create `tests/TaskMaster.Classifier.Tests/KeywordClassifierGoldenTests.cs` with a `[UsesVerify]` test class implementing a `[Theory]` named `Classify_CorpusFixture_MatchesVerifiedOutput` with `[InlineData]` for each of the three fixture filenames; load fixture from filesystem using `AppContext.BaseDirectory` relative path (`../../../../../corpus/classifiers/keyword/<filename>`); deserialize to an internal `CorpusFixture(string MessageId, string Subject, string? BodyPreview)` record; call `Classifier.Classify(snapshot)` and `await Verify(result).UseParameters(filename)`; file-scoped namespace `TaskMaster.Classifier.Tests`
  - Files: `tests/TaskMaster.Classifier.Tests/KeywordClassifierGoldenTests.cs` (new)
  - Acceptance: File exists; test class has `[UsesVerify]`; three `[InlineData]` entries; `CorpusFixture` record is defined in the same file or the project

- [x] [P7-T10] Run golden tests for the first time to generate `.received.json` files, then accept them by renaming to `.verified.json`; commit the three verified files: `KeywordClassifierGoldenTests.Classify_CorpusFixture_MatchesVerifiedOutput_urgent-meeting-001.json.verified.json`, `KeywordClassifierGoldenTests.Classify_CorpusFixture_MatchesVerifiedOutput_newsletter-promo-001.json.verified.json`, `KeywordClassifierGoldenTests.Classify_CorpusFixture_MatchesVerifiedOutput_team-update-001.json.verified.json`
  - Files: `tests/TaskMaster.Classifier.Tests/*.verified.json` (3 new files)
  - Acceptance: All three `.verified.json` files exist in the test project directory; each contains a JSON object with `"Label"` and `"Confidence"` keys; golden tests pass on subsequent `dotnet test` runs

- [x] [P7-T11] Create `tests/TaskMaster.Classifier.Tests/stryker-config.json` with `"project": "TaskMaster.Classifier.csproj"`, `"test-projects": ["TaskMaster.Classifier.Tests.csproj"]`, `"mutation-level": "Standard"`, `"thresholds": { "high": 90, "low": 75, "break": 75 }`, `"reporters": ["html", "json", "progress"]`, `"output-path": "StrykerOutput"`
  - Files: `tests/TaskMaster.Classifier.Tests/stryker-config.json` (new)
  - Acceptance: File exists; valid JSON; `"break": 75` is present; project targets `TaskMaster.Classifier.csproj`

- [x] [P7-T12] Add `TaskMaster.Classifier.Tests` project to `TaskMaster.sln` under the existing `tests` solution folder using `dotnet sln add`
  - Files: `TaskMaster.sln` (modified)
  - Command: `dotnet sln TaskMaster.sln add tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj`
  - Acceptance: `TaskMaster.sln` contains a `Project` entry for `TaskMaster.Classifier.Tests`; `dotnet build TaskMaster.sln` exits 0

- [x] [P7-T13] Add `TaskMaster.Classifier.Tests` entry to `quality-tiers.yml` at tier `t4` with required fields `name`, `path`, `language`, `tier`, and `rationale` matching the spec
  - Files: `quality-tiers.yml` (modified)
  - Acceptance: File contains entry with `name: TaskMaster.Classifier.Tests`, `tier: t4`

**Phase 7 gate:** `dotnet test tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj` passes; all three `.verified.json` files are committed; `quality-tiers.yml` contains both new classifier entries.

---

### Phase 8 — Architecture Boundary Update

- [x] [P8-T1] Add a `ProjectReference` for `TaskMaster.Classifier` to `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`
  - Files: `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj` (modified)
  - Acceptance: File contains `<ProjectReference Include="..\..\src\TaskMaster.Classifier\TaskMaster.Classifier.csproj" />`; `dotnet build tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj` exits 0

- [x] [P8-T2] Update `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs` to add a `[Fact]` named `ClassifierProjectDoesNotDependOnInfrastructure` that uses `Types.InAssembly(typeof(KeywordClassifier).Assembly).Should().NotHaveDependencyOn("TaskMaster.Infrastructure").GetResult()` and asserts `result.IsSuccessful` with a descriptive failure message listing failing type names
  - Files: `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs` (modified)
  - Acceptance: New fact exists; test passes (no Infrastructure dependency); test would fail if Infrastructure reference were added to the Classifier project

**Phase 8 gate:** `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj` passes including the new `ClassifierProjectDoesNotDependOnInfrastructure` fact.

---

### Phase 9 — API Integration Tests

- [x] [P9-T1] Create `tests/TaskMaster.Api.Tests/ClassifyEndpointTests.cs` with three integration tests using `CustomWebApplicationFactory` and `IClassFixture<CustomWebApplicationFactory>`: (1) unauthenticated `POST /api/classify` returns 401 (no auth header); (2) authenticated `POST /api/classify` with valid `{ "messageId": "id", "subject": "urgent test" }` returns 200 with a JSON body containing `"label"` and `"confidence"` keys; (3) authenticated `POST /api/classify` with empty `subject` returns 422
  - Files: `tests/TaskMaster.Api.Tests/ClassifyEndpointTests.cs` (new)
  - Acceptance: Three tests exist; unauthenticated test does NOT set Authorization header; authenticated tests set `Authorization: Test` (matching `TestAuthHandler.SchemeName`); all three pass under `dotnet test`

- [x] [P9-T2] Create `tests/TaskMaster.Api.Tests/ClassifyFeedbackEndpointTests.cs` with two integration tests: (1) unauthenticated `POST /api/classify/feedback` returns 401; (2) authenticated `POST /api/classify/feedback` with valid `{ "messageId": "id", "label": "General", "confirmed": true }` returns 204
  - Files: `tests/TaskMaster.Api.Tests/ClassifyFeedbackEndpointTests.cs` (new)
  - Acceptance: Two tests exist; unauthenticated test returns 401; authenticated test returns 204; both pass under `dotnet test`

- [x] [P9-T3] Verify `tests/TaskMaster.Api.Tests/CustomWebApplicationFactory.cs` does not require changes to wire `IMessageClassifier` and `ITrainingRepository`; if the existing `ConfigureWebHost` override replaces services in a way that drops classifier or training registrations, update `CustomWebApplicationFactory.cs` to preserve those registrations or add NSubstitute stubs
  - Files: `tests/TaskMaster.Api.Tests/CustomWebApplicationFactory.cs` (review; modify only if required)
  - Acceptance: Integration tests from P9-T1 and P9-T2 pass with the factory as-is or after minimal targeted changes; no broad refactors

**Phase 9 gate:** `dotnet test tests/TaskMaster.Api.Tests/TaskMaster.Api.Tests.csproj` passes including all new classify endpoint tests.

---

### Phase 10 — TypeScript Tests

- [x] [P10-T1] Create `src/taskpane/classifier-client.test.ts` with the following test groups: (1) unit tests for `ClassifierClient.classify` using MSW to mock `POST /api/classify` returning `{ label: "HighPriority", confidence: 0.9 }` and asserting the returned object; (2) unit test for `ClassifierClient.classify` throwing on non-200 response; (3) unit test for `ClassifierClient.recordFeedback` returning void on 204; (4) unit test for `ClassifierClient.recordFeedback` throwing on non-200; (5) unit tests for `normalizeClassifyRequest` covering `undefined` body, defined body, and whitespace trimming; (6) unit tests for `parseClassifyResponse` covering valid shape, null input, missing `label`, and missing `confidence`
  - Files: `src/taskpane/classifier-client.test.ts` (new)
  - Acceptance: File exists; all unit tests pass under `npm run test`; MSW server is started/stopped using the pattern in `src/test-support/msw-server.ts`

- [x] [P10-T2] Add property test to `src/taskpane/classifier-client.test.ts`: use `test.prop` from `@fast-check/vitest` with `fc.string()`, `fc.string()`, and `fc.option(fc.string(), { nil: undefined })` to assert that `normalizeClassifyRequest` trims `messageId`, trims `subject`, returns `null` body when input is `undefined`, and returns trimmed body when input is a string
  - Files: `src/taskpane/classifier-client.test.ts` (modified)
  - Acceptance: Property test exists using `test.prop`; runs at least 100 generated samples; passes under `npm run test`

- [x] [P10-T3] Add property test to `src/taskpane/classifier-client.test.ts`: use `test.prop` with `fc.string()` and `fc.double({ min: 0, max: 1 })` to assert that `parseClassifyResponse({ label, confidence })` round-trips correctly returning the same `label` and `confidence`
  - Files: `src/taskpane/classifier-client.test.ts` (modified)
  - Acceptance: Property test exists; passes under `npm run test`; uses `fc.double` with `min: 0, max: 1`

**Phase 10 gate:** `npm run test` passes; all new TypeScript tests green; both `test.prop` property tests present.

---

### Phase 11 — Pre-Merge Pipeline Update

- [x] [P11-T1] Update `.github/workflows/pre-merge-pipeline.yml` to replace the `stage-8-mutation` stub step (`Stub — no T1 module present`) with a real `dotnet stryker` invocation: `dotnet tool restore` followed by `dotnet stryker --config-file tests/TaskMaster.Classifier.Tests/stryker-config.json` from `${{ github.workspace }}`; name the step `stage-8-mutation-classifier`
  - Files: `.github/workflows/pre-merge-pipeline.yml` (modified)
  - Acceptance: The stub `Write-Host` step is removed; a `run:` block invoking `dotnet stryker` is present; `stryker-config.json` path is correct

- [x] [P11-T2] Update `.github/workflows/pre-merge-pipeline.yml` stage `stage-9-golden` to run `dotnet test tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj --no-build` in addition to the existing `TaskMaster.PlaceholderGolden.Tests` run; both test commands must appear in a single `run:` block or sequential steps
  - Files: `.github/workflows/pre-merge-pipeline.yml` (modified)
  - Acceptance: Stage 9 `run:` block includes a `dotnet test` invocation targeting `TaskMaster.Classifier.Tests.csproj`; existing PlaceholderGolden test run is preserved

**Phase 11 gate:** YAML is valid; both pipeline stages reference the correct project paths.

---

### Phase 12 — Full QA Loop

- [x] [P12-T1] Run TypeScript formatting: `npm run format`; if files change, re-run format until no files change
  - Files: all TypeScript source files modified in this feature
  - Command: `npm run format`
  - Acceptance: Command exits 0 with no file modifications on the final run; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/ts-format.md` with `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`

- [x] [P12-T2] Run TypeScript linting: `npm run lint`; resolve all lint errors before proceeding
  - Files: all TypeScript source files modified in this feature
  - Command: `npm run lint`
  - Acceptance: Command exits 0 with 0 errors; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/ts-lint.md`

- [x] [P12-T3] Run TypeScript type checking: `npm run typecheck`; resolve all type errors before proceeding
  - Files: all TypeScript source files modified in this feature
  - Command: `npm run typecheck`
  - Acceptance: Command exits 0 with 0 type errors; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/ts-typecheck.md`

- [x] [P12-T4] Run TypeScript tests with coverage: `npm run test:coverage`; record numeric line and branch coverage values; verify line coverage >= 85% and branch coverage >= 75%; if any stage in the loop (P12-T1 through P12-T4) changes files or fails, restart from P12-T1
  - Files: all TypeScript test files
  - Command: `npm run test:coverage`
  - Acceptance: Command exits 0; all tests pass; numeric coverage values are recorded in evidence artifact `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/ts-coverage.md`; line >= 85%, branch >= 75%

- [x] [P12-T5] Run .NET CSharpier formatting: `dotnet csharpier .`; if files change, restart the loop from P12-T5
  - Files: all C# source files modified in this feature
  - Command: `dotnet tool restore && dotnet csharpier .`
  - Acceptance: Command exits 0 with no file modifications on the final run; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/dotnet-format.md`

- [x] [P12-T6] Run .NET build (lint + type-check): `dotnet build TaskMaster.sln`; resolve all errors and warnings before proceeding
  - Files: `TaskMaster.sln` and all modified C# projects
  - Command: `dotnet build TaskMaster.sln`
  - Acceptance: Command exits 0 with 0 errors and 0 warnings; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/dotnet-build.md`

- [x] [P12-T7] Run .NET architecture boundary tests: `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`; all facts including `ClassifierProjectDoesNotDependOnInfrastructure` must pass
  - Files: `tests/TaskMaster.ArchitectureTests/`
  - Command: `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`
  - Acceptance: Command exits 0; 0 failed tests; evidence artifact written to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/dotnet-arch.md`

- [x] [P12-T8] Run full .NET test suite with coverage: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`; record numeric line and branch coverage values per project; verify line coverage >= 85% and branch coverage >= 75% across all projects; if any stage P12-T5 through P12-T8 changes files or fails, restart from P12-T5
  - Files: all C# test projects
  - Command: `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
  - Acceptance: Command exits 0; 0 failed tests; numeric coverage values recorded in evidence artifact `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/dotnet-coverage.md`; line >= 85%, branch >= 75%

- [x] [P12-T9] Record coverage delta by comparing baseline artifacts (P0-T2, P0-T3) against final QA artifacts (P12-T4, P12-T8); write a delta summary to `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/coverage-delta.md` documenting baseline line/branch coverage, post-change line/branch coverage, and direction of change for each language
  - Files: `docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/qa-gates/coverage-delta.md` (new)
  - Acceptance: Artifact exists; contains baseline and post-change numeric values for both TypeScript and .NET; no regression on changed lines

**Phase 12 gate:** All nine QA tasks complete; all evidence artifacts exist and contain required fields; zero regression on coverage; `dotnet build` and `npm run typecheck` exit 0.

---

## Evidence Artifacts Summary

All evidence artifacts are written to the canonical path:
`docs/features/active/2026-05-12-implement-classify-selected-message-17/evidence/`

| Sub-path | Artifact | Produced by |
|----------|----------|-------------|
| `evidence/baseline/` | `phase0-instructions-read.md` | P0-T1 |
| `evidence/baseline/` | `ts-baseline.md` | P0-T2 |
| `evidence/baseline/` | `dotnet-baseline.md` | P0-T3 |
| `evidence/qa-gates/` | `ts-format.md` | P12-T1 |
| `evidence/qa-gates/` | `ts-lint.md` | P12-T2 |
| `evidence/qa-gates/` | `ts-typecheck.md` | P12-T3 |
| `evidence/qa-gates/` | `ts-coverage.md` | P12-T4 |
| `evidence/qa-gates/` | `dotnet-format.md` | P12-T5 |
| `evidence/qa-gates/` | `dotnet-build.md` | P12-T6 |
| `evidence/qa-gates/` | `dotnet-arch.md` | P12-T7 |
| `evidence/qa-gates/` | `dotnet-coverage.md` | P12-T8 |
| `evidence/qa-gates/` | `coverage-delta.md` | P12-T9 |

---

## Critical Constraints

1. **No command bus routing for classification.** `IMessageClassifier.Classify` is called directly from the API handler. No `ClassifyMessageCommand` type is created. `ICommandBus` is not modified.
2. **`TaskMaster.Classifier` is T1.** Must appear in `quality-tiers.yml` at `tier: t1` or CI fails.
3. **Golden tests require committed `.verified.json` files.** These are source-controlled artifacts, not generated at test time. Three files must be committed after the first golden test run.
4. **`xunit.v3` and `xunit` 2.9.3 must not coexist in `TaskMaster.Classifier.Tests`.** Use only `xunit.v3`.
5. **`MailMessageSnapshot.Create` must guard null/whitespace.** Throws `ArgumentException` for null or whitespace `messageId` or `subject`.
6. **`InMemoryTrainingRepository` must inject `TimeProvider`.** Uses `TimeProvider.GetUtcNow()` for `RecordedAt`; no direct `DateTime.UtcNow` calls.
7. **Architecture boundary.** `TaskMaster.Classifier` must not reference `TaskMaster.Infrastructure`, `TaskMaster.Api`, VSTO, Outlook PIA, or any COM type. Enforced by `ClassifierProjectDoesNotDependOnInfrastructure` fact.
8. **Pre-merge Stage 8 becomes live.** The stub step must be fully replaced with a real `dotnet stryker` invocation.
9. **Coverage floor.** Line >= 85%, branch >= 75% across all tiers; no regression on changed lines.
10. **No new NuGet packages required.** All packages (`xunit.v3`, `Verify.XunitV3`, `CsCheck`, `FluentAssertions`, `NSubstitute`, `coverlet.collector`) are already pinned in `Directory.Packages.props`.

---

## Open Questions / Notes

- The `taskpane.ts` update (P5-T2) extends `RenderDom` with optional properties. Existing tests in `taskpane.test.ts` construct `RenderDom` without the new properties and must continue to pass because the new properties are typed as optional (`HTMLElement | undefined` or a partial pattern). Verify no existing test breaks.
- The `onItemChanged` function in `taskpane.ts` may need to be updated to call `ClassifierClient.classify` when a new item is selected. This requires acquiring a bearer token via `Office.context.auth`. P5-T2 introduces the pure render functions; the `onItemChanged` wiring is within scope of that task but must keep the pure functions testable in isolation without an Office runtime.
- The `CorpusFixture` internal record used in `KeywordClassifierGoldenTests.cs` can be defined in the same file or in a separate file in the test project. Either approach is acceptable; placing it in the same file reduces file count.
