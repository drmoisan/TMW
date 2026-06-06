/**
 * Unit tests for the thin host-bound shell `runBootstrap` (issue #43). Drives the DOM-resolution,
 * backend-URL-guard routing, and Office.auth glue with an Office fake and a stubbed transport so
 * the host-bootstrap seam is covered rather than excluded from coverage.
 */

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
    runBootstrap,
    CONFIGURATION_FAILURE_MESSAGE,
    SIGN_IN_FAILURE_MESSAGE,
} from "../../../src/taskpane/ifile/ifile";
import { formatBuildStamp } from "../../../src/taskpane/ifile/build-stamp";

interface FakeOffice {
    auth: { getAccessToken: () => Promise<string> };
    context: {
        mailbox: { diagnostics: { hostName: string } };
        ui: { messageParent: (message: string) => void };
    };
}

function installOffice(
    hostName: string,
    token: () => Promise<string>,
    messageParent: (message: string) => void = () => undefined
): void {
    const office: FakeOffice = {
        auth: { getAccessToken: token },
        context: { mailbox: { diagnostics: { hostName } }, ui: { messageParent } },
    };
    (globalThis as Record<string, unknown>)["Office"] = office;
}

function installDom(): { searchInput: HTMLInputElement; resultsList: HTMLElement } {
    document.body.innerHTML =
        '<input id="ifile-search" /><div id="ifile-results"></div>';
    const searchInput = document.getElementById("ifile-search") as HTMLInputElement;
    const resultsList = document.getElementById("ifile-results") as HTMLElement;
    return { searchInput, resultsList };
}

/**
 * Installs the host DOM including the optional `ifile-build-stamp` element so the build-stamp
 * wiring in `runBootstrap` has a target to populate.
 */
function installDomWithBuildStamp(): {
    searchInput: HTMLInputElement;
    resultsList: HTMLElement;
    buildStamp: HTMLElement;
} {
    document.body.innerHTML =
        '<input id="ifile-search" /><div id="ifile-results"></div>' +
        '<div id="ifile-build-stamp"></div>';
    const searchInput = document.getElementById("ifile-search") as HTMLInputElement;
    const resultsList = document.getElementById("ifile-results") as HTMLElement;
    const buildStamp = document.getElementById("ifile-build-stamp") as HTMLElement;
    return { searchInput, resultsList, buildStamp };
}

/** An injected NAA-acquirer factory whose acquirer resolves the given token (NAA-supported). */
function supportedAcquirer(token: string): () => Promise<() => Promise<string>> {
    return () => Promise.resolve(() => Promise.resolve(token));
}

/** An injected NAA-acquirer factory whose acquirer rejects (NAA-unsupported environment). */
function unsupportedAcquirer(): () => Promise<() => Promise<string>> {
    return () =>
        Promise.resolve(() =>
            Promise.reject(new Error("This environment does not support NestedAppAuth (NAA) 1.1."))
        );
}

