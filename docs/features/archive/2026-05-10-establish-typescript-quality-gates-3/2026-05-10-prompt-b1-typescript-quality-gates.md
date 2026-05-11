# Research: Prompt B1 — Establish TypeScript Quality Gates (Issue #3)

**Date:** 2026-05-10  
**Branch:** feature/establish-typescript-quality-gates-3  
**Canonical issue:** #3  
**Feature folder:** `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/`

---

## Verified Repo State

All findings below are derived from direct file inspection. Nothing is assumed.

| File | Key facts |
|---|---|
| `package.json` | typescript ^5.4.2, office-addin-lint ^3.0.3, eslint-plugin-office-addins ^4.0.3, office-addin-prettier-config ^2.0.1, babel-loader (no tsc emit), NO vitest/msw/dep-cruiser |
| `tsconfig.json` | target es5, lib es2015+dom, allowJs, esModuleInterop, experimentalDecorators, jsx react, noEmitOnError; no strict flags at all |
| `src/taskpane/taskpane.ts` | Uses `document.getElementById(...)` without null guard on 3 calls; `item.subject` accessed without null check; all problematic under strict |
| `src/commands/commands.ts` | Clean except `Office.context.mailbox.item` (possibly null) and no `notificationMessages.replaceAsync` return awaited |
| Installed: `eslint` | v9.39.4 (transitive via office-addin-lint) — flat config only |
| Installed: `typescript-eslint` | v8.8.1 (transitive via office-addin-lint) — provides `strictTypeChecked`, `stylisticTypeChecked`, `config()` helper |
| Installed: `@typescript-eslint/parser` | v8.8.1 |
| NOT installed | vitest, @vitest/coverage-v8, msw, eslint-plugin-promise, eslint-plugin-import, eslint-plugin-security, dependency-cruiser |
| `office-addin-lint` v3.0.7 | Ships `config/eslint.config.mjs` that already uses flat-config `officeAddins.configs.recommended` spread; `lint.js` auto-discovers `eslint.config.mjs` in project root |
| `eslint-plugin-office-addins` installed | v4.0.7 (transitive; package.json lists ^4.0.3). Its `lib/main.js` exports a native flat-config object with `.configs.recommended` array — no `@eslint/eslintrc` FlatCompat needed |
| `prettier` | v3.8.3 (transitive via office-addin-lint) |
| `.github/workflows/pr-pipeline.yml` | 7 numbered stages + tier-classification + secret-scan; stages 1–7 each delegate to composite actions under `.github/actions/` |
| Stage 1 (format) action | No-op stub with explicit comment "will be activated in a later prompt" |
| Stage 2 (lint) action | Runs `npm run lint` if the script exists |
| Stage 3 (typecheck) action | Runs `npm run typecheck` if script exists, else `npx tsc --noEmit` |
| Stage 4 (architecture) action | Runs `npx depcruise --config .dependency-cruiser.cjs src` if `.dependency-cruiser.cjs` exists |
| Stage 5 (test) action | Runs `npm test` if script exists |

---

## 1. ESLint v9 Flat-Config Setup

### Package list (new installs required)

| Package | Version range | Reason |
|---|---|---|
| `eslint-plugin-promise` | `^7.2.1` | Required by policy; flat-config compatible |
| `eslint-plugin-import` | `^2.31.0` | Required by policy; use `eslint-import-resolver-typescript` for TS paths |
| `eslint-import-resolver-typescript` | `^3.7.0` | Enables `eslint-plugin-import` to resolve TS paths/aliases |
| `eslint-plugin-security` | `^3.0.1` | Required by policy; exports a flat-config `recommended` config |

**Already available (transitive — do not re-declare unless pinning explicitly):**
- `eslint` ^9 (via office-addin-lint — install as direct devDep to pin range)
- `typescript-eslint` ^8 (via office-addin-lint — install as direct devDep)

Recommended: add `eslint` and `typescript-eslint` as explicit devDependencies so the project does not depend solely on transitive resolution.

### Flat-config interop for eslint-plugin-office-addins

