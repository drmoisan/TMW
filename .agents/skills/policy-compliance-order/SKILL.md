# Converted skill

Applied rewrites:
- Rewrite merged standing-guidance source paths to the native AGENTS.md target.
- Rewrite merged standing-guidance source paths to the native AGENTS.md target.
- Rewrite merged standing-guidance source paths to the native AGENTS.md target.
- Rewrite GitHub Copilot instruction-directory references to the native skill root.
- Rewrite Claude rule paths to shared skill paths.
- Rewrite Claude rules-directory references to the native skill root.

---
name: policy-compliance-order
description: 'Repository policy compliance order and hard constraints. Use when an agent must read mandatory policy files, apply repo-wide constraints, or restate policy precedence without duplicating blocks across agents.'
---

# Policy Compliance Order

Shared policy-compliance instructions to avoid duplicating the same policy order across multiple agents.

## When to Use This Skill

Use this skill when:
- An agent must declare the repository’s mandatory policy reading order.
- You need to reiterate non-negotiable constraints (e.g., no policy edits, no secrets, no silent skips).
- Multiple agents share the same compliance preamble.

## Required Policy Reading Order (Baseline)

Claude Code auto-loads rules via path-scoped frontmatter in `.agents/skills/`. This ordering documents precedence when policies conflict:

1) `AGENTS.md` (standing instructions, always loaded)
2) `AGENTS.md` (cross-language code change policy)
3) `AGENTS.md` (cross-language unit test policy)
4) Language- or domain-specific rules based on files in scope:
   - Python: `.agents/skills/python/SKILL.md`, `.agents/skills/python-suppressions/SKILL.md`
   - PowerShell: `.agents/skills/powershell/SKILL.md`
   - TypeScript: `.agents/skills/typescript/SKILL.md`, `.agents/skills/typescript-suppressions/SKILL.md`
   - C#: `.agents/skills/csharp/SKILL.md`

## Hard Constraints (Baseline)

- Do NOT modify policy documents under `.agents/skills/` or `.agents/skills/`.
- Do NOT create secrets or `.env` files unless explicitly requested.
- Prefer repo-defined tasks/commands when running checks.
- If information is missing, proceed with best-effort assumptions and document them.

## Extensions (Agent-Specific)

Agents may append additional requirements that are unique to their role (e.g., policy audit templates or epic docs), but should not duplicate the baseline order above.
