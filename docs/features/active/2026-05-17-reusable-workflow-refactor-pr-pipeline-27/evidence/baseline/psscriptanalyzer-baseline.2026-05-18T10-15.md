# Baseline — PSScriptAnalyzer

Timestamp: 2026-05-18T10-15
Command: Invoke-ScriptAnalyzer -Path scripts/ -Recurse  +  Invoke-ScriptAnalyzer -Path .github/scripts/ -Recurse
EXIT_CODE: 0

Results (combined):
- Total findings: 6
- Information: 4
- Warning: 2
- Error: 0

Output Summary: 6 pre-existing PSSA findings (4 Information, 2 Warning, 0 Error). Refactor adds no PowerShell, so P6-T7 post-refactor count must equal these numbers exactly.
