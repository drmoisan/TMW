# Code Review — boundary-contract-and-e2e-infra (Issue #19)

- Timestamp: 2026-05-15T03-15
- Reviewer scope: full branch diff against `main` @ `7a9c036`.

## Summary

The change establishes the host-to-service contract gates (build-time OpenAPI emission, oasdiff with version-bump bypass, Spectral lint) and the Playwright E2E lane (label-gated PR job, unconditional pre-merge job). The implementation favors small, composable pieces over reinvention: it uses first-party `Microsoft.Extensions.ApiDescription.Server` for emission, `openapi-typescript` for type generation only, and `no-restricted-syntax` ESLint rules instead of a custom plugin. The code is readable, well-scoped, and well-commented.

## Strengths

- **Build-time emission is deterministic.** `evidence/other/openapi-determinism-check.md` records two clean `--no-incremental` builds producing byte-identical SHA-256 output. This makes `oasdiff` baselines stable as required.
- **`Program.cs` startup guard is precise.** The `GetDocument.Insider` entry-assembly check (`Program.cs:13-17`) scopes the auth/Graph skip to the emission tool only and leaves the request pipeline intact in normal runs. `AddAuthorization()` is registered unconditionally (`Program.cs:38`) so the `UseAuthorization` middleware resolves even during emission.
- **Folder guard uses built-in rules.** `eslint.config.mjs` block 6 leverages `no-restricted-syntax` with `TSInterfaceDeclaration`/`TSTypeAliasDeclaration` selectors. No custom plugin is added, satisfying the dependency-minimization constraint. The `!(v1).ts` glob plus `**/*.test.ts` ignore correctly exclude generated output and test fixtures.
- **Contract action sequences are correct.** `.github/actions/contract/action.yml` checks `info.version` *before* installing or invoking oasdiff (`action.yml:56-89`), so version-bumped PRs skip both work and exit cleanly. The oasdiff binary is version-pinned (`OASDIFF_VERSION="1.15.3"`) and downloaded from the official release URL.
- **Fail-closed auth setup.** `tests/e2e/auth.setup.ts:33-51` validates all four required environment variables up front and throws with the offending variable names. No silent skip path exists. The fail-closed behavior is empirically demonstrated in `validation-e2e-smoke.md` run 1.
- **No unsafe suppressions.** No `// eslint-disable` or `// @ts-expect-error` comments were introduced in production TypeScript. Only the generated `v1.ts` has a config-level rule relaxation with a justification comment.

## Findings

### F1 — `parseClassifyResponse` interpolates `JSON.stringify(value)` for `unknown` input in an error message (low)

File: `src/taskpane/classifier-client.ts:46-49`.

```ts
throw new TypeError(
    `parseClassifyResponse: expected { label: string; confidence: number }, got ${JSON.stringify(value)}`
);
```

`JSON.stringify` on values containing `BigInt` or circular references throws. Since this is an error path and `value` is `unknown` from the network, malformed payloads (intentionally adversarial or otherwise) could turn a clear `TypeError` into an uncaught serializer error. The probability is low for the current backend, but the helper is defensive by design.

Suggested treatment: wrap the stringify in a try/catch and fall back to `String(value)` or the `typeof` tag. Not a blocking finding.

### F2 — `Authorization` header construction repeats across two methods (very low)

File: `src/taskpane/classifier-client.ts:67-99`. The two methods build identical `headers` objects inline. Extracting a private `authHeaders(token)` helper would remove the duplication. This is minor and below the threshold the existing code patterns optimize for; leaving it is acceptable given the file is the migration scaffold and the wrapper is expected to be reworked when `openapi-fetch` is fully adopted (spec calls out this as deferred). Recording for completeness.

### F3 — `tests/e2e/smoke.spec.ts` types confidence loosely (low)

File: `tests/e2e/smoke.spec.ts:101-103`.

