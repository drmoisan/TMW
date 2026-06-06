# Final QA — Coverage Delta — iFile #43 Cycle 4

Timestamp: 2026-06-06T13-42

Baseline source: evidence/remediation-baseline/ts-test-coverage.2026-06-06T13-42.md (P0-T6)
Post-change source: evidence/qa-gates/final-ts-test-coverage.2026-06-06T13-42.md (P6-T5)

## All-files coverage

| Metric | Baseline | Post-change | Delta |
|---|---|---|---|
| Line coverage | 95.45% | 95.47% | +0.02 (no regression) |
| Branch coverage | 92.43% | 92.49% | +0.06 (no regression) |
| Statements | 95.45% | 95.47% | +0.02 |
| Functions | 98.61% | 98.61% | 0.00 |

## Changed-file coverage — src/taskpane/ifile/naa-token-acquirer.ts

| Metric | Baseline | Post-change | Delta |
|---|---|---|---|
| Statements | 98.23% | 98.27% | +0.04 |
| Branch | 95.00% | 95.23% | +0.23 (no regression) |
| Functions | 90.00% | 90.00% | 0.00 |
| Lines | 98.23% | 98.27% | +0.04 |

Uncovered lines: baseline 212, 263 → post-change 198, 249 (same two host-bound default paths —
the default nestable-client constructor adapter and the `attachMsalLog` non-writable-target catch;
line numbers shifted up by the removal of the diagnostic comment blocks).

## Changed-line coverage assessment

The cycle-4 edits to naa-token-acquirer.ts are:
1. CLIENT_ID constant value change (covered by the realigned clientId assertion test).
2. Reinstated `if (containsPii) { return; }` guard and the third `containsPii` callback parameter
   — both the true path (PII message excluded) and false path (non-PII message retained) are
   exercised by the restored PII-skip tests.
3. `piiLoggingEnabled: false` (asserted by the updated loggerOptions test).
4. Removal of diagnostic comment blocks (non-executable).

No changed executable line is uncovered. Branch coverage on naa-token-acquirer.ts rose from 95.00%
to 95.23%, confirming the reinstated PII-skip branch is covered. No regression on changed lines.

Output Summary: PASS. No coverage regression at the all-files level or on the changed file; the
reinstated PII-skip branch is covered on both its true and false paths.
