/*
 * Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
 * See LICENSE in the project root for license information.
 */

/* global document, Office, HTMLElement */

function requireElement(id: string): HTMLElement {
  const el = document.getElementById(id);
  if (el === null) {
    throw new Error(`Required element #${id} not found in DOM`);
  }
  return el;
}

void Office.onReady((info) => {
  if (info.host === Office.HostType.Outlook) {
    requireElement("sideload-msg").style.display = "none";
    requireElement("app-body").style.display = "flex";
    requireElement("run").onclick = run;
  }
});

export function run(): void {
  /**
   * Insert your Outlook code here
   */

  const item = Office.context.mailbox.item as Office.MessageRead | null | undefined;
  if (item === null || item === undefined) return;
  const insertAt = requireElement("item-subject");
  const label = document.createElement("b").appendChild(document.createTextNode("Subject: "));
  insertAt.appendChild(label);
  insertAt.appendChild(document.createElement("br"));
  const subject: string = typeof item.subject === "string" ? item.subject : "";
  insertAt.appendChild(document.createTextNode(subject));
  insertAt.appendChild(document.createElement("br"));
}
