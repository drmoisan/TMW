# Issue Acceptance Criteria — Confirmation

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Source: `docs/features/active/2026-05-19-rename-cross-language-stages-33/issue.md`

## Acceptance Criteria Section

The source file contains an Acceptance Criteria section at line 37 titled `## Acceptance Criteria (early draft)`. The seven items are recorded verbatim below.

## Verbatim AC List (issue.md lines 39–45)

1. All five misleading "Cross-language X" workflow files are renamed under the chosen pattern.
2. `.github/workflows/pr-pipeline.yml` `uses:` references point to the new filenames.
3. Job names inside each renamed file match the new filename (so the status-check name reported to GitHub also updates).
4. `.github/workflows/README.md` table descriptors accurately name the toolchain and covered file types for each row.
5. Branch-protection check name mapping is documented in the PR description so an admin can update the protection rule on `main` without searching.
6. No behavioral change to any stage; only names and descriptors move.
7. Full CI pipeline run on the change branch is green under the new names.

## Output Summary

Acceptance Criteria section is present (heading reads `## Acceptance Criteria (early draft)`). Seven AC bullets recorded above. Item 7 (green pipeline run) executes only after PR is opened and CI runs on the change branch; it is not directly testable by this executor session.
