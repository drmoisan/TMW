// eslint.config.mjs
// Project-level ESLint v9 flat config for the TaskMaster Outlook add-in.
// Spreads office-addins recommended config, then layers typescript-eslint
// strict-type-checked + stylistic-type-checked rules over src/**/*.ts with
// type-aware parsing. Test files relax the unsafe-* rule family with
// documented justification comments.

import tseslint from "typescript-eslint";
import officeAddins from "eslint-plugin-office-addins";
import pluginPromise from "eslint-plugin-promise";
import pluginImport from "eslint-plugin-import";
import pluginSecurity from "eslint-plugin-security";

// Infrastructure allowlist: files in these globs may use Date/setTimeout/setInterval/Math.random
const INFRA_ALLOWLIST = ["src/infra/clock/**", "src/infra/random/**"];

// Banned call expressions for non-infrastructure source files
const BANNED_NON_DETERMINISTIC = [
  {
    selector: "CallExpression[callee.object.name='Date'][callee.property.name='now']",
    message: "Use injected Clock interface instead of Date.now(). See src/infra/clock/.",
  },
  {
    selector: "CallExpression[callee.name='setTimeout']",
    message: "Use injected Clock interface instead of setTimeout(). See src/infra/clock/.",
  },
  {
    selector: "CallExpression[callee.name='setInterval']",
    message: "Use injected Clock interface instead of setInterval(). See src/infra/clock/.",
  },
  {
    selector: "MemberExpression[object.name='Math'][property.name='random']",
    message: "Use injected Random interface instead of Math.random(). See src/infra/random/.",
  },
];

// Strip the @typescript-eslint plugin registration from office-addins config to avoid
// conflict with tseslint.configs.strictTypeChecked which also registers it. The rules
// from office-addins that depend on the plugin still resolve because typescript-eslint
// re-registers it in the next block.
const officeAddinsConfigs = officeAddins.configs.recommended.map((entry) => {
  if (!entry.plugins) return entry;
  const { "@typescript-eslint": _drop, ...rest } = entry.plugins;
  return { ...entry, plugins: rest };
});

export default tseslint.config(
  // 1. Office add-ins base (with @typescript-eslint plugin registration stripped)
  ...officeAddinsConfigs,

  // 2. typescript-eslint strict-type-checked + stylistic-type-checked for src
  {
    files: ["src/**/*.ts"],
    extends: [tseslint.configs.strictTypeChecked, tseslint.configs.stylisticTypeChecked],
    plugins: {
      promise: pluginPromise,
      import: pluginImport,
      security: pluginSecurity,
    },
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    settings: {
      "import/resolver": {
        typescript: {
          project: "./tsconfig.json",
        },
      },
    },
    rules: {
      // --- Promise safety ---
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/no-misused-promises": "error",

      // --- Unsafe escape hatches ---
      "@typescript-eslint/no-unsafe-argument": "error",
      "@typescript-eslint/no-unsafe-assignment": "error",
      "@typescript-eslint/no-unsafe-call": "error",
      "@typescript-eslint/no-unsafe-member-access": "error",
      "@typescript-eslint/no-unsafe-return": "error",

      // --- Plugin: promise ---
      "promise/always-return": "error",
      "promise/catch-or-return": "error",
      "promise/no-nesting": "warn",

      // --- Plugin: import ---
      "import/no-duplicates": "error",
      "import/no-cycle": "error",

      // --- Plugin: security ---
      ...pluginSecurity.configs.recommended.rules,

      // --- Non-determinism ban for src (not infra allowlist) ---
      "no-restricted-syntax": ["error", ...BANNED_NON_DETERMINISTIC],
    },
  },

  // 3. Infrastructure allowlist: lift the no-restricted-syntax ban
  {
    files: INFRA_ALLOWLIST,
    rules: {
      "no-restricted-syntax": "off",
    },
  },

  // 4. Generated API client — relax stylistic rules that conflict with the
  // openapi-typescript generator output. This file is auto-generated from
  // artifacts/openapi/current.json by `npm run generate:api` and must not be
  // hand-edited; the folder guard in block 6 enforces that for sibling files.
  {
    files: ["src/api-client/v1.ts"],
    rules: {
      // justification: openapi-typescript emits index signatures for the
      // `paths`/`components`/`operations` maps; converting them to Record types
      // would require hand-editing generated output.
      "@typescript-eslint/consistent-indexed-object-style": "off",
    },
  },

  // 5. Test file overrides — relax type-unsafe rules where mocks require it
  {
    files: ["**/*.test.ts", "src/test-support/**/*.ts"],
    extends: [tseslint.configs.disableTypeChecked],
    rules: {
      // justification: test doubles and vi.mock() factories often produce `any`-typed
      // stubs; banning them here would require extensive redundant casting.
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-member-access": "off",
      "@typescript-eslint/no-unsafe-argument": "off",
      "@typescript-eslint/no-unsafe-return": "off",
      // justification: floating promises are intentional in afterEach/beforeEach
      // lifecycle hooks; Vitest handles the returned promise.
      "@typescript-eslint/no-floating-promises": "off",
    },
  },

  // 6. API client folder guard — hand-editable files under src/api-client/ must
  // not declare wire types. The generated client (v1.ts) is the single source of
  // type truth; the `!(v1).ts` glob excludes it. Test files inside the folder are
  // also excluded so the guard test itself can reference type fixtures as strings.
  {
    files: ["src/api-client/!(v1).ts"],
    ignores: ["src/api-client/**/*.test.ts"],
    rules: {
      "no-restricted-syntax": [
        "error",
        {
          selector: "TSInterfaceDeclaration",
          message:
            "Do not hand-write wire types in src/api-client/. Regenerate the client from artifacts/openapi/current.json with `npm run generate:api`.",
        },
        {
          selector: "TSTypeAliasDeclaration",
          message:
            "Do not hand-write wire types in src/api-client/. Regenerate the client from artifacts/openapi/current.json with `npm run generate:api`.",
        },
      ],
    },
  }
);
