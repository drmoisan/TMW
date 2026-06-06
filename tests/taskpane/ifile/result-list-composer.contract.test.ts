/**
 * Contract/type test for ResultListComposer.compose (AC-9). Asserts the compose signature
 * accepts three FolderResult[] sources in the documented order (classifier, recent, search) and
 * that adding a live source needs only a non-empty array — no signature change.
 */

import { describe, expect, it } from "vitest";
import { compose } from "../../../src/taskpane/ifile/result-list-composer";
import type { FolderResult } from "../../../src/taskpane/ifile/folder-result";

function result(source: FolderResult["source"], name: string): FolderResult {
    return { folderId: `id-${name}`, displayName: name, path: name, source };
}

describe("ResultListComposer contract", () => {
    it("accepts three FolderResult[] sources in the documented order at the type level", () => {
        // The signature is (classifier, recent, search). A type alias pins the arity/order so a
        // future signature change breaks this test at compile time.
        type ComposeSignature = (
            classifier: readonly FolderResult[],
            recent: readonly FolderResult[],
            search: readonly FolderResult[]
        ) => FolderResult[];
        const typed: ComposeSignature = compose;
        expect(typed([], [], [])).toEqual([]);
    });

    it("adds a live classifier source by supplying a non-empty array, no signature change", () => {
        // Today classifier/recent are empty; a future live source is just a non-empty array.
        const classifier = [result("classifier", "Suggested")];
        const search = [result("search", "Acme")];
        const out = compose(classifier, [], search);
        expect(out.map((r) => r.source)).toEqual(["classifier", "search"]);
    });

    it("preserves classifier-then-recent-then-search ordering at runtime", () => {
        const out = compose(
            [result("classifier", "C")],
            [result("recent", "R")],
            [result("search", "S")]
        );
        expect(out.map((r) => r.source)).toEqual(["classifier", "recent", "search"]);
    });
});
