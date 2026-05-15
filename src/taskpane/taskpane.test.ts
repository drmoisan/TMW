import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";

type MailboxHandler = () => void;

interface OfficeMailboxStub {
    item: unknown;
    addHandlerAsync: ReturnType<typeof vi.fn>;
    removeHandlerAsync?: ReturnType<typeof vi.fn>;
}

interface OfficeStub {
    onReady: (cb: (info: { host: string | null }) => void) => void;
    HostType: { Outlook: string };
    EventType: { ItemChanged: string };
    context: { mailbox: OfficeMailboxStub };
}

function installShellDom(): void {
    document.body.innerHTML = `
    <div id="sideload-msg"></div>
    <div id="app-body">
      <p id="status"></p>
      <span id="selected-subject"></span>
      <span id="selected-from"></span>
    </div>
  `;
}

function installOffice(
    stub: Partial<OfficeStub> & { context: { mailbox: OfficeMailboxStub } }
): void {
    const defaults: OfficeStub = {
        onReady: (cb) => {
            cb({ host: "Outlook" });
        },
        HostType: { Outlook: "Outlook" },
        EventType: { ItemChanged: "olkItemSelectedChanged" },
        context: stub.context,
    };
    const merged: OfficeStub = { ...defaults, ...stub };
    (globalThis as Record<string, unknown>)["Office"] = merged;
}

describe("renderItem / renderEmpty pure functions", () => {
    beforeEach(() => {
        vi.resetModules();
        installShellDom();
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("renderItem writes subject and sender into supplied DOM elements", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const dom = {
            status: document.getElementById("status") as HTMLElement,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
        };

        // Act
        mod.renderItem(
            {
                subject: "Quarterly review",
                from: { displayName: "Ana", emailAddress: "ana@example.com" },
            },
            dom
        );

        // Assert
        expect(dom.subject.textContent).toBe("Quarterly review");
        expect(dom.from.textContent).toBe("Ana <ana@example.com>");
    });

    it("renderItem renders an empty string for a missing subject without throwing", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const dom = {
            status: document.getElementById("status") as HTMLElement,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
        };

        // Act + Assert
        expect(() => mod.renderItem({ from: { displayName: "Bo" } }, dom)).not.toThrow();
        expect(dom.subject.textContent).toBe("");
        expect(dom.from.textContent).toBe("Bo");
    });

    it("renderEmpty clears subject/from and sets a placeholder status", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const dom = {
            status: document.getElementById("status") as HTMLElement,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
        };
        dom.subject.textContent = "stale";
        dom.from.textContent = "stale";

        // Act
        mod.renderEmpty(dom);

        // Assert
        expect(dom.subject.textContent).toBe("");
        expect(dom.from.textContent).toBe("");
        expect(dom.status.textContent).toBe("No message selected.");
    });
});

describe("onItemChanged dispatch", () => {
    beforeEach(() => {
        vi.resetModules();
        installShellDom();
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("calls renderEmpty when Office.context.mailbox.item is null", async () => {
        // Arrange
        installOffice({
            onReady: (cb) => {
                cb({ host: "non-outlook" });
            },
            context: { mailbox: { item: null, addHandlerAsync: vi.fn() } },
        });
        const mod = await import("./taskpane");

        // Act
        mod.onItemChanged();

        // Assert
        expect(document.getElementById("status")?.textContent).toBe("No message selected.");
        expect(document.getElementById("selected-subject")?.textContent).toBe("");
        expect(document.getElementById("selected-from")?.textContent).toBe("");
    });
});

describe("Office.onReady subscription wiring", () => {
    beforeEach(() => {
        vi.resetModules();
        installShellDom();
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("subscribes to ItemChanged with a function from inside Office.onReady (called exactly once)", async () => {
        // Arrange
        const addHandlerAsync = vi.fn();
        installOffice({
            context: {
                mailbox: {
                    item: { subject: "Initial", from: { displayName: "Ana" } },
                    addHandlerAsync,
                },
            },
        });

        // Act
        await import("./taskpane");

        // Assert
        expect(addHandlerAsync).toHaveBeenCalledTimes(1);
        expect(addHandlerAsync.mock.calls[0]?.[0]).toBe("olkItemSelectedChanged");
        expect(addHandlerAsync.mock.calls[0]?.[1]).toBeTypeOf("function");
    });

    it("re-renders DOM when the captured handler runs against a new mailbox item", async () => {
        // Arrange
        const addHandlerAsync = vi.fn();
        const mailbox: OfficeMailboxStub = {
            item: {
                subject: "First",
                from: { displayName: "Ana", emailAddress: "ana@example.com" },
            },
            addHandlerAsync,
        };
        installOffice({ context: { mailbox } });

        await import("./taskpane");
        expect(document.getElementById("selected-subject")?.textContent).toBe("First");

        // Act: capture the handler passed to addHandlerAsync, update the item, invoke handler
        const handler = addHandlerAsync.mock.calls[0]?.[1] as MailboxHandler;
        mailbox.item = {
            subject: "Second",
            from: { displayName: "Bo", emailAddress: "bo@example.com" },
        };
        handler();

        // Assert
        expect(document.getElementById("selected-subject")?.textContent).toBe("Second");
        expect(document.getElementById("selected-from")?.textContent).toBe("Bo <bo@example.com>");
    });
});

describe("requireElement helper", () => {
    beforeEach(() => {
        vi.resetModules();
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("module import throws when required DOM elements are missing and host is Outlook", async () => {
        // Arrange: remove sideload-msg so requireElement throws
        document.body.innerHTML = "";
        installOffice({
            context: { mailbox: { item: null, addHandlerAsync: vi.fn() } },
        });

        // Act + Assert
        await expect(import("./taskpane")).rejects.toThrow(/Required element/);
    });
});

describe("renderClassifying and renderClassificationResult pure functions", () => {
    beforeEach(() => {
        vi.resetModules();
        installShellDom();
    });

    afterEach(() => {
        vi.resetAllMocks();
    });

    it("renderClassifying sets status text to Classifying...", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const status = document.getElementById("status") as HTMLElement;
        const dom = {
            status,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
        };

        // Act
        mod.renderClassifying(dom);

        // Assert
        expect(dom.status.textContent).toBe("Classifying...");
    });

    it("renderClassificationResult writes label and confidence to classification element", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const classification = document.createElement("span");
        const confirmBtn = document.createElement("button");
        const rejectBtn = document.createElement("button");
        confirmBtn.setAttribute("disabled", "");
        rejectBtn.setAttribute("disabled", "");
        const dom = {
            status: document.getElementById("status") as HTMLElement,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
            classification,
            confirmBtn,
            rejectBtn,
        };

        // Act
        mod.renderClassificationResult({ label: "HighPriority", confidence: 0.9 }, dom);

        // Assert
        expect(classification.textContent).toBe("HighPriority (90%)");
        expect(confirmBtn.hasAttribute("disabled")).toBe(false);
        expect(rejectBtn.hasAttribute("disabled")).toBe(false);
    });

    it("renderClassificationResult works when optional DOM elements are absent", async () => {
        // Arrange
        installOffice({ context: { mailbox: { item: null, addHandlerAsync: vi.fn() } } });
        const mod = await import("./taskpane");
        const dom = {
            status: document.getElementById("status") as HTMLElement,
            subject: document.getElementById("selected-subject") as HTMLElement,
            from: document.getElementById("selected-from") as HTMLElement,
        };

        // Act + Assert — must not throw when optional properties are absent
        expect(() =>
            mod.renderClassificationResult({ label: "General", confidence: 0.5 }, dom)
        ).not.toThrow();
    });
});
