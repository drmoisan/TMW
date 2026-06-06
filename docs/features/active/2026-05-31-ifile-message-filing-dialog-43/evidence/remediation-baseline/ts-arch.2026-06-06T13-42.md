# Baseline — TypeScript Architecture Boundary (dependency-cruiser) — iFile #43 Cycle 4

Timestamp: 2026-06-06T13-42
Command: npm run depcruise  (depcruise --config .dependency-cruiser.cjs src)
EXIT_CODE: 0
Output Summary: PASS. 0 errors (6 dependency violations, all `warn`-level `no-orphans` on
pre-existing entry-point modules: taskpane.ts, folder-result.ts, archive-root-picker.ts,
classifier-client.ts, commands.ts, api-client/v1.ts). 28 modules, 21 dependencies cruised.

MSAL import-boundary rule confirmed present and passing: the dependency-cruiser config
(.dependency-cruiser.cjs) restricts `@azure/msal-browser` imports so that only
`naa-token-acquirer.ts` (the host-bound NAA auth adapter) may import it; the iFile pure
host-neutral modules are forbidden from importing MSAL. Zero violations of this rule in the
baseline.
