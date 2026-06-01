/**
 * Unit tests for the host-neutral wildcard matcher (AC-7).
 *
 * Covers positive matches, negative matches, case-insensitivity, NFC
 * equivalence, escape handling, lone `*`, and the empty pattern.
 */

import { describe, expect, it } from "vitest";
import { match } from "./wildcard-matcher";

describe("wildcard match — positive matches", () => {
    it("matches a literal equal pattern and target", () => {
        // Arrange / Act / Assert
        expect(match("Acme", "Acme")).toBe(true);
    });

    it("matches `*` as zero or more characters", () => {
        expect(match("Cli*", "Clients")).toBe(true);
        expect(match("*ents", "Clients")).toBe(true);
        expect(match("Cl*nts", "Clients")).toBe(true);
    });

    it("matches `*` as zero characters", () => {
        expect(match("Acme*", "Acme")).toBe(true);
    });

    it("matches `?` as exactly one character", () => {
        expect(match("Acm?", "Acme")).toBe(true);
        expect(match("?cme", "Acme")).toBe(true);
    });

    it("matches against a full folder path", () => {
        expect(match("Archive/Clients/*", "Archive/Clients/Acme")).toBe(true);
    });
});

describe("wildcard match — negative matches", () => {
    it("rejects a non-matching literal", () => {
        expect(match("Acme", "Acmes")).toBe(false);
    });

    it("rejects when `?` has no character to consume", () => {
        expect(match("Acme?", "Acme")).toBe(false);
    });

    it("rejects when a literal differs", () => {
        expect(match("Cli*x", "Clients")).toBe(false);
    });
});

describe("wildcard match — case-insensitivity", () => {
    it("matches regardless of case", () => {
        expect(match("ACME", "acme")).toBe(true);
        expect(match("a*E", "AcmE")).toBe(true);
    });
});

describe("wildcard match — NFC equivalence", () => {
    it("treats decomposed and precomposed forms as equal after NFC", () => {
        // "é" precomposed (U+00E9) vs decomposed "e" + combining acute (U+0301).
        const precomposed = "Café";
        const decomposed = "Café";
        expect(match(precomposed, decomposed)).toBe(true);
        expect(match(decomposed, precomposed)).toBe(true);
    });
});

describe("wildcard match — escape handling", () => {
    it("treats `\\*` as a literal asterisk", () => {
        expect(match("Acme\\*", "Acme*")).toBe(true);
        expect(match("Acme\\*", "Acmexyz")).toBe(false);
    });

    it("treats `\\?` as a literal question mark", () => {
        expect(match("Acme\\?", "Acme?")).toBe(true);
        expect(match("Acme\\?", "Acmex")).toBe(false);
    });

    it("treats `\\\\` as a literal backslash", () => {
        expect(match("a\\\\b", "a\\b")).toBe(true);
    });
});

describe("wildcard match — lone star and empty pattern", () => {
    it("treats a lone `*` as match-all", () => {
        expect(match("*", "anything")).toBe(true);
        expect(match("*", "")).toBe(true);
    });

    it("treats an empty pattern as no-match", () => {
        expect(match("", "anything")).toBe(false);
        expect(match("", "")).toBe(false);
    });
});
