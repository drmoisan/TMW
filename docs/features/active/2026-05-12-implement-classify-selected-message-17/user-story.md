# implement-classify-selected-message — User Story

- **Issue:** #17
- **Owner:** drmoisan
- **Status:** Active
- **Last Updated:** 2026-05-13

---

## Problem / Why

The task pane currently displays the subject and sender of the selected message but performs no
classification. The core value of TaskMaster is enabling fast triage decisions by classifying
messages and presenting filing recommendations. Without a classification pipeline, the task pane
is an information display only. This feature establishes the full classify-selected-message path:
from the task pane capturing the selected message identity, through the backend normalizing and
classifying it, to the task pane displaying the classification result and offering training actions.

---

## Personas

**Developer — backend implementer.** Familiar with C# and ASP.NET Core minimal APIs. Works in
the `TaskMaster.Application`, `TaskMaster.Classifier`, and `TaskMaster.Infrastructure` layers.
Needs to understand exactly which types to create, where they live, and how to register them in DI.
Cares that architecture boundary rules are not violated and that T1 rigor requirements are met.

**Developer — TypeScript implementer.** Works in `src/taskpane/`. Needs to ship a `fetch`-based
client that is testable without an Office runtime. Cares that pure functions are separated from
the fetch boundary so property tests can run without MSW.

**Developer — test author.** Writes unit tests, property tests, golden tests, and integration
tests for this feature. Needs clear guidance on which test types apply to which files, and where
the `.verified.json` golden baselines live.

**Outlook user / triage clerk.** Uses the Outlook task pane to review incoming mail. Wants to see
a classification label and confidence score immediately after opening a message, and to provide
quick "Confirm" or "Reject" feedback to improve future results.

---

## Story 1 — Classify a Selected Message End-to-End

**As an Outlook user, I want the task pane to show a classification label and confidence score
for the currently selected message, so that I can make a faster triage decision without reading
the full message.**

### Scenario

1. The user opens Outlook and selects an email with subject "URGENT: Action required by Friday."
2. The task pane's `onItemChanged` handler fires.
3. The task pane acquires a bearer token via `Office.context.auth` and calls
   `ClassifierClient.classify` with a `ClassifyRequest` containing the trimmed message ID,
   subject, and optional body preview.
4. `POST /api/classify` receives the request, validates that `messageId` and `subject` are
   present, creates a `MailMessageSnapshot`, and calls `IMessageClassifier.Classify`.
5. `KeywordClassifier` finds "urgent" in the subject (case-insensitive, first-match) and returns
   `ClassificationResult { Label = "HighPriority", Confidence = 0.90 }`.
6. The endpoint returns HTTP 200 with `{ "label": "HighPriority", "confidence": 0.9 }`.
7. `parseClassifyResponse` validates the shape and the task pane renders "HighPriority — 90%
   confidence" with "Confirm" and "Reject" buttons.

### Acceptance criteria covered

- [x] `POST /api/classify` endpoint accepts `{ messageId: string, subject: string, body?: string }`
      and returns `{ label: string, confidence: number }`.
- [x] `IMessageClassifier` interface is in `TaskMaster.Application`, registered via DI.
- [x] `MailMessageSnapshot` record exists in `TaskMaster.Application` with fields: `MessageId`,
      `Subject`, `BodyPreview`.
- [x] `ClassificationResult` record exists in `TaskMaster.Application` with fields: `Label`
      (string) and `Confidence` (double, 0.0–1.0).
- [x] `KeywordClassifier` exists in `TaskMaster.Classifier`, implements `IMessageClassifier`,
      and returns a deterministic result for any input.
- [x] TypeScript `classifier-client.ts` module sends and receives classify API calls via `fetch`.
- [x] Task pane UI shows classification label, confidence percentage, and "Confirm" / "Reject"
      buttons after classification completes.
- [x] `dotnet build TaskMaster.sln` passes with 0 errors and 0 warnings.
- [x] `dotnet test TaskMaster.sln` passes (all tests green, 0 errors, 0 warnings).
- [x] `npm run test` passes (all TypeScript tests green).

---

