# P6-T2 — Authoritative mirror map

Timestamp: 2026-05-19T10-15

Method: Test-Path probe of each candidate mirror for each changed .claude/ file across .agents/, .codex/, .github/.

Per-file mirror existence:

SRC: .claude/skills/orchestrate/SKILL.md
- EXISTS: .agents/skills/orchestrate/SKILL.md
- ABSENT: .codex/skills/orchestrate/SKILL.md
- ABSENT: .github/skills/orchestrate/SKILL.md

SRC: .claude/skills/feature-review-workflow/SKILL.md
- EXISTS: .agents/skills/feature-review-workflow/SKILL.md
- ABSENT: .codex/skills/feature-review-workflow/SKILL.md
- EXISTS: .github/skills/feature-review-workflow/SKILL.md

SRC: .claude/rules/benchmark-baselines.md (new file)
- ABSENT: .agents/rules/benchmark-baselines.md
- ABSENT: .codex/rules/benchmark-baselines.md
- ABSENT: .github/rules/benchmark-baselines.md

SRC: .claude/rules/ci-workflows.md (new file)
- ABSENT: .agents/rules/ci-workflows.md
- ABSENT: .codex/rules/ci-workflows.md
- ABSENT: .github/rules/ci-workflows.md

Root directory probes:
- DIR_ABSENT: .agents/rules
- DIR_ABSENT: .codex/rules
- DIR_ABSENT: .github/rules
- DIR_ABSENT: .codex/skills
- DIR_EXISTS: .agents/skills/orchestrate
- DIR_EXISTS: .agents/skills/feature-review-workflow
- DIR_EXISTS: .github/skills/feature-review-workflow
- DIR_ABSENT: .github/skills/orchestrate

Output Summary:
- Existing mirrors requiring sync: .agents/skills/orchestrate/SKILL.md, .agents/skills/feature-review-workflow/SKILL.md, .github/skills/feature-review-workflow/SKILL.md.
- No-mirror facts (explicit): .codex/ has no skills/ or rules/ tree; .agents/ has no rules/ tree; .github/ has no rules/ tree and no skills/orchestrate. The two new .claude/rules/*.md files (benchmark-baselines.md, ci-workflows.md) have no .agents/rules/, .codex/rules/, or .github/rules/ target; no mirror is created for them.
- No bundle-contract test suite was discovered during this probe; P6-T6 will record the no-mirror attestation accordingly.
