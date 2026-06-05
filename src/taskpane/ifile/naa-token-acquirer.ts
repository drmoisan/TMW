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
    type Configuration,
} from "@azure/msal-browser";
import type { TokenAcquirer } from "./ifile";

/**
 * Non-secret application (client) ID for the Entra app registration. This is the Application ID,
 * not a secret; it is safe to embed in client-side code (research section 4).
 */
const CLIENT_ID = "2921bc0b-4518-4547-b8ca-f937713688ec";

/**
 * Authority for token acquisition. `common` supports work/school accounts across tenants. The
 * single-tenant authority alternative is
 * `https://login.microsoftonline.com/d80d0ee6-3e37-43d7-9974-0ae662873253` (tenant id is a
 * non-secret identifier) — switch to it if a single-tenant configuration is required.
 */
const AUTHORITY = "https://login.microsoftonline.com/common";

/** Delegated Graph scopes requested at runtime for the iFile flows (research section 3.4). */
const TOKEN_SCOPES = ["Mail.ReadBasic", "Mail.ReadWrite", "Files.ReadWrite"];

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
}

/** Default runtime support check via the Office requirements API. */
function defaultIsNaaSupported(): boolean {
    return Office.context.requirements.isSetSupported("NestedAppAuth", "1.1");
}

/** The real MSAL nestable-public-client constructor, adapted to the narrow seam type. */
const defaultNestableClientConstructor: NestableClientConstructor = (config) =>
    createNestablePublicClientApplication(config);

/** Builds the MSAL nestable public client from the iFile NAA config via the given constructor. */
async function buildInstance(construct: NestableClientConstructor): Promise<NestablePublicClient> {
    const config: Configuration = {
        auth: { clientId: CLIENT_ID, authority: AUTHORITY },
        cache: { cacheLocation: "localStorage" },
    };
    return construct(config);
}

/** Default interaction-required predicate using the MSAL error type. */
function defaultIsInteractionRequired(error: unknown): boolean {
    return error instanceof InteractionRequiredAuthError;
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
    const createInstance =
        options.createInstance ?? (() => buildInstance(nestableClientConstructor));
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
        } catch (error: unknown) {
            if (isInteractionRequired(error)) {
                const popup = await instance.acquireTokenPopup(request);
                return popup.accessToken;
            }
            throw error;
        }
    };
}
