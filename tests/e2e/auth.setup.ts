/**
 * Playwright auth setup for the TaskMaster E2E smoke lane (Issue #19).
 *
 * Performs the OAuth 2.0 client-credentials (service-principal) flow against the
 * Microsoft identity platform token endpoint and stores the resulting bearer
 * token in a Playwright storageState file for the dependent `smoke` project.
 *
 * Fail-closed: every required environment variable is validated up front. A
 * missing variable throws an explicit error and aborts the run. There is no
 * interactive login fallback.
 */

import { test as setup, expect } from "@playwright/test";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";

const STORAGE_STATE = "tests/e2e/.auth/storage-state.json";

/** Names of the environment variables the client-credentials flow requires. */
const REQUIRED_ENV_VARS = [
    "AZURE_TENANT_ID",
    "AZURE_CLIENT_ID",
    "AZURE_CLIENT_SECRET",
    "E2E_API_BASE_URL",
] as const;

type RequiredEnv = Record<(typeof REQUIRED_ENV_VARS)[number], string>;

/**
 * Reads and validates the required environment variables. Throws an explicit
 * error naming the missing variable if any is absent or empty (fail closed).
 */
function readRequiredEnv(): RequiredEnv {
    const missing: string[] = [];
    const values: Partial<RequiredEnv> = {};
    for (const name of REQUIRED_ENV_VARS) {
        const value = process.env[name];
        if (value === undefined || value.trim() === "") {
            missing.push(name);
        } else {
            values[name] = value;
        }
    }
    if (missing.length > 0) {
        throw new Error(
            `E2E auth setup failed closed: missing required environment variable(s): ${missing.join(", ")}. ` +
                "Supply AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and E2E_API_BASE_URL via CI secrets."
        );
    }
    return values as RequiredEnv;
}

/** Shape of the token endpoint success response used by this setup. */
interface TokenResponse {
    access_token: string;
    expires_in: number;
    token_type: string;
}

/**
 * Acquires an access token via the client-credentials grant against the
 * Microsoft identity platform token endpoint for the configured tenant.
 */
async function acquireAccessToken(env: RequiredEnv): Promise<string> {
    const tokenEndpoint = `https://login.microsoftonline.com/${env.AZURE_TENANT_ID}/oauth2/v2.0/token`;
    const body = new URLSearchParams({
        client_id: env.AZURE_CLIENT_ID,
        client_secret: env.AZURE_CLIENT_SECRET,
        grant_type: "client_credentials",
        scope: `${env.AZURE_CLIENT_ID}/.default`,
    });

    const response = await fetch(tokenEndpoint, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: body.toString(),
    });

    if (!response.ok) {
        const detail = await response.text();
        throw new Error(
            `E2E auth setup failed: token endpoint returned ${String(response.status)} ${response.statusText}. ${detail}`
        );
    }

    const json = (await response.json()) as TokenResponse;
    if (typeof json.access_token !== "string" || json.access_token.length === 0) {
        throw new Error(
            "E2E auth setup failed: token endpoint response did not contain an access_token."
        );
    }
    return json.access_token;
}

setup("authenticate via client-credentials flow", async () => {
    // Arrange — validate required configuration; throws fail-closed if absent.
    const env = readRequiredEnv();

    // Act — acquire a bearer token via the service-principal flow.
    const accessToken = await acquireAccessToken(env);
    expect(accessToken.length).toBeGreaterThan(0);

    // Assert / persist — store the token in a Playwright storageState file so the
    // dependent `smoke` project runs authenticated. The token is exposed to smoke
    // tests via the `origins[].localStorage` channel.
    await mkdir(dirname(STORAGE_STATE), { recursive: true });
    const storageState = {
        cookies: [],
        origins: [
            {
                origin: env.E2E_API_BASE_URL,
                localStorage: [{ name: "e2e.accessToken", value: accessToken }],
            },
        ],
    };
    await writeFile(STORAGE_STATE, JSON.stringify(storageState, null, 2), "utf8");
});
