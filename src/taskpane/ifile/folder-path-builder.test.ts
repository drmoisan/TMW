/**
 * Unit tests for buildPath (AC-6).
 *
 * Covers single-level path, multi-level nested path, and root-folder path.
 */

import { describe, expect, it } from "vitest";
import { buildPath } from "./folder-path-builder";
import type { MailFolder } from "./folder-result";

function folder(
    id: string,
    displayName: string,
    parentFolderId: string | null,
    childFolderCount = 0
): MailFolder {
    return { id, displayName, parentFolderId, childFolderCount };
}

function mapOf(folders: MailFolder[]): Map<string, MailFolder> {
    return new Map(folders.map((f) => [f.id, f]));
}

describe("buildPath", () => {
    it("builds the path for a root folder (no parent)", () => {
        const map = mapOf([folder("root", "Archive", null, 2)]);
        expect(buildPath(map, "root")).toBe("Archive");
    });

    it("builds a single-level nested path", () => {
        const map = mapOf([
            folder("root", "Archive", null, 1),
            folder("clients", "Clients", "root", 0),
        ]);
        expect(buildPath(map, "clients")).toBe("Archive/Clients");
    });

    it("builds a multi-level nested path", () => {
        const map = mapOf([
            folder("root", "Archive", null, 1),
            folder("clients", "Clients", "root", 1),
            folder("acme", "Acme", "clients", 0),
        ]);
        expect(buildPath(map, "acme")).toBe("Archive/Clients/Acme");
    });

    it("throws when the leaf id is missing", () => {
        const map = mapOf([folder("root", "Archive", null, 0)]);
        expect(() => buildPath(map, "missing")).toThrow(/not found/);
    });
});