```ts
expect(typeof body.label).toBe("string");
expect(["number", "string"]).toContain(typeof body.confidence);
```

The OpenAPI schema declares `confidence` as a `number`. The smoke spec accepts either `number` or `string` to tolerate JSON serializer quirks. This is defensive but masks a contract drift the gate is supposed to surface. The more rigorous assertion is `typeof body.confidence === "number"`. Given the smoke suite is the E2E lane (not a contract test) and the contract is enforced separately by oasdiff/Spectral, the looser assertion is acceptable; it is worth tightening once the suite is observed green against the test tenant.

### F4 — `info.version` is derived from `Assembly.Version`, not the literal `<Version>` element (informational)

File: `src/TaskMaster.Api/Program.cs:23-25`.

```csharp
var assemblyVersion =
    typeof(PingResponse).Assembly.GetName().Version?.ToString(3) ?? "1.0.0";
document.Info.Version = assemblyVersion;
```

This relies on MSBuild's `<Version>1.0.0</Version>` propagating to `[AssemblyVersion]`. That mapping is the default in `Sdk.Web`, but a downstream PR that overrides `<AssemblyVersion>` separately could decouple the OpenAPI version from `<Version>`. The fallback string `"1.0.0"` masks a missing version silently. Two refinements would be safer:

1. Read `<InformationalVersion>` or `<Version>` directly via a `Microsoft.Build`-time constant.
2. Throw (or log) if `Assembly.GetName().Version` is null instead of silently falling back.

Informational — the current mapping is correct for the present project state and is what the spec calls for.

### F5 — `tests/e2e/smoke.spec.ts` storage-state token channel is unusual (informational)

The token is written into `storageState.origins[0].localStorage` and read back via `readFile` in `smoke.spec.ts`. This works but is a slightly indirect channel: Playwright's API context does not consume `localStorage` for HTTP request authorization. The cleaner pattern is to use Playwright's `extraHTTPHeaders` (via a fixture or per-`request` option) or `request.newContext({ extraHTTPHeaders: { Authorization: ... } })`. The current implementation is correct and the indirection is explained in `auth.setup.ts` comments; treating as informational.

## Test Quality

- New TypeScript tests:
  - `src/api-client/eslint-guard.test.ts` — 3 tests covering positive (interface), positive (type alias), and negative (generated file) cases. Uses `ESLint.lintText` with synthetic file paths and `lintFiles` for the real file. No temporary files are created. Arrange–Act–Assert structure is followed.
  - Added `taskpane.test.ts` case for `typeof result.confidence === "number"` ternary.
- E2E spec is structured AAA and uses Playwright's `request` fixture for isolation.
- No mocks of database/network exist in unit tests; isolation respected.

## Dependencies

- Added: `Microsoft.Extensions.ApiDescription.Server` (build-time, `PrivateAssets=all`), `openapi-typescript` (devDep), `openapi-fetch` (runtime dep — currently unused by production code; type-only migration retains `fetch` direct calls), `@stoplight/spectral-cli` (devDep), `@playwright/test` (devDep).
- Removed: `NSwag.MSBuild` (superseded).
- Each is well-maintained and widely used. The spec justifies each addition.
- Note: `openapi-fetch` is declared as a runtime dependency but the spec defers full client migration onto `createClient` to a later issue, so the runtime dependency is currently unused at runtime. Acceptable as a forward-looking placement; consider whether it should remain a devDep until consumed.

## Style and Naming

- C#: PascalCase for types and members; file-scoped namespaces in `PingResponse.cs`; XML doc on the public-internal record. Conforms.
- TS: camelCase for locals and exported functions; PascalCase for `ClassifierClient`; kebab-case file names (`auth.setup.ts`, `smoke.spec.ts`, `eslint-guard.test.ts`). Conforms.

## Verdict

PASS with low-severity follow-ups (F1, F3) and informational notes (F2, F4, F5). None block merge.
