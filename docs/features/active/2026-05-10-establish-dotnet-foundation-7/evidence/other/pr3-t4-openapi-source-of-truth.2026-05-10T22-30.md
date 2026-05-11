# PR3-T4 — OpenAPI Source of Truth (Interim)

- Timestamp: 2026-05-10T22-30
- Task: [PR3-T4]

## Decision

`artifacts/openapi/current.json` is hand-authored and is the interim source of truth for the TaskMaster API OpenAPI document until NSwag emission is re-enabled.

## NSwag Emission Status

- NSwag emission is gated by the MSBuild property `EnableNSwagEmission`. Default value: `false`.
- The `GenerateOpenApi` target in `src/TaskMaster.Api/TaskMaster.Api.csproj` only executes when `EnableNSwagEmission` is set to `true`.
- When invoked under net10.0, the upstream `NSwag.AspNetCore.Launcher` throws `System.InvalidOperationException: No service for type 'NSwag.Generation.IOpenApiDocumentGenerator' has been registered`. See [PR3-T3] evidence at `evidence/regression-testing/pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`.
- `ContinueOnError`/`IgnoreExitCode` have been removed; if `EnableNSwagEmission=true` is passed and the upstream issue persists, the build fails loudly (no silent suppression).

## Tracking

- TODO comment in `src/TaskMaster.Api/TaskMaster.Api.csproj` references the NSwag GitHub issue tracker (search "net10" / "IOpenApiDocumentGenerator").
- Follow-up work item: once upstream NSwag supports net10, enable `EnableNSwagEmission=true` by default and remove this interim documentation.

## Verification

- Default build (no property override): NSwag target skipped, build clean (0 errors, 0 warnings). See `evidence/qa-gates/pr3-t2-build-default.2026-05-10T22-30.txt`.
- Opt-in build (`-p:EnableNSwagEmission=true`): NSwag target executes and fails loudly (MSB3073). See `evidence/regression-testing/pr3-t3-nswag-loud-fail.2026-05-10T22-30.txt`.
