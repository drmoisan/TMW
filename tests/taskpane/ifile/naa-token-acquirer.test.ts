/**
 * Diagnostic regression tests for the NAA (nested app auth) token-acquirer adapter (issue #43,
 * OD-8 NAA-primary token path). Drives the not-yet-implemented factory
 * `createNaaTokenAcquirer` from src/taskpane/ifile/naa-token-acquirer.ts.
 *
 * The adapter is host-bound (it is the only iFile module permitted to import
 * `@azure/msal-browser`), but it injects the support-check function, the MSAL-instance factory,
 * and the unsupported-environment fallback hook as parameters so it is unit-testable without the
 * Office host or a real MSAL instance. These tests inject a fake public-client-application shape
 * and never import `@azure/msal-browser`.
 */

import { afterEach, describe, expect, it, vi } from "vitest";
import { InteractionRequiredAuthError } from "@azure/msal-browser";
import { createNaaTokenAcquirer } from "../../../src/taskpane/ifile/naa-token-acquirer";

/** Minimal MSAL public-client shape the adapter relies on (acquireTokenSilent/Popup). */
interface FakeMsalInstance {
    acquireTokenSilent: (request: { scopes: string[] }) => Promise<{ accessToken: string }>;
    acquireTokenPopup: (request: { scopes: string[] }) => Promise<{ accessToken: string }>;
}

/** Shape mirroring @azure/msal-browser InteractionRequiredAuthError for the fallback branch. */
class FakeInteractionRequiredAuthError extends Error {
    public readonly errorCode = "interaction_required";
    constructor(message = "interaction required") {
        super(message);
        this.name = "InteractionRequiredAuthError";
    }
}

describe("createNaaTokenAcquirer — NAA token path", () => {
    it("resolves the silent access token when NAA is supported", async () => {
        // Arrange — NAA supported; acquireTokenSilent resolves a token.
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => Promise.resolve({ accessToken: "silent-token" })),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: (e) => e instanceof FakeInteractionRequiredAuthError,
        });

        // Act
        const token = await acquirer();

        // Assert
        expect(token).toBe("silent-token");
        expect(instance.acquireTokenSilent).toHaveBeenCalledTimes(1);
        expect(instance.acquireTokenPopup).not.toHaveBeenCalled();
    });

    it("falls back to acquireTokenPopup on an interaction-required error", async () => {
        // Arrange — silent acquisition rejects with an interaction-required-shaped error.
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() =>
                Promise.reject(new FakeInteractionRequiredAuthError())
            ),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: (e) => e instanceof FakeInteractionRequiredAuthError,
        });

        // Act
        const token = await acquirer();

        // Assert
        expect(token).toBe("popup-token");
        expect(instance.acquireTokenSilent).toHaveBeenCalledTimes(1);
        expect(instance.acquireTokenPopup).toHaveBeenCalledTimes(1);
    });

    it("invokes the documented fallback and rejects when NAA is unsupported", async () => {
        // Arrange — NestedAppAuth 1.1 not supported at runtime.
        const createInstance = vi.fn(() =>
            Promise.resolve({
                acquireTokenSilent: () => Promise.resolve({ accessToken: "unused" }),
                acquireTokenPopup: () => Promise.resolve({ accessToken: "unused" }),
            })
        );
        const onUnsupported = vi.fn();
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => false,
            createInstance,
            isInteractionRequired: () => false,
            onUnsupported,
        });

        // Act / Assert — the unsupported branch produces a deterministic, testable rejection.
        await expect(acquirer()).rejects.toThrow(/NestedAppAuth|not support|NAA/i);
        expect(onUnsupported).toHaveBeenCalledTimes(1);
        // The MSAL instance must not be constructed when NAA is unsupported.
        expect(createInstance).not.toHaveBeenCalled();
    });

    it("re-throws a non-interaction silent error without calling popup", async () => {
        // Arrange — silent acquisition rejects with an error that is NOT interaction-required.
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => Promise.reject(new Error("network down"))),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: () => false,
        });

        // Act / Assert — the original error propagates; popup is not attempted.
        await expect(acquirer()).rejects.toThrow("network down");
        expect(instance.acquireTokenPopup).not.toHaveBeenCalled();
    });
});

