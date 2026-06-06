/**
 * Host-neutral formatter that renders an unknown caught error into a short, safe detail string for
 * on-screen display (issue #43). A physical iPhone running Outlook mobile has no attachable console
 * (Safari Web Inspector is Mac-only; Edge DevTools is unsupported on Outlook mobile), so the real
 * failure detail — for example an `AADSTS` code, a redirect-URI mismatch, or the deterministic
 * "NAA unsupported" rejection — must be folded into the visible error row rather than only logged.
 *
 * Pure: no Office.js, no DOM, no I/O. Satisfies the `ifile-pure-modules-no-host-deps` architecture
 * rule and is unit-testable without the Outlook host.
 */

/**
 * Maximum length of a formatted detail string before truncation. Bounds the visible error row.
 * Raised to accommodate the multiple MSAL diagnostic fields (`errorCode`, `subError`,
 * `correlationId`) folded into a single detail string, the full own-property enumeration appended
 * for the otherwise-empty `ServerError` case, and the retained Warning/Error `msalLog` line that
 * carries the NAA broker's actual failure description alongside the stack/constructor fields.
 */
export const MAX_DETAIL_LENGTH = 1000;

/** Appended when the formatted detail is truncated at {@link MAX_DETAIL_LENGTH}. */
const ELLIPSIS = "…";

/** Separator placed between diagnostic fields so the detail reads cleanly in a single text row. */
const FIELD_SEPARATOR = " | ";

/**
 * The MSAL `@azure/msal-browser` `AuthError` / `ServerError` shape, narrowed structurally. MSAL
 * errors carry an `errorCode` (for example `interaction_required` or an `AADSTS...` code), an
 * `errorMessage` (sometimes empty for a `ServerError`), an optional `subError`, and a
 * `correlationId` that pinpoints the Entra sign-in-log entry. Each field is optional because a
 * given error instance may populate only a subset.
 */
interface MsalAuthErrorShape {
    readonly name?: string;
    readonly errorCode?: string;
    readonly errorMessage?: string;
    readonly subError?: string;
    readonly correlationId?: string;
}

/** Returns true when `value` is a non-empty string. */
function isNonEmptyString(value: unknown): value is string {
    return typeof value === "string" && value.length > 0;
}

/**
 * Reads the candidate MSAL diagnostic fields from `error` through an index over a typed record so
 * no `any` or unsafe cast is required. Returns the collected non-empty string fields, or `null`
 * when `error` is not an object or carries none of the MSAL fields (`errorCode`, `errorMessage`,
 * `subError`, `correlationId`).
 */
function asMsalAuthError(error: unknown): MsalAuthErrorShape | null {
    if (typeof error !== "object" || error === null) {
        return null;
    }
    const record = error as Record<string, unknown>;
    const name = record["name"];
    const errorCode = record["errorCode"];
    const errorMessage = record["errorMessage"];
    const subError = record["subError"];
    const correlationId = record["correlationId"];

    const hasMsalField =
        isNonEmptyString(errorCode) ||
        isNonEmptyString(errorMessage) ||
        isNonEmptyString(subError) ||
        isNonEmptyString(correlationId);
    if (!hasMsalField) {
        return null;
    }

    const shape: MsalAuthErrorShape = {
        ...(isNonEmptyString(name) ? { name } : {}),
        ...(isNonEmptyString(errorCode) ? { errorCode } : {}),
        ...(isNonEmptyString(errorMessage) ? { errorMessage } : {}),
        ...(isNonEmptyString(subError) ? { subError } : {}),
        ...(isNonEmptyString(correlationId) ? { correlationId } : {}),
    };
    return shape;
}

/**
 * Joins the present MSAL diagnostic fields into a single readable detail string. Fields are emitted
 * in a fixed order — class/name, `errorCode`, `errorMessage`, `subError`, `correlationId` — and
 * separated by {@link FIELD_SEPARATOR}. The `correlationId` is labelled so the developer can locate
 * the exact Entra sign-in-log entry.
 */