**Key finding:** `eslint-plugin-office-addins` v4.0.7 (the installed transitive version) already exports native ESLint v9 flat-config objects. `lib/main.js` constructs `plugin.configs.recommended` as an array of flat-config objects using `languageOptions`, `plugins`, and `rules` keys — no `.eslintrc`-style properties. `@eslint/eslintrc` FlatCompat is NOT needed. Spread `...officeAddins.configs.recommended` directly.

### Recommended `eslint.config.mjs` shape

```js
// eslint.config.mjs
import tseslint from "typescript-eslint";
import officeAddins from "eslint-plugin-office-addins";
import pluginPromise from "eslint-plugin-promise";
import pluginImport from "eslint-plugin-import";
import pluginSecurity from "eslint-plugin-security";

// Infrastructure allowlist: files in these globs may use Date/setTimeout/setInterval/Math.random
const INFRA_ALLOWLIST = [
  "src/infra/clock/**",
  "src/infra/random/**",
];

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

export default tseslint.config(
  // 1. Office add-ins base (includes @typescript-eslint/no-unused-vars, office-addins/* rules, prettier)
  ...officeAddins.configs.recommended,

  // 2. typescript-eslint strict-type-checked + stylistic-type-checked for src
  {
    files: ["src/**/*.ts"],
    extends: [
      tseslint.configs.strictTypeChecked,
      tseslint.configs.stylisticTypeChecked,
    ],
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

  // 4. Test file overrides — relax type-unsafe rules where mocks require it
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
);
```

**Critical notes on `office-addin-lint` script discovery:** `office-addin-lint`'s `lint.js` checks for `eslint.config.mjs` in `process.cwd()` and uses it if found, otherwise falls back to its own config. Name the project config file `eslint.config.mjs` (not `.js` or `.cjs`) to ensure automatic pickup. The existing `npm run lint` script (`office-addin-lint check`) will then use the project's flat config automatically.

**`projectService: true`** is the recommended approach for `typescript-eslint` v8 — it replaces `project: ["./tsconfig.json"]` and avoids issues with files not in the project. `import.meta.dirname` requires Node 20.11+ (available on `windows-latest` GitHub runner).

---

## 2. tsconfig.json Upgrade Path

### Flags to add

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true
  }
}
```

### Scaffold breakage analysis

**`src/taskpane/taskpane.ts` — verified failures under strict + noUncheckedIndexedAccess:**

| Line | Expression | Error |
|---|---|---|
| 10 | `document.getElementById("sideload-msg").style.display` | `getElementById` returns `HTMLElement \| null`; null not narrowed — Property `style` does not exist on `null` |
| 11 | `document.getElementById("app-body").style.display` | Same pattern |
| 12 | `document.getElementById("run").onclick` | Same pattern |
| 22 | `let insertAt = document.getElementById("item-subject")` used at lines 24–27 without null check | Same |
| 22 | `const item = Office.context.mailbox.item` — `item` can be `null` | `item.subject` on line 26 would be unsafe |
| 26 | `item.subject` | `Office.context.mailbox.item` typed as `Office.Item & Office.ItemCompose & Office.ItemRead & Office.Message & ...` or `null`; accessing `.subject` on a possible null |

**`src/commands/commands.ts` — verified failures:**

| Line | Expression | Error |
|---|---|---|
| 25 | `Office.context.mailbox.item.notificationMessages.replaceAsync(...)` | `item` can be null — null access |

**Minimal source edits required (scaffold only):**

For `taskpane.ts` — replace raw `getElementById` calls with guarded versions. Recommended pattern:

```typescript
function requireElement(id: string): HTMLElement {
  const el = document.getElementById(id);
  if (el === null) {
    throw new Error(`Required element #${id} not found in DOM`);
  }
  return el;
}

Office.onReady((info) => {
  if (info.host === Office.HostType.Outlook) {
    requireElement("sideload-msg").style.display = "none";
    requireElement("app-body").style.display = "flex";
    requireElement("run").onclick = run;
  }
});

