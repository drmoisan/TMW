/**
 * iFile backend client. Calls the folder-list query and the filing command via the typed
 * operations generated into src/api-client/v1.ts. Sends only the message REST id, destination
 * folder id, and (optionally) the Archive-root drive-item id. No Graph writes run on the
 * client. Satisfies AC-10, AC-12.
 */

import type { components } from "../../api-client/v1";
import type { FolderResult } from "./folder-result";

/** Wire shapes re-exported from the generated OpenAPI client. */
export type FolderListResponse = components["schemas"]["FolderListResponse"];
export type FolderListItem = components["schemas"]["FolderListItem"];
export type FileMessageRequest = components["schemas"]["FileMessageEndpointRequest"];
export type FileMessageResponse = components["schemas"]["FileMessageEndpointResponse"];

/**
 * Thin HTTP client for GET /api/ifile/folders and POST /api/ifile/file. Holds no Graph logic.
 */
export class IFileApiClient {
    private readonly baseUrl: string;

    constructor(baseUrl: string) {
        this.baseUrl = baseUrl.replace(/\/$/, "");
    }

    /**
     * Fetches the flat leaf-folder list and maps each entry to a search-sourced FolderResult.
     * The client loads this once per container open (AC-8 is enforced by the controller).
     */
    async loadLeafFolders(bearerToken: string): Promise<FolderResult[]> {
        const response = await fetch(`${this.baseUrl}/api/ifile/folders`, {
            method: "GET",
            headers: { Authorization: `Bearer ${bearerToken}` },
        });
        if (!response.ok) {
            throw new Error(
                `loadLeafFolders: unexpected response ${String(response.status)} ${response.statusText}`
            );
        }
        const data = (await response.json()) as FolderListResponse;
        return data.folders.map((f) => ({
            folderId: f.folderId,
            displayName: f.displayName,
            path: f.path,
            source: "search" as const,
        }));
    }

    /**
     * Issues the filing command carrying only the message REST id, destination folder id, and
     * the optional Archive-root drive-item id. No Graph write executes on the client.
     */
    async fileMessage(
        request: {
            messageRestId: string;
            destinationFolderId: string;
            archiveRootDriveItemId?: string;
        },
        bearerToken: string
    ): Promise<FileMessageResponse> {
        const body: FileMessageRequest = {
            messageRestId: request.messageRestId,
            destinationFolderId: request.destinationFolderId,
            archiveRootDriveItemId: request.archiveRootDriveItemId ?? null,
        };
        const response = await fetch(`${this.baseUrl}/api/ifile/file`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${bearerToken}`,
            },
            body: JSON.stringify(body),
        });
        if (!response.ok) {
            throw new Error(
                `fileMessage: unexpected response ${String(response.status)} ${response.statusText}`
            );
        }
        return (await response.json()) as FileMessageResponse;
    }
}
