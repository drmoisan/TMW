/*
 * iFile entry point. Loaded by the shared ifile.html bundle in both the desktop Office Dialog
 * and the mobile inline full-screen task pane. Selects the presentation at runtime via host
 * detection (selectPresentation) so a single UI/logic implementation serves both (AC-2, AC-3).
 *
 * This module is the only host-bound bootstrap; the search behavior, result-list composition,
 * and selection handling live in the shared, host-neutral IFileController. The host-bound shell
 * (Office.onReady) is kept thin: it resolves the real token, applies the build-time backend-URL
 * guard, and resolves the DOM, then delegates to the testable, Office-free `bootstrap` seam.
 */

/* global Office, document, HTMLInputElement, HTMLElement, console */

import type { FolderResult } from "./folder-result";
import { IFileController } from "./ifile-controller";
import { IFileApiClient } from "./ifile-api-client";
import { resolveMessageRestId } from "./message-id-resolver";
import { selectPresentation, type Presentation } from "./host-presentation";
import { mountInline, renderLoadError, type InlineHostDom } from "./inline-host";
import { postSelectionToParent } from "./dialog-host";
import { assertReachableApiBaseUrl } from "./api-base-url";
import { createNaaTokenAcquirer } from "./naa-token-acquirer";
import { formatErrorDetail } from "./sign-in-error-detail";
import { formatBuildStamp } from "./build-stamp";

// Injected by webpack DefinePlugin at build time. __API_BASE_URL__ default: https://localhost:3000
// (desktop dev server). __IS_MOBILE_BUILD__ is true only when IFILE_MOBILE_BUILD is set. A mobile
// build MUST set API_BASE_URL to a reachable Dev-Tunnel/deployed host (see the on-device
// verification runbook, HI-2); a localhost URL in a mobile build is rejected by the guard below.
declare const __API_BASE_URL__: string;
declare const __IS_MOBILE_BUILD__: boolean;
// On-screen build identifier (issue #43). Injected by webpack DefinePlugin; an ISO timestamp by
// default, or the reproducible BUILD_ID override. Rendered early in runBootstrap so the developer
// can confirm on-device which build is loaded, regardless of sign-in success or failure.
declare const __BUILD_ID__: string;

/** Acquires the bearer token used for backend calls. Injected so bootstrap stays Office-free. */
export type TokenAcquirer = () => Promise<string>;

/**
 * Loads the once-per-open leaf-folder list for the given bearer token. Injected so bootstrap
 * stays Office-free. A zero-argument loader is assignable here (the token argument is optional to
 * the caller's perspective in TypeScript).
 */
export type LeafLoader = (token: string) => Promise<FolderResult[]>;

/**
 * Stage-specific failure messages. Splitting the prior single generic message into per-stage
 * messages makes each failure deterministic and testable, and tells the user which step failed:
 * a build-configuration problem (unreachable backend URL), a sign-in problem (token acquisition),
 * or a connection problem (folder-list fetch). Exported so the host-shell and bootstrap-seam
 * tests can assert the exact message routed to each stage.
 */

/** Shown when the build-time backend-URL reachability guard rejects (configuration stage). */
export const CONFIGURATION_FAILURE_MESSAGE =
    "iFile is not configured correctly for this build. The backend address is not reachable; rebuild with a reachable API base URL.";

/** Shown when token acquisition fails (sign-in stage). */
export const SIGN_IN_FAILURE_MESSAGE =
    "iFile could not sign you in. Check your account and sign-in, then try again.";

/** Shown when the one-time folder-list load fails after a successful sign-in (connection stage). */
export const CONNECTION_FAILURE_MESSAGE =
    "iFile could not load your folders. Check your connection, then try again.";

/** Dependencies for the testable host-neutral bootstrap seam. */
export interface BootstrapDeps {
    readonly dom: InlineHostDom;
    readonly presentation: Presentation;
    readonly acquireToken: TokenAcquirer;
    readonly loadLeaves: LeafLoader;
    readonly onSelect: (folder: FolderResult) => void;
    /**
     * When true, the underlying error detail is appended to the visible sign-in-failure row so the
     * real failure (for example an `AADSTS` code or the NAA-unsupported rejection) is readable on a
     * device with no attachable console. The host shell sets this from `__IS_MOBILE_BUILD__`; the
     * seam itself never reads the build-time global, keeping its host-neutral tests independent of
     * webpack DefinePlugin injection.
     */
    readonly showErrorDetail: boolean;
}

/**
 * Host-neutral, testable bootstrap seam. Wires the shared controller to the resolved DOM and
 * keeps the search box responsive regardless of token-acquisition or load outcome.
 *
 * The keystroke handler is bound by `mountInline` before the one-time load settles, so the box
 * is never inert. A token-acquisition failure, URL-guard failure, or load failure renders a
 * visible, deterministic error state via {@link renderLoadError} instead of a silent
 * `console.error`, and never throws out of `bootstrap`.
 */
