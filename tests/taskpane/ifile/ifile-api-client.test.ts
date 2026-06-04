/**
 * Unit tests for IFileApiClient (AC-10). Mocked transport asserts the filing request body
 * carries only the message REST id, destination folder id, and optional archive-root id, and
 * issues no Graph write.
 */

import { afterEach, describe, expect, it, vi } from "vitest";
import { IFileApiClient } from "../../../src/taskpane/ifile/ifile-api-client";

describe("IFileApiClient", () => {
    afterEach(() => {
        vi.restoreAllMocks();
    });

    it("posts only the documented filing body fields", async () => {
        // Arrange
        const fetchMock = vi.fn().mockResolvedValue({
            ok: true,
            status: 200,
            statusText: "OK",
            json: () => Promise.resolve({ outcome: "success", error: null }),
        });
        vi.stubGlobal("fetch", fetchMock);
        const client = new IFileApiClient("https://localhost:3000");

        // Act
        const result = await client.fileMessage(
            {
                messageRestId: "msg-1",
                destinationFolderId: "acme",
                archiveRootDriveItemId: "drive-root",
            },
            "token-abc"
        );

        // Assert
        expect(result.outcome).toBe("success");
        expect(fetchMock).toHaveBeenCalledTimes(1);
        const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
        expect(url).toBe("https://localhost:3000/api/ifile/file");
        expect(init.method).toBe("POST");
        const body = JSON.parse(init.body as string) as Record<string, unknown>;
        expect(Object.keys(body).sort()).toEqual([
            "archiveRootDriveItemId",
            "destinationFolderId",
            "messageRestId",
        ]);
        expect(body["messageRestId"]).toBe("msg-1");
        expect(body["destinationFolderId"]).toBe("acme");
    });

    it("maps the folder-list response to search-sourced FolderResults", async () => {
        // Arrange
        const fetchMock = vi.fn().mockResolvedValue({
            ok: true,
            status: 200,
            statusText: "OK",
            json: () =>
                Promise.resolve({
                    folders: [
                        { folderId: "acme", displayName: "Acme", path: "Archive/Clients/Acme" },
                    ],
                }),
        });
        vi.stubGlobal("fetch", fetchMock);
        const client = new IFileApiClient("https://localhost:3000");

        // Act
        const leaves = await client.loadLeafFolders("token-abc");

        // Assert
        expect(leaves).toHaveLength(1);
        expect(leaves[0]?.source).toBe("search");
        expect(leaves[0]?.path).toBe("Archive/Clients/Acme");
    });

    it("throws on a non-ok filing response", async () => {
        // Arrange
        const fetchMock = vi.fn().mockResolvedValue({
            ok: false,
            status: 500,
            statusText: "Internal Server Error",
            json: () => Promise.resolve({}),
        });
        vi.stubGlobal("fetch", fetchMock);
        const client = new IFileApiClient("https://localhost:3000");

        // Act / Assert
        await expect(
            client.fileMessage({ messageRestId: "m", destinationFolderId: "d" }, "token")
        ).rejects.toThrow(/unexpected response 500/);
    });
});
