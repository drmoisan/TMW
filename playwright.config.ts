/**
 * Playwright configuration for the TaskMaster E2E smoke lane (Issue #19).
 *
 * The `setup` project performs the client-credentials (service-principal) auth
 * flow and writes the bearer token into a Playwright storageState file. The
 * `smoke` project depends on `setup` and consumes that storageState, so every
 * smoke test runs with an authenticated context. There is no interactive login
 * path: missing credentials fail the setup project closed.
 */

import { defineConfig } from "@playwright/test";

const STORAGE_STATE = "tests/e2e/.auth/storage-state.json";

export default defineConfig({
    testDir: "tests/e2e",
    // Fail the run rather than hang if a test or the auth setup stalls.
    timeout: 30_000,
    expect: {
        timeout: 10_000,
    },
    // Smoke tests hit a shared test tenant; keep the run serial and fail fast.
    fullyParallel: false,
    forbidOnly: !!process.env["CI"],
    retries: 0,
    workers: 1,
    reporter: process.env["CI"] ? "github" : "list",
    projects: [
        {
            name: "setup",
            testMatch: /auth\.setup\.ts$/,
        },
        {
            name: "smoke",
            testMatch: /.*\.spec\.ts$/,
            dependencies: ["setup"],
            use: {
                storageState: STORAGE_STATE,
            },
        },
    ],
});
