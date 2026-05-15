# boundary-contract-and-e2e-infra (Issue #19)

- Date captured: 2026-05-14
- Author: Dan Moisan
- Status: Promoted -> docs/features/active/boundary-contract-and-e2e-infra/ (Issue #19)

- Issue: #19
- Issue URL: https://github.com/drmoisan/TMW/issues/19
- Last Updated: 2026-05-15
- Work Mode: full-feature

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

## Proposed Behavior

Stand up the host<->service contract gates and the E2E infrastructure:

- Emit the backend OpenAPI document from `TaskMaster.Api` and commit the snapshot
  to `artifacts/openapi/current.json`.
- Generate the TypeScript API client from that OpenAPI document using
  `openapi-typescript` or `orval`; forbid hand-written types in the API client
  folder via an ESLint rule scoped to that folder.
- Run `oasdiff` in the PR pipeline against the OpenAPI document committed at the
  previous merge base; breaking changes block the PR unless the API version is
  bumped.
- Lint the OpenAPI document with Spectral; the rule set includes "operations
  have descriptions", "responses have schemas", and "no inline anonymous schemas".
- Install Playwright and add a smoke E2E suite that runs against a test M365
  tenant on a label-gated CI job, using a service-principal auth flow rather
  than interactive login.
- Add a `tests/e2e/smoke.spec.ts` placeholder wired into the pre-merge pipeline
  behind an `e2e:run` label.
- Light up PR-pipeline stage 6 (contract / schema compatibility) and a new
  pre-merge E2E smoke stage.

## Acceptance Criteria (early draft)

- [ ] `artifacts/openapi/current.json` is emitted from `TaskMaster.Api` and committed; an emit script regenerates it deterministically.
- [ ] The TypeScript API client is generated from the OpenAPI document via `openapi-typescript` or `orval`; no hand-written wire types remain in the API client folder.
- [ ] An ESLint rule scoped to the API client folder fails the lint stage when hand-written types are added there.
- [ ] `oasdiff` runs in the PR pipeline against the previous merge-base OpenAPI document; a breaking change blocks the PR unless the API version is bumped, and the failure message points to the offending field.
- [ ] Spectral lints the OpenAPI document with the three named rules enabled.
- [ ] Playwright is installed; `tests/e2e/smoke.spec.ts` exists and is wired into the pre-merge pipeline behind the `e2e:run` label using a service-principal auth flow.
- [ ] PR-pipeline `stage-6-contract` performs real oasdiff + Spectral checks (no longer a no-op); the pre-merge pipeline gains an E2E smoke stage.
- [ ] Editing a controller signature without bumping the API version causes the PR to fail with a specific error identifying the offending field.
- [ ] The Playwright smoke job runs successfully against the test tenant when the `e2e:run` label is applied.

## Constraints & Risks

- Service-principal credentials for the test M365 tenant must be supplied through
  CI secrets, not committed; the E2E job must fail closed when secrets are absent.
- The OpenAPI snapshot must be deterministic so `oasdiff` diffs are stable; emit
  ordering and formatting must be pinned.
- New tooling (`oasdiff`, Spectral, Playwright, `openapi-typescript`/`orval`)
  adds dependencies; selection should favor well-maintained, widely used packages.
- Generated client output must satisfy the existing TypeScript toolchain gates
  (format, lint, type-check) and the 500-line file size limit.
- The pre-merge pipeline currently stops at `stage-9-golden`; the new E2E stage
  is additive and the numbering gap (no stage-10) is disregarded per user direction.

## Test Conditions to Consider

- [ ] Unit coverage areas: OpenAPI emit script output shape; generated-client wiring helpers; ESLint rule behavior on hand-written vs generated types.
- [ ] Integration scenarios: `oasdiff` against a synthetic breaking change with and without an API version bump; Spectral run against the committed OpenAPI document.
- [ ] CLI/API examples: emit-OpenAPI command; client-generation command; Playwright smoke run gated by the `e2e:run` label.

## Next Step

- [ ] Promote to GitHub issue (feature request template)
- [ ] Create `docs/features/active/boundary-contract-and-e2e-infra/` folder from the template