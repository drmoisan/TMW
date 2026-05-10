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