function formatMsalDetail(shape: MsalAuthErrorShape): string {
    const fields: string[] = [];
    if (shape.name !== undefined) {
        fields.push(shape.name);
    }
    if (shape.errorCode !== undefined) {
        fields.push(shape.errorCode);
    }
    if (shape.errorMessage !== undefined) {
        fields.push(shape.errorMessage);
    }
    if (shape.subError !== undefined) {
        fields.push(shape.subError);
    }
    if (shape.correlationId !== undefined) {
        fields.push(`correlationId=${shape.correlationId}`);
    }
    return fields.join(FIELD_SEPARATOR);
}

/**
 * Set of own-property keys already rendered by the curated MSAL / `Error` formatting paths. These
 * are skipped by the full own-property enumeration so the appended fallback does not duplicate the
 * curated fields. `name`, `errorMessage`, and `message` are rendered ahead of the enumeration;
 * `stack` is surfaced separately as a trimmed first line.
 */
const CURATED_PROPERTY_KEYS: ReadonlySet<string> = new Set([
    "name",
    "errorCode",
    "errorMessage",
    "subError",
    "correlationId",
    "message",
    "stack",
]);

/**
 * Renders a single own-property value into a `key=value` fragment, or `null` when the value carries
 * no usable text. String, number, and boolean values are emitted directly when non-empty; object
 * values (for example a nested `cause` or a response body) are shallow-serialized with
 * `JSON.stringify`, falling back to `String(value)` when serialization throws (for example on a
 * circular reference).
 */
function formatOwnProperty(key: string, value: unknown): string | null {
    if (typeof value === "string") {
        return value.length > 0 ? `${key}=${value}` : null;
    }
    if (typeof value === "number" || typeof value === "boolean") {
        return `${key}=${String(value)}`;
    }
    if (typeof value === "object" && value !== null) {
        try {
            const serialized = JSON.stringify(value);
            if (isNonEmptyString(serialized)) {
                return `${key}=${serialized}`;
            }
            return `${key}=${stringifyObject(value)}`;
        } catch {
            return `${key}=${stringifyObject(value)}`;
        }
    }
    return null;
}

/**
 * Renders an object to its display string without tripping `no-base-to-string`. A value carrying a
 * meaningful own `toString` (one that is not `Object.prototype.toString`) is rendered through it;
 * otherwise the literal default `"[object Object]"` is returned. Used as the guarded fallback when
 * `JSON.stringify` cannot serialize a value (for example a circular reference).
 */
function stringifyObject(value: object): string {
    const candidate: unknown = (value as { toString?: unknown }).toString;
    if (typeof candidate === "function" && candidate !== Object.prototype.toString) {
        const rendered: unknown = (candidate as () => unknown).call(value);
        if (typeof rendered === "string") {
            return rendered;
        }
    }
    return "[object Object]";
}

/**
 * Enumerates every own property of `error` (including non-enumerable `message` / `stack` on `Error`
 * instances, which {@link Object.getOwnPropertyNames} exposes) and folds the populated ones into a
 * single readable string. This is the last-resort diagnostic used when the curated formatting yields
 * nothing beyond the class/name — the observed Outlook iOS `"ServerError:"` case, where the message
 * and every MSAL field are empty but the object may still carry an `errorNo`, a native-broker code,
 * a `stack`, or a nested `cause`. Returns the collected fragments joined with {@link FIELD_SEPARATOR},
 * or the empty string when the object genuinely carries no other populated property.
 */
function enumerateOwnProperties(error: object): string {
    const fields: string[] = [];

    const record = error as Record<string, unknown>;
    const errorConstructor: unknown = (error as { constructor?: unknown }).constructor;
    const constructorName =
        typeof errorConstructor === "function"
            ? (errorConstructor as { name?: unknown }).name
            : undefined;
    const name = record["name"];
    // Emit the constructor name only when it adds information: it must differ from `name` and not be
    // the generic `Object` carried by a plain object literal, which conveys no diagnostic value.
    if (
        isNonEmptyString(constructorName) &&
        constructorName !== "Object" &&
        (!isNonEmptyString(name) || constructorName !== name)
    ) {
        fields.push(`constructor=${constructorName}`);
    }

    const stack = record["stack"];
    if (isNonEmptyString(stack)) {
        const firstLine = stack.split("\n", 1)[0]?.trim();
        if (isNonEmptyString(firstLine)) {
            fields.push(`stack=${firstLine}`);
        }
    }

    for (const key of Object.getOwnPropertyNames(error)) {
        if (CURATED_PROPERTY_KEYS.has(key)) {
            continue;
        }
        // eslint-disable-next-line security/detect-object-injection -- key is an own-property name from Object.getOwnPropertyNames(error), not external input, so the index cannot reach the prototype chain.
        const fragment = formatOwnProperty(key, record[key]);
        if (fragment !== null) {
            fields.push(fragment);
        }
    }

    return fields.join(FIELD_SEPARATOR);
}

