# Atomic Implementation Plan — boundary-contract-and-e2e-infra (Issue #19)

- **Issue:** #19
- **Feature folder:** `docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/`
- **Work Mode:** full-feature
- **Plan file:** `docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/plan.2026-05-14T21-52.md`
- **Last Updated:** 2026-05-14T21-52
- **Status:** Draft
- **Version:** 1.0
- **Source documents:** `issue.md`, `spec.md`, `user-story.md`, `artifacts/research/2026-05-14-prompt-e1-boundary-contract-and-e2e-infra.md`

## Required References

All work must comply with the repository policy files; their content is not
duplicated here:

- `.claude/rules/general-code-change.md`
- `.claude/rules/general-unit-test.md`
- `.claude/rules/quality-tiers.md`
- `.claude/rules/tonality.md`
- `.claude/rules/csharp.md`
- `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`
- `.claude/rules/architecture-boundaries.md`

## Evidence Location Invariant

All evidence artifacts produced by this plan are written under
`docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/evidence/<kind>/`
per `.claude/skills/evidence-and-timestamp-conventions/SKILL.md`. The
`<FEATURE>` token below resolves to that feature folder. Writing to
`artifacts/baselines/`, `artifacts/qa/`, `artifacts/coverage/`, or any other
non-canonical path is a policy violation. Note: `artifacts/openapi/current.json`
is a product artifact (the committed OpenAPI contract snapshot), not evidence;
it is intentionally written to `artifacts/openapi/` and is not subject to the
evidence-path rule.

## Languages In Scope

- **C#** (`TaskMaster.Api`, `Program.cs`, `TaskMaster.Api.csproj`,
  `Directory.Packages.props`) — coverage policy applies; full toolchain loop:
  format (CSharpier) → lint (.NET analyzers via build) → type-check (nullable via
  build) → architecture (NetArchTest) → unit tests (xUnit + coverage) →
  contract → integration.
- **TypeScript** (`src/api-client/`, `src/taskpane/classifier-client.ts`,
  `eslint.config.mjs`, `package.json`, `tests/e2e/`, `playwright.config.ts`) —
  coverage policy applies; full toolchain loop: format (Prettier) → lint
  (ESLint) → type-check (tsc) → unit tests (Vitest + coverage).
- **YAML / CI** (`.github/actions/contract/action.yml`,
  `.github/workflows/pr-pipeline.yml`,
  `.github/workflows/pre-merge-pipeline.yml`) — no language toolchain loop; CI
  file changes are verified by structural review and by the validation
  scenarios in Phase 7.

---

## Implementation Plan (Atomic Tasks)

### Phase 0 — Baseline Capture

Phase 0 reads repository policy in the required order and captures baseline
toolchain state for every language in scope. Each command-step task writes an
artifact containing `Timestamp:`, `Command:`, `EXIT_CODE:`, and
`Output Summary:` (with numeric coverage headline values for test steps).

- [x] [P0-T1] Read repository policy files in the required order and write
  `<FEATURE>/evidence/baseline/phase0-instructions-read.md` containing
  `Timestamp:`, `Policy Order:`, and the explicit list of files read:
  `CLAUDE.md`, `.claude/rules/general-code-change.md`,
  `.claude/rules/general-unit-test.md`, `.claude/rules/quality-tiers.md`,
  `.claude/rules/tonality.md`, `.claude/rules/csharp.md`,
  `.claude/rules/typescript.md`, `.claude/rules/typescript-suppressions.md`,
  `.claude/rules/architecture-boundaries.md`, and the skills
  `policy-compliance-order`, `atomic-plan-contract`,
  `evidence-and-timestamp-conventions`.
  - Acceptance: artifact exists with all required fields populated.
- [x] [P0-T2] Capture C# format baseline. Run `dotnet tool restore` then
  `dotnet csharpier check .` and write
  `<FEATURE>/evidence/baseline/baseline-csharp-format.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T3] Capture C# build baseline (lint + nullable type-check). Run
  `dotnet build TaskMaster.sln` and write
  `<FEATURE>/evidence/baseline/baseline-csharp-build.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` (warning/error counts).
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T4] Capture C# architecture baseline. Run
  `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj --no-build`
  and write `<FEATURE>/evidence/baseline/baseline-csharp-architecture.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T5] Capture C# unit-test + coverage baseline. Run
  `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"` and write
  `<FEATURE>/evidence/baseline/baseline-csharp-test.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric baseline line
  coverage % and branch coverage % for `TaskMaster.Api`.
  - Acceptance: artifact records numeric coverage headline values (no
    placeholders).
- [x] [P0-T6] Capture TypeScript format baseline. Run `npm ci` then
  `npm run format:check` and write
  `<FEATURE>/evidence/baseline/baseline-ts-format.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T7] Capture TypeScript lint baseline. Run `npm run lint` and write
  `<FEATURE>/evidence/baseline/baseline-ts-lint.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` (error/warning counts).
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T8] Capture TypeScript type-check baseline. Run `npm run typecheck`
  and write `<FEATURE>/evidence/baseline/baseline-ts-typecheck.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T9] Capture TypeScript unit-test + coverage baseline. Run
  `npm run test:coverage` and write
  `<FEATURE>/evidence/baseline/baseline-ts-test.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric baseline line
  coverage % and branch coverage %.
  - Acceptance: artifact records numeric coverage headline values (no
    placeholders).
