/**
 * Tests for classifier-client.ts.
 * Unit tests for ClassifierClient, normalizeClassifyRequest, and parseClassifyResponse.
 * MSW mocks HTTP calls; property tests use @fast-check/vitest.
 */

import { describe, it, expect, beforeEach } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import { http, HttpResponse } from "msw";
import { server } from "../test-support/msw-server";
import {
    ClassifierClient,
    normalizeClassifyRequest,
    parseClassifyResponse,
    type ClassifyRequest,
} from "./classifier-client";

const BASE_URL = "http://localhost";
const TOKEN = "test-bearer-token";

// ---------------------------------------------------------------------------
// ClassifierClient.classify
// ---------------------------------------------------------------------------
describe("ClassifierClient.classify", () => {
    let client: ClassifierClient;

    beforeEach(() => {
        client = new ClassifierClient(BASE_URL);
    });

    it("returns a ClassifyResponse when the server returns 200", async () => {
        // Arrange
        server.use(
            http.post(`${BASE_URL}/api/classify`, () =>
                HttpResponse.json({ label: "HighPriority", confidence: 0.9 })
            )
        );
        const req: ClassifyRequest = { messageId: "id", subject: "urgent", body: null };

        // Act
        const result = await client.classify(req, TOKEN);

        // Assert
        expect(result.label).toBe("HighPriority");
        expect(result.confidence).toBe(0.9);
    });

    it("throws an Error when the server returns a non-200 status", async () => {
        // Arrange
        server.use(
            http.post(`${BASE_URL}/api/classify`, () =>
                HttpResponse.json({ error: "bad" }, { status: 422 })
            )
        );
        const req: ClassifyRequest = { messageId: "id", subject: "", body: null };

        // Act + Assert
        await expect(client.classify(req, TOKEN)).rejects.toThrow("classify");
    });
});

// ---------------------------------------------------------------------------
// ClassifierClient.recordFeedback
// ---------------------------------------------------------------------------
describe("ClassifierClient.recordFeedback", () => {
    let client: ClassifierClient;

    beforeEach(() => {
        client = new ClassifierClient(BASE_URL);
    });

    it("returns void when the server responds with 204", async () => {
        // Arrange
        server.use(
            http.post(
                `${BASE_URL}/api/classify/feedback`,
                () => new HttpResponse(null, { status: 204 })
            )
        );

        // Act + Assert
        await expect(
            client.recordFeedback({ messageId: "id", label: "General", confirmed: true }, TOKEN)
        ).resolves.toBeUndefined();
    });

    it("throws an Error when the server returns a non-200 status", async () => {
        // Arrange
        server.use(
            http.post(`${BASE_URL}/api/classify/feedback`, () =>
                HttpResponse.json({ error: "forbidden" }, { status: 403 })
            )
        );

        // Act + Assert
        await expect(
            client.recordFeedback({ messageId: "id", label: "General", confirmed: true }, TOKEN)
        ).rejects.toThrow("recordFeedback");
    });
});

// ---------------------------------------------------------------------------
// normalizeClassifyRequest — unit tests
// ---------------------------------------------------------------------------
describe("normalizeClassifyRequest", () => {
    it("trims messageId and subject", () => {
        const result = normalizeClassifyRequest("  id  ", " s ");
        expect(result.messageId).toBe("id");
        expect(result.subject).toBe("s");
    });

    it("sets body to null when body is undefined", () => {
        const result = normalizeClassifyRequest("id", "subject", undefined);
        expect(result.body).toBeNull();
    });

    it("trims body when body is a defined string", () => {
        const result = normalizeClassifyRequest("id", "subject", "  preview  ");
        expect(result.body).toBe("preview");
    });
});

// ---------------------------------------------------------------------------
// parseClassifyResponse — unit tests
// ---------------------------------------------------------------------------
describe("parseClassifyResponse", () => {
    it("returns a ClassifyResponse for a valid shape", () => {
        const result = parseClassifyResponse({ label: "General", confidence: 0.5 });
        expect(result.label).toBe("General");
        expect(result.confidence).toBe(0.5);
    });

    it("throws TypeError when input is null", () => {
        expect(() => parseClassifyResponse(null)).toThrow(TypeError);
    });

    it("throws TypeError when label is missing", () => {
        expect(() => parseClassifyResponse({ confidence: 0.5 })).toThrow(TypeError);
    });

    it("throws TypeError when confidence is missing", () => {
        expect(() => parseClassifyResponse({ label: "General" })).toThrow(TypeError);
    });
});

// ---------------------------------------------------------------------------
// Property tests for normalizeClassifyRequest
// ---------------------------------------------------------------------------
describe("normalizeClassifyRequest property tests", () => {
    test.prop([fc.string(), fc.string(), fc.option(fc.string(), { nil: undefined })])(
        "trims messageId, trims subject, and coerces undefined body to null",
        (messageId, subject, body) => {
            const result = normalizeClassifyRequest(messageId, subject, body);
            expect(result.messageId).toBe(messageId.trim());
            expect(result.subject).toBe(subject.trim());
            if (body === undefined) {
                expect(result.body).toBeNull();
            } else {
                expect(result.body).toBe(body.trim());
            }
        }
    );
});

// ---------------------------------------------------------------------------
// Property tests for parseClassifyResponse
// ---------------------------------------------------------------------------
describe("parseClassifyResponse property tests", () => {
    test.prop([fc.string(), fc.double({ min: 0, max: 1 })])(
        "round-trips label and confidence correctly",
        (label, confidence) => {
            const result = parseClassifyResponse({ label, confidence });
            expect(result.label).toBe(label);
            expect(result.confidence).toBe(confidence);
        }
    );
});
