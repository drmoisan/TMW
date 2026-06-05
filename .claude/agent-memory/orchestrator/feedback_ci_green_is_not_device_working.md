---
name: ci-green-is-not-device-working
description: For device-rendered Office add-in features, CI-green is not "working code"; the host-bootstrap wiring seam and on-device runtime path (backend URL reachability, load-failure handling, token acquisition) must be covered and the HI on-device exception must actually be executed before claiming the feature works.
metadata:
  type: feedback
---

A feature that passes all CI gates and whose host-neutral logic is fully unit-tested can still be completely non-functional on a real device. Do not treat CI-green as "working code" for any feature whose value only manifests when rendered in a real host (Outlook desktop/iOS, Office.js dialog/taskpane).

**Why:** Confirmed by user 2026-06-04. The iFile message-filing feature (#43) shipped CI-green on PR #44 with the host-neutral search modules, controller cache, and C# backend all tested. On a physical iPhone the search returned no folders for a known folder, with no error shown. Three on-device-only defects were invisible to CI: (1) the mobile bundle's backend URL defaulted to `https://localhost:3000`, unreachable from a device (webpack `__API_BASE_URL__` default); (2) `mountInline` awaited the one-time folder load before binding the keystroke listener, and the loader threw with only `console.error`, leaving a silent inert search box; (3) token acquisition used SSO rather than the researched NAA-primary path. The common thread: the host-bootstrap/wiring seam (`ifile.ts`, `inline-host.ts`) was coverage-excluded, so the entire device runtime path was unexercised. The original orchestration declared the CI-verifiable scope complete and parked on a vague "manual device verification" item that was never actually performed before the feature was treated as delivered.

**How to apply:**

1. The host-bootstrap/wiring seam must NOT be coverage-excluded (`.claude/rules/general-unit-test.md` coverage-exclusion policy). Extract logic into testable modules and add regression tests for the wiring + the load-failure/error path. An uncovered bootstrap file is a red flag, not an acceptable exclusion.
2. For device-rendered features, the build/runtime config that only matters off-localhost (reachable backend URL, manifest domains, token flow) is part of the deliverable. Add a fail-fast guard (e.g. reject a localhost URL in a mobile build) so a misconfiguration is loud, not silent.
3. A one-time async load that gates the UI must not, on failure, leave an inert surface. Bind input handlers independent of load outcome and render a visible, deterministic, testable error state.
4. CI-green does not satisfy the completion gate for a device feature. The declared HI on-device exception (see [[validate-shellexecute-launchers-on-real-host]] for the analogous real-host-validation principle, and [[autonomous-execution-no-manual-steps]]) must actually be executed by the human and its result fed back before DONE. Keep the runbook concrete (it must include the build-with-reachable-URL + sideload steps), and keep the feature gated until the runbook is run — do not let "manual verification pending" quietly become "delivered."
