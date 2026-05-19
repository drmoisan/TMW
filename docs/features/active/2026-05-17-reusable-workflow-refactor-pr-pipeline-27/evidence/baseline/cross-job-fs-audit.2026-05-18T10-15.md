# Cross-job filesystem-dependency audit — pr-pipeline.yml

Timestamp: 2026-05-18T10-15
Command: grep -nE "download-artifact|needs\.[a-z0-9-]+\.outputs|actions/cache|upload-artifact" .github/workflows/pr-pipeline.yml
EXIT_CODE: 0

Matches:
```
142:        uses: actions/upload-artifact@v4
```

Findings:
- `download-artifact`: 0 occurrences.
- `needs.<id>.outputs.*`: 0 occurrences.
- `actions/cache`: 0 occurrences.
- `actions/upload-artifact`: 1 occurrence — line 142, inside `stage-10-benchmark-regression`. No downstream consumer.

Output Summary: no cross-job filesystem reliance found — confirms spec section "Risks & Mitigations". The single upload-artifact in stage-10 is internal to that job (artifact uploaded for human/CI inspection, not consumed by another job). The refactor is a pure relocation; no new artifact contract is required. Proceeding to Phase 2.
