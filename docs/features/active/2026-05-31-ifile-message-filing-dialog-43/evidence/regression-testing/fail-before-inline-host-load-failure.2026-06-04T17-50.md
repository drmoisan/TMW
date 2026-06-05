# Fail-Before Evidence — inline-host load-failure path ([P1-T1], [expect-fail])

Timestamp: 2026-06-04T17-50
Command: npm run test -- inline-host
EXIT_CODE: 1

## Test Added
File: tests/taskpane/ifile/inline-host.test.ts
Test: `inline-host mountInline > keeps the box responsive and shows a visible error state when the one-time load fails`

The test constructs an `IFileController` whose `loadLeaves` rejects, calls `mountInline`, and asserts:
(a) a visible distinct error/empty-state row (`[data-ifile-error]`) is rendered into the results list, and
(b) a subsequent `input` keystroke still invokes `controller.search`.

## Failing Assertion / Failure
The test fails before any assertion is reached. `mountInline` calls `await controller.open()` (which calls `loadLeaves()`) before attaching the input listener; the rejecting loader propagates `Error: load failed` out of `mountInline`, so the `await mountInline(...)` call throws.

```
FAIL tests/taskpane/ifile/inline-host.test.ts > inline-host mountInline > keeps the box responsive and shows a visible error state when the one-time load fails
Error: load failed
 ❯ IFileController.open src/taskpane/ifile/ifile-controller.ts:49:36
 ❯ Module.mountInline src/taskpane/ifile/inline-host.ts:49:22
 ❯ tests/taskpane/ifile/inline-host.test.ts:78:15

 Test Files  1 failed (1)
      Tests  1 failed | 3 passed (4)
```

This confirms the defect: on a failed one-time load the handler is never bound and no visible error is shown. Fix follows in Phase 3 ([P3-T1]).
