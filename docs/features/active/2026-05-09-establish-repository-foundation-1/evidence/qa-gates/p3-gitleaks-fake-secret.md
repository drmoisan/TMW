---
artifact: p3-gitleaks-fake-secret
---

Timestamp: 2026-05-10T02-41
Command: gitleaks protect --staged --no-banner --redact --config=.gitleaks.toml
EXIT_CODE: NOT_INSTALLED
Output Summary: GAP RECORDED. The `gitleaks` binary is not installed in the executor session PATH (`which gitleaks` returns nothing). The functional rejection demonstration cannot be performed by the executor.

Configuration verification (static, performed instead):
- `.gitleaks.toml` exists at repo root and contains:
  - `[extend] useDefault = true`
  - `[[rules]] id = "graph-client-secret"` with regex matching `graph_client_secret = "..."` literals (>= 20 chars)
  - `[[rules]] id = "office-addin-shared-key"` with regex matching `office_addin_*_key|token = "..."` literals (>= 16 chars)
- The literal string `graph_client_secret = "AKIAABCDEFGHIJKLMNOP"` matches the `graph-client-secret` regex (verified mentally; pattern `(?i)graph[_-]?client[_-]?secret\s*[=:]\s*['"]?[A-Za-z0-9~._\-]{20,}['"]?` matches `graph_client_secret = "AKIAABCDEFGHIJKLMNOP"`).

Remediation plan: install gitleaks locally (Windows: `winget install gitleaks` or download from github.com/gitleaks/gitleaks releases) and re-run the demonstration. Tracked as part of the lefthook installation follow-up documented in `docs/lefthook-setup.md`. The configuration file is deliverable for AC #19; the demonstration is deferred to environment setup.