## Story 2 — Submit Training Feedback After Reviewing a Classification

**As an Outlook user, I want to confirm or reject the classifier's label with a single click, so
that the system can improve its accuracy for future messages.**

### Scenario

1. After Story 1 completes, the user sees "HighPriority — 90%" and clicks "Confirm."
2. The task pane calls `ClassifierClient.recordFeedback` with
   `{ messageId: "<id>", label: "HighPriority", confirmed: true }`.
3. `POST /api/classify/feedback` validates the request, constructs a `TrainingFeedback` value
   object, and calls `ITrainingRepository.RecordAsync`.
4. `InMemoryTrainingRepository` stamps `RecordedAt` with the current UTC time via `TimeProvider`
   and enqueues the entry.
5. The endpoint returns HTTP 204 No Content. The task pane acknowledges the action to the user.

### Alternate flow — Reject

The user clicks "Reject" instead of "Confirm." The call is identical except `confirmed: false`.
The repository records the override for future training signal.

### Acceptance criteria covered

- [x] `POST /api/classify/feedback` endpoint accepts `{ messageId: string, label: string,
      confirmed: boolean }` and returns `204 No Content`.
- [x] `ITrainingRepository` interface and `InMemoryTrainingRepository` exist.

---

## Story 3 — Developer Wires the New Projects Into the Solution

**As a developer, I want the new `TaskMaster.Classifier` and `TaskMaster.Classifier.Tests`
projects to be properly configured in the solution, quality-tiers.yml, and DI, so that the build
pipeline treats them correctly from the first commit.**

### Scenario

1. The developer adds `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj` referencing only
   `TaskMaster.Application`.
2. The developer adds `ClassifierServiceCollectionExtensions.AddClassifierServices()` and calls
   it from `Program.cs` alongside `AddApplicationServices()` and `AddInfrastructureServices()`.
3. The developer adds `ITrainingRepository → InMemoryTrainingRepository` to
   `InfrastructureServiceCollectionExtensions`.
4. The developer registers both projects in `quality-tiers.yml`: `TaskMaster.Classifier` at t1,
   `TaskMaster.Classifier.Tests` at t4.
5. `dotnet build TaskMaster.sln` passes. The tier-classification CI stage reads
   `quality-tiers.yml` and finds both new entries; the stage passes.

### Acceptance criteria covered

- [x] `TaskMaster.Classifier` (source) and `TaskMaster.Classifier.Tests` (tests) added to
      `quality-tiers.yml` at tier t1 and t4 respectively.
- [x] Architecture boundary tests pass (classifier must not reference Outlook PIA or VSTO).

---

## Story 4 — Developer Writes Property Tests for Normalization (T1 Policy)

**As a developer, I want at least one property test per pure function in the classifier and
normalization path, so that the T1 rigor policy is satisfied and edge-case inputs do not produce
invalid outputs.**

### Scenario (.NET — CsCheck)

1. The developer opens `KeywordClassifierTests.cs` in `TaskMaster.Classifier.Tests`.
2. For `MailMessageSnapshot.Create`, the developer writes a CsCheck property test that generates
   arbitrary non-empty string pairs and asserts that the returned snapshot has trimmed
   `MessageId` and `Subject`.
3. For `KeywordClassifier.Classify`, the developer writes a property test that generates arbitrary
   valid snapshots and asserts that `result.Confidence` is always in `[0.0, 1.0]`.
4. `dotnet test` runs the property tests. CsCheck generates hundreds of random inputs; all pass.

### Scenario (TypeScript — fast-check)

1. The developer opens `src/taskpane/classifier-client.test.ts`.
2. For `normalizeClassifyRequest`, the developer writes a `test.prop` assertion covering
   arbitrary string inputs: output `messageId` and `subject` equal the trimmed inputs; output
   `body` is `null` when `body` is `undefined`, and is `body.trim()` otherwise.
3. For `parseClassifyResponse`, the developer writes a `test.prop` assertion: any object with
   `label: string` and `confidence: number` round-trips correctly; any other shape throws
   `TypeError`.
4. `npm run test` passes with all property tests green.

### Acceptance criteria covered

