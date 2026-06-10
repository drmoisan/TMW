/*
 * NAA (nested app authentication) token-acquirer adapter for iFile (issue #43, OD-8 NAA-primary
 * token path).
 *
 * This is the ONLY iFile module permitted to import `@azure/msal-browser`. It is host-bound: by
 * default it gates on the Office runtime support check `isSetSupported("NestedAppAuth", "1.1")`
 * and constructs an MSAL nestable public client. All host/MSAL boundaries are injected as
 * parameters with safe defaults so the adapter is unit-testable without the Office host or a real
 * MSAL instance (the defaults are only reached at runtime in the host).
 *
 * The produced acquirer conforms to the `TokenAcquirer` seam in ifile.ts, so `bootstrap` stays
 * Office-free and MSAL-free: the host shell injects the acquirer through `BootstrapDeps`.
 */

/* global Office */

import {
    createNestablePublicClientApplication,
    InteractionRequiredAuthError,
    LogLevel,
    type Configuration,
} from "@azure/msal-browser";
import type { TokenAcquirer } from "./ifile";

/**
 * Non-secret application (client) ID for the Entra app registration. This is the Application ID,
 * not a secret; it is safe to embed in client-side code (research section 4).
 */
const CLIENT_ID = "3592bf52-46f6-4eb0-835c-4f961058de97";

/**
 * Authority for token acquisition. `common` supports work/school accounts across tenants. The
 * single-tenant authority alternative is
 * `https://login.microsoftonline.com/d80d0ee6-3e37-43d7-9974-0ae662873253` (tenant id is a
 * non-secret identifier) — switch to it if a single-tenant configuration is required.
 */
const AUTHORITY = "https://login.microsoftonline.com/common";

/**
 * Scope requested at runtime. iFile uses the On-Behalf-Of pattern: the client requests the
 * backend API's own exposed scope so MSAL returns a token whose audience is the API
 * (api://3592bf52-46f6-4eb0-835c-4f961058de97). The API validates that token, then exchanges it
 * via OBO for a Microsoft Graph token to perform the Mail/Files operations. Requesting Graph
 * scopes here would instead yield a Graph-audience token that the API cannot validate (IDX10511).
 * The Graph delegated permissions (Mail/Files) now live on the API app registration and are used
 * by the server-side OBO flow, not requested by the client.
 */
const TOKEN_SCOPES = ["api://3592bf52-46f6-4eb0-835c-4f961058de97/access_as_user"];

/**
 * Maximum number of MSAL log messages retained in the capture buffer. The NAA broker bridge surfaces
 * its underlying status/description through MSAL's logger rather than through the thrown error's
 * standard fields; the last few messages carry the relevant detail, so the buffer is kept small and
 * the oldest entry is dropped when this bound is exceeded.
 */
const MSAL_LOG_CAPACITY = 6;

/**
 * Per-message truncation length for captured MSAL log lines, bounding total attached log size. Sized
 * so a full broker failure description (the retained Warning/Error line) survives without clipping.
 */
const MSAL_LOG_MESSAGE_MAX_LENGTH = 300;

/** Separator joining the captured MSAL log messages into the single `msalLog` error property. */
const MSAL_LOG_SEPARATOR = " ;; ";

/**
 * Delimiter MSAL uses between the boilerplate segments of a formatted log message. MSAL formats each
 * message as
 *   `[<timestamp>] : [<correlationId>] : @azure/msal-browser@<version> : <LevelName> - <message>`
 * so the meaningful `<LevelName> - <message>` tail is the final segment after splitting on this
 * delimiter.
 */
const MSAL_LOG_SEGMENT_DELIMITER = " : ";

/**
 * The MSAL logger-callback signature, narrowed to the fields this adapter consumes. Structurally
 * compatible with MSAL's `ILoggerCallback`. Kept local so the seam stays explicit and the capture
 * buffer wiring is testable without constructing a real MSAL `Logger`.
 */
export type MsalLoggerCallback = (level: LogLevel, message: string, containsPii: boolean) => void;

/**
 * The MSAL logger configuration this adapter threads into the MSAL `Configuration`. Mirrors the
 * shape MSAL expects under `system.loggerOptions`, narrowed to the fields the adapter sets.
 */
export interface MsalLoggerOptions {
    readonly loggerCallback: MsalLoggerCallback;
    readonly logLevel: LogLevel;
    readonly piiLoggingEnabled: boolean;
}

/**
 * A bounded MSAL log capture buffer: a callback that records the meaningful (Warning/Error)
 * messages plus a reader that returns the retained messages. Used to fold the NAA broker bridge's
 * underlying failure detail into the thrown error so it reaches the on-screen diagnostic.
 */
export interface MsalLogCapture {
    /** The logger options to thread into the MSAL `Configuration`. */
    readonly loggerOptions: MsalLoggerOptions;
    /** Returns a copy of the currently retained (Warning/Error, stripped, truncated) messages, oldest first. */
    readonly drain: () => string[];
}