export async function run() {
  const item = Office.context.mailbox.item;
  if (item === null) return;
  const insertAt = requireElement("item-subject");
  const label = document.createElement("b").appendChild(document.createTextNode("Subject: "));
  insertAt.appendChild(label);
  insertAt.appendChild(document.createElement("br"));
  insertAt.appendChild(document.createTextNode(item.subject));
  insertAt.appendChild(document.createElement("br"));
}
```

For `commands.ts` — guard the item access:

```typescript
function action(event: Office.AddinCommands.Event) {
  const item = Office.context.mailbox.item;
  if (item === null) {
    event.completed();
    return;
  }
  const message: Office.NotificationMessageDetails = { ... };
  item.notificationMessages.replaceAsync("ActionPerformanceNotification", message);
  event.completed();
}
```

**`exactOptionalPropertyTypes` interaction with Office.js typings:** `@types/office-js` v1.0.377 uses optional properties extensively. Under `exactOptionalPropertyTypes`, assigning `undefined` to an optional property is a type error unless the property explicitly includes `| undefined` in its type. The scaffold source does not directly assign to optional Office.js properties, so this should not produce new errors in the current minimal scaffold. This is a risk for future code; document it in the gotchas section.

**`noPropertyAccessFromIndexSignature`:** The scaffold does not use index signatures directly. No scaffold changes expected from this flag.

---

## 3. Vitest + MSW Configuration

### Package list (all new installs)

| Package | Version range | Role |
|---|---|---|
| `vitest` | `^2.1.8` | Test runner |
| `@vitest/coverage-v8` | `^2.1.8` | V8 coverage provider (matches vitest version) |
| `jsdom` | `^25.0.1` | DOM environment for Office.js tests |
| `msw` | `^2.6.4` | HTTP request mocking (node setup for unit tests) |

**jsdom vs happy-dom:** jsdom is recommended over happy-dom for this project. Office.js `@types/office-js` stubs assume a complete DOM environment. jsdom implements a wider DOM surface area and has more predictable behavior when the fake Office module accesses `document`, `window`, and `XMLHttpRequest`. happy-dom is faster but has documented gaps (e.g., MutationObserver edge cases). The scaffold's `taskpane.ts` calls `document.getElementById`, `document.createElement` — all of which are well-supported by jsdom.

**MSW v2 note:** MSW v2 uses `setupServer` from `msw/node` for Node/Vitest environments. The browser `setupWorker` pattern is not used in unit tests.

### Path aliases

The scaffold has no tsconfig `paths` currently. The Office.js fake module should be placed at `src/test-support/office-fake.ts`.

Add to `tsconfig.json` under `compilerOptions`:
```json
"paths": {
  "@office-fake": ["./src/test-support/office-fake.ts"]
}
```

### `vitest.config.ts` shape

```typescript
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test-support/vitest-setup.ts"],
    include: ["**/*.test.ts"],
    exclude: ["node_modules", "dist", "lib"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov", "json-summary"],
      exclude: [
        "node_modules/**",
        "dist/**",
        "lib/**",
        "**/*.test.ts",
        "src/test-support/**",
        "vitest.config.ts",
        "eslint.config.mjs",
        ".dependency-cruiser.cjs",
      ],
      thresholds: {
        lines: 85,
        branches: 75,
        functions: 85,
        statements: 85,
      },
    },
  },
  resolve: {
    alias: {
      // Redirect Office.js imports to the fake module in tests
      "@microsoft/office-js": path.resolve(__dirname, "src/test-support/office-fake.ts"),
    },
  },
});
```

**Note on Office global:** The scaffold uses `/* global Office */` comment syntax (not an import). In tests, `Office` must be available as a global. The `vitest-setup.ts` file should assign the fake to `globalThis.Office` before tests run. The `resolve.alias` above handles any test files that import Office.js directly (future code). For the current scaffold, the global injection is sufficient.

### Office.js fake module (`src/test-support/office-fake.ts`)

```typescript
// Minimal Office.js fake for unit tests.
// Exposes the same global shape that taskpane.ts and commands.ts expect.

const officeFake = {
  onReady: (callback: (info: { host: unknown }) => void) => {
    callback({ host: null });
  },
  HostType: {
    Outlook: "Outlook",
  },
  context: {
    mailbox: {
      item: null as null | Record<string, unknown>,
    },
  },
  MailboxEnums: {
    ItemNotificationMessageType: {
      InformationalMessage: "InformationalMessage",
    },
  },
  actions: {
    associate: (_name: string, _fn: unknown) => undefined,
  },
} as unknown as typeof Office;

