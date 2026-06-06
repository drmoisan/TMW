# TypeScript Test + Coverage Baseline

Timestamp: 2026-06-04T20-29
Command: npm run test:coverage
EXIT_CODE: 0

Output Summary:
- Test files: 26 passed (26). Tests: 117 passed (117).
- Headline coverage (All files): Lines 96.25%, Branches 95.02%, Functions 100%, Statements 96.25%.
- Per-file (plan-required):
  - src/taskpane/ifile/ifile.ts: 85.48% lines / 94.11% branches / 100% functions. Uncovered lines 141-149 (the `typeof Office !== "undefined"` Office.onReady host-registration guard, not exercised in jsdom). Above the line >= 85% / branch >= 75% thresholds.
  - src/taskpane/ifile/inline-host.ts: 100% lines / 100% branches / 100% functions.
- naa-token-acquirer.ts does not yet exist (NAA adapter is introduced in Phase 4).
- No production file is coverage-excluded in vitest.config.ts.
- Baseline establishes pre-remediation state: ifile.ts and inline-host.ts both meet thresholds; the host-shell and bootstrap seams are exercised by the existing tests/taskpane/ifile/ifile.host-shell.test.ts and ifile.bootstrap.test.ts.
