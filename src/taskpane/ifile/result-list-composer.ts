/**
 * Host-neutral multi-source results-list composer (pure, no I/O).
 *
 * Satisfies AC-4 and AC-9. Preserves the documented source order:
 * classifier results first, then recent choices, then search results.
 * Empty sources contribute nothing. The signature is stable so a live
 * classifier or recent-choices source is added by supplying a non-empty
 * array to the existing parameter — no signature or container change.
 */

import type { FolderResult } from "./folder-result";

/**
 * Composes the ordered results list from the three input sources.
 *
 * Order is classifier, then recent, then search. Each source is appended in
 * its own input order; empty sources add no entries.
 */
export function compose(
    classifierResults: readonly FolderResult[],
    recentChoices: readonly FolderResult[],
    searchResults: readonly FolderResult[]
): FolderResult[] {
    return [...classifierResults, ...recentChoices, ...searchResults];
}