export default officeFake;
```

### Vitest setup file (`src/test-support/vitest-setup.ts`)

```typescript
import { afterEach, beforeAll } from "vitest";
import { server } from "./msw-server";
import officeFake from "./office-fake";

// Inject Office global before any test runs
beforeAll(() => {
  (globalThis as Record<string, unknown>)["Office"] = officeFake;
});

// MSW server lifecycle
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### MSW node server (`src/test-support/msw-server.ts`)

```typescript
import { setupServer } from "msw/node";

// Register default handlers here; test files can add per-test handlers
export const server = setupServer();
```

### Sample test demonstrating Office.js fake and MSW

```typescript
// src/taskpane/taskpane.test.ts
import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { server } from "../test-support/msw-server";
import { http, HttpResponse } from "msw";

describe("run()", () => {
  beforeEach(() => {
    // Arrange: set up DOM elements the function expects
    document.body.innerHTML = `
      <div id="sideload-msg"></div>
      <div id="app-body"></div>
      <button id="run"></button>
      <div id="item-subject"></div>
    `;
    (globalThis as Record<string, unknown>)["Office"] = {
      ...(globalThis as Record<string, unknown>)["Office"],
      context: {
        mailbox: {
          item: { subject: "Test Subject" },
        },
      },
    };
  });

  afterEach(() => {
    vi.resetAllMocks();
  });

  it("appends subject text to #item-subject when item exists", async () => {
    // Arrange: MSW stub (not used by run() directly, but demonstrates wiring)
    server.use(
      http.get("/api/ping", () => HttpResponse.json({ ok: true }))
    );

    // Act
    const { run } = await import("./taskpane");
    await run();

    // Assert
    const el = document.getElementById("item-subject");
    expect(el?.textContent).toContain("Test Subject");
  });
});
```

---

## 4. dependency-cruiser Configuration

### Package list (new install)

| Package | Version range | Role |
|---|---|---|
| `dependency-cruiser` | `^16.8.0` | Architecture boundary enforcement |

**Invocation:** `npx depcruise --config .dependency-cruiser.cjs src` — this is correct per the existing architecture action (`npx depcruise --config .dependency-cruiser.cjs src`). The `.cjs` extension is required because the project root `package.json` does not declare `"type": "module"`; CommonJS is the default, and dependency-cruiser can parse `module.exports` in `.cjs` files regardless.

### `.dependency-cruiser.cjs` shape

```js
// .dependency-cruiser.cjs
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      comment: "Circular dependencies are forbidden across all modules.",
      from: {},
      to: {
        circular: true,
      },
    },
    {
      name: "no-orphans",
      severity: "warn",
      comment:
        "Orphaned modules (no incoming or outgoing deps) are usually dead code. " +
        "Warn rather than error to allow new files during active development.",
      from: {
        orphan: true,
        pathNot: [
          "\\.test\\.ts$",
          "src/test-support/",
          "\\.d\\.ts$",
          "vitest\\.config\\.ts$",
          "eslint\\.config\\.mjs$",
        ],
      },
      to: {},
    },
    {
      name: "taskpane-not-from-commands",
      severity: "error",
      comment:
        "src/commands/ must not import from src/taskpane/. " +
        "These are separate Office.js entry points with distinct lifecycles.",
      from: {
        path: "^src/commands/",
      },
      to: {
        path: "^src/taskpane/",
      },
    },
    {
      name: "commands-not-from-taskpane",
      severity: "error",
      comment:
        "src/taskpane/ must not import from src/commands/. " +
        "These are separate Office.js entry points with distinct lifecycles.",
      from: {
        path: "^src/taskpane/",
      },
      to: {
        path: "^src/commands/",
      },
    },
  ],
  options: {
    doNotFollow: {
      path: "node_modules",
    },
    tsConfig: {
      fileName: "tsconfig.json",
    },
    enhancedResolveOptions: {
      exportsFields: ["exports"],
      conditionNames: ["import", "require", "node", "default"],
    },
    reporterOptions: {
      text: {
        highlightFocused: true,
      },
    },
  },
};
```

