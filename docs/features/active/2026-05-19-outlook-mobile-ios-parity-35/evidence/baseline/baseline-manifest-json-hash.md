# Baseline — manifest.json Content Fingerprint

- Timestamp: 2026-05-19T22-42
- Task: [P0-T8]
- Command (PowerShell): `Get-FileHash manifest.json -Algorithm SHA256`
- EXIT_CODE: 0
- Output Summary: SHA-256 = `7BDD7A7F32C8B519F3D98275B5D071340669499211C4D9D1BA4E4C4564870026`
  - Path: C:\Users\DanMoisan\repos\TMW\manifest.json
  - This pre-change hash is the no-regression reference used by P7-T7 to prove `manifest.json` is byte-for-byte unchanged.
