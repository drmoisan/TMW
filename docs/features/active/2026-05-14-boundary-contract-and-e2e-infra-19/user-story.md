# `boundary-contract-and-e2e-infra` — User Story

- Issue: #19
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-14T21-52

## Story Statement

- As a backend engineer changing `TaskMaster.Api`, I want a contract gate that
  diffs the emitted OpenAPI document against the merge-base snapshot, so that a
  breaking wire change cannot merge without an explicit API version bump.
- As a TypeScript developer consuming the API, I want the client's wire types
  generated from the committed OpenAPI document and hand-written types blocked
  in the API client folder, so that the client cannot silently drift from the
  backend.
- As a reviewer, I want a Playwright smoke suite that exercises the
  host-to-service path against a test M365 tenant on an opt-in CI job, so that
  the downstream filing workflow (Prompt E2) has the E2E lane it depends on.

## Problem / Why

The host (Outlook task pane / commands TypeScript) and the backend service
(`TaskMaster.Api`) communicate over an HTTP contract, but that contract is not
gated. The TypeScript API client (`src/taskpane/classifier-client.ts`) carries
hand-written wire types that can silently drift from the backend. There is no
OpenAPI snapshot committed to the repository, the PR-pipeline `stage-6-contract`
job is a no-op placeholder, and there is no end-to-end (E2E) lane. Downstream
work — notably the filing workflow (Prompt E2) — depends on contract tests and a
Playwright smoke suite that do not yet exist. The boundary contract gates and
the E2E lane must be established before that workflow exercises both.

Prompt C1 (emit the OpenAPI document) has not produced `artifacts/openapi/current.json`.
Per user decision, C1 is folded into this work: `TaskMaster.Api` already calls
`AddOpenApi()` / `MapOpenApi()`, so the document can be emitted and snapshotted
as part of this feature.

## Personas & Scenarios

- Persona: Backend engineer on `TaskMaster.Api`
  - Who they are: owns the HTTP endpoints and their request/response records.
  - What they care about: shipping endpoint changes without breaking the
    TypeScript host unexpectedly.
  - Their constraints: net10.0 blocks the prior NSwag emission path; the
    OpenAPI document must be emitted at build time and committed.
  - Their goals and frustrations: wants a clear signal when a change is
    breaking; today nothing flags wire drift until the host fails at runtime.
  - Their context and motivations: the contract gate must be in place before the
    Prompt E2 filing workflow exercises it.

- Persona: TypeScript developer on the Outlook task pane
  - Who they are: maintains `src/taskpane/classifier-client.ts` and other host
    code that calls the backend.
  - What they care about: client types that match the live backend contract.
  - Their constraints: generated output must pass the existing TypeScript
    toolchain gates (format, lint, type-check) and the 500-line file size limit;
    `openapi-fetch` uses native fetch, so an existing fetch polyfill must cover
    the supported browser targets.
  - Their goals and frustrations: wants to stop hand-maintaining wire
    interfaces that drift from the backend.
  - Their context and motivations: the migration to generated types should be
    low-risk — keep the `ClassifierClient` wrapper class, replace only the type
    declarations now.

- Persona: Reviewer / release gatekeeper
  - Who they are: approves PRs and merges to `main`.
  - What they care about: that contract and E2E gates actually run and fail
    closed.
  - Their constraints: E2E secrets are CI-only and must never be committed; the
    E2E job must fail (not silently skip) when secrets are absent.
  - Their goals and frustrations: wants a real `stage-6-contract`, not a no-op,
    and an E2E lane that runs at pre-merge.
  - Their context and motivations: the downstream filing workflow depends on
    both gates existing and being trustworthy.

