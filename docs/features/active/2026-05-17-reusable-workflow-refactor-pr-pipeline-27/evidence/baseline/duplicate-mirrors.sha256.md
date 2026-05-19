# Baseline — Duplicate mirror SHA256

Timestamp: 2026-05-18T10-15
Command: Get-FileHash <each mirror> -Algorithm SHA256
EXIT_CODE: 0

| File | SHA256 |
|---|---|
| .github/workflows/stage-10-benchmark-regression.yml | A32955BCD8E08BAB2065D80C53E74D612DA11EB94AF64EBEC97B897C234F4223 |
| .github/workflows/benchmark-gate-self-validation.yml | ECB5102F60D49F6DAF89360E7C022F8D985814AE7E7D8CA82129C45E0E9930CC |

Output Summary: 2 duplicate mirror files preserved at evidence/baseline/*.pre-delete.yml prior to deletion in Phase 4; sha256 above is the authoritative provenance.