- [x] [P0-T10] Capture architecture-boundary (dependency-cruiser) baseline. Run
  `npm run depcruise` and write
  `<FEATURE>/evidence/baseline/baseline-ts-depcruise.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: artifact records the exact command and exit code.
- [x] [P0-T11] Capture CI baseline state. Record the current contents and
  no-op status of `.github/actions/contract/action.yml`, the current
  `stage-6-contract` job in `.github/workflows/pr-pipeline.yml` (including its
  current `runs-on:` value, `windows-latest`), and the final stage
  (`stage-9-golden`) of `.github/workflows/pre-merge-pipeline.yml` into
  `<FEATURE>/evidence/baseline/baseline-ci-state.md` with `Timestamp:` and
  `Output Summary:`.
  - Acceptance: artifact records the pre-change CI structure for later diff
    comparison, and explicitly records the current `stage-6-contract`
    `runs-on:` value (`windows-latest`).

### Phase 1 — OpenAPI Emission and Committed Snapshot (C#)

This phase replaces the NSwag emission path with
`Microsoft.Extensions.ApiDescription.Server` build-time emission, adds
`info.version`, guards startup for the `GetDocument.Insider` entry assembly,
wraps the `/api/ping` anonymous response in a named type, and commits the
deterministic snapshot. It must complete before Phases 2–4 (client generation,
oasdiff, Spectral all consume the committed snapshot). C# production-file batch
budget: this phase touches `Program.cs`, `TaskMaster.Api.csproj`, and one new
named-response type file — within the 1–3 production-file budget.

Toolchain loop for every code-change task in this phase: CSharpier format →
`dotnet build` (analyzers + nullable) → NetArchTest architecture →
`dotnet test` with coverage → re-run from format on any failure or file change.

- [x] [P1-T1] Update `src/TaskMaster.Api/TaskMaster.Api.csproj`: remove the
  `NSwag.MSBuild` `PackageReference`, the `GenerateOpenApi` MSBuild `Target`,
  and the `EnableNSwagEmission` property group.
  - Acceptance: file no longer references NSwag and
    `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj` succeeds. Run the C#
    toolchain loop.
- [x] [P1-T2] Update `Directory.Packages.props`: remove the `NSwag.MSBuild`
  `PackageVersion` entry (no other project references it) and add
  `<PackageVersion Include="Microsoft.Extensions.ApiDescription.Server" Version="10.0.7" />`.
  - Acceptance: `dotnet restore TaskMaster.sln` succeeds with no central-package
    warnings. Run the C# toolchain loop.
- [x] [P1-T3] Update `src/TaskMaster.Api/TaskMaster.Api.csproj`: add the
  `Microsoft.Extensions.ApiDescription.Server` `PackageReference` with
  `<PrivateAssets>all</PrivateAssets>` and
  `<IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>`,
  and add a `<PropertyGroup>` with `<OpenApiGenerateDocuments>true</OpenApiGenerateDocuments>`,
  `<OpenApiDocumentsDirectory>..\..\artifacts\openapi</OpenApiDocumentsDirectory>`,
  and `<OpenApiGenerateDocumentsOptions>--file-name current</OpenApiGenerateDocumentsOptions>`.
  - Acceptance: `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj` produces
    `artifacts/openapi/current.json`. Run the C# toolchain loop.
- [x] [P1-T4] Update `src/TaskMaster.Api/TaskMaster.Api.csproj`: add
  `<Version>1.0.0</Version>` to the main `<PropertyGroup>`.
  - Acceptance: build succeeds and `dotnet build` output reflects assembly
    version 1.0.0. Run the C# toolchain loop.
- [x] [P1-T5] Update `src/TaskMaster.Api/Program.cs`: add a `DocumentTransformer`
  (registered via `AddOpenApi(options => options.AddDocumentTransformer(...))`)
  that sets `info.version` from the assembly version so the emitted document
  contains a populated `info.version` field.
  - Acceptance: emitted `artifacts/openapi/current.json` contains
    `"info": { "version": "1.0.0", ... }`. Run the C# toolchain loop.
- [x] [P1-T6] Update `src/TaskMaster.Api/Program.cs`: wrap the
  `AddMicrosoftIdentityWebApi` and `AddMicrosoftGraph` registrations in a guard
  that skips them when `Assembly.GetEntryAssembly()?.GetName().Name` equals
  `"GetDocument.Insider"`. Leave `AddOpenApi`, `AddApplicationServices`,
  `AddInfrastructureServices`, and `AddClassifierServices` outside the guard.
  - Acceptance: `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj` emits the
    document without an `AzureAd` configuration error. Run the C# toolchain loop.
- [x] [P1-T7] Create `src/TaskMaster.Api/PingResponse.cs` defining a named
  `PingResponse` record (file-scoped namespace, e.g. `PingResponse(string Status)`),
  and update the `/api/ping` endpoint in `src/TaskMaster.Api/Program.cs` to
  return `Results.Ok(new PingResponse("pong"))` instead of the inline anonymous
  object.
  - Acceptance: the emitted document contains a named `PingResponse` component
    schema and no inline anonymous schema for `/api/ping`. Run the C# toolchain
    loop.
- [x] [P1-T8] Verify `.gitignore` does not exclude `artifacts/openapi/`.
  `.gitignore` line 52 is `artifacts/`, a parent-directory ignore; a single
  negation entry is insufficient because Git does not re-include files under a
  fully ignored parent directory. Add the pattern pair `!artifacts/openapi/`
  followed by `!artifacts/openapi/*` to `.gitignore` so the snapshot file is
  re-included. Record the check result in
  `<FEATURE>/evidence/other/gitignore-openapi-check.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`.
  - Acceptance: `git check-ignore artifacts/openapi/current.json` returns no
    match AND `git add artifacts/openapi/current.json` succeeds (the file is
    stageable). Both observations are recorded in the evidence artifact.
- [x] [P1-T9] Verify deterministic emission: run
  `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj` twice from a clean
  state and confirm `artifacts/openapi/current.json` is byte-identical between
  runs. Record the comparison in
  `<FEATURE>/evidence/other/openapi-determinism-check.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: the two emitted documents are identical; if not, pin emit
    ordering before proceeding.
- [x] [P1-T10] Commit the generated `artifacts/openapi/current.json` snapshot to
  the repository as the contract source of truth.
  - Acceptance: the file is tracked by git and contains the four active
    endpoints (`GET /health`, `GET /api/ping`, `POST /api/classify`,
    `POST /api/classify/feedback`) with populated `info.version`.

### Phase 2 — TypeScript API Client Generation and Migration (TypeScript)

This phase adds the client-generation tooling, generates and commits
`src/api-client/v1.ts`, migrates `classifier-client.ts` type declarations onto
generated types, and verifies the fetch polyfill covers `openapi-fetch`. It
depends on Phase 1 (the committed snapshot is the generation input).

Toolchain loop for every code-change task in this phase: Prettier format →
ESLint lint → `tsc` type-check → Vitest unit tests with coverage → re-run from
format on any failure or file change.

- [x] [P2-T1] Update `package.json`: add `openapi-typescript` and
  `@stoplight/spectral-cli` to `devDependencies`, add `openapi-fetch` to
  `dependencies`, and add scripts
  `"generate:api": "openapi-typescript artifacts/openapi/current.json --output src/api-client/v1.ts"`
  and `"lint:openapi": "spectral lint artifacts/openapi/current.json --ruleset .spectral.yaml"`.
  - Acceptance: `npm install` resolves the new packages and the scripts are
    present. (`.spectral.yaml` is created in Phase 3; the `lint:openapi` script
    is added here so `package.json` is edited once.)
- [x] [P2-T2] Run `npm run generate:api` to generate `src/api-client/v1.ts` from
  `artifacts/openapi/current.json`, and commit the generated file.
  - Acceptance: `src/api-client/v1.ts` exists, exports `paths` and `components`,
    is under the 500-line file size limit, and passes `npm run format:check`,
    `npm run lint`, and `npm run typecheck`. Run the TypeScript toolchain loop.
- [x] [P2-T3] Update `src/taskpane/classifier-client.ts`: replace the
  hand-written `ClassifyRequest`, `ClassifyResponse`, and `FeedbackRequest`
  interface declarations with imports of the generated
  `components["schemas"][...]` types from `src/api-client/v1.ts`. Retain the
  `ClassifierClient` class and the pure helpers `normalizeClassifyRequest` and
  `parseClassifyResponse` (no `openapi-fetch` `createClient` rewrite — out of
  scope).
  - Acceptance: `src/taskpane/classifier-client.ts` contains no hand-written
    wire interface declarations and `src/taskpane/classifier-client.test.ts`
    passes. Run the TypeScript toolchain loop.
- [x] [P2-T4] Update `src/taskpane/classifier-client.test.ts` only if the type
  migration in P2-T3 requires import-path or type-name adjustments; do not
  weaken existing assertions.
  - Acceptance: `npm run test:coverage` passes and coverage for
    `classifier-client.ts` is not reduced versus the P0-T9 baseline. Run the
    TypeScript toolchain loop.
- [x] [P2-T5] Verify the existing fetch polyfill covers `openapi-fetch`'s
  native-fetch usage for the `browserslist` targets (including `ie 11`). Inspect
  `webpack.config.js`, `package.json` dependencies (`core-js`,
  `regenerator-runtime`), and any polyfill entry; confirm a `fetch` polyfill is
  present and loaded. Do not modify `browserslist`. Record findings in
  `<FEATURE>/evidence/other/fetch-polyfill-verification.md` with `Timestamp:`
  and `Output Summary:` stating whether the polyfill covers `openapi-fetch` and
  the evidence basis.
  - Acceptance: artifact concludes coverage status; if the polyfill is absent,
    the artifact records the gap as a follow-up finding rather than dropping
    IE 11.

### Phase 3 — ESLint Folder Guard and Spectral Ruleset (TypeScript)

This phase adds the `src/api-client/` ESLint folder guard and the
`.spectral.yaml` ruleset. It depends on Phase 2 (the generated `v1.ts` must
exist so the guard's exclusion glob can be verified).

Toolchain loop for code-change tasks: Prettier format → ESLint lint → `tsc`
type-check → Vitest unit tests → re-run from format on any failure or file
change.

- [x] [P3-T1] Update `eslint.config.mjs`: add a new config block scoped to
  `src/api-client/` hand-editable files (`files: ["src/api-client/!(v1).ts"]`)
  that sets `no-restricted-syntax` to `error` banning `TSInterfaceDeclaration`
  and `TSTypeAliasDeclaration`, each with a message directing the developer to
  regenerate types from `artifacts/openapi/current.json`. Leave the existing
  `src/**/*.ts` non-determinism `no-restricted-syntax` block unchanged.
  - Acceptance: `npm run lint` passes (the generated `v1.ts` is excluded by the
    glob) and the new block is present. Run the TypeScript toolchain loop.
- [x] [P3-T2] Create `src/api-client/eslint-guard.test.ts`: a unit test that
  runs ESLint programmatically (`ESLint#lintText`) against a hand-written
  interface snippet with a synthetic `filePath` under `src/api-client/` and
  asserts a `no-restricted-syntax` error is reported, and against the generated
  `v1.ts` path asserts no such error. Use in-memory strings only — no temporary
  files.
  - Acceptance: the test passes and fails if the guard block is removed. Run the
    TypeScript toolchain loop.
