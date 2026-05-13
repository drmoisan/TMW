---
name: project-behavior-correctness-infra
description: Feature #15 establishes property-based, golden, and mutation test infrastructure before T1 classifiers land. Key version pins and scope constraints.
metadata:
  type: project
---

Feature #15 (2026-05-12): stand up behavior-correctness test infrastructure as a pre-requisite before any T1 classifier module arrives.

Key decisions and constraints:
- `@fast-check/vitest` is pinned to `0.3.0` (last version supporting Vitest 2.x). Do not suggest upgrading until Vitest moves to 4.x.
- `Verify.XunitV3` (31.16.3) requires `xunit.v3` 3.2.2. The new placeholder project (`TaskMaster.PlaceholderGolden.Tests`) uses `xunit.v3`; all existing test projects stay on `xunit` 2.9.3. Never suggest migrating the existing projects as part of this feature.
- `dotnet-stryker` 4.14.1 registered as a local tool in `.config/dotnet-tools.json`.
- Mutation and golden CI stages (8 and 9) go in a new `pre-merge-pipeline.yml`, not in `pr-pipeline.yml`.
- Stryker stubs are active but `break: 75` only enforces once real T1 source code is present.
- `TaskMaster.PlaceholderGolden.Tests` must be registered in `quality-tiers.yml` as t4 or tier-classification CI fails.

**Why:** Retrofitting infra after classifiers land creates gate failures on first introduction and adds friction. Infrastructure first.

**How to apply:** When working on feature #15 implementation or follow-on T1 modules, respect the version pins above and the xunit.v3 / xunit 2.9.3 split.