- Scenario: Breaking endpoint change without a version bump
  - Who is acting: a backend engineer.
  - What triggered the action: the engineer changes a controller signature, for
    example renaming a field on `ClassifyResponse`.
  - Steps they take: they push the branch and open a PR.
  - Obstacles or decisions: `stage-6-contract` emits the PR-head OpenAPI
    document, extracts the merge-base baseline, compares `info.version`, finds it
    unchanged, and runs `oasdiff breaking`. The breaking change is detected.
  - Outcome they expect: the PR fails with a specific error identifying the
    offending field as a GitHub Actions annotation on the diff. To proceed, the
    engineer bumps `<Version>` in `TaskMaster.Api.csproj`, which changes
    `info.version` and causes the contract step to treat the change as a
    permitted breaking change.

- Scenario: Adding a hand-written type to the API client folder
  - Who is acting: a TypeScript developer.
  - What triggered the action: the developer adds a hand-written `interface` to
    a file under `src/api-client/`.
  - Steps they take: they run the lint stage locally or push to CI.
  - Obstacles or decisions: the folder-scoped `no-restricted-syntax` ESLint rule
    flags the `TSInterfaceDeclaration` with a message directing the developer to
    regenerate types from the OpenAPI document.
  - Outcome they expect: the lint stage fails; the developer moves the type into
    the backend contract and regenerates `src/api-client/v1.ts` instead.

- Scenario: Running the E2E smoke suite on an opt-in PR
  - Who is acting: a developer changing API or E2E-relevant code.
  - What triggered the action: the developer applies the `e2e:run` label to the
    PR.
  - Steps they take: CI runs the label-gated `stage-e2e-smoke` job on
    `ubuntu-latest`; the auth setup obtains a token via the client-credentials
    flow using the CI secrets.
  - Obstacles or decisions: if any required secret is missing, the setup throws
    and the job fails closed rather than skipping. When the label is absent, the
    job skips entirely.
  - Outcome they expect: with the label applied and secrets present, the smoke
    suite runs against the test tenant and passes — `GET /health`,
    `POST /api/classify`, and `POST /api/classify/feedback` all behave as
    specified.

## Acceptance Criteria

- [x] `artifacts/openapi/current.json` is emitted from `TaskMaster.Api` and committed; an emit script regenerates it deterministically.
- [x] The TypeScript API client is generated from the OpenAPI document via `openapi-typescript`; no hand-written wire types remain in the API client folder.
- [x] An ESLint rule scoped to the API client folder fails the lint stage when hand-written types are added there.
- [x] `oasdiff` runs in the PR pipeline against the previous merge-base OpenAPI document; a breaking change blocks the PR unless the API version is bumped, and the failure message points to the offending field.
- [x] Spectral lints the OpenAPI document with the three named rules enabled.
- [x] Playwright is installed; `tests/e2e/smoke.spec.ts` exists and is wired into the pre-merge pipeline behind the `e2e:run` label using a service-principal auth flow.
- [x] PR-pipeline `stage-6-contract` performs real oasdiff + Spectral checks (no longer a no-op); the pre-merge pipeline gains an E2E smoke stage.
- [x] Editing a controller signature without bumping the API version causes the PR to fail with a specific error identifying the offending field.
- [x] The Playwright smoke job runs successfully against the test tenant when the `e2e:run` label is applied.

## Non-Goals

- A full rewrite of `ClassifierClient` onto an `openapi-fetch` `createClient` is
  out of scope for issue #19; only the hand-written type declarations are
  migrated to generated types now.
- Dropping IE 11 from `browserslist` is out of scope; this feature instead
  verifies that an existing fetch polyfill covers `openapi-fetch`'s native-fetch
  usage.
- The downstream filing workflow (Prompt E2) is not implemented here; this
  feature only establishes the contract gates and E2E lane it depends on.
- Renumbering existing CI stages is out of scope; the `stage-10-e2e` numbering
  gap is disregarded per user direction.
- Expanding the E2E suite beyond the initial `/health`, `/api/classify`, and
  `/api/classify/feedback` smoke checks is out of scope.
- Adding new C# projects or new `package.json` projects is out of scope;
  `src/api-client/` and `tests/e2e/` fall under existing project entries.
