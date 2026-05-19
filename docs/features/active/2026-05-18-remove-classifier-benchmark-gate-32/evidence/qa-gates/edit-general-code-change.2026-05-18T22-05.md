# Edit .claude/rules/general-code-change.md

Timestamp: 2026-05-18T22-40
Command: Edit tool (remove " and benchmark regression" from the nightly-pipeline sentence at line 45); Select-String -Path .claude/rules/general-code-change.md -Pattern 'benchmark regression'
EXIT_CODE: 0
Output Summary: Sentence updated; grep returned 0 matches.

## Diff (logical)
Before:
```
Mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines, not the per-commit loop.
```
After:
```
Mutation testing and golden tests run in pre-merge or nightly pipelines, not the per-commit loop.
```