/**
 * Truncates `text` to {@link MAX_DETAIL_LENGTH}, appending an ellipsis when characters were
 * dropped, so the visible error row cannot grow unbounded from an oversized error message.
 */
function truncate(text: string): string {
    if (text.length <= MAX_DETAIL_LENGTH) {
        return text;
    }
    return text.slice(0, MAX_DETAIL_LENGTH) + ELLIPSIS;
}

/**
 * Joins a curated prefix and an own-property enumeration into a single detail string, omitting
 * either side when it is empty so the result never carries a dangling separator. Used to fold the
 * last-resort enumeration onto the curated `"<name>:"` form for the observed empty-message case.
 */
function joinDetail(curated: string, enumeration: string): string {
    if (enumeration.length === 0) {
        return curated;
    }
    if (curated.length === 0) {
        return enumeration;
    }
    return `${curated}${FIELD_SEPARATOR}${enumeration}`;
}

/**
 * Formats an unknown caught error into a short, safe detail string suitable for on-screen display.
 *
 * Resolution order:
 * 1. MSAL `AuthError` / `ServerError` shape (any of non-empty `errorCode`, `errorMessage`,
 *    `subError`, `correlationId`) → the present fields joined in the order
 *    `"<name> | <errorCode> | <errorMessage> | <subError> | correlationId=<id>"`, with each absent
 *    field omitted. An MSAL `ServerError` whose `errorMessage` is empty therefore still surfaces its
 *    `errorCode` and `correlationId` rather than collapsing to a bare class name. An MSAL match
 *    always carries at least one diagnostic field, so the enumeration fallback is not applied here.
 * 2. `Error` instance → `"<name>: <message>"`. When `message` is empty (the observed Outlook iOS
 *    `"ServerError:"` case), the full own-property enumeration is appended so nothing populated is
 *    hidden.
 * 3. Other non-null object → `"<name>"` when a `name` is present, then the full own-property
 *    enumeration; otherwise `String(error)` plus the enumeration.
 * 4. Anything else → `String(error)`.
 *
 * The own-property enumeration captures non-enumerable `message` / `stack`, the constructor name
 * when it differs from `name`, the first line of `stack`, populated string / number / boolean own
 * properties, and a shallow `JSON.stringify` of nested object values.
 *
 * The result is truncated to {@link MAX_DETAIL_LENGTH} characters with an ellipsis on truncation.
 */
export function formatErrorDetail(error: unknown): string {
    const msal = asMsalAuthError(error);
    if (msal !== null) {
        // An MSAL match implies a non-empty errorCode, subError, or correlationId, so the curated
        // detail already carries diagnostic value beyond the class/name; no enumeration is needed.
        return truncate(formatMsalDetail(msal));
    }
    if (error instanceof Error) {
        if (error.message.length === 0) {
            // Empty message: the curated `"<name>: "` carries no value beyond the name, so use the
            // bare name as the prefix and append the full own-property enumeration.
            return truncate(joinDetail(error.name, enumerateOwnProperties(error)));
        }
        return truncate(`${error.name}: ${error.message}`);
    }
    if (typeof error === "object" && error !== null) {
        const record = error as Record<string, unknown>;
        const name = record["name"];
        const prefix = isNonEmptyString(name) ? name : stringifyObject(error);
        return truncate(joinDetail(prefix, enumerateOwnProperties(error)));
    }
    return truncate(String(error));
}
