/**
 * Unit tests for the leaf-filter + search pipeline (AC-5, AC-6, AC-7).
 *
 * Covers empty pattern (no results), name-match, path-match, and leaf-only
 * filtering over a fixture folder set.
 */

import { describe, expect, it } from "vitest";
import { searchLeafFolders, toLeafResults } from "../../../src/taskpane/ifile/folder-search";
import type { FolderResult, MailFolder } from "../../../src/taskpane/ifile/folder-result";

function leaf(name: string, path: string): FolderResult {
    return { folderId: `id-${path}`, displayName: name, path, source: "search" };
}

const fixture: FolderResult[] = [
    leaf("Acme", "Archive/Clients/Acme"),
    leaf("Beta", "Archive/Clients/Beta"),
    leaf("Invoices", "Archive/Finance/Invoices"),
];

describe("searchLeafFolders", () => {
    it("returns no results for an empty pattern", () => {
        expect(searchLeafFolders(fixture, "")).toEqual([]);
    });

    it("matches by display name", () => {
        const out = searchLeafFolders(fixture, "acme");
        expect(out.map((r) => r.displayName)).toEqual(["Acme"]);
    });

    it("matches by full path with wildcards", () => {
        const out = searchLeafFolders(fixture, "archive/finance/*");
        expect(out.map((r) => r.displayName)).toEqual(["Invoices"]);
    });

    it("returns all leaves for a lone star, ordered deterministically", () => {
        const out = searchLeafFolders(fixture, "*");
        expect(out).toHaveLength(3);
        expect(out.map((r) => r.path)).toEqual([
            "Archive/Clients/Acme",
            "Archive/Clients/Beta",
            "Archive/Finance/Invoices",
        ]);
    });
});

describe("toLeafResults — leaf-only filtering", () => {
    it("includes only folders with childFolderCount === 0", () => {
        const folders: MailFolder[] = [
            { id: "root", displayName: "Archive", parentFolderId: null, childFolderCount: 1 },
            { id: "clients", displayName: "Clients", parentFolderId: "root", childFolderCount: 1 },
            { id: "acme", displayName: "Acme", parentFolderId: "clients", childFolderCount: 0 },
        ];
        const map = new Map(folders.map((f) => [f.id, f]));
        const leaves = toLeafResults(map);
        expect(leaves.map((r) => r.displayName)).toEqual(["Acme"]);
        expect(leaves[0]?.path).toBe("Archive/Clients/Acme");
    });
});
