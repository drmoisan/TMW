/**
 * Host-neutral leaf-folder search pipeline (pure, no I/O).
 *
 * Satisfies AC-5, AC-6, and AC-7. Filters a pre-loaded leaf-folder list to those
 * whose display name or full path matches the wildcard pattern, then orders the
 * matches deterministically (OD-9). An empty pattern returns no results.
 *
 * The input is the already-loaded leaf list (childFolderCount === 0 filtering is
 * applied by the caller when constructing the list, and re-asserted here is not
 * needed because FolderResult carries only leaves; callers pass leaf folders).
 * Depends only on the pure modules wildcard-matcher and search-result-ordering.
 */

import type { FolderResult, MailFolder } from "./folder-result";
import { buildPath } from "./folder-path-builder";
import { match } from "./wildcard-matcher";
import { orderSearchResults } from "./search-result-ordering";

/**
 * Projects a folder map to the search-source leaf list: only leaf folders
 * (childFolderCount === 0) become FolderResult entries, with the full path
 * computed via buildPath. Pure, no I/O. This is the leaf-only filter (AC-6).
 */
export function toLeafResults(folderMap: Map<string, MailFolder>): FolderResult[] {
    const leaves: FolderResult[] = [];
    for (const folder of Array.from(folderMap.values())) {
        if (folder.childFolderCount === 0) {
            leaves.push({
                folderId: folder.id,
                displayName: folder.displayName,
                path: buildPath(folderMap, folder.id),
                source: "search",
            });
        }
    }
    return leaves;
}

/**
 * Returns the ordered list of leaf folders whose display name or full path
 * matches `pattern`. An empty pattern returns an empty list.
 */
export function searchLeafFolders(
    leaves: readonly FolderResult[],
    pattern: string
): FolderResult[] {
    if (pattern.length === 0) {
        return [];
    }

    const matches = leaves.filter(
        (leaf) => match(pattern, leaf.displayName) || match(pattern, leaf.path)
    );

    return orderSearchResults(matches, pattern);
}
