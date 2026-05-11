---
Timestamp: 2026-05-10T20-14
Task: P0-T7
Source: quality-tiers.yml (raw copy)
---

```yaml
# quality-tiers.yml
# Source of truth for module rigor tier classification across this repository.
# Every project MUST be listed below with a tier value of t1, t2, t3, or t4.
# Adding a project without a tier classification fails the CI tier-classification stage.
# See .claude/rules/quality-tiers.md for tier definitions.

schema_version: 1

projects:
  # Current TypeScript scaffold (the Office add-in skeleton at the repo root).
  - name: tmw-taskpane-scaffold
    path: .
    language: typescript
    tier: t4
    rationale: |
      Scaffold-tier (T4): build wiring, manifest, and bootstrap only. Will be re-tiered
      when domain modules and classifier engines are introduced (Prompt B1+).

# Validator behavior (read by .github/workflows/pr-pipeline.yml stage tier-classification):
# - Every entry under projects MUST have name, path, language, tier.
# - tier value MUST be one of: t1, t2, t3, t4.
# - The validation script also confirms that every directory in the repo that contains a
#   package.json, *.csproj, or pyproject.toml is represented by exactly one entry.
```
