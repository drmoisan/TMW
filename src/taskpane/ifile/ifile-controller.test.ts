/**
 * Unit tests for IFileController (AC-4, AC-5, AC-8).
 *
 * Asserts: empty textbox yields no results; typing prepends matches and clearing removes them;
 * the folder query runs exactly once per open and never per keystroke.
 */

import { describe, expect, it, vi } from "vitest";
import { IFileController } from "./ifile-controller";
import type { FolderResult } from "./folder-result";

function leaf(name: string, path: string): FolderResult {
    return { folderId: `id-${path}`, displayName: name, path, source: "search" };
}

const fixture: FolderResult[] = [
    leaf("Acme", "Archive/Clients/Acme"),
    leaf("Beta", "Archive/Clients/Beta"),
];

describe("IFileController", () => {
    it("yields no results for an empty textbox (AC-4)", async () => {
        // Arrange
        const controller = new IFileController({
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: () => undefined,
        });
        await controller.open();

        // Act / Assert
        expect(controller.search("")).toEqual([]);
    });

    it("prepends matches when typing and removes them when cleared (AC-5)", async () => {
        // Arrange
        const controller = new IFileController({
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: () => undefined,
        });
        await controller.open();

        // Act
        const typed = controller.search("acme");
        const cleared = controller.search("");

        // Assert
        expect(typed.map((r) => r.displayName)).toEqual(["Acme"]);
        expect(cleared).toEqual([]);
    });

    it("loads the folder list exactly once per open and never per keystroke (AC-8)", async () => {
        // Arrange
        const loader = vi.fn(() => Promise.resolve(fixture));
        const controller = new IFileController({ loadLeaves: loader, onSelect: () => undefined });

        // Act
        await controller.open();
        await controller.open(); // second open must not re-fetch
        controller.search("a");
        controller.search("ac");
        controller.search("acme");

        // Assert
        expect(loader).toHaveBeenCalledTimes(1);
    });

    it("invokes the selection callback on select", async () => {
        // Arrange
        const onSelect = vi.fn();
        const controller = new IFileController({
            loadLeaves: () => Promise.resolve(fixture),
            onSelect,
        });
        await controller.open();

        // Act
        const target = fixture[0];
        if (target !== undefined) {
            controller.select(target);
        }

        // Assert
        expect(onSelect).toHaveBeenCalledTimes(1);
        expect(onSelect).toHaveBeenCalledWith(fixture[0]);
    });
});
