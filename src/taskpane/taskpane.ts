/*
 * TaskMaster task pane entry point.
 *
 * Responsibilities:
 *   - Wire Office.onReady to display the app shell when running in Outlook.
 *   - Subscribe to Office.EventType.ItemChanged and re-render selected-message context.
 *   - Keep render logic pure (DOM-only, no Office.* references) so it is unit-testable.
 */

/* global document, Office, HTMLElement */

export interface RenderableItem {
  subject?: string;
  from?: { displayName?: string; emailAddress?: string };
}

export interface RenderDom {
  status: HTMLElement;
  subject: HTMLElement;
  from: HTMLElement;
}

export function renderItem(item: RenderableItem, dom: RenderDom): void {
  const subject = typeof item.subject === "string" ? item.subject : "";
  const fromName =
    item.from && typeof item.from.displayName === "string" ? item.from.displayName : "";
  const fromEmail =
    item.from && typeof item.from.emailAddress === "string" ? item.from.emailAddress : "";
  const fromText =
    fromName.length > 0 && fromEmail.length > 0
      ? `${fromName} <${fromEmail}>`
      : fromName.length > 0
        ? fromName
        : fromEmail;
  dom.status.textContent = "Message selected.";
  dom.subject.textContent = subject;
  dom.from.textContent = fromText;
}

export function renderEmpty(dom: RenderDom): void {
  dom.status.textContent = "No message selected.";
  dom.subject.textContent = "";
  dom.from.textContent = "";
}

function requireElement(id: string): HTMLElement {
  const el = document.getElementById(id);
  if (el === null) {
    throw new Error(`Required element #${id} not found in DOM`);
  }
  return el;
}

function getRenderDom(): RenderDom {
  return {
    status: requireElement("status"),
    subject: requireElement("selected-subject"),
    from: requireElement("selected-from"),
  };
}

export function onItemChanged(): void {
  const item = Office.context.mailbox.item as RenderableItem | null | undefined;
  const dom = getRenderDom();
  if (item === null || item === undefined) {
    renderEmpty(dom);
    return;
  }
  renderItem(item, dom);
}

void Office.onReady((info) => {
  if (info.host === Office.HostType.Outlook) {
    requireElement("sideload-msg").style.display = "none";
    requireElement("app-body").style.display = "flex";
    Office.context.mailbox.addHandlerAsync(Office.EventType.ItemChanged, onItemChanged);
    onItemChanged();
  }
});
