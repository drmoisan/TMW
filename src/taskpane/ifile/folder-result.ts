/**
 * iFile result-list input contract (host-neutral, no I/O).
 *
 * The search container composes its results list from ordered input sources via
 * ResultListComposer (see result-list-composer.ts). Each source supplies an array
 * of FolderResult records. This contract is intentionally versioned so the
 * classifier and recent-choices sources can be added later by supplying a
 * non-empty array to the existing composer parameter, with no signature change.
 *
 * Contract version: 1 (see CONTRACT_VERSION). Satisfies AC-9 (type portion).
 */

/**
 * The ordered set of result sources the container supports. Only "search" is
 * populated this iteration; "classifier" and "recent" are wired to the contract
 * but receive no data.
 */
export type FolderResultSource = "classifier" | "recent" | "search";

/**
 * A single destination-folder candidate in the results list.
 *
 * - folderId: the Outlook mail-folder id of the destination.
 * - displayName: the leaf folder display name.
 * - path: the full folder path (for example "Archive/Clients/Acme").
 * - source: which ordered source produced this result.
 */
export interface FolderResult {
    readonly folderId: string;
    readonly displayName: string;
    readonly path: string;
    readonly source: FolderResultSource;
}

/**
 * Version tag for the FolderResult input contract. Increment on any
 * breaking change to the FolderResult shape or the composer signature.
 */
export const CONTRACT_VERSION = 1 as const;

/**
 * A leaf-folder mail-folder node used by folder-path-builder and folder-search.
 *
 * - childFolderCount === 0 identifies a leaf folder (AC-6).
 * - parentFolderId is null for a folder directly under the mailbox root.
 */
export interface MailFolder {
    readonly id: string;
    readonly displayName: string;
    readonly parentFolderId: string | null;
    readonly childFolderCount: number;
}