**`no-orphans` is `warn` not `error`:** The existing scaffold has only two source files, and dependency-cruiser considers entry points (imported by webpack but not by other TS files) as orphans. Setting `no-orphans` to `warn` avoids a false-positive error on `taskpane.ts` and `commands.ts` themselves. The executor can promote to `error` once the module graph has internal imports.

---

## 5. CI Pipeline Extensions

### Existing CI workflow shape (verified)

The PR pipeline at `.github/workflows/pr-pipeline.yml` already has:
- `tier-classification` (prerequisite for all)
- `stage-1-format` → `stage-2-lint` → `stage-3-typecheck` → `stage-4-architecture` → `stage-5-test` → `stage-6-contract` → `stage-7-integration`
- `secret-scan` (independent)

Each stage delegates to a composite action under `.github/actions/<name>/action.yml`.

### Stage 1 (format) — replace no-op

Current: explicit no-op stub. Prompt B1 must replace the stub body in `.github/actions/format/action.yml`.

**Required replacement:**
```yaml
name: Format
description: Prettier format check using office-addin-prettier-config.
runs:
  using: composite
  steps:
    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: "20"
        cache: "npm"
    - name: Install dependencies
      shell: pwsh
      run: npm ci --no-audit --no-fund
    - name: Prettier format check
      shell: pwsh
      run: npm run format:check
```

### Stage 2 (lint) — activate the script

Current: conditional check for `"lint"` script existence. The `npm run lint` script already exists (`office-addin-lint check`). Prompt B1 must ensure the script invokes the new `eslint.config.mjs` (it will — `office-addin-lint` auto-discovers `eslint.config.mjs`). No change needed to `action.yml` for stage 2 — it already runs `npm run lint`. The action needs a Node setup step:

```yaml
name: Lint
description: ESLint v9 flat-config with typescript-eslint strict-type-checked.
runs:
  using: composite
  steps:
    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: "20"
        cache: "npm"
    - name: Install dependencies
      shell: pwsh
      run: npm ci --no-audit --no-fund
    - name: ESLint
      shell: pwsh
      run: npm run lint
```

### Stage 3 (typecheck) — activate the script

Current: runs `npm run typecheck` if script exists, else `npx tsc --noEmit`. Prompt B1 adds the `typecheck` npm script; the action will pick it up automatically. Same Node setup step needed.

### Stage 4 (architecture) — activate via config file presence

Current: runs `npx depcruise --config .dependency-cruiser.cjs src` if the config exists. Adding `.dependency-cruiser.cjs` activates this automatically. Same Node setup step needed.

### Stage 5 (test) — replace stub body

Current: runs `npm test` if script exists. Prompt B1 adds `npm test`. The action must also enforce coverage thresholds. The coverage threshold enforcement is handled by vitest's `thresholds` config (exit code non-zero when thresholds not met), so `npm run test:coverage` in CI achieves both. Recommend using `npm run test:coverage` in the CI action rather than `npm test`:

```yaml
name: Test
description: Vitest unit tests with V8 coverage enforcement (line >= 85%, branch >= 75%).
runs:
  using: composite
  steps:
    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: "20"
        cache: "npm"
    - name: Install dependencies
      shell: pwsh
      run: npm ci --no-audit --no-fund
    - name: Vitest with coverage
      shell: pwsh
      run: npm run test:coverage
```

**Coverage threshold enforcement:** Vitest exits with non-zero when `thresholds` are not met (when using `--coverage`). This makes the CI step fail automatically without additional scripts.

---

## 6. npm Scripts

### Existing scripts (from package.json)

| Script | Current value |
|---|---|
| `lint` | `office-addin-lint check` |
| `lint:fix` | `office-addin-lint fix` |
| `prettier` | `office-addin-lint prettier` |

### Collisions and recommendations

- **`lint`**: Already exists. Its behavior will change when `eslint.config.mjs` is added (office-addin-lint auto-discovers it). No rename needed; the script name matches the policy requirement.
- **`prettier`**: Already exists, but naming conflicts with the policy-required `format` and `format:check` scripts. Do NOT rename the existing `prettier` script — it is likely used by tooling. Add the new `format` and `format:check` scripts as separate entries.
- **`format`**: New. Runs prettier in write mode.
- **`format:check`**: New. Runs prettier in check mode (used by CI).

