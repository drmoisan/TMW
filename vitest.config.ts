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
      include: ["src/**/*.ts"],
      exclude: [
        "node_modules/**",
        "dist/**",
        "lib/**",
        "lib-amd/**",
        "**/*.test.ts",
        "src/test-support/**",
        "vitest.config.ts",
        "eslint.config.mjs",
        ".dependency-cruiser.cjs",
        "webpack.config.js",
        // Auto-generated, type-only API client (openapi-typescript output). It
        // contains no executable runtime code, so coverage metrics do not apply.
        "src/api-client/v1.ts",
        // iFile host-bootstrap entry: Office.onReady wiring + Office.auth/diagnostics glue that
        // runs only inside the Outlook host. Its testable behavior lives in the shared
        // host-neutral modules (ifile-controller, host-presentation, message-id-resolver) and the
        // host-wiring modules (dialog-host, inline-host), which are unit/contract tested.
        "src/taskpane/ifile/ifile.ts",
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
