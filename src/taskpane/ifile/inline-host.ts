/*
 * Inline (mobile) host wiring for the iFile search container. Satisfies AC-3, AC-24.
 *
 * On Outlook mobile the Office Dialog API is unsupported (HC-1), so the same shared
 * IFileController renders inline in the full-screen task pane. This module wires the controller
 * to a minimal DOM (a search input and a results list) so the search behavior and result-list
 * composition are identical to the desktop dialog presentation.
 */

/* global HTMLInputElement, HTMLElement */

import type { FolderResult } from "./folder-result";
import { IFileController } from "./ifile-controller";

/** The DOM elements the inline host renders the controller into. */
export interface InlineHostDom {
    readonly searchInput: HTMLInputElement;
    readonly resultsList: HTMLElement;
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
 * Wires the shared controller to the inline DOM: loads the folder list once on open, then
 * re-renders results on each keystroke. Returns a promise that resolves when the initial load
 * completes.
 */
export async function mountInline(controller: IFileController, dom: InlineHostDom): Promise<void> {
    await controller.open();
    const update = (): void => {
        const results = controller.search(dom.searchInput.value);
        renderResults(dom, results, (folder) => {
            controller.select(folder);
        });
    };
    dom.searchInput.addEventListener("input", update);
    update();
}
