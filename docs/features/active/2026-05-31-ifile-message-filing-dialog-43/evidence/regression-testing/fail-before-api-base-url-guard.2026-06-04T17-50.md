# Fail-Before Evidence — backend-URL reachability guard ([P1-T2], [expect-fail])

Timestamp: 2026-06-04T17-50
Command: npm run test -- api-base-url
EXIT_CODE: 1

## Test Added
File: tests/taskpane/ifile/api-base-url.test.ts (new)
Imports `assertReachableApiBaseUrl` from the not-yet-existing module `src/taskpane/ifile/api-base-url.ts` and asserts:
- it throws for `"https://localhost:3000"` when `isMobileBuild: true`, and
- it returns a non-localhost host unchanged.

## Failure (missing-module / import resolution)
The suite fails to load because the module under test does not yet exist:

```
FAIL tests/taskpane/ifile/api-base-url.test.ts
Error: Failed to resolve import "../../../src/taskpane/ifile/api-base-url" from
"tests/taskpane/ifile/api-base-url.test.ts". Does the file exist?
  Plugin: vite:import-analysis
  File: .../tests/taskpane/ifile/api-base-url.test.ts:10:42

 Test Files  1 failed (1)
      Tests  no tests
```

This confirms the guard module is absent. It is implemented in Phase 2 ([P2-T1]).
