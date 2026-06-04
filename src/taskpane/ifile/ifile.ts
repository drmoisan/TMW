/*
 * iFile entry point. Loaded by the shared ifile.html bundle in both the desktop Office Dialog
 * and the mobile inline full-screen task pane. Selects the presentation at runtime via host
 * detection (selectPresentation) so a single UI/logic implementation serves both (AC-2, AC-3).
 *
 * This module is the only host-bound bootstrap; the search behavior, result-list composition,
 * and selection handling live in the shared, host-neutral IFileController.
 */

/* global Office, document, HTMLInputElement, HTMLElement, console */

import { IFileController } from "./ifile-controller";
import { IFileApiClient } from "./ifile-api-client";
import { resolveMessageRestId } from "./message-id-resolver";
import { selectPresentation } from "./host-presentation";
import { mountInline } from "./inline-host";
import { postSelectionToParent } from "./dialog-host";

// Injected by webpack DefinePlugin at build time. Default: https://localhost:3000 (desktop dev
// server). Set API_BASE_URL env var before running 'npm run build' to override for mobile builds.
declare const __API_BASE_URL__: string;
const API_BASE_URL = __API_BASE_URL__;

void Office.onReady((info) => {
    if (info.host !== Office.HostType.Outlook) {
        return;
    }
    bootstrap().catch((error: unknown) => {
        console.error("iFile bootstrap failed", error);
    });
});

async function bootstrap(): Promise<void> {
    const hostName = Office.context.mailbox.diagnostics.hostName;
    const presentation = selectPresentation(hostName);

    const token = await Office.auth.getAccessToken({ allowSignInPrompt: true });
    const client = new IFileApiClient(API_BASE_URL);

    const controller = new IFileController({
        loadLeaves: () => client.loadLeafFolders(token),
        onSelect: (folder) => {
            // In the dialog presentation the selection is posted to the parent; the inline
            // presentation handles the filing call in the parent pane directly.
            if (presentation === "dialog") {
                postSelectionToParent(folder.folderId, folder.path);
            }
        },
    });

    const searchInput = document.getElementById("ifile-search");
    const resultsList = document.getElementById("ifile-results");
    if (searchInput instanceof HTMLInputElement && resultsList instanceof HTMLElement) {
        await mountInline(controller, { searchInput, resultsList });
    }
}

// Re-export the resolver so the host page can compute the message REST id when issuing a filing
// call. Kept here to anchor the host-detection bootstrap module's public surface.
export { resolveMessageRestId };
