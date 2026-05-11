---
artifact: p3-gitleaks-fake-secret
---

# P3-T3 Gitleaks Functional Fake-Secret Demonstration

Timestamp: 2026-05-10T00-21
Installer Invocation: pwsh -NoProfile -File .github/scripts/install-gitleaks.ps1 (see evidence/qa-gates/p3-gitleaks-install.md)
Resolved Binary: C:\Users\DanMoisan\AppData\Local\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_Microsoft.Winget.Source_8wekyb3d8bbwe\gitleaks.exe (version 8.30.1)

Procedure:
1. Created fixture `tmp-secret-fixture-issue1.txt` at repo root with content:
   `graph_client_secret = "AKIAABCDEFGHIJKLMNOP1234567890"`
2. `git add tmp-secret-fixture-issue1.txt`
3. Ran `gitleaks protect --staged --no-banner --redact --verbose --config=.gitleaks.toml`
4. `git restore --staged tmp-secret-fixture-issue1.txt`
5. Removed fixture from working tree.

Command: `<resolved-gitleaks> protect --staged --no-banner --redact --verbose --config=.gitleaks.toml`
EXIT_CODE: 1 (non-zero — secret correctly rejected)

Output Summary: gitleaks reported `leaks found: 2` (2 findings against the staged fixture):
- RuleID: `graph-client-secret` — matched `graph_client_secret = "REDACTED"` (custom rule from `.gitleaks.toml`).
- RuleID: `generic-api-key` — matched the redacted secret literal (default-rules extension via `[extend].useDefault = true`).

Both findings show `Secret: REDACTED` (redaction enforced). The presence of the
`graph-client-secret` finding confirms the repository-specific custom rule fires on the
staged content. The non-zero exit code (1) is the gate signal lefthook uses to block the
commit.

Redacted output (verbose):
```
Finding:     REDACTED = "AKIAABCDEFGHIJKLMNOP1234567890"
Secret:      REDACTED
RuleID:      graph-client-secret
Entropy:     3.576618
Tags:        [secret graph]
File:        tmp-secret-fixture-issue1.txt
Line:        1
Fingerprint: tmp-secret-fixture-issue1.txt:graph-client-secret:1

Finding:     graph_client_secret = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.615061
File:        tmp-secret-fixture-issue1.txt
Line:        1
Fingerprint: tmp-secret-fixture-issue1.txt:generic-api-key:1

8:07AM INF 0 commits scanned.
8:07AM INF scanned ~55 bytes (55 bytes) in 95.8ms
8:07AM WRN leaks found: 2
```

WorkingTreeRestored: true (fixture file deleted after scan; `git status` shows no `tmp-secret-fixture-issue1.txt` entry).
