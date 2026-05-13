/**
 * HTTP client and pure helper functions for the TaskMaster classifier API.
 *
 * - ClassifyRequest / ClassifyResponse / FeedbackRequest — wire-level shapes
 * - normalizeClassifyRequest — pure transform, trims inputs and coerces undefined body
 * - parseClassifyResponse — pure validator, throws TypeError on invalid shape
 * - ClassifierClient — thin HTTP wrapper, no Office.js references
 */

export interface ClassifyRequest {
    messageId: string;
    subject: string;
    body: string | null;
}

export interface ClassifyResponse {
    label: string;
    confidence: number;
}

export interface FeedbackRequest {
    messageId: string;
    label: string;
    confirmed: boolean;
}

/**
 * Trims whitespace from messageId and subject, and coerces an undefined body to null.
 */
export function normalizeClassifyRequest(
    messageId: string,
    subject: string,
    body?: string
): ClassifyRequest {
    return {
        messageId: messageId.trim(),
        subject: subject.trim(),
        body: body !== undefined ? body.trim() : null,
    };
}

/**
 * Validates that a value has the shape of a ClassifyResponse.
 * Throws TypeError with a descriptive message if the shape is invalid.
 */
export function parseClassifyResponse(value: unknown): ClassifyResponse {
    if (
        value === null ||
        typeof value !== "object" ||
        !("label" in value) ||
        !("confidence" in value) ||
        typeof (value as Record<string, unknown>)["label"] !== "string" ||
        typeof (value as Record<string, unknown>)["confidence"] !== "number"
    ) {
        throw new TypeError(
            `parseClassifyResponse: expected { label: string; confidence: number }, got ${JSON.stringify(value)}`
        );
    }
    return value as ClassifyResponse;
}

/**
 * HTTP client for the /api/classify and /api/classify/feedback endpoints.
 */
export class ClassifierClient {
    private readonly baseUrl: string;

    constructor(baseUrl: string) {
        this.baseUrl = baseUrl.replace(/\/$/, "");
    }

    /**
     * Classifies a mail message via POST /api/classify.
     * Throws an Error if the response is not OK.
     */
    async classify(req: ClassifyRequest, bearerToken: string): Promise<ClassifyResponse> {
        const response = await fetch(`${this.baseUrl}/api/classify`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${bearerToken}`,
            },
            body: JSON.stringify(req),
        });

        if (!response.ok) {
            throw new Error(
                `classify: unexpected response ${String(response.status)} ${response.statusText}`
            );
        }

        const data: unknown = await response.json();
        return parseClassifyResponse(data);
    }

    /**
     * Records user feedback via POST /api/classify/feedback.
     * Throws an Error if the response is not OK.
     */
    async recordFeedback(req: FeedbackRequest, bearerToken: string): Promise<void> {
        const response = await fetch(`${this.baseUrl}/api/classify/feedback`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${bearerToken}`,
            },
            body: JSON.stringify(req),
        });

        if (!response.ok) {
            throw new Error(
                `recordFeedback: unexpected response ${String(response.status)} ${response.statusText}`
            );
        }
    }
}
