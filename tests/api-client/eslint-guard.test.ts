/**
 * Tests for the src/api-client/ ESLint folder guard.
 *
 * The guard (eslint.config.mjs block 6) bans hand-written wire type
 * declarations (`interface` / `type` alias) in hand-editable files under
 * src/api-client/, while excluding the generated client (v1.ts).
 *
 * Hand-written cases are linted from in-memory strings via `lintText` with a
 * synthetic non-generated filePath — no temporary files are created. The
 * generated-file case lints the real on-disk `v1.ts` via `lintFiles` because
 * its content must match disk for the type-aware project service.
 */

import { describe, it, expect } from "vitest";
import { ESLint } from "eslint";

const HAND_WRITTEN_INTERFACE = `export interface ClassifyRequest {
    messageId: string;
}
`;

const HAND_WRITTEN_TYPE_ALIAS = `export type ClassifyResponse = {
    label: string;
};
`;

/**
 * Builds an ESLint instance whose project service tolerates synthetic files
 * under src/api-client/ that are not listed in tsconfig.json.
 */
function makeEslint(): ESLint {
    return new ESLint({
        overrideConfig: {
            languageOptions: {
                parserOptions: {
                    projectService: {
                        allowDefaultProject: ["src/api-client/*.ts"],
                    },
                },
            },
        },
    });
}

/** Collects the rule IDs of all reported messages across lint results. */
function ruleIds(results: ESLint.LintResult[]): (string | null)[] {
    return results.flatMap((result) => result.messages.map((message) => message.ruleId));
}

describe("src/api-client/ ESLint folder guard", () => {
    it("reports no-restricted-syntax for a hand-written interface in a non-generated file", async () => {
        // Arrange
        const eslint = makeEslint();

        // Act
        const results = await eslint.lintText(HAND_WRITTEN_INTERFACE, {
            filePath: "src/api-client/hand-written.ts",
        });

        // Assert
        expect(ruleIds(results)).toContain("no-restricted-syntax");
    });

    it("reports no-restricted-syntax for a hand-written type alias in a non-generated file", async () => {
        // Arrange
        const eslint = makeEslint();

        // Act
        const results = await eslint.lintText(HAND_WRITTEN_TYPE_ALIAS, {
            filePath: "src/api-client/hand-written.ts",
        });

        // Assert
        expect(ruleIds(results)).toContain("no-restricted-syntax");
    });

    it("does not report no-restricted-syntax for the generated v1.ts client", async () => {
        // Arrange — v1.ts is excluded from the guard glob; lint the real file.
        const eslint = makeEslint();

        // Act
        const results = await eslint.lintFiles(["src/api-client/v1.ts"]);

        // Assert
        expect(ruleIds(results)).not.toContain("no-restricted-syntax");
    });
});
