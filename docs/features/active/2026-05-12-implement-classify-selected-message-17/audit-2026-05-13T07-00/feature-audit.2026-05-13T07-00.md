# Feature Audit — Issue #17: Implement Classify Selected Message

- **Feature:** 2026-05-12-implement-classify-selected-message-17
- **Audit timestamp:** 2026-05-13T07-00
- **Branch:** feature/17-implement-classify-selected-message
- **Merge base:** ee1709b6e8eb8c346335885184d0a76337b5e3ec
- **Auditor:** Feature Review Agent (claude-sonnet-4-6)
- **Work mode:** full-feature
- **AC sources:** `spec.md` and `user-story.md`

---

## Overall Verdict

**PASS with notes**

All 19 acceptance criteria from the authoritative AC sources (`spec.md` / `user-story.md`) are satisfied. Two discrepancies exist between `issue.md` and `user-story.md` regarding namespace placement (`TaskMaster.Domain` vs `TaskMaster.Application`) and `KeywordClassifier` location (`TaskMaster.Infrastructure` vs `TaskMaster.Classifier`). The implementation follows `spec.md` and `user-story.md`, which are the authoritative AC sources for `full-feature` work mode. These discrepancies are noted below.

---

## AC Source Disambiguation

`issue.md` contains two AC items that differ from `user-story.md` and `spec.md`:

- **issue.md AC #5**: "`MailMessageSnapshot` record exists in `TaskMaster.Domain`…" — **`user-story.md` AC (Story 1)** and `spec.md` both specify `TaskMaster.Application`. The implementation uses `TaskMaster.Application`. The authoritative source for `full-feature` is `user-story.md` + `spec.md`; `issue.md` contains a stale reference to `TaskMaster.Domain`.

- **issue.md AC #6**: "`ClassificationResult` record exists in `TaskMaster.Domain`…" — same discrepancy, same resolution. `user-story.md` and `spec.md` specify `TaskMaster.Application`.

- **issue.md AC #7**: "`KeywordClassifier` exists in `TaskMaster.Infrastructure`…" — **`user-story.md` AC (Story 1)** specifies `TaskMaster.Classifier`. `spec.md` specifies `TaskMaster.Classifier`. The implementation uses `TaskMaster.Classifier`. This is consistent with `issue.md` AC #13 (which references `TaskMaster.Classifier` project) and with the Constraints note in `issue.md` itself.

Evaluation below follows `user-story.md` and `spec.md` as the authoritative AC sources.

---

## Acceptance Criteria Evaluation Table

The 19 AC items are numbered following the traceability table in `user-story.md`. Items 1–19 correspond to the AC checkboxes in `user-story.md` Stories 1–8 and the traceability table.

