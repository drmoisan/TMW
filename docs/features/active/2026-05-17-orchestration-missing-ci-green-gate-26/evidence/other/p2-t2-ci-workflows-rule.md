# P2-T2 — .claude/rules/ci-workflows.md created

Timestamp: 2026-05-19T10-15

File: C:\Users\DanMoisan\repos\TMW-wt-2026-05-18-09-47\.claude\rules\ci-workflows.md (36 lines, new file)

Content summary (maps to spec.md AC8):
- Documents the pwsh deliberately-failing-nested-command pattern.
- Requires either explicit "$LASTEXITCODE = 0" reset after the expected failure or explicit "exit 0" on the success path for any step whose run: block intentionally invokes a failing nested command.
- Explains the rationale (GitHub Actions reads the step process exit code; no local stage runs the run: block) and cross-references the modified-workflow-needs-green-run rule.

git status: new file (mode 100644).