describe("ifile runBootstrap host shell", () => {
    beforeEach(() => {
        document.body.innerHTML = "";
    });

    afterEach(() => {
        vi.restoreAllMocks();
        vi.unstubAllGlobals();
        document.body.innerHTML = "";
    });

    it("logs and returns without throwing when the host DOM is missing", async () => {
        // Arrange — no #ifile-search / #ifile-results elements present.
        installOffice("Outlook", () => Promise.resolve("t"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        const errorSpy = vi.spyOn(console, "error").mockImplementation(() => undefined);

        // Act
        await runBootstrap();

        // Assert
        expect(errorSpy).toHaveBeenCalled();
    });

    it("renders a visible error and keeps the box responsive when the URL guard rejects", async () => {
        // Arrange — a mobile build pointed at localhost trips the reachability guard.
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("t"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", true);
        vi.spyOn(console, "error").mockImplementation(() => undefined);

        // Act
        await runBootstrap();

        // Assert — visible error row present; input handler bound (no throw on keystroke).
        expect(dom.resultsList.querySelector("[data-ifile-error]")).not.toBeNull();
        dom.searchInput.value = "x";
        expect(() => dom.searchInput.dispatchEvent(new Event("input"))).not.toThrow();
    });

    it("renders the configuration message with the appended error detail when the build URL guard rejects on mobile", async () => {
        // Arrange — a mobile build pointed at localhost trips the reachability/configuration guard.
        // On a mobile build (__IS_MOBILE_BUILD__ true) the underlying detail is folded into the row.
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("t"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", true);
        vi.spyOn(console, "error").mockImplementation(() => undefined);

        // Act
        await runBootstrap();

        // Assert — the row leads with the configuration-stage message and contains the guard detail
        // (the unreachable-loopback Error message), so the failure is readable on a device.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        const text = errorRow?.textContent ?? "";
        expect(text.startsWith(CONFIGURATION_FAILURE_MESSAGE)).toBe(true);
        expect(text).toContain("loopback host");
        expect(text).not.toBe(CONFIGURATION_FAILURE_MESSAGE);
    });

    it("loads folders and renders results on input for a reachable desktop build", async () => {
        // Arrange — desktop build, token via Office.auth, folder load via stubbed fetch.
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("token-xyz"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        const fetchMock = vi.fn().mockResolvedValue({
            ok: true,
            status: 200,
            statusText: "OK",
            json: () =>
                Promise.resolve({
                    folders: [
                        { folderId: "acme", displayName: "Acme", path: "Archive/Clients/Acme" },
                    ],
                }),
        });
        vi.stubGlobal("fetch", fetchMock);

        // Act — inject a NAA-supported acquirer seam so the host shell stays MSAL-free in tests.
        await runBootstrap(supportedAcquirer("token-xyz"));
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert — the folder load reached the backend and a result row rendered.
        expect(fetchMock).toHaveBeenCalledTimes(1);
        const rows = dom.resultsList.querySelectorAll("[data-folder-id]");
        expect(rows).toHaveLength(1);
        expect(rows[0]?.textContent).toBe("Archive/Clients/Acme");
    });

    it("posts the selection to the parent in the dialog presentation on row click", async () => {
        // Arrange — a non-mobile host name resolves to the "dialog" presentation.
        const dom = installDom();
        const messageParent = vi.fn();
        installOffice("Outlook", () => Promise.resolve("token-xyz"), messageParent);
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        vi.stubGlobal(
            "fetch",
            vi.fn().mockResolvedValue({
                ok: true,
                status: 200,
                statusText: "OK",
                json: () =>
                    Promise.resolve({
                        folders: [
                            { folderId: "acme", displayName: "Acme", path: "Archive/Clients/Acme" },
                        ],
                    }),
            })
        );

        // Act — inject a NAA-supported acquirer; render results, then click the result row.
        await runBootstrap(supportedAcquirer("token-xyz"));
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));
        const row = dom.resultsList.querySelector("[data-folder-id]") as HTMLElement;
        row.click();

        // Assert — the dialog-presentation branch posts the selection to the parent.
        expect(messageParent).toHaveBeenCalledTimes(1);
        const posted = JSON.parse(messageParent.mock.calls[0]?.[0] as string) as Record<
            string,
            unknown
        >;
        expect(posted["folderId"]).toBe("acme");
        expect(posted["path"]).toBe("Archive/Clients/Acme");
    });

    it("loads results when the NAA-supported acquirer resolves a token (positive branch)", async () => {
        // Arrange — desktop build with an injected NAA-supported acquirer and a stubbed fetch.
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("unused"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        const fetchMock = vi.fn().mockResolvedValue({
            ok: true,
            status: 200,
            statusText: "OK",
            json: () =>
                Promise.resolve({
                    folders: [
                        { folderId: "acme", displayName: "Acme", path: "Archive/Clients/Acme" },
                    ],
                }),
        });
        vi.stubGlobal("fetch", fetchMock);

        // Act — the NAA-supported acquirer resolves a token, so the box loads results.
        await runBootstrap(supportedAcquirer("naa-token"));
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert — no error row; the folder load reached the backend and a result row rendered.
        expect(dom.resultsList.querySelector("[data-ifile-error]")).toBeNull();
        expect(fetchMock).toHaveBeenCalledTimes(1);
        const rows = dom.resultsList.querySelectorAll("[data-folder-id]");
        expect(rows).toHaveLength(1);
    });

    it("renders the sign-in message and stays responsive when NAA is unsupported", async () => {
        // Arrange — desktop build but the injected acquirer rejects (NAA-unsupported environment).
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("unused"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        const fetchMock = vi.fn();
        vi.stubGlobal("fetch", fetchMock);

        // Act
        await runBootstrap(unsupportedAcquirer());

        // Assert — the visible error row carries the sign-in-stage message; no backend call was
        // made; and a subsequent keystroke does not throw (the box stays responsive).
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow?.textContent).toBe(SIGN_IN_FAILURE_MESSAGE);
        expect(fetchMock).not.toHaveBeenCalled();
        dom.searchInput.value = "x";
        expect(() => dom.searchInput.dispatchEvent(new Event("input"))).not.toThrow();
    });

    it("appends the sign-in detail on a mobile build when NAA is unsupported", async () => {
        // Arrange — a mobile build (__IS_MOBILE_BUILD__ true) wires showErrorDetail through the
        // bootstrap seam, so the NAA-unsupported rejection detail must be visible on the device.
        const dom = installDom();
        installOffice("Outlook", () => Promise.resolve("unused"));
        vi.stubGlobal("__API_BASE_URL__", "https://tunnel.example.dev");
        vi.stubGlobal("__IS_MOBILE_BUILD__", true);
        vi.spyOn(console, "error").mockImplementation(() => undefined);
        const fetchMock = vi.fn();
        vi.stubGlobal("fetch", fetchMock);

        // Act
        await runBootstrap(unsupportedAcquirer());

        // Assert — the row leads with the sign-in-stage message and contains the NAA-unsupported
        // detail; no backend call was made.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        const text = errorRow?.textContent ?? "";
        expect(text.startsWith(SIGN_IN_FAILURE_MESSAGE)).toBe(true);
        expect(text).toContain("does not support NestedAppAuth");
        expect(text).not.toBe(SIGN_IN_FAILURE_MESSAGE);
        expect(fetchMock).not.toHaveBeenCalled();
    });

    it("populates the build-stamp element early, even when sign-in fails", async () => {
        // Arrange — the stamp element is present; the injected acquirer rejects (sign-in fails) so
        // the stamp must still be populated because the wiring runs before token acquisition.
        const dom = installDomWithBuildStamp();
        installOffice("Outlook", () => Promise.resolve("unused"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        vi.stubGlobal("__BUILD_ID__", "2026-06-05T12:00:00.000Z");
        vi.spyOn(console, "error").mockImplementation(() => undefined);
        vi.stubGlobal("fetch", vi.fn());

        // Act — sign-in fails, but the stamp is wired earlier in runBootstrap.
        await runBootstrap(unsupportedAcquirer());

        // Assert — the stamp carries the formatted build label.
        expect(dom.buildStamp.textContent).toBe(formatBuildStamp("2026-06-05T12:00:00.000Z"));
    });

    it("does not throw when the build-stamp element is absent", async () => {
        // Arrange — the default DOM has no #ifile-build-stamp element; runBootstrap must tolerate it.
        installDom();
        installOffice("Outlook", () => Promise.resolve("token-xyz"));
        vi.stubGlobal("__API_BASE_URL__", "https://localhost:3000");
        vi.stubGlobal("__IS_MOBILE_BUILD__", false);
        vi.stubGlobal("__BUILD_ID__", "2026-06-05T12:00:00.000Z");
        vi.stubGlobal(
            "fetch",
            vi.fn().mockResolvedValue({
                ok: true,
                status: 200,
                statusText: "OK",
                json: () => Promise.resolve({ folders: [] }),
            })
        );

        // Act / Assert — the missing stamp element does not cause a throw and the shell completes.
        await expect(runBootstrap(supportedAcquirer("token-xyz"))).resolves.toBeUndefined();
        expect(document.getElementById("ifile-build-stamp")).toBeNull();
    });
});