| # | AC Text (from user-story.md / spec.md) | Evidence | Verdict |
|---|---|---|---|
| 1 | `POST /api/classify` accepts `{ messageId, subject, body? }` and returns `{ label, confidence }` | `Program.cs` lines 47–62 implement the endpoint. `ClassifyEndpointTests.cs` verifies 200 with label+confidence. Evidence: `dotnet-coverage.md` (19 Api.Tests passed). | PASS |
| 2 | `POST /api/classify/feedback` accepts `{ messageId, label, confirmed }` and returns 204 No Content | `Program.cs` lines 64–79. `ClassifyFeedbackEndpointTests.cs` asserts `HttpStatusCode.NoContent`. | PASS |
| 3 | `IMessageClassifier` interface is in `TaskMaster.Application`, registered via DI | `IMessageClassifier.cs` in `TaskMaster.Application`. `ClassifierServiceCollectionExtensions.AddClassifierServices()` registers `IMessageClassifier → KeywordClassifier` as Singleton; called from `Program.cs`. | PASS |
| 4 | `IMessageClassifier` is called directly from the API endpoint handler (not through command bus) | `Program.cs` `/api/classify` lambda injects `IMessageClassifier classifier` directly. No command bus involved. | PASS |
| 5 | `MailMessageSnapshot` record exists in `TaskMaster.Application` with fields: `MessageId`, `Subject`, `BodyPreview` | `MailMessageSnapshot.cs` in `src/TaskMaster.Application/`. Record has positional parameters `MessageId`, `Subject`, `BodyPreview?`. | PASS |
| 6 | `ClassificationResult` record exists in `TaskMaster.Application` with fields: `Label` (string), `Confidence` (double, 0.0–1.0) | `ClassificationResult.cs` in `src/TaskMaster.Application/`. Record has `Label` (string) and `Confidence` (double) with range guard [0.0, 1.0] via init property. | PASS |
| 7 | `KeywordClassifier` exists in `TaskMaster.Classifier`, implements `IMessageClassifier`, returns deterministic result | `KeywordClassifier.cs` in `src/TaskMaster.Classifier/`. Implements `IMessageClassifier`. Rule table is static; classifier is deterministic. | PASS |
| 8 | `ITrainingRepository` interface and `InMemoryTrainingRepository` exist | `ITrainingRepository.cs` in `TaskMaster.Application`. `InMemoryTrainingRepository.cs` in `TaskMaster.Infrastructure` as `internal sealed class`. | PASS |
| 9 | TypeScript `classifier-client.ts` module sends and receives classify API calls via `fetch` | `classifier-client.ts` present in `src/taskpane/`. `ClassifierClient.classify` and `recordFeedback` use `fetch`. | PASS |
| 10 | Task pane UI shows classification label, confidence percentage, and "Confirm" / "Reject" buttons after classification completes | `taskpane.html` contains `#classification-result`, `#classify-btn`, `#confirm-btn`, `#reject-btn`. `taskpane.ts` exports `renderClassificationResult` which writes label + pct to `#classification-result` and removes `disabled` from confirm/reject buttons. `taskpane.test.ts` verifies "HighPriority (90%)" rendered and buttons enabled. | PASS |
| 11 | At least one property test per pure function (.NET CsCheck; TypeScript `test.prop`) | .NET: `Classify_AnyValidSnapshot_ConfidenceInRange` and `Classify_TrimmedVsUntrimmedSubject_ProduceIdenticalResults` in `KeywordClassifierTests.cs`. TypeScript: two `test.prop` assertions in `classifier-client.test.ts`. | PASS |
| 12 | Golden test in `TaskMaster.Classifier.Tests` verifies `KeywordClassifier` output on a fixed corpus slice (at least 3 representative messages in `corpus/classifiers/keyword/`) | `KeywordClassifierGoldenTests.cs` drives `[Theory]` against `urgent-meeting-001.json`, `newsletter-promo-001.json`, `team-update-001.json`. Three `.verified.json` files are committed. Corpus fixtures present at `corpus/classifiers/keyword/`. | PASS |
| 13 | `TaskMaster.Classifier` (t1) and `TaskMaster.Classifier.Tests` (t4) added to `quality-tiers.yml` | `quality-tiers.yml` contains both entries with tier and rationale. | PASS |
| 14 | `stryker-config.json` placed in `TaskMaster.Classifier.Tests` targeting `TaskMaster.Classifier.csproj` with `break: 75` | `tests/TaskMaster.Classifier.Tests/stryker-config.json` present. `"break": 75` confirmed in thresholds. `"project": "TaskMaster.Classifier.csproj"`. | PASS |
| 15 | `dotnet test TaskMaster.sln` passes (all tests green) | Evidence: `dotnet-coverage.md` (EXIT_CODE: 0, 68/68 tests passed). | PASS |
| 16 | `npm run test` passes (all TypeScript tests green) | Evidence: `ts-coverage.md` (EXIT_CODE: 0, 27/27 tests passed). | PASS |
| 17 | `dotnet build TaskMaster.sln` passes with 0 errors and 0 warnings | Evidence: `dotnet-build.md` (EXIT_CODE: 0, 0 warnings, 0 errors, 11 projects). | PASS |
| 18 | Architecture boundary tests pass (classifier must not reference Outlook PIA or VSTO) | Evidence: `dotnet-arch.md` (EXIT_CODE: 0, 7/7 passed). `ClassifierProjectDoesNotDependOnInfrastructure` fact passes. `TaskMaster.Classifier.csproj` references only `TaskMaster.Application`. | PASS |
| 19 | TypeScript `test.prop` property test covering normalization edge cases | `classifier-client.test.ts` line 151–164: `test.prop([fc.string(), fc.string(), fc.option(fc.string(), { nil: undefined })])` covers `normalizeClassifyRequest`. | PASS |

---

## Story-Level Verification

### Story 1 — Classify a Selected Message End-to-End

Scenario steps verified:
- `ClassifierClient.classify` sends `POST /api/classify` with trimmed fields (covered by `normalizeClassifyRequest` tests).
- Backend creates `MailMessageSnapshot` and calls `IMessageClassifier.Classify`.
- `KeywordClassifier` finds "urgent" (case-insensitive) and returns `{ Label = "HighPriority", Confidence = 0.90 }`.
- Endpoint returns HTTP 200 with `{ label, confidence }`.
- `parseClassifyResponse` validates shape; `renderClassificationResult` renders label + percentage.

**Story 1 Verdict: PASS**

### Story 2 — Submit Training Feedback

- `ClassifierClient.recordFeedback` sends `POST /api/classify/feedback`.
- Backend constructs `TrainingFeedback` and calls `ITrainingRepository.RecordAsync`.
- `InMemoryTrainingRepository` stamps `RecordedAt` via `TimeProvider` and enqueues.
- Endpoint returns HTTP 204.

**Story 2 Verdict: PASS**

### Story 3 — Developer Wires Projects Into Solution

