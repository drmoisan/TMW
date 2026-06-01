/**
 * Unit tests for the Archive-root picker flow (AC-21, AC-23 CI portion).
 *
 * Asserts the select-or-create step is surfaced when no mapping exists, and skipped when a
 * mapping is present (the backend returned a non-archiveRootRequired outcome).
 */

import { describe, expect, it, vi } from "vitest";
import {
    isArchiveRootRequired,
    resolveArchiveRoot,
    ARCHIVE_ROOT_REQUIRED,
} from "./archive-root-picker";
import type { FileMessageResponse } from "./ifile-api-client";

describe("archive-root picker", () => {
    it("detects the archiveRootRequired outcome", () => {
        expect(isArchiveRootRequired({ outcome: ARCHIVE_ROOT_REQUIRED, error: null })).toBe(true);
        expect(isArchiveRootRequired({ outcome: "success", error: null })).toBe(false);
    });

    it("surfaces select-or-create when no mapping exists (AC-21)", async () => {
        // Arrange
        const select = vi.fn(() => Promise.resolve("chosen-drive-item"));
        const result: FileMessageResponse = { outcome: ARCHIVE_ROOT_REQUIRED, error: null };

        // Act
        const chosen = await resolveArchiveRoot(result, select);

        // Assert
        expect(select).toHaveBeenCalledTimes(1);
        expect(chosen).toBe("chosen-drive-item");
    });

    it("skips the picker when a mapping is present (AC-23)", async () => {
        // Arrange
        const select = vi.fn(() => Promise.resolve("should-not-be-used"));
        const result: FileMessageResponse = { outcome: "success", error: null };

        // Act
        const chosen = await resolveArchiveRoot(result, select);

        // Assert
        expect(select).not.toHaveBeenCalled();
        expect(chosen).toBeNull();
    });

    it("returns null when the user cancels the picker", async () => {
        // Arrange
        const select = vi.fn(() => Promise.resolve(null));
        const result: FileMessageResponse = { outcome: ARCHIVE_ROOT_REQUIRED, error: null };

        // Act
        const chosen = await resolveArchiveRoot(result, select);

        // Assert
        expect(chosen).toBeNull();
    });
});