- [x] At least one property test per pure function in the classifier/normalization path
      (T1 policy: CsCheck for .NET; `test.prop` for TypeScript).
- [x] The TypeScript classifier-client is tested with at least one `test.prop` property test
      covering normalization edge cases.

---

## Story 5 — Developer Runs Golden Tests Against the Keyword Corpus

**As a developer, I want golden tests to verify that `KeywordClassifier` produces the expected
output for each corpus fixture, so that any future change to the keyword rules immediately
produces a failing test before reaching CI.**

### Scenario

1. The developer creates three corpus fixtures in `corpus/classifiers/keyword/`:
   - `urgent-meeting-001.json` — subject contains "URGENT: Action required by Friday"
   - `newsletter-promo-001.json` — subject contains "Your weekly newsletter — unsubscribe"
   - `team-update-001.json` — subject contains "Team update for Q3 planning"
2. The developer runs the golden tests for the first time. Verify creates three
   `.received.json` files alongside the test. The developer inspects each and promotes them to
   `.verified.json` by running `dotnet verify accept` (or by manually renaming).
3. The developer commits the three `.verified.json` files. From this point, any regression in
   `KeywordClassifier`'s output on the corpus produces a diff and fails CI.
4. On subsequent runs, `dotnet test` compares the current output to the committed baselines; all
   three pass.

### Acceptance criteria covered

- [x] Golden test in `TaskMaster.Classifier.Tests` verifies `KeywordClassifier` output on a
      fixed corpus slice (at least 3 representative messages in
      `corpus/classifiers/keyword/`).

---

## Story 6 — CI Enforces Mutation Score >= 75% on the First T1 Module

**As a developer, I want the pre-merge pipeline to run Stryker.NET against
`TaskMaster.Classifier` and break the build when mutation score falls below 75%, so that weak
tests are caught before they reach the main branch.**

### Scenario

1. The developer adds `tests/TaskMaster.Classifier.Tests/stryker-config.json` with
   `"break": 75` targeting `TaskMaster.Classifier.csproj`.
2. The developer replaces the Stage 8 stub in `pre-merge-pipeline.yml` with a real
   `dotnet stryker` invocation using that config file.
3. Stage 9 is extended to run `TaskMaster.Classifier.Tests` alongside
   `TaskMaster.PlaceholderGolden.Tests`.
4. On a PR with adequate tests, Stryker reports a mutation score above 75% and Stage 8 passes.
5. If a future PR removes or weakens a test, Stryker's score drops below 75%, the stage exits
   non-zero, and the PR is blocked.

### Acceptance criteria covered

- [x] `stryker-config.json` placed in `TaskMaster.Classifier.Tests` project directory targeting
      `TaskMaster.Classifier.csproj` with `break: 75`.

---

## Story 7 — API Rejects Unauthenticated Classify Requests

**As a developer, I want `POST /api/classify` and `POST /api/classify/feedback` to return HTTP
401 for unauthenticated requests, so that the classification pipeline cannot be called without a
valid bearer token.**

### Scenario

1. A developer writes an integration test in `ClassifyEndpointTests.cs` that sends a POST to
   `/api/classify` using `CustomWebApplicationFactory` but omits the bearer token.
2. The test asserts `HttpStatusCode.Unauthorized`.
3. A second test sends a valid authenticated request (using `TestAuthHandler`) with a properly
   formed body and asserts HTTP 200 with a JSON body.
4. A third test sends an authenticated request with an empty `subject` and asserts HTTP 422.
5. All three tests pass under `dotnet test`.

### Acceptance criteria covered

(This story covers test conditions rather than a discrete acceptance criterion checkbox, but
satisfies the test conditions documented in `issue.md` under "Test Conditions to Consider":
API: unauthenticated POST /api/classify returns 401; API: valid authenticated POST /api/classify
returns 200 with JSON body.)

---

## Story 8 — Developer Confirms Architecture Boundary Is Enforced

**As a developer, I want an architecture test that asserts `TaskMaster.Classifier` does not
depend on `TaskMaster.Infrastructure`, so that the T1 classifier engine cannot inadvertently
acquire adapter-layer dependencies.**

### Scenario

