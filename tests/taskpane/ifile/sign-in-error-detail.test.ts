/**
 * Unit tests for the host-neutral error-detail formatter (issue #43).
 *
 * Verifies that an unknown caught error is rendered into a short, safe detail string suitable for
 * the on-device error row: the MSAL `AuthError` / `ServerError` shape, a plain `Error`, a string,
 * and a non-Error object each resolve to their documented form, oversized input is truncated at the
 * boundary, and an error whose curated detail collapses to a bare class name still surfaces every
 * populated own property (extra fields, a nested `cause`, the first line of `stack`) rather than
 * hiding them.
 */

import { describe, expect, it } from "vitest";
import {
    formatErrorDetail,
    MAX_DETAIL_LENGTH,
} from "../../../src/taskpane/ifile/sign-in-error-detail";

describe("formatErrorDetail", () => {
    it("formats a full MSAL AuthError shape with name, errorCode, and errorMessage joined", () => {
        // Arrange — an @azure/msal-browser AuthError carrying an AADSTS code in the message.
        const error = {
            errorCode: "interaction_required",
            errorMessage: "AADSTS65001: The user or administrator has not consented.",
            name: "InteractionRequiredAuthError",
        };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — name, errorCode, and errorMessage joined in fixed order with the field separator.
        expect(detail).toBe(
            "InteractionRequiredAuthError | interaction_required | " +
                "AADSTS65001: The user or administrator has not consented."
        );
    });

    it("surfaces errorCode and correlationId for a ServerError with an empty errorMessage", () => {
        // Arrange — the observed device case: a ServerError whose errorMessage is empty but whose
        // errorCode and correlationId carry the diagnostic value. The earlier implementation
        // collapsed this to a bare "ServerError:"; the detail must now retain the diagnostic fields.
        const error = {
            name: "ServerError",
            errorCode: "AADSTS50011",
            errorMessage: "",
            subError: "",
            correlationId: "abc-123",
        };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — the AADSTS code, the labelled correlationId, and the class name are all present,
        // and the detail does not collapse to a bare class name with an empty tail.
        expect(detail).toContain("AADSTS50011");
        expect(detail).toContain("correlationId=abc-123");
        expect(detail).toContain("ServerError");
        expect(detail).not.toBe("ServerError:");
        expect(detail).toBe("ServerError | AADSTS50011 | correlationId=abc-123");
    });

    it("surfaces the errorCode when errorMessage is empty and only errorCode is populated", () => {
        // Arrange — errorMessage empty, but a populated errorCode still identifies the failure.
        const error = {
            name: "ServerError",
            errorCode: "AADSTS700016",
            errorMessage: "",
        };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — the errorCode is preserved rather than dropped.
        expect(detail).toContain("AADSTS700016");
        expect(detail).toBe("ServerError | AADSTS700016");
    });

    it("includes the subError when present", () => {
        // Arrange — a ServerError carrying a subError that refines the failure cause.
        const error = {
            name: "ServerError",
            errorCode: "invalid_grant",
            errorMessage: "",
            subError: "consent_required",
            correlationId: "def-456",
        };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — subError appears in order between errorCode and the labelled correlationId.
        expect(detail).toBe(
            "ServerError | invalid_grant | consent_required | correlationId=def-456"
        );
    });

    it("formats a plain Error as '<name>: <message>'", () => {
        // Arrange
        const error = new TypeError("redirect_uri mismatch");

        // Act
        const detail = formatErrorDetail(error);

        // Assert
        expect(detail).toBe("TypeError: redirect_uri mismatch");
    });

    it("formats a string error via String(error)", () => {
        // Arrange — a thrown string carries no name/message structure.
        const error = "NAA unsupported in this environment";

        // Act
        const detail = formatErrorDetail(error);

        // Assert
        expect(detail).toBe("NAA unsupported in this environment");
    });

    it("surfaces own properties of a non-Error object lacking MSAL fields and a name", () => {
        // Arrange — a plain object lacking every MSAL field and a name. The String() form alone
        // ("[object Object]") would hide the populated status, so the enumeration must surface it.
        const error = { status: 500 };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — String() prefix retained for the nameless object, with the own property appended.
        expect(detail).toBe("[object Object] | status=500");
    });

    it("surfaces extra own properties when an Error-like object has an empty message and no MSAL fields", () => {
        // Arrange — the observed "ServerError:" class: name present, message/MSAL fields empty, but
        // the object still carries diagnostic own properties (errorNo, status). The earlier
        // implementation collapsed this to a bare "ServerError"; the populated fields must surface.
        const error = { name: "ServerError", errorNo: 12345, status: "failed" };

        // Act
        const detail = formatErrorDetail(error);

        // Assert — the extra own properties are surfaced rather than hidden behind the class name.
        expect(detail).toContain("errorNo=12345");
        expect(detail).toContain("status=failed");
        expect(detail).not.toBe("ServerError:");
        expect(detail).toBe("ServerError | errorNo=12345 | status=failed");
    });

    it("includes a JSON fragment of a nested object property such as cause", () => {
        // Arrange — an Error whose message is empty but which carries a nested cause object. The
        // nested value must be shallow-serialized so the broker/response detail is not hidden.
        const error = Object.assign(new Error(""), {
            cause: { aadsts: "AADSTS50011", reason: "redirect_uri_mismatch" },
        });

        // Act
        const detail = formatErrorDetail(error);

        // Assert — the nested object is rendered as a JSON fragment within the detail string.
        expect(detail).toContain('cause={"aadsts":"AADSTS50011","reason":"redirect_uri_mismatch"}');
    });

    it("falls back to String(value) for a circular nested object property", () => {
        // Arrange — an Error with an empty message and a self-referential nested property, which
        // cannot be JSON-serialized. The guarded fallback must keep the detail from throwing.
        const circular: Record<string, unknown> = { label: "broker" };
        circular["self"] = circular;
        const error = Object.assign(new Error(""), { details: circular });

        // Act
        const detail = formatErrorDetail(error);

        // Assert — serialization fails, so the property falls back to String(value) without throwing.
        expect(detail).toContain("details=[object Object]");
    });

    it("surfaces the first line of stack when message and MSAL fields are empty", () => {
        // Arrange — an Error whose message is empty but whose stack carries the AADSTS detail on its
        // first line. The trimmed first stack line must surface so the code is not hidden.
        const error = new Error("");
        error.stack = "Error: AADSTS50011 redirect mismatch\n    at signIn (app.js:1:1)";

        // Act
        const detail = formatErrorDetail(error);

        // Assert — only the first, trimmed line of the stack appears.
        expect(detail).toContain("stack=Error: AADSTS50011 redirect mismatch");
        expect(detail).not.toContain("at signIn");
    });

    it("falls back to Error formatting when an Error carries no non-empty MSAL fields", () => {
        // Arrange — errorCode and errorMessage are both empty: no usable MSAL detail. The value is
        // an Error instance, so it must fall through to the '<name>: <message>' branch.
        const error = Object.assign(new Error("real message"), {
            errorCode: "",
            errorMessage: "",
        });

        // Act
        const detail = formatErrorDetail(error);

        // Assert — no non-empty MSAL field, so Error formatting is used.
        expect(detail).toBe("Error: real message");
    });

    it("exposes the raised 1000-character truncation boundary", () => {
        // Assert — the boundary was raised to 1000 to accommodate the retained Warning/Error msalLog
        // line alongside the appended own-property enumeration and the curated MSAL fields.
        expect(MAX_DETAIL_LENGTH).toBe(1000);
    });

    it("returns the string unchanged at exactly the truncation boundary", () => {
        // Arrange — a string error of exactly MAX_DETAIL_LENGTH (1000) characters.
        const exact = "a".repeat(MAX_DETAIL_LENGTH);

        // Act
        const detail = formatErrorDetail(exact);

        // Assert — no truncation occurs at the boundary; length is preserved.
        expect(detail).toBe(exact);
        expect(detail).toHaveLength(MAX_DETAIL_LENGTH);
    });

    it("truncates and appends an ellipsis when the formatted detail exceeds the boundary", () => {
        // Arrange — a string error one character over the boundary.
        const oversized = "b".repeat(MAX_DETAIL_LENGTH + 1);

        // Act
        const detail = formatErrorDetail(oversized);

        // Assert — truncated to MAX_DETAIL_LENGTH chars plus a single-character ellipsis.
        expect(detail).toHaveLength(MAX_DETAIL_LENGTH + 1);
        expect(detail.endsWith("…")).toBe(true);
        expect(detail.slice(0, MAX_DETAIL_LENGTH)).toBe("b".repeat(MAX_DETAIL_LENGTH));
    });
});
