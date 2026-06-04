/**
 * Unit tests for the inline (mobile) host wiring (AC-3). Uses jsdom to assert renderResults and
 * mountInline drive the shared controller and render rows without Office.js dialog calls.
 */

import { describe, expect, it, vi } from "vitest";
import { mountInline, renderResults } from "../../../src/taskpane/ifile/inline-host";
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
});