- [x] [P3-T3] Create `.spectral.yaml` at repo root extending `spectral:oas` with
  three error-level rules: (1) operations must have a non-empty description,
  (2) all responses must declare a schema, (3) no inline anonymous schemas —
  request and response bodies must reference a named component.
  - Acceptance: the file exists and is valid YAML.
- [x] [P3-T4] Run `npm run lint:openapi` against the committed
  `artifacts/openapi/current.json` and confirm it exits zero (the Phase 1
  changes — named `PingResponse`, operation descriptions, response schemas —
  satisfy the three rules). If Spectral reports error-level findings, return to
  the relevant Phase 1 task to add the missing description or named schema, then
  re-run. Record the run in
  `<FEATURE>/evidence/other/spectral-lint-check.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: `npm run lint:openapi` exits zero against the committed
    document.

### Phase 4 — Contract CI Action: oasdiff + Spectral (CI)

This phase replaces the no-op `.github/actions/contract/action.yml` with real
oasdiff and Spectral steps including the `info.version` bump bypass. It depends
on Phases 1–3 (emitted document, committed snapshot, Spectral ruleset, npm
scripts). CI YAML changes have no language toolchain loop; they are verified by
structural review and by Phase 7 validation scenario 1.

- [x] [P4-T1] Replace `.github/actions/contract/action.yml` with a composite
  action that: sets up .NET 10 via `actions/setup-dotnet`, restores tools and
  NuGet (`dotnet tool restore` plus NuGet restore), emits the PR-head OpenAPI
  document via `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj`, sets up
  Node via `actions/setup-node` and runs `npm ci`, runs `npm run lint:openapi`
  (Spectral), then extracts the merge-base baseline via
  `git show origin/<base_ref>:artifacts/openapi/current.json` into a baseline
  file.
  - Acceptance: the action file is valid composite-action YAML and explicitly
    includes the steps required for the job to be runnable —
    `actions/setup-dotnet`, `dotnet tool restore` plus NuGet restore,
    `actions/setup-node`, and `npm ci` — in addition to the emit, Spectral, and
    baseline-extraction steps.
- [x] [P4-T2] Update `.github/actions/contract/action.yml`: add the
  `info.version` bump-bypass step before `oasdiff breaking` — read
  `info.version` from both the baseline and the PR-head document; if they
  differ, print a message that breaking changes are permitted and exit the
  contract check successfully; if unchanged, continue to `oasdiff`.
  - Acceptance: the bypass logic is present and reads `info.version` from both
    documents.
- [x] [P4-T3] Update `.github/actions/contract/action.yml`: add the oasdiff
  install step (download a version-pinned `oasdiff` Linux binary, since
  `stage-6-contract` runs on `ubuntu-latest` per P4-T4) and the
  `oasdiff breaking <baseline> <pr-head> --fail-on ERR --format githubactions`
  step so error-level breaking changes fail the step and offending fields are
  rendered as GitHub Actions annotations on the PR diff.
  - Acceptance: the action pins an explicit `oasdiff` version, downloads the
    Linux binary, and invokes `oasdiff breaking` with
    `--fail-on ERR --format githubactions`.
- [x] [P4-T4] Update `.github/workflows/pr-pipeline.yml`: change the
  `stage-6-contract` job's `runs-on:` value from `windows-latest` to
  `ubuntu-latest`, consistent with `spec.md` and the settled decision that
  oasdiff and Playwright CI jobs run on `ubuntu-latest`. Do not renumber
  existing stages.
  - Acceptance: `stage-6-contract` in `.github/workflows/pr-pipeline.yml`
    declares `runs-on: ubuntu-latest`.
- [x] [P4-T5] Update `.github/workflows/pr-pipeline.yml`: ensure the
  `stage-6-contract` job checks out with `fetch-depth: 0` so the merge-base
  baseline is reachable by `git show`. Do not renumber existing stages.
  - Acceptance: `stage-6-contract` uses `actions/checkout@v4` with
    `fetch-depth: 0` and still references `./.github/actions/contract`.

### Phase 5 — Playwright E2E Lane (TypeScript)

This phase installs Playwright, adds `playwright.config.ts`, the
client-credentials auth setup, and `tests/e2e/smoke.spec.ts`. It depends only on
Phase 2 for the `package.json` edit pattern but is otherwise independent of the
contract lane and may proceed in parallel with Phases 1–4.

Toolchain loop for code-change tasks: Prettier format → ESLint lint → `tsc`
type-check → Vitest unit tests → re-run from format on any failure or file
change. Note: Playwright `*.spec.ts` files are E2E tests run by the Playwright
runner, not Vitest; they must still pass format, lint, and type-check.

- [x] [P5-T1] Update `package.json`: add `@playwright/test` to
  `devDependencies`.
  - Acceptance: `npm install` resolves `@playwright/test`.
- [x] [P5-T2] Create `playwright.config.ts` at repo root defining the
  `tests/e2e/` test directory, timeouts, a `setup` project that runs the auth
  setup, and a dependent test project that consumes the stored `storageState`.
  - Acceptance: `npx playwright test --list` enumerates the configured projects
    without configuration errors. Run the TypeScript format/lint/type-check loop.
- [x] [P5-T3] Create `tests/e2e/auth.setup.ts` implementing the
  client-credentials (service-principal) flow against the Microsoft identity
  platform token endpoint. It must validate that `AZURE_TENANT_ID`,
  `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `E2E_API_BASE_URL` are present
  and throw an explicit error if any is missing (fail closed), then store the
  access token in Playwright `storageState`.
  - Acceptance: the file throws on a missing required variable; no interactive
    login path exists. Run the TypeScript format/lint/type-check loop.