### Scripts to add to `package.json`

```json
{
  "scripts": {
    "format": "prettier --write \"src/**/*.ts\"",
    "format:check": "prettier --check \"src/**/*.ts\"",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "test:coverage": "vitest run --coverage",
    "depcruise": "depcruise --config .dependency-cruiser.cjs src"
  }
}
```

**Note on `format` vs `prettier` scripts:** The policy requires `npm run format`. The existing `prettier` script calls `office-addin-lint prettier` which runs prettier's write mode over `src/**/*.{ts,tsx,js,jsx}`. The new `format` and `format:check` scripts call `prettier` directly (it's available in PATH via `node_modules/.bin/prettier`). This is consistent with how `office-addin-lint`'s own `lint.js` resolves prettier.

**Note on `test` script:** `vitest run` exits after a single pass (non-watch mode), which is appropriate for CI. For local development, `vitest` without `run` enters watch mode.

---

## 7. Representative Violation Demonstration

### Approach

Create a directory `tests/violations/` containing one deliberately-broken file per gate category. These files are excluded from the normal test and lint run by default via gitignore or explicit config exclusions. A documented invocation temporarily includes them to prove each gate catches its category.

**Evidence destination:** `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/qa-gates/`

### File structure

```
tests/violations/
  format-violation.ts.disabled    # Malformatted (wrong indent, missing semicolons)
  lint-violation.ts.disabled      # Floating promise: async function call without await
  typecheck-violation.ts.disabled # Type mismatch: string assigned to number variable
  arch-violation.ts.disabled      # Import from src/taskpane/ inside src/commands/
  test-violation.test.ts.disabled # Always-failing assertion: expect(1).toBe(2)
```

The `.disabled` extension prevents normal tooling from picking up these files. To demonstrate detection, rename one file at a time, run the gate, record the output, then rename back.

### Invocation protocol (PowerShell)

```powershell
# Demonstrate format gate violation
Copy-Item tests/violations/format-violation.ts.disabled src/format-violation.ts
npm run format:check   # exits non-zero
Remove-Item src/format-violation.ts

# Demonstrate lint gate violation
Copy-Item tests/violations/lint-violation.ts.disabled src/lint-violation.ts
npm run lint           # exits non-zero
Remove-Item src/lint-violation.ts

# Demonstrate typecheck gate violation
Copy-Item tests/violations/typecheck-violation.ts.disabled src/typecheck-violation.ts
npm run typecheck      # exits non-zero
Remove-Item src/typecheck-violation.ts

# Demonstrate architecture gate violation
Copy-Item tests/violations/arch-violation.ts.disabled src/commands/arch-violation.ts
npm run depcruise      # exits non-zero
Remove-Item src/commands/arch-violation.ts

# Demonstrate test gate violation
Copy-Item tests/violations/test-violation.test.ts.disabled src/test-violation.test.ts
npm test               # exits non-zero
Remove-Item src/test-violation.test.ts
```

Each invocation's stdout/stderr is captured and saved as an evidence artifact under `evidence/qa-gates/violation-<category>-<timestamp>.md`.

**Violation file content examples:**

`format-violation.ts.disabled`:
```typescript
export const x = 1   // missing semicolon triggers prettier format violation
const y=2+x; // no spaces around operator
```

`lint-violation.ts.disabled`:
```typescript
// eslint-disable line intentionally absent — this file is a violation demo
async function fetchData() { return Promise.resolve(1); }
fetchData(); // no-floating-promises violation
export {};
```

`typecheck-violation.ts.disabled`:
```typescript
const x: number = "this is a string"; // TS2322
export {};
```

`arch-violation.ts.disabled` (placed in `src/commands/` during demo):
```typescript
import { run } from "../taskpane/taskpane"; // commands-not-from-taskpane violation
export { run };
```

`test-violation.test.ts.disabled`:
```typescript
import { it, expect } from "vitest";
it("always fails", () => { expect(1).toBe(2); });
```

---

## 8. Risks and Known Gotchas

