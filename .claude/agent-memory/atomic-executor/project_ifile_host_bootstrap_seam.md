---
name: ifile-host-bootstrap-seam
description: ifile.ts host-bootstrap was made unit-testable by exporting a bootstrap seam plus runBootstrap, guarded behind typeof Office check
metadata:
  type: project
---

The iFile host-bootstrap module `src/taskpane/ifile/ifile.ts` was restructured during remediation cycle #43 so the previously-uncovered (0%) host-bootstrap seam is now testable and in coverage.

Design: the module exports `bootstrap(deps)` (Office-free, injectable `acquireToken`/`loadLeaves`/`dom`/`onSelect`/`presentation`) and `runBootstrap()` (thin host shell that resolves DOM, applies the backend-URL guard, and wires Office.auth). The top-level `Office.onReady` registration is wrapped in `if (typeof Office !== "undefined")` so the module is importable in Vitest (where Office.js is not defined at module-evaluation time, before the vitest-setup beforeAll installs the fake).

**Why:** issue #43 on-device defect — the original `ifile.ts` ran everything inside `Office.onReady` with no exported seam, was excluded from coverage, and silently failed (console.error only) on token/load failure. The coverage-exclusion was disallowed by `general-unit-test.md`.

**How to apply:** future tests of `ifile.ts` drive `runBootstrap` by installing a minimal Office fake on `globalThis.Office` and `vi.stubGlobal("__API_BASE_URL__", ...)` / `__IS_MOBILE_BUILD__`. The only intentionally-uncovered region is the `if (typeof Office !== "undefined") { Office.onReady(...) }` block (host-registration wrapper, cannot run under the test runtime). Do not re-exclude this file from coverage. See [[ifile-token-path-od8]].