/**
 * Tests that exercise the adapter's DEFAULT host/MSAL boundaries (no injected overrides), so the
 * default support check and default interaction-required predicate are covered rather than
 * excluded from coverage. An Office fake is installed on the global so the default support check
 * is reachable; the real `InteractionRequiredAuthError` drives the default predicate.
 */
describe("createNaaTokenAcquirer — default host/MSAL boundaries", () => {
    afterEach(() => {
        delete (globalThis as Record<string, unknown>)["Office"];
        vi.restoreAllMocks();
    });

    function installOfficeRequirements(naaSupported: boolean): void {
        (globalThis as Record<string, unknown>)["Office"] = {
            context: {
                requirements: {
                    isSetSupported: (set: string, version: string) =>
                        set === "NestedAppAuth" && version === "1.1" && naaSupported,
                },
            },
        };
    }

    it("uses the default Office support check and reports unsupported when NAA is absent", async () => {
        // Arrange — Office fake reports NestedAppAuth 1.1 NOT supported; no isNaaSupported override.
        installOfficeRequirements(false);

        // Act — the default support check runs; the acquirer rejects with the unsupported error.
        const acquirer = await createNaaTokenAcquirer({
            // createInstance is injected only as a guard; it must not be reached when unsupported.
            createInstance: () =>
                Promise.resolve({
                    acquireTokenSilent: () => Promise.resolve({ accessToken: "x" }),
                    acquireTokenPopup: () => Promise.resolve({ accessToken: "x" }),
                }),
        });

        // Assert
        await expect(acquirer()).rejects.toThrow(/NestedAppAuth|NAA/i);
    });

    it("uses the default Office support check when NAA is supported and the default interaction predicate", async () => {
        // Arrange — Office fake reports NAA supported; inject only the MSAL instance so the default
        // support check (line 70-72) and default interaction predicate (line 84-87) are exercised.
        installOfficeRequirements(true);
        const instance = {
            acquireTokenSilent: vi
                .fn()
                .mockRejectedValueOnce(new InteractionRequiredAuthError("interaction_required")),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "default-popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            createInstance: () => Promise.resolve(instance),
        });

        // Act — the default predicate recognizes the real InteractionRequiredAuthError and the
        // acquirer falls back to popup.
        const token = await acquirer();

        // Assert
        expect(token).toBe("default-popup-token");
        expect(instance.acquireTokenPopup).toHaveBeenCalledTimes(1);
    });

    it("builds the MSAL instance via the default constructor seam with the iFile config", async () => {
        // Arrange — NAA supported; inject the nestable-client constructor so the default
        // createInstance path (config-building + construct) is exercised without a real broker.
        installOfficeRequirements(true);
        const constructed = {
            acquireTokenSilent: vi.fn(() => Promise.resolve({ accessToken: "built-token" })),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "unused" })),
        };
        const nestableClientConstructor = vi.fn((config: { auth: { clientId: string } }) => {
            // Assert the adapter passed the non-secret client id into the MSAL config.
            expect(config.auth.clientId).toBe("2921bc0b-4518-4547-b8ca-f937713688ec");
            return Promise.resolve(constructed);
        });
        const acquirer = await createNaaTokenAcquirer({ nestableClientConstructor });

        // Act
        const token = await acquirer();

        // Assert — the default createInstance built the client via the injected constructor.
        expect(nestableClientConstructor).toHaveBeenCalledTimes(1);
        expect(token).toBe("built-token");
    });

    it("the default interaction predicate re-throws a non-interaction error", async () => {
        // Arrange — NAA supported via the default check; a plain error from silent acquisition.
        installOfficeRequirements(true);
        const instance = {
            acquireTokenSilent: vi.fn(() => Promise.reject(new Error("transient"))),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "unused" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            createInstance: () => Promise.resolve(instance),
        });

        // Act / Assert — the default predicate returns false, so the original error propagates.
        await expect(acquirer()).rejects.toThrow("transient");
        expect(instance.acquireTokenPopup).not.toHaveBeenCalled();
    });
});
