# Final QA — Coverage Delta / Threshold Verification (Issue #43, cycle 2)

Timestamp: 2026-06-04T20-29

Uniform gates: line >= 85%, branch >= 75%, no regression on changed lines. C# is not modified this
cycle (Phase 6 is verification-only), so no .NET coverage delta applies.

## TypeScript — headline (All files)

| Metric | Baseline (P0-T6) | Post-change (P8-T5) |
|---|---|---|
| Line | 96.25% | 96.48% |
| Branch | 95.02% | 95.47% |

Headline line and branch both increased; both exceed the 85% / 75% gates.

## TypeScript — modified / new files (changed-line coverage)

| File | Baseline line / branch | Post-change line / branch | Status |
|---|---|---|---|
| src/taskpane/ifile/ifile.ts | 85.48% / 94.11% | 86.95% / 93.75% | PASS (>= 85% / >= 75%) |
| src/taskpane/ifile/inline-host.ts | 100% / 100% | 100% / 100% | PASS |
| src/taskpane/ifile/naa-token-acquirer.ts | n/a (new file) | 98.14% / 100% | PASS (>= 85% / >= 75%) |

- ifile.ts: the only uncovered lines (174-182) are the `typeof Office !== "undefined"`
  Office.onReady host-registration guard, not reachable in jsdom. The new stage-message routing and
  the NAA-acquirer wiring are covered by the host-shell and bootstrap-seam tests. Line coverage rose
  from 85.48% to 86.95% (no regression on changed lines).
- inline-host.ts: unchanged at 100% / 100% after the parameterized connection-message change.
- naa-token-acquirer.ts (new): 98.14% line / 100% branch. The single uncovered line (83) is the real
  MSAL `createNestablePublicClientApplication` default-constructor lambda — the thinnest host-only
  wiring. The config-building default, the support-check default, the interaction-required default,
  the silent path, the popup fallback, the non-interaction re-throw, and the unsupported-environment
  branch are all covered.

## No production file excluded from coverage

vitest.config.ts excludes only non-production paths. naa-token-acquirer.ts, ifile.ts, and
inline-host.ts are all in the coverage denominator. No production file is coverage-excluded.

## Outcome

PASS. All required coverage values are numeric (no placeholders). The headline and every
changed/new iFile production file meet line >= 85% and branch >= 75% with no regression on changed
lines. The NAA adapter and the stage-message routing are covered.
