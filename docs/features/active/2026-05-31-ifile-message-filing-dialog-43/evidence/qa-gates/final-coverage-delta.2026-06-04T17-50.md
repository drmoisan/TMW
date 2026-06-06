# Coverage Delta / Threshold Verification ([P6-T6])

Timestamp: 2026-06-04T17-50
Baseline source: evidence/remediation-baseline/ts-test-coverage.md (Phase 0 [P0-T6])
Post-change source: evidence/qa-gates/final-ts-test-coverage.2026-06-04T17-50.md (Phase 6 [P6-T5])

## Headline Coverage (All files)

| Metric | Baseline | Post-change | Threshold | Result |
|---|---|---|---|---|
| Lines | 91.37% | 96.25% | >= 85% | PASS (+4.88) |
| Branches | 94.00% | 95.02% | >= 75% | PASS (+1.02) |

No global regression: both metrics increased.

## Changed / New File Coverage (modified or added this cycle)

| File | Baseline lines / branches | Post-change lines / branches | Changed-line threshold (line >= 85% / branch >= 75%) |
|---|---|---|---|
| src/taskpane/ifile/ifile.ts | 0% / 0% (lines 1-56 uncovered) | 85.48% / 94.11% | PASS |
| src/taskpane/ifile/inline-host.ts | 96.29% / 100% | 100% / 100% | PASS |
| src/taskpane/ifile/api-base-url.ts | n/a (new) | 100% / 90.9% | PASS |
| webpack.config.js | (not in coverage scope) | n/a | n/a (config, build-only) |

Phase 4 file: none (P4-T2 was OUT_OF_SCOPE_DEFERRED; no token-acquisition file added).

## Seam Coverage Conclusion

- The previously-uncovered host-bootstrap seam `ifile.ts` is now covered: 0% -> 85.48% lines,
  0% -> 94.11% branches. The only remaining uncovered region (lines 141-149) is the
  `if (typeof Office !== "undefined") { Office.onReady(...) }` host-registration block, which is the
  thinnest possible host-only wiring and cannot execute under the test runtime. This is a real,
  visible cost left in the metric rather than a coverage exclusion.
- No production file is coverage-excluded in vitest.config.ts (verified: the exclude list contains
  only non-production paths — node_modules, dist, lib, *.test.ts, test-support, and config files).
- Changed-line coverage meets line >= 85% and branch >= 75% on every modified/new production file.

## Outcome

PASS. No regression on changed lines; changed-line thresholds met; the host-bootstrap seam is now
covered and not excluded.