export async function bootstrap(deps: BootstrapDeps): Promise<void> {
    let token: string;
    try {
        token = await deps.acquireToken();
    } catch (error: unknown) {
        // Token acquisition failed (e.g. SSO denied on device). Bind the handler so the box is
        // responsive, then surface the error. The controller below would re-fetch on open, but
        // without a token the load cannot succeed; render the error state directly.
        const signInMessage = deps.showErrorDetail
            ? `${SIGN_IN_FAILURE_MESSAGE} — ${formatErrorDetail(error)}`
            : SIGN_IN_FAILURE_MESSAGE;
        renderLoadError(deps.dom, signInMessage);
        deps.dom.searchInput.addEventListener("input", () => undefined);
        console.error("iFile bootstrap: sign-in (token acquisition) failed", error);
        return;
    }

    const controller = new IFileController({
        loadLeaves: () => deps.loadLeaves(token),
        onSelect: deps.onSelect,
    });

    // mountInline binds the input handler before the load settles and renders a visible error
    // state if the one-time load fails; it never throws out of a failed load. The connection-stage
    // message is passed so a folder-fetch failure is distinct from a sign-in failure, and
    // showErrorDetail is forwarded so mobile builds surface the underlying error detail (mirroring
    // the sign-in failure path above).
    await mountInline(controller, deps.dom, CONNECTION_FAILURE_MESSAGE, deps.showErrorDetail);
}

/** Builds the primary {@link TokenAcquirer}. Injected so the host shell is testable without MSAL. */
export type TokenAcquirerFactory = () => Promise<TokenAcquirer>;

/**
 * Host-bound shell. Resolves the presentation, applies the backend-URL reachability guard,
 * resolves the DOM, and delegates to {@link bootstrap}. A URL-guard failure or a missing DOM is
 * surfaced visibly where the DOM exists, otherwise logged as a last resort.
 *
 * Exported so the thin host-bound wiring (DOM resolution, URL-guard routing, NAA acquirer glue) is
 * unit-testable with an Office fake and a stubbed transport, keeping this seam in coverage rather
 * than excluded. The NAA acquirer factory is injected (default {@link createNaaTokenAcquirer}) so
 * the supported and unsupported branches can be driven in tests without a real MSAL instance.
 */
export async function runBootstrap(
    createAcquirer: TokenAcquirerFactory = createNaaTokenAcquirer
): Promise<void> {
    const hostName = Office.context.mailbox.diagnostics.hostName;
    const presentation = selectPresentation(hostName);

    // Populate the on-screen build stamp early — before token acquisition — so it is visible even
    // when sign-in fails. A missing element is tolerated (the stamp is unobtrusive, not required).
    const buildStamp = document.getElementById("ifile-build-stamp");
    if (buildStamp instanceof HTMLElement) {
        buildStamp.textContent = formatBuildStamp(__BUILD_ID__);
    }

    const searchInput = document.getElementById("ifile-search");
    const resultsList = document.getElementById("ifile-results");
    if (!(searchInput instanceof HTMLInputElement) || !(resultsList instanceof HTMLElement)) {
        // No DOM to render into; nothing to wire. This is a structural error in the host page.
        console.error("iFile bootstrap: search input or results list not found in the host page");
        return;
    }
    const dom: InlineHostDom = { searchInput, resultsList };

    let apiBaseUrl: string;
    try {
        apiBaseUrl = assertReachableApiBaseUrl(__API_BASE_URL__, {
            isMobileBuild: __IS_MOBILE_BUILD__,
        });
    } catch (error: unknown) {
        // A mobile build pointed at localhost cannot reach the backend. Surface this visibly and
        // keep the box responsive rather than failing silently.
        const configMessage = __IS_MOBILE_BUILD__
            ? `${CONFIGURATION_FAILURE_MESSAGE} — ${formatErrorDetail(error)}`
            : CONFIGURATION_FAILURE_MESSAGE;
        renderLoadError(dom, configMessage);
        dom.searchInput.addEventListener("input", () => undefined);
        console.error("iFile bootstrap: unreachable API base URL", error);
        return;
    }

    const client = new IFileApiClient(apiBaseUrl);

    // NAA (nested app auth) is the primary client-side token path (OD-8). The acquirer gates on
    // the runtime `isSetSupported("NestedAppAuth", "1.1")` check inside the host-bound adapter and,
    // when NAA is unsupported, returns an acquirer that rejects with a clear error. That rejection
    // is caught by the Office-free `bootstrap` seam, which renders SIGN_IN_FAILURE_MESSAGE so the
    // unsupported-environment failure is visible and stage-specific. MSAL is imported only by the
    // adapter, keeping `bootstrap` Office-free and MSAL-free.
    const acquireToken = await createAcquirer();

    await bootstrap({
        dom,
        presentation,
        acquireToken,
        showErrorDetail: __IS_MOBILE_BUILD__,
        loadLeaves: (token) => client.loadLeafFolders(token),
        onSelect: (folder) => {
            // In the dialog presentation the selection is posted to the parent; the inline
            // presentation handles the filing call in the parent pane directly.
            if (presentation === "dialog") {
                postSelectionToParent(folder.folderId, folder.path);
            }
        },
    });
}

// Register the host-bound bootstrap only when the Office runtime is present. Guarding the call
// keeps this module importable by the host-neutral `bootstrap` seam tests, where Office.js is
// not loaded at module-evaluation time.
if (typeof Office !== "undefined") {
    void Office.onReady((info) => {
        if (info.host !== Office.HostType.Outlook) {
            return;
        }
        runBootstrap().catch((error: unknown) => {
            console.error("iFile bootstrap failed", error);
        });
    });
}

// Re-export the resolver so the host page can compute the message REST id when issuing a filing
// call. Kept here to anchor the host-detection bootstrap module's public surface.
export { resolveMessageRestId };