- [x] [P5-T4] Create `tests/e2e/smoke.spec.ts` with three smoke tests against
  `E2E_API_BASE_URL` using the stored bearer token: `GET /health` returns 200
  with `{ status: "ok" }`; `POST /api/classify` with a minimal valid payload
  returns 200 with `label` and `confidence`; `POST /api/classify/feedback`
  returns 204.
  - Acceptance: `npx playwright test --list` includes the three tests; the file
    passes format, lint, and type-check. Run the TypeScript
    format/lint/type-check loop.
- [x] [P5-T5] Verify `tests/e2e/` requires no new `quality-tiers.yml` entry (it
  has no `package.json` of its own and falls under the root
  `tmw-taskpane-scaffold` entry). Record the confirmation in
  `<FEATURE>/evidence/other/quality-tiers-scope-check.md` with `Timestamp:` and
  `Output Summary:`.
  - Acceptance: artifact confirms no new tier entry is required; if `tests/e2e/`
    is found to need one, the artifact records the required entry and
    `quality-tiers.yml` is updated accordingly.

### Phase 6 — E2E CI Wiring (CI)

This phase wires the Playwright lane into both pipelines. It depends on Phase 5
(the E2E suite and config must exist). CI YAML changes are verified by
structural review and by Phase 7 validation scenario 2.