/**
 * Reduces an MSAL-formatted log message to its meaningful `<LevelName> - <message>` tail by dropping
 * the leading timestamp, correlationId, and `@azure/msal-browser@<version>` boilerplate segments.
 *
 * MSAL formats each message as
 *   `[<timestamp>] : [<correlationId>] : @azure/msal-browser@<version> : <LevelName> - <message>`
 * The segments are joined by {@link MSAL_LOG_SEGMENT_DELIMITER}, so the meaningful tail is the final
 * segment after splitting on that delimiter. When the delimiter is absent (an unexpected format), the
 * raw message is returned unchanged rather than risking loss of the only diagnostic on screen.
 */
function stripMsalBoilerplate(message: string): string {
    const delimiterIndex = message.lastIndexOf(MSAL_LOG_SEGMENT_DELIMITER);
    if (delimiterIndex === -1) {
        return message;
    }
    return message.slice(delimiterIndex + MSAL_LOG_SEGMENT_DELIMITER.length);
}

/**
 * Creates a bounded MSAL log capture buffer. The returned `loggerCallback`:
 * - retains a message only when its `LogLevel` is `Error` or `Warning`; `Info`, `Verbose`, and
 *   `Trace` are dropped (they are the telemetry flood that otherwise pushes the meaningful broker
 *   failure line out of the small buffer),
 * - strips MSAL's timestamp/correlationId/package boilerplate down to the `<LevelName> - <message>`
 *   tail via {@link stripMsalBoilerplate},
 * - truncates each retained message to {@link MSAL_LOG_MESSAGE_MAX_LENGTH}, and
 * - keeps only the last {@link MSAL_LOG_CAPACITY} retained messages (dropping the oldest).
 */
export function createMsalLogCapture(): MsalLogCapture {
    const messages: string[] = [];
    const loggerCallback: MsalLoggerCallback = (level, message, containsPii) => {
        if (containsPii) {
            return;
        }
        if (level !== LogLevel.Error && level !== LogLevel.Warning) {
            return;
        }
        messages.push(stripMsalBoilerplate(message).slice(0, MSAL_LOG_MESSAGE_MAX_LENGTH));
        if (messages.length > MSAL_LOG_CAPACITY) {
            messages.shift();
        }
    };
    return {
        loggerOptions: {
            loggerCallback,
            logLevel: LogLevel.Verbose,
            piiLoggingEnabled: false,
        },
        drain: () => [...messages],
    };
}

/**
 * The result shape the adapter consumes from MSAL token acquisition. The adapter only reads
 * `accessToken`, so the seam requires only that property. The real MSAL `AuthenticationResult`
 * is structurally assignable to this, and tests can supply a minimal fake without importing MSAL.
 */
export interface TokenResult {
    readonly accessToken: string;
}

/** The minimal MSAL public-client surface the adapter depends on. */
export interface NestablePublicClient {
    acquireTokenSilent(request: { scopes: string[] }): Promise<TokenResult>;
    acquireTokenPopup(request: { scopes: string[] }): Promise<TokenResult>;
}

/** Constructs an MSAL public client from a config. Defaults to the official MSAL constructor. */
export type NestableClientConstructor = (config: Configuration) => Promise<NestablePublicClient>;

/** Injected boundaries for {@link createNaaTokenAcquirer}; defaults bind to the Office host + MSAL. */
export interface NaaTokenAcquirerOptions {
    /** Runtime gate: returns true when `NestedAppAuth 1.1` is supported. */
    readonly isNaaSupported?: () => boolean;
    /** Builds the MSAL nestable public client. Called only when NAA is supported. */
    readonly createInstance?: () => Promise<NestablePublicClient>;
    /**
     * The MSAL nestable-public-client constructor used by the default {@link createInstance}.
     * Injectable so the config-building default is testable without a real MSAL/browser broker.
     */
    readonly nestableClientConstructor?: NestableClientConstructor;
    /** Predicate identifying an interaction-required error (drives the popup fallback). */
    readonly isInteractionRequired?: (error: unknown) => boolean;
    /** Invoked when NAA is unsupported, before the deterministic rejection is produced. */
    readonly onUnsupported?: () => void;
    /**
     * Bounded MSAL log capture buffer. Its `loggerOptions` are threaded into the MSAL config so MSAL
     * routes its internal logger through the capture, and its `drain` output is attached to the
     * propagated error as `msalLog`. Injectable so tests can drive the logger seam directly; defaults
     * to a fresh {@link createMsalLogCapture}.
     */
    readonly logCapture?: MsalLogCapture;
}

/** Default runtime support check via the Office requirements API. */
function defaultIsNaaSupported(): boolean {
    return Office.context.requirements.isSetSupported("NestedAppAuth", "1.1");
}

