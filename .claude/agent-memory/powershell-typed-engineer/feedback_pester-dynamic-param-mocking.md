---
name: pester-dynamic-param-mocking
description: Pester v5 cannot reliably bind FileSystem-provider dynamic params (-Raw, -Encoding) on cmdlets mocked across a dot-sourced-file scope boundary
metadata:
  type: feedback
---

When a production `.ps1` is imported into a Pester v5 test via `. $ScriptPath` (dot-source) and a function defined in that file calls `Get-Content -Raw` or `Set-Content -Encoding`, mocking `Get-Content`/`Set-Content` fails with "A parameter cannot be found that matches parameter name 'Raw'/'Encoding'". `-Raw` and `-Encoding` are FileSystem-provider *dynamic* parameters; Pester's mock bootstrap injected into the dot-sourced file's separate session state does not expose them. Mocks of the same cmdlets work when the calling function is defined *inline* in the test's own `BeforeAll` scope, and mocks of static-parameter cmdlets (Test-Path, Get-Command, Start-Process, Get-Process, Stop-Process, Remove-Item) work fine across the dot-source boundary. Verified empirically on Pester 5.6.1, PowerShell 7, win32, 2026-05-20.

**Why:** The mock wrapper Pester generates lives in the mock-declaration session state and only carries the cmdlet's static parameter metadata; provider dynamic parameters are resolved per-call and are absent from the cross-scope wrapper.

**How to apply:** Do not unit-test single raw-I/O lines (`Get-Content -Raw`, `Set-Content -Encoding`) by mocking the framework cmdlet across a dot-sourced-file boundary. Those lines carry no branching logic. Cover the JSON parse/serialize transform end-to-end through the higher-level injected I/O seam (e.g. `ReadStateAction`/`WriteStateAction`) instead, and document the omission. This aligns with the repo's "prefer real code paths / isolate I/O" mocking guidance. If the raw line itself must be covered, define the function inline in the test scope rather than dot-sourcing the file. See [[pester-scripts-test-layout]].
