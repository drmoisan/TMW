/**
 * Unit tests for ResultListComposer.compose (AC-4, AC-9).
 *
 * Covers all-empty input, search-only input, ordering across all three
 * sources, and that empty sources contribute nothing.
 */

import { describe, expect, it } from "vitest";
import { compose } from "../../../src/taskpane/ifile/result-list-composer";
import type { FolderResult } from "../../../src/taskpane/ifile/folder-result";

function result(source: FolderResult["source"], name: string): FolderResult {
    return { folderId: `id-${name}`, displayName: name, path: name, source };
}

describe("compose", () => {
    it("returns an empty list when all sources are empty", () => {
        // Arrange
        // Act
        const out = compose([], [], []);
        // Assert
        expect(out).toEqual([]);
    });

    it("returns only search results when classifier and recent are empty", () => {
        const search = [result("search", "Acme"), result("search", "Beta")];
        const out = compose([], [], search);
        expect(out).toEqual(search);
    });

    it("preserves source order: classifier, then recent, then search", () => {
        const classifier = [result("classifier", "C1")];
        const recent = [result("recent", "R1")];
        const search = [result("search", "S1")];
        const out = compose(classifier, recent, search);
        expect(out.map((r) => r.source)).toEqual(["classifier", "recent", "search"]);
    });

    it("contributes nothing for empty sources but keeps non-empty ones in order", () => {
        const search = [result("search", "S1"), result("search", "S2")];
        const out = compose([], [], search);
        expect(out).toHaveLength(2);
        expect(out.every((r) => r.source === "search")).toBe(true);
    });
});