/** The real MSAL nestable-public-client constructor, adapted to the narrow seam type. */
const defaultNestableClientConstructor: NestableClientConstructor = (config) =>
    createNestablePublicClientApplication(config);

/**
 * Builds the MSAL nestable public client from the iFile NAA config via the given constructor. When
 * `loggerOptions` is supplied it is threaded into `system.loggerOptions` so MSAL routes its internal
 * logger output (including the NAA broker bridge status/description) through the capture callback.
 */
async function buildInstance(
    construct: NestableClientConstructor,
    loggerOptions?: MsalLoggerOptions
): Promise<NestablePublicClient> {
    const config: Configuration = {
        auth: { clientId: CLIENT_ID, authority: AUTHORITY },
        cache: { cacheLocation: "localStorage" },
        ...(loggerOptions !== undefined ? { system: { loggerOptions } } : {}),
    };
    return construct(config);
}

/** Default interaction-required predicate using the MSAL error type. */
function defaultIsInteractionRequired(error: unknown): boolean {
    return error instanceof InteractionRequiredAuthError;
}

/**
 * Attaches the captured MSAL log to `error` as an enumerable own property named `msalLog` (the
 * messages joined with {@link MSAL_LOG_SEPARATOR}), then returns the same error for rethrow.
 *
 * The NAA broker bridge can return a `ServerError` that MSAL cannot populate with `errorCode` /
 * `errorMessage` / `correlationId`; the underlying status/description is only emitted through MSAL's
 * logger. Folding the captured log into an enumerable property lets the on-screen formatter surface
 * it via its full own-property enumeration. Non-object errors are returned unchanged, the attachment
 * is skipped when no messages were captured, and the `defineProperty` call is guarded so attaching
 * the diagnostic can never itself throw and mask the original failure.
 */
function attachMsalLog(error: unknown, messages: string[]): unknown {
    if (typeof error !== "object" || error === null) {
        return error;
    }
    if (messages.length === 0) {
        return error;
    }
    try {
        Object.defineProperty(error, "msalLog", {
            value: messages.join(MSAL_LOG_SEPARATOR),
            enumerable: true,
            configurable: true,
            writable: true,
        });
    } catch {
        // Attaching the diagnostic must never mask the original error; ignore a non-writable target.
    }
    return error;
}

/**
 * Creates a {@link TokenAcquirer} backed by NAA.
 *
 * Behavior:
 * - When NAA is supported, constructs the MSAL instance and returns an acquirer that calls
 *   `acquireTokenSilent`; on an interaction-required error it falls back to `acquireTokenPopup`.
 *   Both return the resolved `accessToken`.
 * - When NAA is unsupported, the returned acquirer invokes the `onUnsupported` hook and rejects
 *   with a clear, specific error. The error names the Office dialog interactive flow as the
 *   required fallback (the full Office-dialog interactive MSAL flow is an explicit out-of-scope
 *   follow-up; this branch is a deterministic, testable signal, not a silent no-op).
 *
 * The MSAL instance is constructed only when NAA is supported, so an unsupported environment
 * never reaches MSAL.
 */
export async function createNaaTokenAcquirer(
    options: NaaTokenAcquirerOptions = {}
): Promise<TokenAcquirer> {
    const isNaaSupported = options.isNaaSupported ?? defaultIsNaaSupported;
    const nestableClientConstructor =
        options.nestableClientConstructor ?? defaultNestableClientConstructor;
    const logCapture = options.logCapture ?? createMsalLogCapture();
    const createInstance =
        options.createInstance ??
        (() => buildInstance(nestableClientConstructor, logCapture.loggerOptions));
    const isInteractionRequired = options.isInteractionRequired ?? defaultIsInteractionRequired;
    const onUnsupported = options.onUnsupported;

    if (!isNaaSupported()) {
        // NAA is not available in this environment. Return an acquirer that produces a visible,
        // deterministic failure rather than silently dropping the sign-in.
        return () => {
            onUnsupported?.();
            return Promise.reject(
                new Error(
                    "This environment does not support NestedAppAuth (NAA) 1.1. The Office dialog " +
                        "interactive sign-in flow is the required fallback and is not yet available."
                )
            );
        };
    }

    const instance = await createInstance();
    const request = { scopes: TOKEN_SCOPES };

    return async (): Promise<string> => {
        try {
            const silent = await instance.acquireTokenSilent(request);
            return silent.accessToken;
        } catch (silentError: unknown) {
            if (isInteractionRequired(silentError)) {
                try {
                    const popup = await instance.acquireTokenPopup(request);
                    return popup.accessToken;
                } catch (popupError: unknown) {
                    // The popup fallback also failed; attach the captured MSAL log to the error that
                    // propagates out of the acquirer so the NAA broker detail reaches the screen.
                    throw attachMsalLog(popupError, logCapture.drain());
                }
            }
            throw attachMsalLog(silentError, logCapture.drain());
        }
    };
}
