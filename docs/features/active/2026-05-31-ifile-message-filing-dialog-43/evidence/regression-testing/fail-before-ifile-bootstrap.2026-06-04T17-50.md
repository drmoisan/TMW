# Fail-Before Evidence — host-bootstrap wiring seam ([P1-T3], [expect-fail])

Timestamp: 2026-06-04T17-50
Command: npm run test -- ifile.bootstrap
EXIT_CODE: 1

## Test Added
File: tests/taskpane/ifile/ifile.bootstrap.test.ts (new)
Drives an exported `bootstrap` seam of `src/taskpane/ifile/ifile.ts` (Office-free, injectable deps) and asserts that when token acquisition fails or the one-time folder load fails, `bootstrap` still binds the input handler and renders a visible error state (`[data-ifile-error]`) into the results list rather than leaving the box inert.

## Failure (no testable seam; bootstrap rejects before wiring)
The current `ifile.ts` exports no `bootstrap` function and executes host-bound code at import time (`const API_BASE_URL = __API_BASE_URL__;`), so the module cannot be imported under the test seam. The suite fails to load:

```
FAIL tests/taskpane/ifile/ifile.bootstrap.test.ts
ReferenceError: __API_BASE_URL__ is not defined
 ❯ src/taskpane/ifile/ifile.ts:22:22
     21| declare const __API_BASE_URL__: string;
     22| const API_BASE_URL = __API_BASE_URL__;
        |                      ^
 ❯ tests/taskpane/ifile/ifile.bootstrap.test.ts:2:31

 Test Files  1 failed (1)
      Tests  no tests
```

This confirms the defect class: the host-bootstrap path is untestable, exports no resilient `bootstrap` seam, and (on current code) the only error sink is `console.error`. The fix restructures `bootstrap` into an exported, Office-free seam that binds the handler and surfaces a visible error state regardless of token/load outcome (Phase 2 [P2-T3], Phase 3 [P3-T2]).
