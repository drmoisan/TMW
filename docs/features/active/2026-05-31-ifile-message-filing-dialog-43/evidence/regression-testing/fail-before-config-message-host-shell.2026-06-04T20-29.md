# Fail-Before Evidence — Configuration-Stage Message in Host Shell (P1-T3)

Timestamp: 2026-06-04T20-29
Command: npm run test -- ifile.host-shell
EXIT_CODE: 1

SearchScope: tests/taskpane/ifile/, src/taskpane/ifile/
SearchPatterns: ifile.host-shell.test.ts, ifile.ts (exported constant CONFIGURATION_FAILURE_MESSAGE)
SearchResult:
- tests/taskpane/ifile/ifile.host-shell.test.ts — extended this cycle with a configuration-message test driving the URL-guard path (mobile build + localhost URL).
- src/taskpane/ifile/ifile.ts — exports `runBootstrap` but does NOT export `CONFIGURATION_FAILURE_MESSAGE`; the `assertReachableApiBaseUrl` catch currently renders the generic internal `BOOTSTRAP_FAILURE_MESSAGE`.

Failure (assertion):

```
FAIL tests/taskpane/ifile/ifile.host-shell.test.ts > ... > renders the distinct configuration message when the build URL guard rejects
AssertionError: expected 'iFile could not start. Check your con…' to be undefined
  Expected: undefined   (CONFIGURATION_FAILURE_MESSAGE is not exported)
  Received: "iFile could not start. Check your connection and sign-in, then try again."

 Test Files  1 failed (1)
      Tests  1 failed | 4 passed (5)
```

Interpretation: The new test drives `runBootstrap` with a mobile-build flag and a localhost URL so the reachability guard rejects, then asserts the rendered error row matches the not-yet-exported `CONFIGURATION_FAILURE_MESSAGE`. Because the constant is `undefined` and the current code renders the generic message on the URL-guard catch, the assertion fails. The 4 pre-existing host-shell tests still pass. This satisfies the [expect-fail] requirement for [P1-T3]. The test will pass after Phase 2 [P2-T1] routes the configuration-stage message.
