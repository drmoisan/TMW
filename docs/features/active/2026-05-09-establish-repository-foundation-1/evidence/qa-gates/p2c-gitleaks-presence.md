---
artifact: p2c-gitleaks-presence
---

Timestamp: 2026-05-10T02-41
Command: Test-Path .gitleaks.toml; Select-String 'graph-client-secret|office-addin-shared-key' .gitleaks.toml
EXIT_CODE: 0
Output Summary: .gitleaks.toml exists at repo root, non-empty, and contains both extension rules: graph-client-secret and office-addin-shared-key. [extend] useDefault=true present.
