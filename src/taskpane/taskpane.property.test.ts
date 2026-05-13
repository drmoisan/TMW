/**
 * Property-based tests for pure helpers in taskpane.ts.
 *
 * Uses @fast-check/vitest to verify invariants that must hold
 * for all inputs, not just selected examples.
 *
 * The module is dynamically imported after the Office global is installed
 * because taskpane.ts calls Office.onReady() at module scope.
 */

import { beforeAll, describe } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import type { normalizeTitle as NormalizeTitle } from "./taskpane";

// normalizeTitle is resolved via dynamic import after the Office mock is in place.
let normalizeTitle: typeof NormalizeTitle;

beforeAll(async () => {
    (globalThis as Record<string, unknown>)["Office"] = {
        onReady: () => undefined,
        HostType: { Outlook: "Outlook" },
        EventType: { ItemChanged: "olkItemSelectedChanged" },
        context: { mailbox: { item: null, addHandlerAsync: () => undefined } },
    };
    const mod = await import("./taskpane");
    normalizeTitle = mod.normalizeTitle;
});

describe("normalizeTitle property invariants", () => {
    /**
     * Property: normalizeTitle is idempotent — applying it twice produces
     * the same result as applying it once.
     */
    test.prop([fc.string()])("normalizeTitle is idempotent", (s) => {
        const once = normalizeTitle(s);
        const twice = normalizeTitle(once);
        return once === twice;
    });

    /**
     * Property: normalizeTitle never increases the length of the input string
     * because trim() can only remove characters, never add them.
     */
    test.prop([fc.string()])("normalizeTitle does not increase string length", (s) => {
        return normalizeTitle(s).length <= s.length;
    });

    /**
     * Property: normalizeTitle output has no leading or trailing whitespace.
     */
    test.prop([fc.string()])("normalizeTitle output has no leading or trailing whitespace", (s) => {
        const result = normalizeTitle(s);
        return result === result.trim();
    });
});
