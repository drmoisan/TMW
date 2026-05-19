# P4 — README Structural Lint

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command: `python -c "import re; s=open('.github/workflows/README.md').read(); rows=[l for l in s.splitlines() if l.strip().startswith('|')]; bad=[l for l in rows if l.count('|')<3]; assert not bad, bad; print('OK', len(rows), 'table rows')"`
- EXIT_CODE: 0

## Output Summary

`OK 34 table rows`. All Markdown table rows in `.github/workflows/README.md` contain at least three `|` separators (no broken rows). Companion grep `rg -n 'Cross-language' .github/workflows/README.md` returns no hits (EXIT 1), confirming the misleading label has been fully removed from the README.
