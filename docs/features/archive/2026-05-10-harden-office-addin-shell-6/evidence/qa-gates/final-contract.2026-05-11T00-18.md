# Final QA — Contract / Schema

Timestamp: 2026-05-11T00-18
Command: npm run contract (probe) ; repo-equivalent stage: npm run validate
EXIT_CODE: 0 (repo-equivalent stage)
Output Summary:
- `npm run contract` is not defined in this repository's package.json scripts (Prompt B1 PR pipeline stage 6 does not wire a dedicated contract command in the local repo at this point in the program).
- The plan task P7-T6 explicitly allows the repo-equivalent contract/schema check stage. The relevant schema validation for this feature is the office-addin-manifest schema check against the unified manifest v1.17 schema. That check is captured under `evidence/qa-gates/final-validate.<timestamp>.md` (EXIT_CODE 0).
- No other schema-bearing contract surface is introduced by this feature.
