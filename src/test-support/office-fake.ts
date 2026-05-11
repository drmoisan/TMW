// Minimal Office.js fake for unit tests.
// Exposes the same global shape that taskpane.ts and commands.ts expect.

type MailboxHandler = (...args: unknown[]) => void;
type AsyncCallback = (...args: unknown[]) => void;

const officeFake = {
    onReady: (callback: (info: { host: unknown }) => void) => {
        callback({ host: null });
    },
    HostType: {
        Outlook: "Outlook",
    },
    EventType: {
        ItemChanged: "olkItemSelectedChanged",
    },
    context: {
        mailbox: {
            item: null as null | Record<string, unknown>,
            addHandlerAsync: (
                _eventType: string,
                _handler: MailboxHandler,
                callback?: AsyncCallback
            ) => {
                if (typeof callback === "function") {
                    callback({ status: "succeeded" });
                }
            },
            removeHandlerAsync: (_eventType: string, callback?: AsyncCallback) => {
                if (typeof callback === "function") {
                    callback({ status: "succeeded" });
                }
            },
        },
    },
    MailboxEnums: {
        ItemNotificationMessageType: {
            InformationalMessage: "InformationalMessage",
        },
    },
    actions: {
        associate: () => undefined,
    },
} as unknown as typeof Office;

export default officeFake;