- `TaskMaster.Classifier.csproj` references only `TaskMaster.Application`.
- `ClassifierServiceCollectionExtensions.AddClassifierServices()` registered in `Program.cs`.
- `ITrainingRepository → InMemoryTrainingRepository` registered in `InfrastructureServiceCollectionExtensions`.
- Both projects in `quality-tiers.yml`.
- `dotnet build TaskMaster.sln` passes.

**Story 3 Verdict: PASS**

### Story 4 — Property Tests for Normalization (T1 Policy)

- .NET: Two CsCheck property tests in `KeywordClassifierTests.cs` for confidence range and trimmed-field invariants.
- TypeScript: Two `test.prop` assertions in `classifier-client.test.ts` for `normalizeClassifyRequest` and `parseClassifyResponse`.

**Story 4 Verdict: PASS**

### Story 5 — Golden Tests Against Keyword Corpus

- Three corpus fixtures present in `corpus/classifiers/keyword/`.
- `KeywordClassifierGoldenTests.cs` runs `[Theory]` against all three; `.verified.json` baselines committed.
- Evidence: 14/14 `TaskMaster.Classifier.Tests` tests passed.

**Story 5 Verdict: PASS**

### Story 6 — Stryker.NET Configuration

- `stryker-config.json` present with `break: 75`.
- `pre-merge-pipeline.yml` Stage 8 replaced with real `dotnet stryker` invocation.

**Story 6 Verdict: PASS**

### Story 7 — API Rejects Unauthenticated Requests

- `ClassifyEndpointTests.PostClassify_WithoutAuthorizationHeader_Returns401` asserts 401 for unauthenticated classify.
- `ClassifyFeedbackEndpointTests.PostClassifyFeedback_WithoutAuthorizationHeader_Returns401` asserts 401 for unauthenticated feedback.
- `ClassifyEndpointTests.PostClassify_AuthenticatedWithEmptySubject_Returns422` asserts 422 for empty subject.
- All three API tests pass (19/19 `TaskMaster.Api.Tests`).

**Story 7 Verdict: PASS**

### Story 8 — Architecture Boundary Enforcement

- `ClassifierProjectDoesNotDependOnInfrastructure` fact in `LayerBoundaryTests.cs` passes.
- `TaskMaster.Classifier.csproj` lists only `TaskMaster.Application` as a project reference.
- Architecture tests: 7/7 passed.

**Story 8 Verdict: PASS**

---

## Non-Goals Verified (Not Implemented)

The following items are correctly absent from the implementation:

| Non-Goal | Verified Absent |
|---|---|
| ML/probabilistic classification | Only deterministic keyword rules in `KeywordClassifier`. |
| Persistent training feedback (across restarts) | `InMemoryTrainingRepository` is process-scoped only. |
| `ClassifyMessageCommand` or widening of `ICommandBus` | No command bus changes. `IMessageClassifier` called directly. |
| Body-text keyword matching (per non-goals list) | **Note:** Body-preview matching IS present in implementation (see CR-001 in code review). This diverges from the non-goals list, though it is tested and does not break any AC. |
| User-facing accuracy metrics or training admin UI | Not present. |
| Internationalization or locale-aware matching | Not present. |

---

## issue.md AC Discrepancies (Informational)

The following items in `issue.md` contain stale or inconsistent references not present in the authoritative AC sources (`user-story.md` and `spec.md`). They are documented here for completeness but do not affect the PASS verdict.

| issue.md AC item | Discrepancy | Resolution |
|---|---|---|
| AC #5: `MailMessageSnapshot` in `TaskMaster.Domain` | `user-story.md` and `spec.md` specify `TaskMaster.Application` | Implementation follows spec (PASS) |
| AC #6: `ClassificationResult` in `TaskMaster.Domain` | Same as above | Implementation follows spec (PASS) |
| AC #7: `KeywordClassifier` in `TaskMaster.Infrastructure` | `user-story.md` and `spec.md` specify `TaskMaster.Classifier` | Implementation follows spec (PASS) |

---

## AC Check-Off Status

Per the acceptance-criteria-tracking skill (full-feature mode, AC sources: spec.md + user-story.md):

All 19 acceptance criteria evaluated as PASS. The following checkboxes in `user-story.md` are marked as delivered and verified:

- Story 1 (5 checkboxes): all PASS
- Story 2 (2 checkboxes): all PASS
- Story 3 (2 checkboxes): all PASS
- Story 4 (2 checkboxes): all PASS
- Story 5 (1 checkbox): PASS
- Story 6 (1 checkbox): PASS
- Story 7 (no discrete AC checkbox; covered by test conditions): PASS
- Story 8 (1 checkbox): PASS

### Acceptance Criteria Status

- Source: `user-story.md`, `spec.md`
- Total AC items: 19
- Checked off (delivered): 19
- Remaining (unchecked): 0
- Items remaining: none
