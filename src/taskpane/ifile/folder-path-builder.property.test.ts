/**
 * Property-based tests for buildPath (AC-6, T2 property gate).
 */

import { describe } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import { buildPath } from "./folder-path-builder";
import type { MailFolder } from "./folder-result";

/**
 * Generates a linear folder chain of a given depth (root -> child -> ...),
 * returning the folder map and the leaf id. Depth is at least 1.
 */
const arbChain = fc
    .array(
        fc.string({ minLength: 1 }).filter((s) => !s.includes("/")),
        {
            minLength: 1,
            maxLength: 8,
        }
    )
    .map((names) => {
        const folders: MailFolder[] = names.map((name, index) => ({
            id: `f${String(index)}`,
            displayName: name,
            parentFolderId: index === 0 ? null : `f${String(index - 1)}`,
            childFolderCount: index === names.length - 1 ? 0 : 1,
        }));
        const map = new Map(folders.map((f) => [f.id, f]));
        return { map, leafId: `f${String(names.length - 1)}`, depth: names.length };
    });

describe("buildPath property invariants", () => {
    /**
     * Property: the number of path segments equals the parent-chain depth.
     */
    test.prop([arbChain])("segment count equals parent-chain depth", ({ map, leafId, depth }) => {
        const path = buildPath(map, leafId);
        return path.split("/").length === depth;
    });
});
