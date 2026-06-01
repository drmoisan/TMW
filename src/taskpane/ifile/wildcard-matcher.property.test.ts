/**
 * Property-based tests for the wildcard matcher (AC-7, T2 property-density gate).
 *
 * Uses @fast-check/vitest. On failure, fast-check prints the failing seed so the
 * counterexample is reproducible.
 */

import { describe } from "vitest";
import { test } from "@fast-check/vitest";
import * as fc from "fast-check";
import { match } from "./wildcard-matcher";

/**
 * Generates strings that contain no glob metacharacters or backslashes, so the
 * string is a literal pattern that should match itself.
 */
const literalString = fc.string().filter((s) => !/[*?\\]/.test(s) && s.length > 0);

describe("wildcard match property invariants", () => {
    /**
     * Property: a literal pattern (no wildcards/escapes) always matches its own
     * NFC-normalized target.
     */
    test.prop([literalString])("a literal pattern matches its own target", (s) => {
        return match(s, s);
    });

    /**
     * Property: a lone `*` matches any string.
     */
    test.prop([fc.string()])("lone star matches any string", (s) => {
        return match("*", s);
    });

    /**
     * Property: an empty pattern never matches.
     */
    test.prop([fc.string()])("empty pattern never matches", (s) => {
        return match("", s) === false;
    });
});
