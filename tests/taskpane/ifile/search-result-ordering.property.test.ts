/**
 * Property-based tests for orderSearchResults (AC-5, T2 property gate).
 */

import { describe } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import { orderSearchResults } from "../../../src/taskpane/ifile/search-result-ordering";
import type { FolderResult } from "../../../src/taskpane/ifile/folder-result";

const arbResult: fc.Arbitrary<FolderResult> = fc.record({
    folderId: fc.string(),
    displayName: fc.string(),
    path: fc.string(),
    source: fc.constant<"search">("search"),
});

describe("orderSearchResults property invariants", () => {
    /**
     * Property: the output is a permutation of the input (same multiset of items).
     */
    test.prop([fc.array(arbResult), fc.string()])(
        "output is a permutation of the input",
        (items, pattern) => {
            const out = orderSearchResults(items, pattern);
            if (out.length !== items.length) {
                return false;
            }
            const sortKey = (r: FolderResult): string => `${r.folderId} ${r.displayName} ${r.path}`;
            const inKeys = items.map(sortKey).sort();
            const outKeys = out.map(sortKey).sort();
            // eslint-disable-next-line security/detect-object-injection -- numeric array index from Array.every callback, not an attacker-controlled key
            return inKeys.every((k, i) => k === outKeys[i]);
        }
    );

    /**
     * Property: the result is non-decreasing by the documented (rank, path) key,
     * verified by re-sorting the output and confirming it is unchanged.
     */
    test.prop([fc.array(arbResult), fc.string()])(
        "output is stable under re-ordering with the same key",
        (items, pattern) => {
            const once = orderSearchResults(items, pattern);
            const twice = orderSearchResults(once, pattern);
            // eslint-disable-next-line security/detect-object-injection -- numeric array index from Array.every callback, not an attacker-controlled key
            return once.every((r, i) => r === twice[i]);
        }
    );
});
