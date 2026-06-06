/*
 * Desktop dialog host wiring for the iFile search container. Satisfies AC-2, AC-3, AC-24.
 *
 * On desktop/web the container is presented as an Office Dialog opened via
 * Office.context.ui.displayDialogAsync against a same-origin URL. The parent listens for
 * DialogMessageReceived and the dialog posts its selection via messageParent (the round-trip).
 * The dialog page itself renders the shared IFileController inline (see inline-host.ts), so the
 * search behavior and result-list composition are identical to the mobile presentation.
 */

/* global Office */

/** The JSON message contract posted by the dialog to its parent via messageParent. */
export interface DialogSelectionMessage {
    readonly kind: "ifile-selection";
    readonly folderId: string;
    readonly path: string;
}

/** Options for opening the iFile dialog. */
export interface DialogHostOptions {
    /** Same-origin dialog URL (shares the add-in origin). */
    readonly url: string;
    /** Dialog height as a percentage of the screen. */
    readonly heightPercent: number;
    /** Dialog width as a percentage of the screen. */
    readonly widthPercent: number;
    /** Invoked with the parsed selection message when the dialog reports a choice. */
    readonly onSelection: (message: DialogSelectionMessage) => void;
}

/**
 * Builds the displayDialogAsync options object (same-origin URL + percentage sizing). Exposed
 * for the Office.js dialog-contract test (AC-2) so the options shape is asserted without a host.
 */
export function buildDialogOptions(options: DialogHostOptions): {
    url: string;
    height: number;
    width: number;
    displayInIframe: boolean;
} {
    return {
        url: options.url,
        height: options.heightPercent,
        width: options.widthPercent,
        // Same-origin dialog runs in an iframe on desktop/web.
        displayInIframe: true,
    };
}

/**
 * Parses a DialogMessageReceived payload string into a DialogSelectionMessage, or returns null
 * when the payload is not a valid iFile selection message. Pure; used by the contract test.
 */
export function parseSelectionMessage(payload: string): DialogSelectionMessage | null {
    let parsed: unknown;
    try {
        parsed = JSON.parse(payload);
    } catch {
        return null;
    }
    if (
        typeof parsed === "object" &&
        parsed !== null &&
        (parsed as { kind?: unknown }).kind === "ifile-selection" &&
        typeof (parsed as { folderId?: unknown }).folderId === "string" &&
        typeof (parsed as { path?: unknown }).path === "string"
    ) {
        const message = parsed as { folderId: string; path: string };
        return { kind: "ifile-selection", folderId: message.folderId, path: message.path };
    }
    return null;
}

/**
 * Opens the iFile Office Dialog and wires the DialogMessageReceived handler to deliver parsed
 * selections through onSelection. The dialog reference is closed after a selection is received.
 */
export function openDialog(options: DialogHostOptions): void {
    const dialogOptions = buildDialogOptions(options);
    Office.context.ui.displayDialogAsync(
        dialogOptions.url,
        { height: dialogOptions.height, width: dialogOptions.width, displayInIframe: true },
        (result) => {
            if (result.status !== Office.AsyncResultStatus.Succeeded) {
                return;
            }
            const dialog = result.value;
            dialog.addEventHandler(Office.EventType.DialogMessageReceived, (arg) => {
                const message = parseSelectionMessage((arg as { message: string }).message);
                if (message !== null) {
                    options.onSelection(message);
                    dialog.close();
                }
            });
        }
    );
}

/**
 * Called from within the dialog page to post the user's selection back to the parent via
 * messageParent. Mirrors the DialogSelectionMessage contract asserted by the contract test.
 */
export function postSelectionToParent(folderId: string, path: string): void {
    const message: DialogSelectionMessage = { kind: "ifile-selection", folderId, path };
    Office.context.ui.messageParent(JSON.stringify(message));
}
