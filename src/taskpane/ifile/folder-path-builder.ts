/**
 * Host-neutral folder-path construction (pure, no I/O).
 *
 * Satisfies AC-6 and the path-construction portion of AC-14. Builds the display
 * path of a leaf folder by walking the parent chain to the mailbox root.
 *
 * The MailFolder type is defined in the shared contract module (folder-result.ts)
 * and re-exported here for callers that work primarily with the path builder.
 */

import type { MailFolder } from "./folder-result";

export type { MailFolder } from "./folder-result";

/**
 * Constructs the full display path for `leafId` by following parentFolderId
 * links through `folderMap` up to the mailbox root, joining display names with
 * "/". A folder with a null (or absent) parent contributes the root segment.
 *
 * Throws if `leafId` is not present in `folderMap`, or if a referenced parent
 * id is missing (a broken chain is a programmer error, not user input).
 */
export function buildPath(folderMap: Map<string, MailFolder>, leafId: string): string {
    const segments: string[] = [];
    const visited = new Set<string>();
    let currentId: string | null = leafId;

    while (currentId !== null) {
        if (visited.has(currentId)) {
            throw new Error(`buildPath: cycle detected at folder id "${currentId}"`);
        }
        visited.add(currentId);

        const folder = folderMap.get(currentId);
        if (folder === undefined) {
            throw new Error(`buildPath: folder id "${currentId}" not found in folder map`);
        }

        segments.push(folder.displayName);
        currentId = folder.parentFolderId;
    }

    return segments.reverse().join("/");
}
