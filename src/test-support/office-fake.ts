// Minimal Office.js fake for unit tests.
// Exposes the same global shape that taskpane.ts and commands.ts expect.

const officeFake = {
  onReady: (callback: (info: { host: unknown }) => void) => {
    callback({ host: null });
  },
  HostType: {
    Outlook: "Outlook",
  },
  context: {
    mailbox: {
      item: null as null | Record<string, unknown>,
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