### ESLint v9 + office-addin-lint interop

**Risk (mitigated):** `office-addin-lint` v3.0.7 checks for `eslint.config.mjs` in `process.cwd()` and uses it if found. This means `npm run lint` will use the project's `eslint.config.mjs` not the package's bundled config. The project config must spread `officeAddins.configs.recommended` to retain the office-specific rules — omitting this would silently drop Office Add-in rules.

**Risk (mitigated):** The `office-addin-lint` `prettier` script uses `prettier --parser typescript --write`, not `--check`. Do not use `npm run prettier` as the CI format-check; use `npm run format:check` which calls `prettier --check`.

**Risk (active):** `eslint-plugin-office-addins` v4.0.7 is the installed transitive version but the direct devDependency in the repo's `package.json` pins `^4.0.3`. Npm may resolve to v4.0.7 but future `npm install` could pull different minor versions. The executor should add `eslint-plugin-office-addins` as a direct devDependency at `^4.0.7` to stabilize.

### exactOptionalPropertyTypes interplay with Office.js typings

**Risk (active):** `@types/office-js` v1.0.377 defines many optional properties without explicit `| undefined`. Under `exactOptionalPropertyTypes: true`, code that destructures optional Office.js properties or assigns `undefined` to them will fail. The current minimal scaffold does not hit this path, but any future code that does `const opts: SomeOfficeOptions = { optionalProp: undefined }` will fail. The mitigation is to use `Partial<T>` or `{ optionalProp?: string | undefined }` patterns explicitly.

**Risk (lower):** `noUncheckedIndexedAccess` affects array indexing (`arr[0]` returns `T | undefined`). The scaffold does not index arrays, so no immediate impact. Future code iterating Office.js collections must guard index access.

### Vitest jsdom Office global pollution

**Risk (active):** The `vitest-setup.ts` assigns `Office` to `globalThis`. If tests run in parallel (the default), a test that modifies `globalThis.Office.context.mailbox.item` will affect concurrent tests. Mitigation: each test that needs a specific item state should set it in `beforeEach` and restore in `afterEach`. Document this in the test support module.

**Risk:** jsdom does not implement all Web APIs used by Office.js; specifically, `XMLHttpRequest` is partially implemented and `fetch` is not present in older jsdom versions. Vitest with `environment: "jsdom"` will polyfill `fetch` via `undici`. If Office.js (real, not fake) were loaded in tests, it would fail. Since we use a fake module, this is not a current risk — but the fake must remain minimal and not import from `@types/office-js`.

### dependency-cruiser and webpack entry points

**Risk (active):** Webpack entry points (`taskpane.ts`, `commands.ts`) are not imported by any other module in the project. dependency-cruiser will flag them as orphans. The `.dependency-cruiser.cjs` above sets `no-orphans` to `warn` and excludes test files to prevent false-positive errors. If the orphan rule is later promoted to `error`, the entry points must be explicitly excluded by path.

### `projectService: true` in ESLint parserOptions

**Risk (lower):** `projectService: true` (typescript-eslint v8 default) starts a TypeScript language service. On `windows-latest` runners, this adds ~2–5 seconds to lint time. For a small scaffold this is negligible, but document that lint will be slower than non-type-checked configurations.

### `eslint-plugin-import` flat-config status

**Risk (active):** `eslint-plugin-import` v2.x predates ESLint v9's flat config. The flat-config API in v2.x is not fully stable; some rules rely on resolver APIs that changed. Use `eslint-import-resolver-typescript` v3+ which has flat-config support. If import rules cause spurious errors, the executor should verify with `import/no-cycle` first (the most commonly broken rule) and disable problematic rules individually with documented justification.

---

## Requirements Mapping to Acceptance Criteria

