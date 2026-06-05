/**
 * Unit tests for the host-neutral backend-URL reachability guard (root cause 1, issue #43).
 *
 * A mobile build must inject a reachable Dev-Tunnel/deployed host as the API base URL. A
 * localhost URL is unreachable from a physical device, so the guard must fail fast for a mobile
 * build pointed at localhost, and must otherwise return the URL unchanged.
 */

import { describe, expect, it } from "vitest";
import { assertReachableApiBaseUrl } from "../../../src/taskpane/ifile/api-base-url";

describe("assertReachableApiBaseUrl", () => {
    it("throws for a localhost URL when the build is a mobile build", () => {
        // Arrange / Act / Assert
        expect(() =>
            assertReachableApiBaseUrl("https://localhost:3000", { isMobileBuild: true })
        ).toThrow();
    });

    it("returns the URL unchanged for a non-localhost host on a mobile build", () => {
        // Arrange
        const url = "https://taskmaster-api.example.devtunnels.ms";

        // Act
        const result = assertReachableApiBaseUrl(url, { isMobileBuild: true });

        // Assert
        expect(result).toBe(url);
    });

    it("returns a localhost URL unchanged for a non-mobile (desktop) build", () => {
        // Arrange / Act — desktop dev is allowed to point at the local dev server.
        const result = assertReachableApiBaseUrl("https://localhost:3000", { isMobileBuild: false });

        // Assert
        expect(result).toBe("https://localhost:3000");
    });

    it("throws for the 127.0.0.1 and IPv6 loopback hosts on a mobile build", () => {
        expect(() =>
            assertReachableApiBaseUrl("https://127.0.0.1:3000", { isMobileBuild: true })
        ).toThrow();
        expect(() =>
            assertReachableApiBaseUrl("https://[::1]:3000", { isMobileBuild: true })
        ).toThrow();
    });

    it("fails closed for a malformed URL whose host token is loopback (fallback path)", () => {
        // Arrange — a value the URL constructor rejects (space in the port), exercising the
        // host-token fallback extraction.
        // Act / Assert — the coarse extraction still identifies the loopback host and throws.
        expect(() =>
            assertReachableApiBaseUrl("https://localhost:30 00", { isMobileBuild: true })
        ).toThrow();
    });

    it("returns a malformed non-loopback URL unchanged on a mobile build (fallback, non-loopback)", () => {
        // Arrange — malformed (rejected by URL constructor) but a non-loopback host token.
        const url = "https://taskmaster-api.example.devtunnels.ms:30 00";

        // Act / Assert — fallback yields a non-loopback host, so the URL passes through.
        expect(assertReachableApiBaseUrl(url, { isMobileBuild: true })).toBe(url);
    });
});
