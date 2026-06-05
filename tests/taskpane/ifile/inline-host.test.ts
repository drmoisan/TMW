/**
 * Unit tests for the inline (mobile) host wiring (AC-3). Uses jsdom to assert renderResults and
 * mountInline drive the shared controller and render rows without Office.js dialog calls.
 */

import { describe, expect, it, vi } from "vitest";
import {
    mountInline,
    renderLoadError,
    renderResults,
} from "../../../src/taskpane/ifile/inline-host";
import { IFileController } from "../../../src/taskpane/ifile/ifile-controller";
import type { FolderResult } from "../../../src/taskpane/ifile/folder-result";

function leaf(name: string, path: string): FolderResult {
    return { folderId: `id-${path}`, displayName: name, path, source: "search" };
}

const fixture: FolderResult[] = [
    leaf("Acme", "Archive/Clients/Acme"),
    leaf("Beta", "Archive/Clients/Beta"),
];

function makeDom(): { searchInput: HTMLInputElement; resultsList: HTMLDivElement } {
    const searchInput = document.createElement("input");
    const resultsList = document.createElement("div");
    document.body.append(searchInput, resultsList);
    return { searchInput, resultsList };
}

describe("inline-host renderResults", () => {
    it("renders one row per result with the folder id and a click handler", () => {
        // Arrange
        const dom = makeDom();
        const onSelect = vi.fn();

        // Act
        renderResults(dom, fixture, onSelect);

        // Assert
        const rows = dom.resultsList.querySelectorAll("div");
        expect(rows).toHaveLength(2);
        expect(rows[0]?.getAttribute("data-folder-id")).toBe("id-Archive/Clients/Acme");
        (rows[0] as HTMLElement).click();
        expect(onSelect).toHaveBeenCalledWith(fixture[0]);
    });

    it("clears prior rows on re-render", () => {
        const dom = makeDom();
        renderResults(dom, fixture, vi.fn());
        renderResults(dom, [], vi.fn());
        expect(dom.resultsList.querySelectorAll("div")).toHaveLength(0);
    });
});

describe("inline-host mountInline", () => {
    it("loads the folder list once and renders results on input", async () => {
        // Arrange
        const dom = makeDom();
        const loader = vi.fn(() => Promise.resolve(fixture));
        const controller = new IFileController({ loadLeaves: loader, onSelect: vi.fn() });

        // Act
        await mountInline(controller, dom);
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert
        expect(loader).toHaveBeenCalledTimes(1);
        const rows = dom.resultsList.querySelectorAll("div");
        expect(rows).toHaveLength(1);
        expect(rows[0]?.textContent).toBe("Archive/Clients/Acme");
    });

    it("keeps the box responsive and shows a visible error state when the one-time load fails", async () => {
        // Arrange — a loader that rejects simulates a failed one-time folder load on device.
        const dom = makeDom();
        const loader = vi.fn(() => Promise.reject(new Error("load failed")));
        const controller = new IFileController({ loadLeaves: loader, onSelect: vi.fn() });

        // Act — mountInline must not throw even though the load rejects.
        await mountInline(controller, dom);

        // Assert (a) a visible, distinct error/empty-state row is rendered into the results list.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow).not.toBeNull();
        expect(errorRow?.textContent?.length ?? 0).toBeGreaterThan(0);

        // Assert (b) a subsequent keystroke still invokes search (handler is bound).
        const searchSpy = vi.spyOn(controller, "search");
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));
        expect(searchSpy).toHaveBeenCalledWith("acme");
    });

    it("renders an error row that is distinct from a normal result row", async () => {
        // Arrange
        const dom = makeDom();
        const controller = new IFileController({
            loadLeaves: () => Promise.reject(new Error("load failed")),
            onSelect: vi.fn(),
        });

        // Act
        await mountInline(controller, dom);

        // Assert — the error row carries the stable error marker and NOT a result's folder-id.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow).not.toBeNull();
        expect(errorRow?.getAttribute("data-folder-id")).toBeNull();
        expect(dom.resultsList.querySelectorAll("[data-folder-id]")).toHaveLength(0);
    });

    it("renders the injected connection-stage message when the one-time load fails", async () => {
        // Arrange — a rejecting loader and an explicit connection-stage message from the caller.
        const dom = makeDom();
        const connectionMessage = "iFile could not load your folders. Check your connection, then try again.";
        const controller = new IFileController({
            loadLeaves: () => Promise.reject(new Error("load failed")),
            onSelect: vi.fn(),
        });

        // Act — pass the connection-stage message as the third argument.
        await mountInline(controller, dom, connectionMessage);

        // Assert (a) the error row carries the injected connection-stage message text.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow?.textContent).toBe(connectionMessage);

        // Assert (b) a subsequent keystroke still invokes search (the box stays responsive).
        const searchSpy = vi.spyOn(controller, "search");
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));
        expect(searchSpy).toHaveBeenCalledWith("acme");
    });

    it("renders results on input when the load succeeds with an injected message (no regression)", async () => {
        // Arrange — a successful load plus an injected connection-stage message that must not show.
        const dom = makeDom();
        const controller = new IFileController({
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: vi.fn(),
        });

        // Act
        await mountInline(controller, dom, "connection failed");
        dom.searchInput.value = "beta";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert — results render and no error row is present on the success path.
        expect(dom.resultsList.querySelector("[data-ifile-error]")).toBeNull();
        const rows = dom.resultsList.querySelectorAll("[data-folder-id]");
        expect(rows).toHaveLength(1);
        expect(rows[0]?.textContent).toBe("Archive/Clients/Beta");
    });

    it("renders results on input when the load succeeds (positive path preserved)", async () => {
        // Arrange
        const dom = makeDom();
        const controller = new IFileController({
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: vi.fn(),
        });

        // Act
        await mountInline(controller, dom);
        dom.searchInput.value = "beta";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert — a normal result row is rendered and no error row is present.
        expect(dom.resultsList.querySelector("[data-ifile-error]")).toBeNull();
        const rows = dom.resultsList.querySelectorAll("[data-folder-id]");
        expect(rows).toHaveLength(1);
        expect(rows[0]?.textContent).toBe("Archive/Clients/Beta");
    });
});

describe("inline-host renderLoadError", () => {
    it("renders a single distinct alert row with the given message", () => {
        // Arrange
        const dom = makeDom();
        renderResults(dom, fixture, vi.fn());

        // Act — renderLoadError replaces prior content with the error row.
        renderLoadError(dom, "boom");

        // Assert
        expect(dom.resultsList.querySelectorAll("[data-folder-id]")).toHaveLength(0);
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow?.textContent).toBe("boom");
        expect(errorRow?.getAttribute("role")).toBe("alert");
    });
});