| AC # | Criterion | Implementation target |
|---|---|---|
| 1 | `npm run format:check` exits 0 | Add `format:check` script; Prettier already wired via `office-addin-prettier-config` |
| 2 | `eslint.config.mjs` exists and loaded by ESLint v9+ | Create `eslint.config.mjs` |
| 3 | Extends `strictTypeChecked` | `tseslint.configs.strictTypeChecked` in config |
| 4 | Extends `stylisticTypeChecked` | `tseslint.configs.stylisticTypeChecked` in config |
| 5 | Type-aware parsing enabled | `projectService: true` in `languageOptions.parserOptions` |
| 6 | `eslint-plugin-office-addins` configured | Spread `officeAddins.configs.recommended` |
| 7 | `eslint-plugin-promise` configured | `plugins: { promise: pluginPromise }` + rules |
| 8 | `eslint-plugin-import` configured | `plugins: { import: pluginImport }` + rules |
| 9 | `eslint-plugin-security` configured | `plugins: { security: pluginSecurity }` + rules |
| 10 | `no-floating-promises` error for src | `"@typescript-eslint/no-floating-promises": "error"` in src block |
| 11 | `no-misused-promises` error for src | `"@typescript-eslint/no-misused-promises": "error"` in src block |
| 12 | All `no-unsafe-*` error for src | Explicit rules in src block |
| 13 | Test files relax with documented justification | `// justification:` comments in test override block |
| 14–18 | tsconfig strict flags | Edit `tsconfig.json` |
| 19 | `npm test` exits 0 | Add `test` script; fix scaffold to pass type check |
| 20 | MSW wired | `src/test-support/msw-server.ts` + setup file |
| 21 | Office.js fake as path alias | `resolve.alias` in `vitest.config.ts` + fake module |
| 22 | `.dependency-cruiser.cjs` with 4 rules | Create config file |
| 23 | `no-restricted-syntax` ban | `BANNED_NON_DETERMINISTIC` array in eslint config |
| 24–28 | CI stages 1–5 execute on every PR | Update composite action stubs |
| 29 | All 5 stages pass on unmodified scaffold | Scaffold source edits in tsconfig + taskpane.ts + commands.ts |
| 30 | Violations detected | `tests/violations/` directory + invocation protocol |

---

## File Change Inventory for Executor

| File | Action | Notes |
|---|---|---|
| `package.json` | Edit — add scripts and devDependencies | Add format, format:check, typecheck, test, test:coverage, depcruise scripts; add eslint-plugin-promise, eslint-plugin-import, eslint-import-resolver-typescript, eslint-plugin-security, vitest, @vitest/coverage-v8, jsdom, msw, dependency-cruiser as devDependencies; add eslint and typescript-eslint as explicit devDependencies |
| `tsconfig.json` | Edit — add strict compiler flags | Add strict, noUncheckedIndexedAccess, exactOptionalPropertyTypes, noImplicitOverride, noPropertyAccessFromIndexSignature; add paths for test alias |
| `eslint.config.mjs` | Create | Per Section 1 shape above |
| `vitest.config.ts` | Create | Per Section 3 shape above |
| `src/taskpane/taskpane.ts` | Edit — minimal scaffold fix | Add `requireElement` helper; guard item null check |
| `src/commands/commands.ts` | Edit — minimal scaffold fix | Guard `item` null check before `notificationMessages.replaceAsync` |
| `src/test-support/office-fake.ts` | Create | Minimal Office global fake |
| `src/test-support/vitest-setup.ts` | Create | Global injection + MSW lifecycle |
| `src/test-support/msw-server.ts` | Create | `setupServer()` export |
| `src/taskpane/taskpane.test.ts` | Create | Sample test exercising run() |
| `.dependency-cruiser.cjs` | Create | Per Section 4 shape above |
| `.github/actions/format/action.yml` | Edit — replace no-op | Prettier check with Node setup |
| `.github/actions/lint/action.yml` | Edit — add Node setup | Node 20 + npm ci + npm run lint |
| `.github/actions/typecheck/action.yml` | Edit — add Node setup | Node 20 + npm ci + npm run typecheck |
| `.github/actions/architecture/action.yml` | Edit — add Node setup | Node 20 + npm ci + npx depcruise |
| `.github/actions/test/action.yml` | Edit — replace stub | Node 20 + npm ci + npm run test:coverage |
| `tests/violations/` | Create directory + 5 `.disabled` files | Violation demonstration artifacts |
| `docs/features/active/2026-05-10-establish-typescript-quality-gates-3/evidence/qa-gates/` | Create (during QA phase) | Violation demonstration evidence |
