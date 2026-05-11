import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

describe("commands module", () => {
    let associateSpy: ReturnType<typeof vi.fn>;

    beforeEach(() => {
        vi.resetModules();
        associateSpy = vi.fn();
        (globalThis as Record<string, unknown>)["Office"] = {
            onReady: (cb: () => void) => {
                cb();
            },
            HostType: { Outlook: "Outlook" },
            EventType: { ItemChanged: "olkItemSelectedChanged" },
            context: {
                mailbox: { item: null },
            },
            MailboxEnums: {
                ItemNotificationMessageType: { InformationalMessage: "InformationalMessage" },
            },
            actions: {
                associate: associateSpy,
            },
        };
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("imports without throwing and registers no Office.actions.associate calls", async () => {
        // Act
        await expect(import("./commands")).resolves.toBeDefined();

        // Assert
        expect(associateSpy).toHaveBeenCalledTimes(0);
    });
});
