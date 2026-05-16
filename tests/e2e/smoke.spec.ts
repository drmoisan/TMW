/**
 * E2E smoke tests for the TaskMaster API (Issue #19).
 *
 * Exercises three smoke paths against the test tenant using the bearer token
 * acquired by `auth.setup.ts`:
 *   1. GET /health                  -> 200, { status: "ok" }
 *   2. POST /api/classify           -> 200, { label, confidence }
 *   3. POST /api/classify/feedback  -> 204
 *
 * The tests depend on Playwright's `setup` project (configured in
 * `playwright.config.ts`) running first; the storageState file produced there
 * carries the bearer token.
 */

import { test, expect, type APIRequestContext } from "@playwright/test";
import { readFile } from "node:fs/promises";

const STORAGE_STATE = "tests/e2e/.auth/storage-state.json";

interface StoredOrigin {
    origin: string;
    localStorage: { name: string; value: string }[];
}

interface StoredAuthState {
    cookies: unknown[];
    origins: StoredOrigin[];
}

/** Reads the bearer token written by `auth.setup.ts`. */
async function readAccessToken(): Promise<string> {
    const raw = await readFile(STORAGE_STATE, "utf8");
    const parsed = JSON.parse(raw) as StoredAuthState;
    const entry = parsed.origins
        .flatMap((origin) => origin.localStorage)
        .find((item) => item.name === "e2e.accessToken");
    if (entry === undefined || entry.value.length === 0) {
        throw new Error(
            "E2E smoke: storage state did not contain an access token. Did auth.setup.ts run?"
        );
    }
    return entry.value;
}

/** Resolves the API base URL from the required environment variable. */
function readBaseUrl(): string {
    const url = process.env["E2E_API_BASE_URL"];
    if (url === undefined || url.trim() === "") {
        throw new Error("E2E smoke: E2E_API_BASE_URL is required but was not set.");
    }
    return url.replace(/\/$/, "");
}

async function authorizedHeaders(): Promise<Record<string, string>> {
    const token = await readAccessToken();
    return {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
    };
}

async function getJson(
    request: APIRequestContext,
    url: string
): Promise<{ status: number; body: unknown }> {
    const headers = await authorizedHeaders();
    const response = await request.get(url, { headers });
    return { status: response.status(), body: await response.json() };
}

test.describe("TaskMaster API smoke", () => {
    test("GET /health returns 200 with status ok", async ({ request }) => {
        // Arrange + Act
        const baseUrl = readBaseUrl();
        const result = await getJson(request, `${baseUrl}/health`);

        // Assert
        expect(result.status).toBe(200);
        expect(result.body).toMatchObject({ status: "ok" });
    });

    test("POST /api/classify returns 200 with label and confidence", async ({ request }) => {
        // Arrange
        const baseUrl = readBaseUrl();
        const headers = await authorizedHeaders();
        const payload = {
            messageId: "smoke-test-message",
            subject: "Smoke test subject",
            body: "Smoke test body content.",
        };

        // Act
        const response = await request.post(`${baseUrl}/api/classify`, {
            headers,
            data: payload,
        });

        // Assert
        expect(response.status()).toBe(200);
        const body = (await response.json()) as { label?: unknown; confidence?: unknown };
        expect(typeof body.label).toBe("string");
        expect(["number", "string"]).toContain(typeof body.confidence);
    });

    test("POST /api/classify/feedback returns 204", async ({ request }) => {
        // Arrange
        const baseUrl = readBaseUrl();
        const headers = await authorizedHeaders();
        const payload = {
            messageId: "smoke-test-message",
            label: "General",
            confirmed: true,
        };

        // Act
        const response = await request.post(`${baseUrl}/api/classify/feedback`, {
            headers,
            data: payload,
        });

        // Assert
        expect(response.status()).toBe(204);
    });
});
