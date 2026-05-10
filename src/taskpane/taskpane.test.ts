import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

describe("taskpane module import and run()", () => {
  beforeEach(() => {
    vi.resetModules();
    document.body.innerHTML = `
      <div id="sideload-msg"></div>
      <div id="app-body"></div>
      <button id="run"></button>
      <div id="item-subject"></div>
    `;
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it("on Office.onReady with Outlook host, wires up DOM elements", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "Outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: { subject: "Hello" } } },
    };

    // Act
    await import("./taskpane");

    // Assert
    const sideload = document.getElementById("sideload-msg") as HTMLElement;
    const appBody = document.getElementById("app-body") as HTMLElement;
    const runBtn = document.getElementById("run") as HTMLButtonElement;
    expect(sideload.style.display).toBe("none");
    expect(appBody.style.display).toBe("flex");
    expect(runBtn.onclick).toBeTypeOf("function");
  });

  it("on Office.onReady with non-Outlook host, leaves DOM untouched", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string | null }) => void) => {
        cb({ host: null });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: null } },
    };

    // Act
    await import("./taskpane");

    // Assert
    const sideload = document.getElementById("sideload-msg") as HTMLElement;
    expect(sideload.style.display).toBe("");
  });

  it("run() appends subject text when item exists", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "non-outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: { subject: "Test Subject" } } },
    };
    const mod = await import("./taskpane");

    // Act
    mod.run();

    // Assert
    const el = document.getElementById("item-subject");
    expect(el?.textContent).toContain("Test Subject");
  });

  it("run() returns early when item is null", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "non-outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: null } },
    };
    const mod = await import("./taskpane");

    // Act
    mod.run();

    // Assert
    const el = document.getElementById("item-subject");
    expect(el?.textContent ?? "").toBe("");
  });

  it("run() returns early when item is undefined", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "non-outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: undefined } },
    };
    const mod = await import("./taskpane");

    // Act
    mod.run();

    // Assert
    const el = document.getElementById("item-subject");
    expect(el?.textContent ?? "").toBe("");
  });

  it("run() uses empty subject when item.subject is not a string", async () => {
    // Arrange
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "non-outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: { subject: undefined } } },
    };
    const mod = await import("./taskpane");

    // Act
    mod.run();

    // Assert: text node was appended even with empty subject
    const el = document.getElementById("item-subject");
    expect(el?.textContent).toContain("Subject: ");
  });

  it("module import throws when required DOM elements are missing and host is Outlook", async () => {
    // Arrange: remove sideload-msg so requireElement throws
    document.body.innerHTML = "";
    (globalThis as Record<string, unknown>)["Office"] = {
      onReady: (cb: (info: { host: string }) => void) => {
        cb({ host: "Outlook" });
      },
      HostType: { Outlook: "Outlook" },
      context: { mailbox: { item: null } },
    };

    // Act + Assert
    await expect(import("./taskpane")).rejects.toThrow(/Required element/);
  });
});