1. The developer adds a `ProjectReference` for `TaskMaster.Classifier` to
   `TaskMaster.ArchitectureTests.csproj`.
2. The developer adds a `[Fact]` named
   `ClassifierProjectDoesNotDependOnInfrastructure` using `NetArchTest.Rules`.
3. The developer runs `dotnet test tests/TaskMaster.ArchitectureTests`. The new fact passes
   because `TaskMaster.Classifier` references only `TaskMaster.Application`.
4. If a future change adds a reference from `TaskMaster.Classifier` to `TaskMaster.Infrastructure`,
   the fact fails and blocks the PR.

The existing `NoComArchitectureTests` block that loads all `TaskMaster.*` assemblies
automatically covers `TaskMaster.Classifier` for COM/VSTO/PIA ban assertions without any
additional fact.

### Acceptance criteria covered

- [x] Architecture boundary tests pass (classifier must not reference Outlook PIA or VSTO).

---

## Acceptance Criteria Traceability

The following table maps all 18 acceptance criteria from `issue.md` to the user stories above.
All 18 are within scope for this feature.

| # | Acceptance Criterion (from issue.md) | Story |
|---|--------------------------------------|-------|
| 1 | `POST /api/classify` accepts and returns correct shapes | Story 1 |
| 2 | `POST /api/classify/feedback` accepts and returns 204 | Story 2 |
| 3 | `IMessageClassifier` in Application, registered via DI | Story 1, Story 3 |
| 4 | `ClassifyMessageCommand` and handler exist, wire through command bus | Note: design decision superseded — see below |
| 5 | `MailMessageSnapshot` record in Application with correct fields | Story 1 |
| 6 | `ClassificationResult` record in Application with correct fields | Story 1 |
| 7 | `KeywordClassifier` in Infrastructure, implements interface, deterministic | Story 1 |
| 8 | `ITrainingRepository` and `InMemoryTrainingRepository` exist | Story 2 |
| 9 | TypeScript `classifier-client.ts` sends and receives classify API calls | Story 1 |
| 10 | Task pane UI shows label, confidence, Confirm/Reject buttons | Story 1 |
| 11 | At least one property test per pure function (.NET CsCheck; TS test.prop) | Story 4 |
| 12 | Golden test in `TaskMaster.Classifier.Tests` on 3 corpus fixtures | Story 5 |
| 13 | `TaskMaster.Classifier` (t1) and `TaskMaster.Classifier.Tests` (t4) in quality-tiers.yml | Story 3 |
| 14 | `stryker-config.json` in Classifier.Tests targeting Classifier with break: 75 | Story 6 |
| 15 | `dotnet test TaskMaster.sln` passes | Story 1, Story 3 |
| 16 | `npm run test` passes | Story 1, Story 4 |
| 17 | `dotnet build TaskMaster.sln` passes | Story 3 |
| 18 | Architecture boundary tests pass | Story 8 |
| 19 | TypeScript `test.prop` property test covering normalization edge cases | Story 4 |

**Note on AC #4** (`ClassifyMessageCommand` and handler via command bus): The research document
(section 1) concluded that routing a result-bearing, stateless operation through the command bus
is architecturally unnecessary and would require widening `ICommandBus` for a single use case.
The accepted design (Option C) calls `IMessageClassifier` directly from the endpoint. AC #4 as
written in `issue.md` reflects an earlier design intent and is superseded by the research
recommendation. The constraint note in `issue.md` ("The command bus currently returns Task (no
result)...") acknowledges this explicitly. The command bus is not changed by this feature.

---

## Non-Goals

- Machine learning or probabilistic classification. `KeywordClassifier` is a deterministic
  placeholder only.
- Persistent storage of training feedback across process restarts. `InMemoryTrainingRepository`
  is append-only and process-scoped.
- A `ClassifyMessageCommand` type or widening of `ICommandBus`. Classification routes directly
  through `IMessageClassifier`.
- Body-text keyword matching (body text may be used in future iterations; subject is the sole
  classifier input for this feature).
- Any user-facing model accuracy metrics or training administration UI.
- Internationalization or locale-aware keyword matching.
