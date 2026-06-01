/**
 * Host-neutral glob wildcard matcher (pure, no I/O). Satisfies AC-7.
 *
 * Rules:
 * - `*` matches zero or more characters.
 * - `?` matches exactly one character.
 * - Matching is case-insensitive.
 * - Unicode NFC normalization is applied to both pattern and target before matching.
 * - `\*` and `\?` match the literal `*` / `?` characters; `\\` matches a literal backslash.
 * - A pattern of only `*` matches all targets.
 * - An empty pattern matches nothing (returns false).
 */

/**
 * Returns true when `target` matches the glob `pattern` under the rules above.
 *
 * The implementation compiles the pattern into a token stream (literal char,
 * single-wildcard, or multi-wildcard) and runs a linear backtracking match,
 * which is sufficient for folder name/path patterns.
 */
export function match(pattern: string, target: string): boolean {
    if (pattern.length === 0) {
        return false;
    }

    const tokens = tokenize(pattern.normalize("NFC").toLowerCase());
    const text = Array.from(target.normalize("NFC").toLowerCase());

    return matchTokens(tokens, 0, text, 0);
}

type Token =
    | { readonly kind: "literal"; readonly char: string }
    | { readonly kind: "single" }
    | { readonly kind: "star" };

/**
 * Converts a normalized lowercase pattern into a token stream, honoring `\`
 * escapes for `*`, `?`, and `\` itself. A trailing lone `\` is treated as a
 * literal backslash.
 */
function tokenize(pattern: string): Token[] {
    const chars = Array.from(pattern);
    const tokens: Token[] = [];
    let index = 0;

    while (index < chars.length) {
        // eslint-disable-next-line security/detect-object-injection -- numeric loop index into a local array of code points, not an attacker-controlled object key
        const char = chars[index] ?? "";
        const next = chars[index + 1];
        if (char === "\\" && (next === "*" || next === "?" || next === "\\")) {
            tokens.push({ kind: "literal", char: next });
            index += 2;
            continue;
        }
        if (char === "*") {
            tokens.push({ kind: "star" });
        } else if (char === "?") {
            tokens.push({ kind: "single" });
        } else {
            tokens.push({ kind: "literal", char });
        }
        index += 1;
    }

    return tokens;
}

/**
 * Recursive backtracking matcher over the token stream and the target's code
 * points. `star` collapses greedily with backtracking; `single` consumes one
 * code point; `literal` requires an exact (already lowercased) code-point match.
 */
function matchTokens(tokens: Token[], ti: number, text: string[], xi: number): boolean {
    // eslint-disable-next-line security/detect-object-injection -- numeric recursion index into a local token array, not an attacker-controlled object key
    const token = tokens[ti];
    // eslint-disable-next-line security/detect-possible-timing-attacks -- folder-name matching, not a secret comparison; the heuristic misfires on the undefined narrowing guard
    if (token === undefined) {
        return xi === text.length;
    }

    if (token.kind === "star") {
        for (let advance = xi; advance <= text.length; advance += 1) {
            if (matchTokens(tokens, ti + 1, text, advance)) {
                return true;
            }
        }
        return false;
    }

    // eslint-disable-next-line security/detect-object-injection -- numeric recursion index into a local code-point array, not an attacker-controlled object key
    const current = text[xi];
    if (current === undefined) {
        return false;
    }

    if (token.kind === "single") {
        return matchTokens(tokens, ti + 1, text, xi + 1);
    }

    if (token.char === current) {
        return matchTokens(tokens, ti + 1, text, xi + 1);
    }

    return false;
}
