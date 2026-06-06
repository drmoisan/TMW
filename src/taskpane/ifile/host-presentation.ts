/**
 * Host-neutral presentation selector (pure). Satisfies AC-3, AC-24 (host-detection branch).
 *
 * On Outlook mobile the Office Dialog API is unsupported (HC-1), so the search container and
 * the Archive-root picker render inline in the full-screen task pane. On desktop/web the
 * container is presented as an Office Dialog.
 */

import { MOBILE_HOST_NAME } from "./message-id-resolver";

/** The two supported presentation modes. */
export type Presentation = "dialog" | "inline";

/**
 * Returns the presentation mode for the given Office.js host name: "inline" for Outlook
 * mobile, "dialog" otherwise.
 */
export function selectPresentation(hostName: string): Presentation {
    return hostName === MOBILE_HOST_NAME ? "inline" : "dialog";
}
