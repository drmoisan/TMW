/*
 * Inline (mobile) host wiring for the iFile search container. Satisfies AC-3, AC-24.
 *
 * On Outlook mobile the Office Dialog API is unsupported (HC-1), so the same shared
 * IFileController renders inline in the full-screen task pane. This module wires the controller
 * to a minimal DOM (a search input and a results list) so the search behavior and result-list
 * composition are identical to the desktop dialog presentation.
 */

/* global HTMLInputElement, HTMLElement, console */

import type { FolderResult } from "./folder-result";
import { IFileController } from "./ifile-controller";
// Importing the standalone error-detail formatter does not create a circular dependency: this
// module imports from `./sign-in-error-detail` (a pure leaf module), not from `./ifile.ts`, which
// imports from this module.
import { formatErrorDetail } from "./sign-in-error-detail";

/** The DOM elements the inline host renders the controller into. */
export interface InlineHostDom {
    readonly searchInput: HTMLInputElement;
    readonly resultsList: HTMLElement;
}

/**
 * Renders a visible, distinct error/empty-state row into the results list. The row is marked
 * with a stable `data-ifile-error` attribute so it is unit-testable and clearly different from a
 * normal result row (which carries `data-folder-id`). Clears any prior content first. Pure with
 * respect to the controller (DOM-only side effects). Exposed for unit testing.
 */
export function renderLoadError(dom: InlineHostDom, message: string): void {
    dom.resultsList.textContent = "";
    const row = dom.resultsList.ownerDocument.createElement("div");
    row.setAttribute("data-ifile-error", "true");
    row.setAttribute("role", "alert");
    row.textContent = message;
    dom.resultsList.appendChild(row);
}

/**
 * Renders the composed results into the results list element, one row per result, each carrying
 * the folder id in a data attribute and invoking the controller's selection on click. Pure with
 * respect to the controller (DOM-only side effects). Exposed for unit testing.
 */
export function renderResults(
    dom: InlineHostDom,
    results: readonly FolderResult[],
    onSelect: (folder: FolderResult) => void
): void {
    dom.resultsList.textContent = "";
    for (const result of results) {
        const row = dom.resultsList.ownerDocument.createElement("div");
        row.textContent = result.path;
        row.setAttribute("data-folder-id", result.folderId);
        row.addEventListener("click", () => {
            onSelect(result);
        });
        dom.resultsList.appendChild(row);
    }
}

/**
 * Default message shown when the one-time folder load fails. Used when {@link mountInline} is
 * called without an explicit load-failure message. The host shell passes the connection-stage
 * message (`CONNECTION_FAILURE_MESSAGE`) so the failure is stage-specific; this default keeps
 * `inline-host.ts` host-neutral and self-contained when invoked directly in tests.
 */
export const LOAD_FAILURE_MESSAGE =
    "Folder list could not be loaded. Check your connection and try again.";

/**
 * Wires the shared controller to the inline DOM and keeps the search box responsive regardless
 * of the one-time load outcome.
 *
 * The `input` listener is bound and an initial render performed independently of the one-time
 * load, so a load failure never leaves the box inert. The one-time `controller.open()` is awaited
 * in a guarded wrapper: on success the results re-render; on failure a visible, distinct
 * error/empty-state row is rendered via {@link renderLoadError} using `loadFailureMessage`.
 * `mountInline` never throws out of a failed load. Returns a promise that resolves once the
 * guarded load settles.
 *
 * `loadFailureMessage` is injected (default {@link LOAD_FAILURE_MESSAGE}) so the caller — the
 * Office-bound shell — can supply the connection-stage message without `inline-host.ts` importing
 * from `ifile.ts`, avoiding a circular dependency.
 *
 * `appendErrorDetail` is a host-neutral seam (default `false`) controlling whether the underlying
 * caught error detail is appended to the visible failure row via {@link formatErrorDetail}. It is
 * gated because a physical device running Outlook mobile has no attachable console, so the real
 * failure detail must be folded into the visible row there; on desktop the bare message suffices.
 * The host shell passes the mobile-build flag, so this module stays host-neutral and its direct
 * callers (and existing tests) are unaffected by the default-off behavior. The failure is always
 * logged via `console.error` regardless of this flag.
 */
export async function mountInline(
    controller: IFileController,
    dom: InlineHostDom,
    loadFailureMessage: string = LOAD_FAILURE_MESSAGE,
    appendErrorDetail = false
): Promise<void> {
    const update = (): void => {
        const results = controller.search(dom.searchInput.value);
        renderResults(dom, results, (folder) => {
            controller.select(folder);
        });
    };

    // Bind the keystroke handler and render the initial (empty) state BEFORE the load resolves,
    // so the box is responsive even if the load later fails.
    dom.searchInput.addEventListener("input", update);
    update();

    try {
        await controller.open();
        // Re-render with the now-loaded leaves for the current input value.
        update();
    } catch (error: unknown) {
        // The one-time folder load failed. Log the underlying error so the failure is recorded
        // (mirroring the sign-in failure path), then render a visible error row. When detail
        // surfacing is enabled (mobile builds), append the formatted detail so the real failure is
        // readable on a device with no attachable console; otherwise render the bare message.
        console.error("iFile inline host: one-time folder load failed", error);
        const message = appendErrorDetail
            ? `${loadFailureMessage} — ${formatErrorDetail(error)}`
            : loadFailureMessage;
        renderLoadError(dom, message);
    }
}
