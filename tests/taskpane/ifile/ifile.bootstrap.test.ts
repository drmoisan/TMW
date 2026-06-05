/**
 * Wiring-seam unit tests for the iFile host-bootstrap module (issue #43, defect 2/3).
 *
 * Drives the exported `bootstrap` seam of src/taskpane/ifile/ifile.ts without the real Office
 * host. Asserts that when token acquisition or the one-time folder load fails, bootstrap still
 * binds the input handler and surfaces a visible error state rather than leaving the box inert.
 */

import { describe, expect, it, vi } from "vitest";
import {
    bootstrap,
    SIGN_IN_FAILURE_MESSAGE,
    CONNECTION_FAILURE_MESSAGE,
} from "../../../src/taskpane/ifile/ifile";
import type { FolderResult } from "../../../src/taskpane/ifile/folder-result";

function leaf(name: string, path: string): FolderResult {
    return { folderId: `id-${path}`, displayName: name, path, source: "search" };
}

const fixture: FolderResult[] = [leaf("Acme", "Archive/Clients/Acme")];

function makeDom(): { searchInput: HTMLInputElement; resultsList: HTMLDivElement } {
    const searchInput = document.createElement("input");
    const resultsList = document.createElement("div");
    document.body.append(searchInput, resultsList);
    return { searchInput, resultsList };
}

describe("ifile bootstrap — resilient wiring", () => {
    it("binds the input handler and surfaces a visible error when token acquisition fails", async () => {
        // Arrange — token acquisition rejects (SSO failure on device).
        const dom = makeDom();

        // Act
        await bootstrap({
            dom,
            presentation: "inline",
            acquireToken: () => Promise.reject(new Error("token denied")),
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: vi.fn(),
        });

        // Assert — a visible error row exists and the box is still responsive.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow).not.toBeNull();
        dom.searchInput.value = "acme";
        expect(() => dom.searchInput.dispatchEvent(new Event("input"))).not.toThrow();
    });

    it("binds the input handler and surfaces a visible error when the one-time load fails", async () => {
        // Arrange — load rejects after a successful token.
        const dom = makeDom();

        // Act
        await bootstrap({
            dom,
            presentation: "inline",
            acquireToken: () => Promise.resolve("token-123"),
            loadLeaves: () => Promise.reject(new Error("load failed")),
            onSelect: vi.fn(),
        });

        // Assert
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow).not.toBeNull();
        dom.searchInput.value = "acme";
        expect(() => dom.searchInput.dispatchEvent(new Event("input"))).not.toThrow();
    });

    it("renders the distinct sign-in message when token acquisition fails", async () => {
        // Arrange — token acquisition rejects; the sign-in stage failed.
        const dom = makeDom();

        // Act
        await bootstrap({
            dom,
            presentation: "inline",
            acquireToken: () => Promise.reject(new Error("token denied")),
            loadLeaves: () => Promise.resolve(fixture),
            onSelect: vi.fn(),
        });

        // Assert — the error row carries the sign-in-stage message, not the connection message.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow?.textContent).toBe(SIGN_IN_FAILURE_MESSAGE);
        expect(errorRow?.textContent).not.toBe(CONNECTION_FAILURE_MESSAGE);
    });

    it("renders the distinct connection message when the one-time load fails", async () => {
        // Arrange — token resolves but the folder load rejects; the connection stage failed.
        const dom = makeDom();

        // Act
        await bootstrap({
            dom,
            presentation: "inline",
            acquireToken: () => Promise.resolve("token-123"),
            loadLeaves: () => Promise.reject(new Error("load failed")),
            onSelect: vi.fn(),
        });

        // Assert — the error row carries the connection-stage message, not the sign-in message.
        const errorRow = dom.resultsList.querySelector("[data-ifile-error]");
        expect(errorRow?.textContent).toBe(CONNECTION_FAILURE_MESSAGE);
        expect(errorRow?.textContent).not.toBe(SIGN_IN_FAILURE_MESSAGE);
    });

    it("renders results on input when token and load both succeed (positive path)", async () => {
        // Arrange — both token acquisition and load succeed.
        const dom = makeDom();
        const loadLeaves = vi.fn((token: string) => {
            expect(token).toBe("token-123");
            return Promise.resolve(fixture);
        });

        // Act
        await bootstrap({
            dom,
            presentation: "inline",
            acquireToken: () => Promise.resolve("token-123"),
            loadLeaves,
            onSelect: vi.fn(),
        });
        dom.searchInput.value = "acme";
        dom.searchInput.dispatchEvent(new Event("input"));

        // Assert — a normal result row renders and no error row is present.
        expect(loadLeaves).toHaveBeenCalledTimes(1);
        expect(dom.resultsList.querySelector("[data-ifile-error]")).toBeNull();
        const rows = dom.resultsList.querySelectorAll("[data-folder-id]");
        expect(rows).toHaveLength(1);
        expect(rows[0]?.textContent).toBe("Archive/Clients/Acme");
    });
});
