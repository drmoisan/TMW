# Fail-Before Evidence — Stage-Specific Bootstrap Messages (P1-T2)

Timestamp: 2026-06-04T20-29
Command: npm run test -- ifile.bootstrap
EXIT_CODE: 1

SearchScope: tests/taskpane/ifile/, src/taskpane/ifile/
SearchPatterns: ifile.bootstrap.test.ts, ifile.ts (exported message constants SIGN_IN_FAILURE_MESSAGE / CONNECTION_FAILURE_MESSAGE)
SearchResult:
- tests/taskpane/ifile/ifile.bootstrap.test.ts — extended this cycle with two stage-message tests.
- src/taskpane/ifile/ifile.ts — exports `bootstrap` but does NOT export `SIGN_IN_FAILURE_MESSAGE` or `CONNECTION_FAILURE_MESSAGE`; the module currently uses a single internal `BOOTSTRAP_FAILURE_MESSAGE`.

Failure (assertion):

```
FAIL tests/taskpane/ifile/ifile.bootstrap.test.ts > ... > renders the distinct sign-in message when token acquisition fails
AssertionError: expected 'iFile could not start. Check your conn…' to be undefined
  Expected: undefined   (SIGN_IN_FAILURE_MESSAGE is not exported)

FAIL ... > renders the distinct connection message when the one-time load fails
AssertionError: expected 'Folder list could not be loaded. Chec…' to be undefined
  Expected: undefined   (CONNECTION_FAILURE_MESSAGE is not exported)

 Test Files  1 failed (1)
      Tests  2 failed | 3 passed (5)
```

Interpretation: The two new assertions compare the rendered error-row text against the not-yet-exported message constants `SIGN_IN_FAILURE_MESSAGE` and `CONNECTION_FAILURE_MESSAGE`. Because they are `undefined` (current code uses a single `BOOTSTRAP_FAILURE_MESSAGE`, and the connection failure currently shows the inline-host `LOAD_FAILURE_MESSAGE` text), the `.toBe(<undefined>)` assertions fail. The 3 pre-existing bootstrap tests still pass. This satisfies the [expect-fail] requirement for [P1-T2]. The tests will pass after Phase 2 [P2-T1]/[P2-T2] export and route the stage-specific messages.