- [x] [P6-T1] Update `.github/workflows/pr-pipeline.yml`: add a label-gated job
  `stage-e2e-smoke` that runs on `ubuntu-latest`, has
  `if: contains(github.event.pull_request.labels.*.name, 'e2e:run')`, depends on
  `stage-7-integration`, checks out, sets up Node 20, runs `npm ci`, installs
  Playwright Chromium via `npx playwright install --with-deps chromium`, and
  runs `npx playwright test tests/e2e/` with `AZURE_TENANT_ID`,
  `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `E2E_API_BASE_URL` supplied from
  GitHub secrets.
  - Acceptance: the job is present, skips (does not fail) when the `e2e:run`
    label is absent, and does not renumber existing stages.
- [x] [P6-T2] Update `.github/workflows/pre-merge-pipeline.yml`: add an
  unconditional job `stage-10-e2e` that runs on `ubuntu-latest`, depends on
  `stage-9-golden`, and performs the same checkout, Node setup, `npm ci`,
  Playwright install, and `npx playwright test tests/e2e/` steps with the four
  secrets supplied from GitHub secrets.
  - Acceptance: `stage-10-e2e` is present, runs unconditionally after
    `stage-9-golden`, and existing stages are not renumbered.

### Phase 7 — Validation Scenarios and Final QA Loop

This phase verifies the two `issue.md` validation scenarios and runs the full
language-appropriate QA loop for C# and TypeScript with coverage. Every
command-step task writes a final-QC artifact containing `Timestamp:`,
`Command:`, `EXIT_CODE:`, and `Output Summary:`; test artifacts record numeric
post-change coverage values.

#### Validation Scenarios

- [x] [P7-T1] **Validation scenario 1 — breaking change without version bump
  `[expect-fail]`.** In a scratch working copy, edit a controller signature in
  `src/TaskMaster.Api/Program.cs` (e.g. rename a field on `ClassifyResponse`)
  without bumping `<Version>` in `src/TaskMaster.Api/TaskMaster.Api.csproj`,
  re-emit the document, and run the contract action's
  `oasdiff breaking <baseline> <pr-head> --fail-on ERR --format githubactions`
  step locally against the committed baseline. The oasdiff step is expected to
  exit non-zero and name the offending field. Record the run in
  `<FEATURE>/evidence/regression-testing/validation-oasdiff-breaking.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:` (expected non-zero), and
  `Output Summary:` quoting the offending-field message. Revert the scratch
  edit afterward.
  - Acceptance: the artifact shows a non-zero exit and a specific
    offending-field identifier; if the run cannot be executed, record a
    `fail-before-exception.<timestamp>.md` dossier under
    `<FEATURE>/evidence/regression-testing/`.
- [x] [P7-T2] **Validation scenario 1 — version bump bypass.** Repeat the P7-T1
  scratch edit but also bump `<Version>` in
  `src/TaskMaster.Api/TaskMaster.Api.csproj`, re-emit, and run the contract
  action's `info.version` comparison step plus `oasdiff`. Record the run in
  `<FEATURE>/evidence/regression-testing/validation-oasdiff-bypass.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:` (expected zero), and `Output Summary:`.
  Revert the scratch edits afterward.
  - Acceptance: the artifact shows the version-bump bypass exits zero and treats
    the breaking change as permitted.
- [x] [P7-T3] **Validation scenario 2 — Playwright smoke run.** Run
  `npx playwright test tests/e2e/` locally (or document the gated CI invocation
  path) with the four required environment variables set, exercising the
  client-credentials auth setup and the three smoke tests against the test
  tenant; then re-run with one secret removed to confirm fail-closed behavior.
  Record both runs in
  `<FEATURE>/evidence/regression-testing/validation-e2e-smoke.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:`, and `Output Summary:` listing the
  three test outcomes and the fail-closed observation.
  - Acceptance: with secrets present the suite passes; with a secret removed,
    the auth setup throws and the run fails closed — both observations recorded
    in the artifact.

#### Final QA Loop — C#

- [x] [P7-T4] Run `dotnet csharpier check .` and write
  `<FEATURE>/evidence/qa-gates/final-csharp-format.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`. If it changes files, restart the
  C# loop from this task.
  - Acceptance: exit code 0.
- [x] [P7-T5] Run `dotnet build TaskMaster.sln` and write
  `<FEATURE>/evidence/qa-gates/final-csharp-build.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` (warning/error counts). If it
  fails or changes files, fix and restart the C# loop from P7-T4.
  - Acceptance: exit code 0 with zero analyzer/nullable warnings.
- [x] [P7-T6] Run
  `dotnet test tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj --no-build`
  and write `<FEATURE>/evidence/qa-gates/final-csharp-architecture.md` with
  `Timestamp:`, `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: exit code 0, zero architecture violations.
