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
import { InteractionRequiredAuthError, LogLevel } from "@azure/msal-browser";
import {
    createMsalLogCapture,
    createNaaTokenAcquirer,
    type MsalLogCapture,
} from "../../../src/taskpane/ifile/naa-token-acquirer";

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
            acquireTokenSilent: vi.fn(() => Promise.reject(new FakeInteractionRequiredAuthError())),
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

    it("attaches the captured MSAL log to a non-interaction silent error as an enumerable msalLog property", async () => {
        // Arrange — a real capture buffer; the test drives its logger seam to record a known message,
        // then silent acquisition rejects with a non-interaction error (the observed ServerError case).
        const logCapture = createMsalLogCapture();
        const brokerDetail = "NAA broker bridge: status=BadRequest description=blocked by policy";
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => {
                // Simulate MSAL routing internal logger output through the capture during acquisition.
                logCapture.loggerOptions.loggerCallback(LogLevel.Error, brokerDetail, false);
                return Promise.reject(new Error("ServerError"));
            }),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: () => false,
            logCapture,
        });

        // Act — capture the propagated error.
        let caught: unknown;
        try {
            await acquirer();
        } catch (error: unknown) {
            caught = error;
        }

        // Assert — msalLog is an enumerable own string property carrying the captured broker detail.
        expect(typeof caught).toBe("object");
        const record = caught as Record<string, unknown>;
        expect(Object.keys(record)).toContain("msalLog");
        expect(typeof record["msalLog"]).toBe("string");
        expect(record["msalLog"]).toContain(brokerDetail);
        expect(instance.acquireTokenPopup).not.toHaveBeenCalled();
    });

    it("excludes a Warning/Error message flagged as containing PII while retaining a non-PII message at the same level", async () => {
        // Arrange — drive the logger seam with a PII-flagged message and a non-PII message, both at
        // Warning level. The PII-skip guard must drop the PII-flagged message and keep the non-PII one.
        const logCapture = createMsalLogCapture();
        const piiMessage = "bridge description=blocked for upn=user@contoso.com";
        const safeMessage = "bridge status=Forbidden";
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => {
                logCapture.loggerOptions.loggerCallback(LogLevel.Warning, piiMessage, true);
                logCapture.loggerOptions.loggerCallback(LogLevel.Warning, safeMessage, false);
                return Promise.reject(new Error("ServerError"));
            }),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: () => false,
            logCapture,
        });

        // Act
        let caught: unknown;
        try {
            await acquirer();
        } catch (error: unknown) {
            caught = error;
        }

        // Assert — the PII-flagged message is excluded; the non-PII message at the same level is retained.
        const msalLog = (caught as Record<string, unknown>)["msalLog"];
        expect(typeof msalLog).toBe("string");
        expect(msalLog).not.toContain(piiMessage);
        expect(msalLog).toContain(safeMessage);
    });

    it("retains only Warning/Error messages and strips MSAL boilerplate from them", async () => {
        // Arrange — drive the logger seam with a mix of levels formatted the way MSAL formats them
        // (leading timestamp, correlationId, and @azure/msal-browser@<version> boilerplate). Only the
        // Warning and Error lines must survive, with the boilerplate stripped to the level/message tail.
        const logCapture = createMsalLogCapture();
        const infoLine =
            "[Mon, 01 Jan 2026 00:00:00 GMT] : [11111111-2222-3333-4444-555555555555] : " +
            "@azure/msal-browser@3.0.0 : Info - NativeMessageHandler - sending request to broker";
        const verboseLine =
            "[Mon, 01 Jan 2026 00:00:01 GMT] : [11111111-2222-3333-4444-555555555555] : " +
            "@azure/msal-browser@3.0.0 : Verbose - internal event code 0x8004";
        const warningLine =
            "[Mon, 01 Jan 2026 00:00:02 GMT] : [11111111-2222-3333-4444-555555555555] : " +
            "@azure/msal-browser@3.0.0 : Warning - NAA broker bridge returned status=BadRequest " +
            "description=blocked by Conditional Access policy";
        const errorLine =
            "[Mon, 01 Jan 2026 00:00:03 GMT] : [11111111-2222-3333-4444-555555555555] : " +
            "@azure/msal-browser@3.0.0 : Error - ServerError: invalid_grant";
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => {
                logCapture.loggerOptions.loggerCallback(LogLevel.Info, infoLine, false);
                logCapture.loggerOptions.loggerCallback(LogLevel.Verbose, verboseLine, false);
                logCapture.loggerOptions.loggerCallback(LogLevel.Warning, warningLine, false);
                logCapture.loggerOptions.loggerCallback(LogLevel.Error, errorLine, false);
                return Promise.reject(new Error("ServerError"));
            }),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "popup-token" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: () => false,
            logCapture,
        });

        // Act
        let caught: unknown;
        try {
            await acquirer();
        } catch (error: unknown) {
            caught = error;
        }

        // Assert
        const msalLog = (caught as Record<string, unknown>)["msalLog"];
        expect(typeof msalLog).toBe("string");
        const log = msalLog as string;
        // (a) Info/Verbose messages are not present.
        expect(log).not.toContain("sending request to broker");
        expect(log).not.toContain("internal event code");
        // (b) Warning and Error messages are present.
        expect(log).toContain("NAA broker bridge returned status=BadRequest");
        expect(log).toContain("ServerError: invalid_grant");
        // (c) The boilerplate (timestamp/correlationId/package) is stripped; the level/message tail
        // remains.
        expect(log).not.toContain("@azure/msal-browser@");
        expect(log).not.toContain("11111111-2222-3333-4444-555555555555");
        expect(log).toContain(
            "Warning - NAA broker bridge returned status=BadRequest " +
                "description=blocked by Conditional Access policy"
        );
        expect(log).toContain("Error - ServerError: invalid_grant");
    });

    it("attaches the captured MSAL log to an error from the acquireTokenPopup fallback", async () => {
        // Arrange — silent rejects interaction-required, then the popup fallback also fails. The
        // captured log must be attached to the error that ultimately propagates out of the acquirer.
        const logCapture = createMsalLogCapture();
        const popupDetail = "popup broker: status=Cancelled";
        const instance: FakeMsalInstance = {
            acquireTokenSilent: vi.fn(() => Promise.reject(new FakeInteractionRequiredAuthError())),
            acquireTokenPopup: vi.fn(() => {
                logCapture.loggerOptions.loggerCallback(LogLevel.Error, popupDetail, false);
                return Promise.reject(new Error("popup ServerError"));
            }),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: (e) => e instanceof FakeInteractionRequiredAuthError,
            logCapture,
        });

        // Act
        let caught: unknown;
        try {
            await acquirer();
        } catch (error: unknown) {
            caught = error;
        }

        // Assert — the popup error propagates with the captured popup-path detail attached.
        expect((caught as Error).message).toBe("popup ServerError");
        const msalLog = (caught as Record<string, unknown>)["msalLog"];
        expect(typeof msalLog).toBe("string");
        expect(msalLog).toContain(popupDetail);
        expect(instance.acquireTokenPopup).toHaveBeenCalledTimes(1);
    });

    it("does not attach msalLog to a non-object thrown value", async () => {
        // Arrange — silent acquisition rejects with a primitive (string) and no captured messages.
        const instance: FakeMsalInstance = {
            // eslint-disable-next-line prefer-promise-reject-errors -- exercising the non-object guard in attachMsalLog.
            acquireTokenSilent: vi.fn(() => Promise.reject("string failure")),
            acquireTokenPopup: vi.fn(() => Promise.resolve({ accessToken: "unused" })),
        };
        const acquirer = await createNaaTokenAcquirer({
            isNaaSupported: () => true,
            createInstance: () => Promise.resolve(instance),
            isInteractionRequired: () => false,
        });

        // Act / Assert — the primitive propagates unchanged (no attachment attempted).
        await expect(acquirer()).rejects.toBe("string failure");
    });
});

