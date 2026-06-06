/**
 * Host-neutral REST-id resolver (pure given the injected converter). Satisfies AC-11 (HC-3).
 *
 * On Outlook mobile (hostName === "OutlookIOS"), `item.itemId` is already REST-formatted and
 * `convertToRestId` is not supported, so the id is returned as-is. On all other hosts the id
 * is converted via the injected `convert` function (the caller supplies
 * `Office.context.mailbox.convertToRestId(id, Office.MailboxEnums.RestVersion.v2_0)`).
 */

/** The Office.js host name reported for Outlook on iOS/Android mobile. */
export const MOBILE_HOST_NAME = "OutlookIOS";

/**
 * Returns the Graph REST id for the message. On mobile the `itemId` is returned unchanged
 * (no conversion); otherwise the injected `convert` is applied.
 */
export function resolveMessageRestId(
    hostName: string,
    itemId: string,
    convert: (id: string) => string
): string {
    if (hostName === MOBILE_HOST_NAME) {
        return itemId;
    }
    return convert(itemId);
}
