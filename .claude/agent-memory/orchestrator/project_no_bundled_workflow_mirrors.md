---
name: project_no_bundled_workflow_mirrors
description: TMW has no bundled mirrors of `.github/workflows/` files and no python/pester contract tests that pin workflow filenames.
metadata:
  type: project
---

TMW has no bundled mirrors for `.github/workflows/` files. `.github/workflows/` is the single source of truth for CI workflow definitions.

**Why:** During Issue #33 planning, an agent erroneously imported "sync bundled mirrors" guidance from an unrelated repo. The user confirmed that bundled mirrors do not exist in TMW. Probing `.codex/` and `.agents/` in TMW shows they contain agent/skill content only, not workflow file copies, and `tests/` contains no python or Pester contract tests that pin workflow filenames.

**How to apply:** When planning or executing changes to `.github/workflows/` in TMW, do not include tasks to resync mirrored copies under `.codex/`, `.agents/`, or other roots, and do not require pytest + Pester bundle-contract tests as a gate. If a future change introduces such a mirror, update this memory.
