# implement-classify-selected-message (Issue #17)

- Date captured: 2026-05-13
- Author: Dan Moisan
- Status: Active
- Issue: #17
- Issue URL: https://github.com/drmoisan/TMW/issues/17
- Last Updated: 2026-05-13
- Work Mode: full-feature

## Problem / Why

The task pane currently displays the subject and sender of the selected message but performs no
classification. The core value of TaskMaster is enabling fast triage decisions by classifying
messages and presenting filing recommendations. Without a classify pipeline, the task pane is an
information display only. This feature establishes the full classify-selected-message path: from
the task pane capturing the selected message identity, through the backend normalizing and
classifying it, to the task pane displaying the classification result and offering training actions.

## Proposed Behavior

1. The task pane sends the selected message's internet message ID and subject to the backend via
   a POST `/api/classify` request.
2. The backend normalizes the message fields into a `MailMessageSnapshot` value object.
3. The backend passes the snapshot to `IMessageClassifier`, which returns a `ClassificationResult`
   (label + confidence score).
4. The backend responds with `ClassificationResult` in JSON.
5. The task pane displays the label and confidence and offers "Confirm" and "Reject" training
   actions.
6. The task pane sends a POST `/api/classify/feedback` request when the user confirms or rejects
   the classification.
7. The backend records the feedback via `ITrainingRepository`, updating the service-side model
   state so future classifications can use this signal.

## Acceptance Criteria

- [ ] `POST /api/classify` endpoint accepts `{ messageId: string, subject: string, body?: string }`
      and returns `{ label: string, confidence: number }`.
- [ ] `POST /api/classify/feedback` endpoint accepts `{ messageId: string, label: string,
      confirmed: boolean }` and returns `204 No Content`.
- [ ] `IMessageClassifier` interface is in `TaskMaster.Application`, registered via DI.
- [ ] `IMessageClassifier` is called directly from the API endpoint handler (not routed
      through the command bus); this is a stateless query that returns a result.
- [ ] `MailMessageSnapshot` record exists in `TaskMaster.Domain` with fields: `MessageId`,
      `Subject`, `BodyPreview`.
- [ ] `ClassificationResult` record exists in `TaskMaster.Domain` with fields: `Label`
      (string) and `Confidence` (double, 0.0–1.0).
- [ ] `KeywordClassifier` (placeholder) exists in `TaskMaster.Infrastructure`, implements
      `IMessageClassifier`, and returns a deterministic result for any input.
- [ ] `ITrainingRepository` interface and `InMemoryTrainingRepository` exist.
- [ ] TypeScript `classifier-client.ts` module in `src/taskpane/` sends and receives
      classify API calls via `fetch`.
- [ ] Task pane UI shows classification label, confidence percentage, and "Confirm" /
      "Reject" buttons after classification completes.
- [ ] At least one property test per pure function in the classifier/normalization path
      (T1 policy: CsCheck for .NET; `test.prop` for TypeScript).
- [ ] Golden test in `TaskMaster.Classifier.Tests` verifies `KeywordClassifier` output on
      a fixed corpus slice (at least 3 representative messages in
      `corpus/classifiers/keyword/`).
- [ ] `TaskMaster.Classifier` (source) and `TaskMaster.Classifier.Tests` (tests) added to
      `quality-tiers.yml` at tier t1 and t4 respectively.
- [ ] `stryker-config.json` placed in `TaskMaster.Classifier.Tests` project directory
      targeting `TaskMaster.Classifier.csproj` with `break: 75`.
- [ ] `dotnet test TaskMaster.sln` passes (all tests green, 0 errors, 0 warnings).
- [ ] `npm run test` passes (all TypeScript tests green).
- [ ] `dotnet build TaskMaster.sln` passes with 0 errors and 0 warnings.
- [ ] Architecture boundary tests pass (classifier must not reference Outlook PIA or VSTO).
- [ ] The TypeScript classifier-client is tested with at least one `test.prop` property test
      covering normalization edge cases.

## Constraints & Risks

- `KeywordClassifier` is a deterministic placeholder — no ML model. A later prompt
  (SpamBayes engine) replaces it behind the `IMessageClassifier` interface.
- Golden tests require committed `.verified.json` files in the test project and corpus JSON
  fixtures in `corpus/classifiers/keyword/`.
- `TaskMaster.Classifier` is T1; it must not reference Outlook PIA, VSTO, or any COM type.
- `POST /api/classify` requires authentication (`RequireAuthorization()`); API tests use
  `TestAuthHandler` from `TaskMaster.Api.Tests`.
- `MailMessageSnapshot.BodyPreview` is optional; normalization must handle null/empty body.
- All new .NET code must pass `dotnet csharpier check .` and zero analyzer warnings.
- Coverage floor: line >= 85%, branch >= 75% across all tiers (T1–T4).
- The command bus currently returns `Task` (no result). `ClassifyMessageCommand` needs a
  result; the command bus interface must be extended or a query pattern introduced.

## Test Conditions to Consider

- [ ] Property: normalization of any string subject produces a non-null, trimmed snapshot
- [ ] Property: classifier confidence is always in [0.0, 1.0] for any valid input
- [ ] Golden: `KeywordClassifier` returns expected label for each corpus fixture
- [ ] Unit: `ClassifyMessageCommandHandler` dispatches to `IMessageClassifier` and returns result
- [ ] Unit: `TrainCommandHandler` calls `ITrainingRepository.RecordAsync`
- [ ] Edge: empty subject, null body, very long subject (>500 chars)
- [ ] Edge: Unicode subject (CJK, emoji, RTL text)
- [ ] API: unauthenticated POST /api/classify returns 401
- [ ] API: valid authenticated POST /api/classify returns 200 with JSON body
- [ ] TypeScript: classifier-client returns typed result on 200 response
- [ ] TypeScript: classifier-client throws on non-200 response
