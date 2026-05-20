# Regression — manifest.json Byte-for-Byte Unchanged

- Timestamp: 2026-05-19T22-50
- Task: [P7-T7]
- Command (PowerShell): `Get-FileHash manifest.json -Algorithm SHA256`
- EXIT_CODE: 0
- Output Summary: HASHES MATCH — `manifest.json` is byte-for-byte unchanged.
  - Baseline (P0-T8) SHA-256:    `7BDD7A7F32C8B519F3D98275B5D071340669499211C4D9D1BA4E4C4564870026`
  - Post-change (P7-T7) SHA-256: `7BDD7A7F32C8B519F3D98275B5D071340669499211C4D9D1BA4E4C4564870026`
  - Result: EQUAL. The unified `manifest.json` was not modified by this feature; only `manifest.xml` (new), `package.json` (added `validate:xml`), `webpack.config.js` (extended copy glob), `assets/` (nine new icons), `src/taskpane/*` (responsive CSS + close button), CI contract action, and tests changed. Maps to spec/user-story CI-AC "manifest.json is unchanged".
