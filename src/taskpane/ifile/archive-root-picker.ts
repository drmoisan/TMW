/**
 * Presentation-agnostic Archive-root select-or-create step (host-neutral). Satisfies AC-21, AC-24.
 *
 * Invoked when the backend reports no stored Archive-root mapping (the filing result outcome
 * is "archiveRootRequired"). The user either selects an existing OneDrive folder or creates a
 * new one; the chosen drive-item id is returned for the retry filing call. The OneDrive
 * Archive root is never auto-named or auto-created by convention — selection is always explicit.
 */

import type { FileMessageResponse } from "./ifile-api-client";

/** The outcome string the backend returns when no Archive-root mapping is stored. */
export const ARCHIVE_ROOT_REQUIRED = "archiveRootRequired";

/**
 * Presents the select-or-create step and resolves to the chosen OneDrive drive-item id, or
 * null if the user cancels. Supplied by the host wiring (dialog or inline) so the same flow
 * works across presentations.
 */
export type ArchiveRootSelector = () => Promise<string | null>;

/**
 * Returns true when the filing result indicates the Archive-root select-or-create step is
 * required (no stored mapping).
 */
export function isArchiveRootRequired(result: FileMessageResponse): boolean {
    return result.outcome === ARCHIVE_ROOT_REQUIRED;
}

/**
 * Runs the select-or-create step only when the prior filing result requires it. Returns the
 * chosen drive-item id (or null on cancel) when required, or null when not required (the
 * caller should not re-prompt). No folder named "Archive" is auto-created — the selector
 * surfaces an explicit choice.
 */
export async function resolveArchiveRoot(
    result: FileMessageResponse,
    select: ArchiveRootSelector
): Promise<string | null> {
    if (!isArchiveRootRequired(result)) {
        return null;
    }
    return select();
}
