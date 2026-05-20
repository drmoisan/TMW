# Baseline — Architecture-Boundary Check

- Timestamp: 2026-05-19T22-42
- Task: [P0-T5]
- Command: `npm run depcruise` (`depcruise --config .dependency-cruiser.cjs src`)
- EXIT_CODE: 0
- Output Summary: PASS. 1 dependency violation reported as a warning (0 errors, 1 warning): `no-orphans: src/api-client/v1.ts`. 18 modules, 20 dependencies cruised. Zero error-level violations; the single warning is a pre-existing orphan on a generated file and does not fail the gate (exit code 0).
