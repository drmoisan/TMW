# Feature Audit — boundary-contract-and-e2e-infra (Issue #19)

- Timestamp: 2026-05-15T03-15
- Work Mode: `full-feature`
- AC sources: `docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/spec.md` (section "## Acceptance Criteria") and `docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/user-story.md` (section "## Acceptance Criteria").
- Baseline: `main` @ `7a9c036`.

## Acceptance Criteria Evaluation

The nine AC items are identical in both source files (`spec.md` and `user-story.md`). Both sources already have all items checked. The evaluation below verifies each item against evidence in the branch diff and feature `evidence/` directory.

| # | Criterion | Verdict | Evidence |
|---|---|---|---|
| AC1 | `artifacts/openapi/current.json` is emitted from `TaskMaster.Api` and committed; an emit script regenerates it deterministically. | PASS | Committed at `artifacts/openapi/current.json` (212 lines). Emitted via `Microsoft.Extensions.ApiDescription.Server` configured in `TaskMaster.Api.csproj`. Determinism verified twice with byte-identical SHA-256 in `evidence/other/openapi-determinism-check.md`. |
| AC2 | The TypeScript API client is generated from the OpenAPI document via `openapi-typescript`; no hand-written wire types remain in the API client folder. | PASS | `src/api-client/v1.ts` is the openapi-typescript output (header banner present). `src/taskpane/classifier-client.ts` re-exports types via `components["schemas"][...]` rather than declaring them. `src/api-client/` contains only `v1.ts` and the guard test. |
| AC3 | An ESLint rule scoped to the API client folder fails the lint stage when hand-written types are added there. | PASS | `eslint.config.mjs` block 6 applies `no-restricted-syntax` for `TSInterfaceDeclaration` and `TSTypeAliasDeclaration` to `src/api-client/!(v1).ts`. Behavior tested by `src/api-client/eslint-guard.test.ts` (3 tests, all asserting expected rule firings/absences). |
| AC4 | `oasdiff` runs in the PR pipeline against the previous merge-base OpenAPI document; a breaking change blocks the PR unless the API version is bumped, and the failure message points to the offending field. | PASS | `.github/actions/contract/action.yml:46-101` extracts baseline via `git show origin/<base_ref>:artifacts/openapi/current.json`, runs version comparison, then runs `oasdiff breaking ... --fail-on ERR --format githubactions`. End-to-end demonstrated in `evidence/regression-testing/validation-oasdiff-breaking.md` (EXIT 1, annotation names `label` as the offending field on `POST /api/classify`). |
| AC5 | Spectral lints the OpenAPI document with the three named rules enabled. | PASS | `.spectral.yaml` defines `operation-description`, `response-schema-required`, and two `no-inline-anonymous-*-schema` rules (the third logical rule is split into request and response halves). `evidence/qa-gates/final-spectral-openapi.md` records `npm run lint:openapi` EXIT 0. The `/api/ping` anonymous response is wrapped in `PingResponse` to satisfy the inline-schema rule. |
| AC6 | Playwright is installed; `tests/e2e/smoke.spec.ts` exists and is wired into the pre-merge pipeline behind the `e2e:run` label using a service-principal auth flow. | PASS | `@playwright/test` declared in `package.json`. `tests/e2e/smoke.spec.ts` (124 lines) and `tests/e2e/auth.setup.ts` (117 lines) exist. Service-principal flow targets `https://login.microsoftonline.com/.../oauth2/v2.0/token` with `client_credentials` grant. Pre-merge `stage-10-e2e` runs unconditionally; PR `stage-e2e-smoke` gated by `e2e:run` label. (Note: the AC text says "wired into the pre-merge pipeline behind the `e2e:run` label", which conflates two jobs. The implementation matches the spec text more precisely: unconditional in pre-merge, label-gated in PR pipeline. Both are wired; the criterion is satisfied either way.) |
| AC7 | PR-pipeline `stage-6-contract` performs real oasdiff + Spectral checks (no longer a no-op); the pre-merge pipeline gains an E2E smoke stage. | PASS | `.github/actions/contract/action.yml` is replaced with real steps (setup .NET, emit OpenAPI, install Node, install npm deps, Spectral, baseline extract, version compare, oasdiff). `pre-merge-pipeline.yml:56-79` adds `stage-10-e2e`. |
| AC8 | Editing a controller signature without bumping the API version causes the PR to fail with a specific error identifying the offending field. | PASS | `evidence/regression-testing/validation-oasdiff-breaking.md` records the synthetic `Label` -> `Classification` edit, EXIT 1, with `::error title=response-required-property-removed,...::in API POST /api/classify removed the required property \`label\`` annotation. The complementary bypass scenario (with version bump) in `validation-oasdiff-bypass.md` confirms the escape hatch path. |
| AC9 | The Playwright smoke job runs successfully against the test tenant when the `e2e:run` label is applied. | PARTIAL | The wiring is in place and the fail-closed path is demonstrated locally (`validation-e2e-smoke.md` Run 1 EXIT 1 with explicit missing-secret error). Run 2 (suite-pass against the test tenant) is **documented, not executed** — secrets are unavailable in the local environment. The CI invocation path is wired to run on the first merged PR that carries the `e2e:run` label. Per the plan's `[expect-pass]` task text, documenting the gated CI invocation path is permitted in lieu of a local run; AC9 will be empirically verified on the next CI execution with secrets present. |

## Acceptance Criteria Status

```
### Acceptance Criteria Status
- Source: docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/spec.md, docs/features/active/2026-05-14-boundary-contract-and-e2e-infra-19/user-story.md
- Total AC items: 9
- Checked off (delivered): 9 (already checked in both source files)
- Remaining (unchecked): 0
- Items remaining: (none)
```

The reviewer leaves the source-file checkboxes as-is. All nine items had been checked by the executor; the reviewer's verdicts above corroborate eight as PASS and one (AC9) as PARTIAL with a documented CI-only verification path. Per the AC-tracking skill, PARTIAL is not grounds to uncheck; the gap is recorded here for visibility on the next CI run.

## Out-of-Scope Verifications

- The downstream filing workflow (Prompt E2) is not implemented here, per the Non-Goals in `user-story.md`. Not evaluated.
- `ClassifierClient` rewrite onto `openapi-fetch` `createClient` is deferred. Not evaluated.
- Dropping IE 11 from `browserslist` is out of scope; `evidence/other/fetch-polyfill-verification.md` records the polyfill verification.

## Overall Feature Verdict

PASS with one PARTIAL pending CI confirmation (AC9). The infrastructure is fully wired and the contract gates are empirically demonstrated to block breaking changes by default and permit explicit version-bump bypasses. The E2E lane's success path will be observable on the first PR carrying the `e2e:run` label with secrets present.
