# Mirror Resync — general-code-change

Timestamp: 2026-05-18T22-40
Command: Edit `.github/instructions/general-code-change.instructions.md` at line 241 to remove "and benchmark regression" from the nightly-pipeline sentence (matching the P4-T4 edit). Then `Select-String -Path .github/instructions/general-code-change.instructions.md -Pattern 'benchmark regression'`.
EXIT_CODE: 0
Output Summary: Mirror edit applied; grep returned 0 matches. The mirror is an intentionally longer/expanded variant of the live rule (not a verbatim copy); body comparison shows pre-existing structural differences that are intrinsic to the bundled-mirror format. The targeted policy claim ("benchmark regression" in the nightly-pipeline sentence) is removed from both files.

LiveHash:   DD6D1957D37686ADC3C8AF6A8ACD45A867D29EE288541F6BF1CF4E3253D46027
MirrorHash: 40CD382AAFD4EB991D0DDF21224AD7577A8317202844C10A5994BE1B64B27075

## Diff (logical)
Before:
```
Treat these seven steps as one **toolchain pass**. Mutation testing, golden tests, and benchmark regression run in pre-merge or nightly pipelines, not the per-commit loop.
```
After:
```
Treat these seven steps as one **toolchain pass**. Mutation testing and golden tests run in pre-merge or nightly pipelines, not the per-commit loop.
```
