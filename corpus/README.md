# corpus/ — Contribution Policy and Git LFS Rules

This directory holds versioned input fixtures for golden tests once T1 classifier modules are introduced.
No fixtures exist yet; this file establishes governance before they arrive.

## Directory Layout

Top-level subdirectories name the classifier. Example structure once fixtures exist:

```
corpus/
  classifiers/
    spam-samples/
      sample-001.json
      sample-001.meta.json
    triage-samples/
      sample-001.eml
      sample-001.meta.json
  README.md
```

File names must include a zero-padded sequence number (e.g., `sample-001.json`, `sample-042.eml`).

## Contribution Rules

The following five rules apply to all corpus changes:

1. **Separate PR required.** Corpus updates must be submitted as a dedicated PR, not bundled
   with source code changes. The PR description must state which classifier's corpus is changing
   and why.

2. **Explicit diff review.** The project lead reviews all corpus changes via CODEOWNERS
   (entry: `corpus/** @drmoisan`). No corpus PR may be merged without this approval.

3. **Git LFS for binary files.** Files matching `corpus/**/*.eml` and `corpus/**/*.bin` are
   tracked via Git LFS using the patterns in `.gitattributes` (see below). Text fixtures under
   1 MB may use regular Git with `text eol=lf`. Large JSON fixtures (over 1 MB) should also
   use Git LFS.

4. **Directory layout.** Top-level subdirectories name the classifier
   (e.g., `corpus/classifiers/spam-samples/`, `corpus/classifiers/triage-samples/`).
   File names include a zero-padded sequence number.

5. **No generated content without metadata.** Corpus files must represent real or carefully
   curated inputs. Synthetically generated fixtures must be tagged as synthetic in a sidecar
   `.meta.json` file next to the fixture file. The `.meta.json` must include at minimum:
   `{ "synthetic": true, "generator": "<tool or script name>", "date": "<ISO-8601>" }`.

## Git LFS Patterns

The following Git LFS tracking rules are configured in `.gitattributes`:

```
corpus/**/*.eml filter=lfs diff=lfs merge=lfs -text
corpus/**/*.bin filter=lfs diff=lfs merge=lfs -text
```

Text fixtures (`.json`, `.txt`) under 1 MB use regular Git with `text eol=lf` and do not
require LFS. If a text fixture exceeds 1 MB, add a corresponding LFS pattern to `.gitattributes`
and document it in this file before committing.

## Verified Files

`.verified.json` snapshot files produced by `Verify.XunitV3` are committed to source control
and must not be placed in this directory. They live alongside their test files in
`tests/TaskMaster.PlaceholderGolden.Tests/` (and future T1 test projects).

`.received.*` files are temporary; they are excluded from source control via `.gitignore`.
