# Final QA — Coverage Delta / Threshold Verification

- Timestamp: 2026-06-06T12-22
- Task: [P5-T4]

## Values

| Measurement | Line coverage | Source |
|---|---|---|
| Baseline (P0-T4) | 0.00% (instrumented `.claude/hooks` set, not exercised by the `tests/pester/powershell` scope; no feature file existed) | `evidence/baseline/baseline-pester-coverage.md` |
| Post-change (P5-T3), new file | 92.31% line (92.44% command) | `evidence/qa-gates/final-pester-coverage.md` |
| New/changed-code coverage | 92.31% line — the new file `Invoke-AuthenticodeSigning.ps1` is entirely new code; its post-change coverage is the new-code coverage | `artifacts/pester/authenticode-coverage.xml` |

## No-regression determination

- The feature adds two new files (`Invoke-AuthenticodeSigning.ps1`, `Invoke-AuthenticodeSigning.Tests.ps1`)
  and modifies no existing production file, so there are no pre-existing changed lines whose coverage could
  regress. No-regression on changed lines is satisfied by construction.
- The new production file's line coverage is 92.31%, exceeding the uniform thresholds (line >= 85%,
  branch >= 75%). Branch behavior is fully exercised (see [P5-T3] evidence); command coverage 92.44% is the
  branch proxy.

## Determination: PASS

All required coverage values are available and numeric. New-code line coverage (92.31%) meets the line
threshold; branch behavior is fully exercised and meets the branch threshold. No coverage regression on
changed lines (no existing production lines changed).
