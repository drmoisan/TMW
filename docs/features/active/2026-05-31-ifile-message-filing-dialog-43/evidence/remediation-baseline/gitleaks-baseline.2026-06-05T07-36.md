# Gitleaks Baseline (Pre-Fix Failing State)

Timestamp: 2026-06-05T07-36

Command: `gitleaks detect --no-banner --redact --config=.gitleaks.toml --log-opts="origin/main..HEAD"`

EXIT_CODE: 1

## Output Summary

- Leak count: 1
- Rule id: `generic-api-key` (gitleaks default ruleset)
- File: `README.md` (repo root)
- Line reported by gitleaks: 145 (the line position in the historical blob at commit `89f8381`, which is the commit the line is attributed to). The same assignment is at current `README.md` line 153 after the cycle-3 README restructure; gitleaks reports the blob-relative line number for the attributed commit.
- Finding form: `$secretsId = "REDACTED"   # project UserSecretsId (from TaskMaster.Api.csproj)`
- Secret value (non-secret in reality): `b3c44e17-fca8-45e2-a550-80f2d481007e` — the dotnet `UserSecretsId` published in `src/TaskMaster.Api/TaskMaster.Api.csproj`.
- Fingerprint: `89f8381ba9422bd9b49e4bf412eafc0a523f2b16:README.md:generic-api-key:145`
- Commit: `89f8381` (`docs: updated README`)

This reproduces the failing `secret-scan` CI state: exactly one finding, rule `generic-api-key`, on the repo-root `README.md` `secretsId = "<guid>"` assignment. The value is a non-secret project identifier (dotnet `UserSecretsId`), not a credential.

6 commits scanned (origin/main..HEAD); ~781.69 KB scanned.
