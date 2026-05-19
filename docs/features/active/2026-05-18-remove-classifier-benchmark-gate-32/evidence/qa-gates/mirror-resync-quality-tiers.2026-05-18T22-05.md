# Mirror Resync — quality-tiers

Timestamp: 2026-05-18T22-40
Command: Edit `.github/instructions/quality-tiers.instructions.md` to remove the "Benchmark p99 regression" row at line 45 (matching the P4-T3 edit to the live file). Then compare body-after-frontmatter-strip.
EXIT_CODE: 0
Output Summary: Mirror updated. Body comparison (frontmatter stripped from both sides) returns BODY MATCH. The two files retain different SHA256 because each has its own frontmatter (live uses `paths:` + `description:`; mirror uses `applyTo:` + `name:` + `description:`); this divergence pre-existed and is intrinsic to the bundled-mirror convention.

LiveHash:   0307F01124DCAF7545568B5A94D24C13073B7B08E7A623721B49B85BCCE2B02A
MirrorHash: 17AB6726CC9CB07653ED8BF370D8510C3471D56BF681F8A0ACF8E503E2EA5D0A

## Diff (logical)
Removed line 45:
```
| Benchmark p99 regression | < 5% | < 10% | none | none |
```
