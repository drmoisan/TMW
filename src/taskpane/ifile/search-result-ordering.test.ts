/**
 * Unit tests for orderSearchResults (AC-5 ordering).
 *
 * Covers exact-before-prefix, prefix-before-other, and alphabetical-by-path
 * tie-break within a rank.
 */

import { describe, expect, it } from "vitest";
import { orderSearchResults } from "./search-result-ordering";
import type { FolderResult } from "./folder-result";

function leaf(name: string, path: string): FolderResult {
    return { folderId: `id-${path}`, displayName: name, path, source: "search" };
}

describe("orderSearchResults", () => {
    it("places exact matches before prefix matches", () => {
        const exact = leaf("Acme", "Archive/Acme");
        const prefix = leaf("Acmeco", "Archive/Acmeco");
        const out = orderSearchResults([prefix, exact], "acme");
        expect(out[0]).toBe(exact);
        expect(out[1]).toBe(prefix);
    });

    it("places prefix matches before other matches", () => {
        const prefix = leaf("Acmeco", "Archive/Acmeco");
        const other = leaf("BigAcme", "Archive/BigAcme");
        const out = orderSearchResults([other, prefix], "acme");
        expect(out[0]).toBe(prefix);
        expect(out[1]).toBe(other);
    });

    it("breaks ties alphabetically by full path within a rank", () => {
        const beta = leaf("Acme", "Archive/Beta/Acme");
        const alpha = leaf("Acme", "Archive/Alpha/Acme");
        const out = orderSearchResults([beta, alpha], "acme");
        expect(out.map((r) => r.path)).toEqual(["Archive/Alpha/Acme", "Archive/Beta/Acme"]);
    });
});