- [x] [P7-T7] Run `dotnet test TaskMaster.sln --collect:"XPlat Code Coverage"`
  and write `<FEATURE>/evidence/qa-gates/final-csharp-test.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:` including numeric post-change line
  coverage % and branch coverage % for `TaskMaster.Api`.
  - Acceptance: exit code 0; line coverage >= 85%, branch coverage >= 75%; no
    regression on changed lines versus the P0-T5 baseline.

#### Final QA Loop — TypeScript

- [x] [P7-T8] Run `npm run format:check` and write
  `<FEATURE>/evidence/qa-gates/final-ts-format.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`. If formatting changes files,
  apply `npm run format` and restart the TypeScript loop from this task.
  - Acceptance: exit code 0.
- [x] [P7-T9] Run `npm run lint` and write
  `<FEATURE>/evidence/qa-gates/final-ts-lint.md` with `Timestamp:`, `Command:`,
  `EXIT_CODE:`, `Output Summary:` (error/warning counts). If it fails or changes
  files, fix and restart the TypeScript loop from P7-T8.
  - Acceptance: exit code 0, zero lint errors.
- [x] [P7-T10] Run `npm run typecheck` and write
  `<FEATURE>/evidence/qa-gates/final-ts-typecheck.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`. If it fails, fix and restart the
  TypeScript loop from P7-T8.
  - Acceptance: exit code 0.
