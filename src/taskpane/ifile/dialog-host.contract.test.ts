/**
 * Office.js dialog-contract test for the desktop dialog host (AC-2, CI portion). Asserts the
 * displayDialogAsync options shape (same-origin URL, percentage sizing, iframe) and the
 * messageParent / DialogMessageReceived JSON message contract against a faked Office.context.ui.
 */

import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
    buildDialogOptions,
    openDialog,
    parseSelectionMessage,
    postSelectionToParent,
    type DialogSelectionMessage,
} from "./dialog-host";

interface FakeDialog {
    addEventHandler: (eventType: string, handler: (arg: { message: string }) => void) => void;
    close: () => void;
}

interface CapturedDialog {
    url: string;
    options: { height: number; width: number; displayInIframe: boolean };
    messageHandler?: (arg: { message: string }) => void;
    closed: boolean;
}

function installOfficeFake(capture: CapturedDialog): void {
    const dialog: FakeDialog = {
        addEventHandler: (_eventType, handler) => {
            capture.messageHandler = handler;
        },
        close: () => {
            capture.closed = true;
        },
    };
    (globalThis as Record<string, unknown>)["Office"] = {
        AsyncResultStatus: { Succeeded: "succeeded" },
        EventType: { DialogMessageReceived: "dialogMessageReceived" },
        context: {
            ui: {
                displayDialogAsync: (
                    url: string,
                    options: { height: number; width: number; displayInIframe: boolean },
                    callback: (result: { status: string; value: FakeDialog }) => void
                ) => {
                    capture.url = url;
                    capture.options = options;
                    callback({ status: "succeeded", value: dialog });
                },
                messageParent: (message: string) => {
                    capture.messageHandler?.({ message });
                },
            },
        },
    };
}

describe("dialog-host contract — options shape", () => {
    it("builds same-origin URL with percentage sizing and iframe", () => {
        const options = buildDialogOptions({
            url: "https://localhost:3000/ifile.html",
            heightPercent: 60,
            widthPercent: 40,
            onSelection: () => undefined,
        });
        expect(options.url).toBe("https://localhost:3000/ifile.html");
        expect(options.height).toBe(60);
        expect(options.width).toBe(40);
        expect(options.displayInIframe).toBe(true);
    });
});

describe("dialog-host contract — selection message JSON", () => {
    it("parses a valid ifile-selection message", () => {
        const json = JSON.stringify({
            kind: "ifile-selection",
            folderId: "acme",
            path: "Archive/Clients/Acme",
        } satisfies DialogSelectionMessage);
        expect(parseSelectionMessage(json)).toEqual({
            kind: "ifile-selection",
            folderId: "acme",
            path: "Archive/Clients/Acme",
        });
    });

    it("rejects malformed or non-selection payloads", () => {
        expect(parseSelectionMessage("not json")).toBeNull();
        expect(parseSelectionMessage(JSON.stringify({ kind: "other" }))).toBeNull();
        expect(parseSelectionMessage(JSON.stringify({ kind: "ifile-selection" }))).toBeNull();
    });
});

describe("dialog-host contract — round trip", () => {
    let capture: CapturedDialog;

    beforeEach(() => {
        capture = {
            url: "",
            options: { height: 0, width: 0, displayInIframe: false },
            closed: false,
        };
        installOfficeFake(capture);
    });

    afterEach(() => {
        delete (globalThis as Record<string, unknown>)["Office"];
    });

    it("opens the dialog and delivers a parsed selection then closes", () => {
        // Arrange
        const onSelection = vi.fn();
        openDialog({
            url: "https://localhost:3000/ifile.html",
            heightPercent: 60,
            widthPercent: 40,
            onSelection,
        });

        // Act — simulate the dialog posting a selection to its parent.
        postSelectionToParent("acme", "Archive/Clients/Acme");

        // Assert
        expect(capture.url).toBe("https://localhost:3000/ifile.html");
        expect(capture.options.displayInIframe).toBe(true);
        expect(onSelection).toHaveBeenCalledWith({
            kind: "ifile-selection",
            folderId: "acme",
            path: "Archive/Clients/Acme",
        });
        expect(capture.closed).toBe(true);
    });
});
