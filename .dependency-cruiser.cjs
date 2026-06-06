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
    {
      name: "ifile-pure-modules-no-host-deps",
      severity: "error",
      comment:
        "The iFile pure host-neutral modules (wildcard-matcher, result-list-composer, " +
        "search-result-ordering, folder-path-builder, folder-search, folder-result) must " +
        "remain free of Office.js, the Microsoft Graph SDK, the generated API client, and " +
        "MSAL (@azure/msal-browser). Office.js / API-client / MSAL imports belong only in the " +
        "iFile host-wiring modules (dialog-host, inline-host, ifile-api-client) and the " +
        "host-bound NAA auth adapter (naa-token-acquirer), which is the ONLY module permitted " +
        "to import @azure/msal-browser.",
      from: {
        path: "^src/taskpane/ifile/(wildcard-matcher|result-list-composer|search-result-ordering|folder-path-builder|folder-search|folder-result|message-id-resolver|host-presentation|archive-root-picker|ifile-controller)\\.ts$",
        pathNot: "\\.test\\.ts$",
      },
      to: {
        path: [
          "^src/api-client/",
          "node_modules/@types/office-js",
          "node_modules/@microsoft/microsoft-graph-client",
          "node_modules/@azure/msal-browser",
        ],
        dependencyTypesNot: ["type-only"],
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
