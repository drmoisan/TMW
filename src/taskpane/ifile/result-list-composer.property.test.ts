/**
 * Property-based tests for ResultListComposer.compose (AC-9, T2 property gate).
 */

import { describe } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import { compose } from "./result-list-composer";
import type { FolderResult, FolderResultSource } from "./folder-result";

function arbResult(source: FolderResultSource): fc.Arbitrary<FolderResult> {
    return fc.record({
        folderId: fc.string(),
        displayName: fc.string(),
        path: fc.string(),
        source: fc.constant(source),
    });
}

const arbClassifier = fc.array(arbResult("classifier"));
const arbRecent = fc.array(arbResult("recent"));
const arbSearch = fc.array(arbResult("search"));

describe("compose property invariants", () => {
    /**
     * Property: output length equals the sum of input lengths.
     */
    test.prop([arbClassifier, arbRecent, arbSearch])(
        "output length equals the sum of input lengths",
        (c, r, s) => {
            return compose(c, r, s).length === c.length + r.length + s.length;
        }
    );

    /**
     * Property: the search subsequence of the output preserves its input order.
     */
    test.prop([arbClassifier, arbRecent, arbSearch])(
        "search subsequence preserves input order",
        (c, r, s) => {
            const out = compose(c, r, s);
            const searchOut = out.filter((x) => x.source === "search");
            // eslint-disable-next-line security/detect-object-injection -- numeric array index from Array.every callback, not an attacker-controlled key
            return searchOut.length === s.length && searchOut.every((x, i) => x === s[i]);
        }
    );
});
