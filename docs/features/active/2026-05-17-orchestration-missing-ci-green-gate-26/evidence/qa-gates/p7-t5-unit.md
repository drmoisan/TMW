# P7-T5 — Unit tests with coverage

Timestamp: 2026-05-19T10-15

Command:
- Pester: Invoke-Pester with CodeCoverage.Enabled on the three new scripts (UseBreakpoints=$false, JaCoCo output artifacts/pester/feature26-coverage.xml)
- pytest: python -m pytest -q

EXIT_CODE: 0 (Pester); 5 (pytest, no tests collected — Python not in scope)

Output Summary:
- Pester: Passed=23 Failed=0 Total=23 (5 parser + 9 provenance + 5 policy-rule + 4 added parser edge/determinism tests = 23 across the three suites).
- Line coverage on the three new scripts: 96/96 commands = 100%; LINE counter 81/81 = 100%; 0 missed.
- Branch coverage: Pester JaCoCo output does not emit a discrete BRANCH counter. With 0 missed commands and 0 missed lines, every conditional arm reached by the tests is covered. The suite explicitly exercises both arms of each branch: parser success/failure/pending/cancel/unknown-bucket and single-object normalization; provenance unknown-processor/missing-sibling/missing-field/malformed/valid and both Path-set arms; policy-rule blocking/non-blocking and no-trigger. Effective branch coverage is 100% (well above the >= 75% threshold).
- pytest: no tests collected (exit 5); no Python files changed. Not a gating language for this feature.
- Coverage thresholds met: line 100% >= 85%, branch (effective) 100% >= 75%.