- [x] [P7-T11] Run `npm run depcruise` and write
  `<FEATURE>/evidence/qa-gates/final-ts-depcruise.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: exit code 0, zero architecture-boundary violations.
- [x] [P7-T12] Run `npm run test:coverage` and write
  `<FEATURE>/evidence/qa-gates/final-ts-test.md` with `Timestamp:`, `Command:`,
  `EXIT_CODE:`, `Output Summary:` including numeric post-change line coverage %
  and branch coverage %.
  - Acceptance: exit code 0; line coverage >= 85%, branch coverage >= 75%; no
    regression on changed lines versus the P0-T9 baseline.
- [x] [P7-T13] Run `npm run lint:openapi` (Spectral) against the committed
  `artifacts/openapi/current.json` and write
  `<FEATURE>/evidence/qa-gates/final-spectral-openapi.md` with `Timestamp:`,
  `Command:`, `EXIT_CODE:`, `Output Summary:`.
  - Acceptance: exit code 0.

#### Coverage Delta Verification

- [x] [P7-T14] Compare baseline and post-change coverage for both languages and
  write `<FEATURE>/evidence/qa-gates/coverage-delta.md` with `Timestamp:` and an
  `Output Summary:` reporting, per language: baseline line/branch coverage
  (from P0-T5 / P0-T9), post-change line/branch coverage (from P7-T7 / P7-T12),
  and new/changed-code coverage.
  - Acceptance: the artifact shows post-change coverage meets the >= 85% line /
    >= 75% branch thresholds with no regression on changed lines; if any
    required value is unavailable, the plan outcome is remediation-required and
    not PASS.

---

## Acceptance Criteria Traceability

Each acceptance criterion from `issue.md` (identical to `spec.md` and
`user-story.md`) maps to the plan tasks below.

| AC | Acceptance Criterion (abbreviated) | Plan Tasks |
|----|-----------------------------------|-----------|
| AC1 | `artifacts/openapi/current.json` emitted from `TaskMaster.Api` and committed; emit regenerates deterministically | P1-T1, P1-T2, P1-T3, P1-T4, P1-T5, P1-T6, P1-T8, P1-T9, P1-T10 |
| AC2 | TypeScript API client generated via `openapi-typescript`; no hand-written wire types remain in the API client folder | P2-T1, P2-T2, P2-T3 |
| AC3 | ESLint rule scoped to the API client folder fails the lint stage when hand-written types are added there | P3-T1, P3-T2 |
| AC4 | `oasdiff` runs in the PR pipeline against the merge-base document; breaking change blocks the PR unless the API version is bumped; failure points to the offending field | P1-T4, P1-T5, P4-T1, P4-T2, P4-T3, P4-T4, P4-T5, P7-T1, P7-T2 |
| AC5 | Spectral lints the OpenAPI document with the three named rules enabled | P1-T7, P3-T3, P3-T4, P4-T1, P7-T13 |
| AC6 | Playwright installed; `tests/e2e/smoke.spec.ts` exists and is wired into the pre-merge pipeline behind `e2e:run` using a service-principal auth flow | P5-T1, P5-T2, P5-T3, P5-T4, P6-T1, P6-T2 |
| AC7 | PR-pipeline `stage-6-contract` performs real oasdiff + Spectral checks (no longer a no-op); pre-merge pipeline gains an E2E smoke stage | P4-T1, P4-T2, P4-T3, P4-T4, P4-T5, P6-T2 |
| AC8 | Editing a controller signature without bumping the API version causes the PR to fail with a specific error identifying the offending field | P7-T1 `[expect-fail]`, P7-T2 |
| AC9 | The Playwright smoke job runs successfully against the test tenant when the `e2e:run` label is applied | P5-T3, P5-T4, P6-T1, P7-T3 |

Supporting non-AC scope items: fetch polyfill verification (P2-T5, addresses the
`issue.md` / settled-decision IE 11 requirement); `quality-tiers.yml` scope
confirmation (P5-T5); NSwag cleanup (P1-T1, P1-T2).

## Test Plan

- **Unit (C#):** existing `TaskMaster.Api.Tests` re-run with coverage; the
  named `PingResponse` type and the `GetDocument.Insider` startup guard are
  exercised by build-time emission and the existing API host tests.
- **Unit (TypeScript):** `src/taskpane/classifier-client.test.ts` re-run after
  the generated-type migration; new `src/api-client/eslint-guard.test.ts`
  asserts the folder-guard ESLint rule behavior on hand-written vs generated
  types.
- **Integration / contract:** `npm run lint:openapi` (Spectral) against the
  committed document; `oasdiff breaking` against a synthetic breaking change
  with and without an `info.version` bump (P7-T1, P7-T2).
- **E2E:** Playwright `tests/e2e/smoke.spec.ts` against the test tenant via the
  client-credentials auth setup, gated by the `e2e:run` label in the PR
  pipeline and unconditional in the pre-merge pipeline (P7-T3).
- **Coverage evidence:** baseline artifacts `<FEATURE>/evidence/baseline/baseline-csharp-test.md`
  and `<FEATURE>/evidence/baseline/baseline-ts-test.md`; post-change artifacts
  `<FEATURE>/evidence/qa-gates/final-csharp-test.md` and
  `<FEATURE>/evidence/qa-gates/final-ts-test.md`; comparison artifact
  `<FEATURE>/evidence/qa-gates/coverage-delta.md`.

## Open Questions / Notes

- oasdiff has no npm distribution; the contract action downloads a
  version-pinned binary. `stage-6-contract` runs on `ubuntu-latest` (set by
  P4-T4, consistent with `spec.md` and the settled decision that oasdiff and
  Playwright CI jobs run on `ubuntu-latest`); P4-T3 pins the `oasdiff` Linux
  binary version accordingly. The E2E jobs likewise run on `ubuntu-latest` per
  the settled decisions.
- The exact Spectral `no-inline-schema` rule implementation may require tuning
  against the emitted document; P3-T4 includes a return-to-Phase-1 loop if
  Spectral reports findings the Phase 1 changes did not anticipate.

---

## Phase and Task Summary

- **Phase 0 — Baseline Capture:** 11 tasks (P0-T1 … P0-T11)
- **Phase 1 — OpenAPI Emission and Committed Snapshot (C#):** 10 tasks (P1-T1 … P1-T10)
- **Phase 2 — TypeScript API Client Generation and Migration:** 5 tasks (P2-T1 … P2-T5)
- **Phase 3 — ESLint Folder Guard and Spectral Ruleset:** 4 tasks (P3-T1 … P3-T4)
- **Phase 4 — Contract CI Action: oasdiff + Spectral:** 5 tasks (P4-T1 … P4-T5)
- **Phase 5 — Playwright E2E Lane:** 5 tasks (P5-T1 … P5-T5)
- **Phase 6 — E2E CI Wiring:** 2 tasks (P6-T1 … P6-T2)
- **Phase 7 — Validation Scenarios and Final QA Loop:** 14 tasks (P7-T1 … P7-T14)

**Total: 8 phases, 56 atomic tasks.**

Dependency sequencing: Phase 1 (OpenAPI emission + committed snapshot) precedes
Phases 2, 3, and 4 (client generation, ESLint/Spectral, oasdiff all consume the
committed snapshot). Phase 5 (Playwright lane) is independent of Phases 1–4 and
may proceed in parallel. Phase 6 depends on Phase 5. Phase 7 depends on all
prior phases.
