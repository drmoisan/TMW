import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

type ActionFn = (event: { completed: () => void }) => void;

describe("commands module action() handler", () => {
  let registeredAction: ActionFn | undefined;
  let replaceAsyncMock: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    vi.resetModules();
    registeredAction = undefined;
    replaceAsyncMock = vi.fn();

    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: () => void) => {
        cb();
      },
      HostType: { Outlook: "Outlook" },
      context: {
        mailbox: {
          item: {
            notificationMessages: {
              replaceAsync: replaceAsyncMock,
            },
          },
        },
      },
      MailboxEnums: {
        ItemNotificationMessageType: { InformationalMessage: "InformationalMessage" },
      },
      actions: {
        associate: (_name: string, fn: ActionFn) => {
          registeredAction = fn;
        },
      },
    };
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it("registers an action named 'action' on module import", async () => {
    // Act
    await import("./commands");

    // Assert
    expect(registeredAction).toBeTypeOf("function");
  });

  it("action() invokes notificationMessages.replaceAsync and event.completed when item is present", async () => {
    // Arrange
    await import("./commands");
    const completed = vi.fn();

    // Act
    registeredAction?.({ completed });

    // Assert
    expect(replaceAsyncMock).toHaveBeenCalledWith(
      "ActionPerformanceNotification",
      expect.objectContaining({
        type: "InformationalMessage",
        message: "Performed action.",
        icon: "Icon.80x80",
        persistent: true,
      })
    );
    expect(completed).toHaveBeenCalledTimes(1);
  });

  it("action() completes event without notification when item is null", async () => {
    // Arrange
    ((globalThis as Record<string, unknown>)["Office"] as Record<string, unknown>)["context"] = {
      mailbox: { item: null },
    };
    await import("./commands");
    const completed = vi.fn();

    // Act
    registeredAction?.({ completed });

    // Assert
    expect(replaceAsyncMock).not.toHaveBeenCalled();
    expect(completed).toHaveBeenCalledTimes(1);
  });

  it("action() completes event without notification when item is undefined", async () => {
    // Arrange
    ((globalThis as Record<string, unknown>)["Office"] as Record<string, unknown>)["context"] = {
      mailbox: { item: undefined },
    };
    await import("./commands");
    const completed = vi.fn();

    // Act
    registeredAction?.({ completed });

    // Assert
    expect(replaceAsyncMock).not.toHaveBeenCalled();
    expect(completed).toHaveBeenCalledTimes(1);
  });
});
