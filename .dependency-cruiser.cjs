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
