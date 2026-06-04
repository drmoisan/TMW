/**
 * Unit tests for resolveMessageRestId (AC-11, CI portion).
 *
 * Covers the mobile branch (no convert call) and the non-mobile branch (convert invoked).
 */

import { describe, expect, it, vi } from "vitest";
import {
    resolveMessageRestId,
    MOBILE_HOST_NAME,
} from "../../../src/taskpane/ifile/message-id-resolver";

describe("resolveMessageRestId", () => {
    it("returns itemId unchanged on mobile and does not call convert", () => {
        // Arrange
        const convert = vi.fn((id: string) => `converted-${id}`);

        // Act
        const result = resolveMessageRestId(MOBILE_HOST_NAME, "rest-id-123", convert);

        // Assert
        expect(result).toBe("rest-id-123");
        expect(convert).not.toHaveBeenCalled();
    });

    it("converts the id on non-mobile hosts", () => {
        // Arrange
        const convert = vi.fn((id: string) => `converted-${id}`);

        // Act
        const result = resolveMessageRestId("Outlook", "ews-id-123", convert);

        // Assert
        expect(result).toBe("converted-ews-id-123");
        expect(convert).toHaveBeenCalledTimes(1);
        expect(convert).toHaveBeenCalledWith("ews-id-123");
    });
});
