/**
 * Host-neutral deterministic ordering for search results (pure, no I/O).
 *
 * Satisfies AC-5 (ordering portion) and AC-9. Implements OD-9: exact matches
 * first, then prefix matches, then everything else, with an alphabetical tie-break
 * by full folder path within each rank.
 */

import type { FolderResult } from "./folder-result";

/**
 * Match rank used for ordering. Lower rank sorts first.
 * 0 = exact (displayName or path equals the pattern, case-insensitively).
 * 1 = prefix (displayName or path starts with the pattern, case-insensitively).
 * 2 = other matches.
 */
function rankOf(result: FolderResult, normalizedPattern: string): number {
    const name = result.displayName.normalize("NFC").toLowerCase();
    const path = result.path.normalize("NFC").toLowerCase();
    if (name === normalizedPattern || path === normalizedPattern) {
        return 0;
    }
    if (name.startsWith(normalizedPattern) || path.startsWith(normalizedPattern)) {
        return 1;
    }
    return 2;
}

/**
 * Returns a new array containing the same results ordered by match rank
 * (exact, then prefix, then other) and, within each rank, alphabetically by
 * full folder path. The input is not mutated.
 */
export function orderSearchResults(
    matches: readonly FolderResult[],
    pattern: string
): FolderResult[] {
    const normalizedPattern = pattern.normalize("NFC").toLowerCase();
    return [...matches].sort((a, b) => {
        const rankA = rankOf(a, normalizedPattern);
        const rankB = rankOf(b, normalizedPattern);
        if (rankA !== rankB) {
            return rankA - rankB;
        }
        return a.path.localeCompare(b.path);
    });
}