describe("createMsalLogCapture — bounded buffer", () => {
    it("exposes loggerOptions typed for MSAL (Verbose level, PII logging disabled)", () => {
        // Arrange / Act
        const capture: MsalLogCapture = createMsalLogCapture();

        // Assert — the options match the shape threaded into system.loggerOptions; PII logging is
        // disabled so MSAL does not emit PII-flagged content through the capture callback.
        expect(capture.loggerOptions.logLevel).toBe(LogLevel.Verbose);
        expect(capture.loggerOptions.piiLoggingEnabled).toBe(false);
        expect(typeof capture.loggerOptions.loggerCallback).toBe("function");
    });

    it("drops Info and Verbose messages and any PII-flagged message, retaining only non-PII Warning/Error", () => {
        // Arrange — drive the seam with Info/Verbose at both PII flag values, a PII-flagged Warning,
        // and a non-PII Error. The PII-skip guard drops anything flagged PII; the level filter drops
        // Info/Verbose; only the non-PII Warning/Error survives.
        const capture = createMsalLogCapture();
        capture.loggerOptions.loggerCallback(LogLevel.Info, "info-nonpii", false);
        capture.loggerOptions.loggerCallback(LogLevel.Info, "info-pii", true);
        capture.loggerOptions.loggerCallback(LogLevel.Verbose, "verbose-nonpii", false);
        capture.loggerOptions.loggerCallback(LogLevel.Verbose, "verbose-pii", true);
        capture.loggerOptions.loggerCallback(LogLevel.Warning, "warning-pii", true);
        capture.loggerOptions.loggerCallback(LogLevel.Error, "error-nonpii", false);

        // Act
        const drained = capture.drain();

        // Assert — Info/Verbose are dropped at both PII flag values; the PII-flagged Warning is
        // dropped by the PII-skip guard; only the non-PII Error is retained.
        expect(drained).toEqual(["error-nonpii"]);
    });

    it("retains only the last six Warning/Error messages and truncates each to 300 characters", () => {
        // Arrange — push more than the capacity at Warning/Error level, including one oversized
        // message. Messages have no MSAL boilerplate delimiter, so they are retained verbatim
        // (subject to truncation).
        const capture = createMsalLogCapture();
        const oversized = "x".repeat(500);
        capture.loggerOptions.loggerCallback(LogLevel.Warning, oversized, false);
        for (let i = 1; i <= 7; i += 1) {
            capture.loggerOptions.loggerCallback(LogLevel.Error, `msg-${String(i)}`, false);
        }

        // Act
        const drained = capture.drain();

        // Assert — capacity is six; the oldest (oversized) message was dropped; none exceeds 300 chars.
        expect(drained).toHaveLength(6);
        expect(drained).not.toContain(oversized.slice(0, 300));
        expect(drained[0]).toBe("msg-2");
        expect(drained.every((m) => m.length <= 300)).toBe(true);
    });

    it("drops Info, Verbose, and Trace messages entirely", () => {
        // Arrange — drive the seam with one message at each retained and dropped level.
        const capture = createMsalLogCapture();
        capture.loggerOptions.loggerCallback(LogLevel.Info, "info-msg", false);
        capture.loggerOptions.loggerCallback(LogLevel.Verbose, "verbose-msg", false);
        capture.loggerOptions.loggerCallback(LogLevel.Trace, "trace-msg", false);
        capture.loggerOptions.loggerCallback(LogLevel.Warning, "warning-msg", false);
        capture.loggerOptions.loggerCallback(LogLevel.Error, "error-msg", false);

        // Act
        const drained = capture.drain();

        // Assert — only the Warning and Error messages are retained, in order.
        expect(drained).toEqual(["warning-msg", "error-msg"]);
    });

    it("returns the raw message unchanged when the MSAL boilerplate delimiter is absent", () => {
        // Arrange — a retained (Error) message that does not contain the " : " segment delimiter.
        const capture = createMsalLogCapture();
        capture.loggerOptions.loggerCallback(LogLevel.Error, "no-delimiter-here", false);

        // Act
        const drained = capture.drain();

        // Assert — the message is kept verbatim rather than being clipped to an empty tail.
        expect(drained).toEqual(["no-delimiter-here"]);
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
            expect(config.auth.clientId).toBe("3592bf52-46f6-4eb0-835c-4f961058de97");
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
