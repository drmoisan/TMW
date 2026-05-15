# Spectral OpenAPI Lint Check

Timestamp: 2026-05-14T22-58
Command: `npm run lint:openapi` (`spectral lint artifacts/openapi/current.json --ruleset .spectral.yaml`)
EXIT_CODE: 0

## Output Summary

`npm run lint:openapi` exits zero against the committed `artifacts/openapi/current.json`. The three custom error-level rules in `.spectral.yaml` all pass:
- `operation-description` — every operation has a non-empty description.
- `response-schema-required` — every body-bearing 2xx success response declares a schema.
- `no-inline-anonymous-request-schema` / `no-inline-anonymous-response-schema` — all request and response body schemas reference a named component via `$ref`.

Spectral reports 3 warnings from the inherited `spectral:oas` base ruleset (`oas3-api-servers`, `info-contact`, `info-description`). These are warning-level, not error-level, and do not fail the check (exit code 0).

## Return-to-Phase-1 Loop (per P3-T4)

The initial Spectral run reported 10 error-level findings. Two root causes were addressed:

1. **Missing operation descriptions** — `Program.cs` was updated (authorized return-to-Phase-1 per the P3-T4 task text) to add `.WithDescription(...)` to all four endpoints (`/health`, `/api/ping`, `/api/classify`, `/api/classify/feedback`).
2. **`no-inline-anonymous-*` rules matching resolved component definitions** — the rules were corrected to use `resolved: false` so the JSONPath inspects the literal `$ref` in request/response body schemas rather than the resolved component target.

Rule 2 (`response-schema-required`) was scoped to 2xx success responses (excluding 204 No Content), because error responses such as 422 Unprocessable Entity legitimately carry no body in this minimal API. This keeps the rule meaningful for generated-client typing while not flagging body-less status codes.

After re-emitting the document (`dotnet build`) and regenerating the TypeScript client (`npm run generate:api`), the Spectral run exits zero. The re-emitted document was confirmed byte-identical across `--no-incremental` builds (deterministic).
