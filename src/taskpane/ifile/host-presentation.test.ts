/**
 * Unit tests for selectPresentation (AC-3, AC-24).
 *
 * Covers mobile → inline and desktop/web → dialog.
 */

import { describe, expect, it } from "vitest";
import { selectPresentation } from "./host-presentation";
import { MOBILE_HOST_NAME } from "./message-id-resolver";

describe("selectPresentation", () => {
    it("selects inline for Outlook mobile", () => {
        expect(selectPresentation(MOBILE_HOST_NAME)).toBe("inline");
    });

    it("selects dialog for desktop", () => {
        expect(selectPresentation("Outlook")).toBe("dialog");
    });

    it("selects dialog for web", () => {
        expect(selectPresentation("OutlookWebApp")).toBe("dialog");
    });
});
