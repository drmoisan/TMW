/**
 * Unit tests for the host-neutral build-stamp formatter (issue #43).
 *
 * Verifies that a build id is rendered into the visible stamp label `build <buildId>`, including the
 * empty-id edge case where the bare prefix is returned rather than throwing, so the stamp element is
 * always populated.
 */

import { describe, expect, it } from "vitest";
import { formatBuildStamp } from "../../../src/taskpane/ifile/build-stamp";

describe("formatBuildStamp", () => {
    it("formats a typical build id as 'build <buildId>'", () => {
        // Arrange — an ISO-timestamp build id of the kind injected by the webpack define.
        const buildId = "2026-06-05T12:00:00.000Z";

        // Act
        const label = formatBuildStamp(buildId);

        // Assert
        expect(label).toBe("build 2026-06-05T12:00:00.000Z");
    });

    it("returns the bare prefix for an empty build id without throwing", () => {
        // Arrange — an empty id (e.g. a misconfigured BUILD_ID override) must still produce a label.
        const buildId = "";

        // Act
        const label = formatBuildStamp(buildId);

        // Assert — the bare prefix is returned so the stamp element is always populated.
        expect(label).toBe("build ");
    });
});
