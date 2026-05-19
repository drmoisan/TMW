# Baseline — Workflow Files Pre-Rename

- Timestamp: 2026-05-19T08-44
- Issue: #33
- Command: `git rev-parse HEAD:.github/workflows/<file>` and `git cat-file -s HEAD:.github/workflows/<file>` for each file
- EXIT_CODE: 0

## Output Summary

Six workflow files captured at branch HEAD (`feature/rename-cross-language-stages-33`) prior to rename:

| File | Blob SHA | Bytes |
|---|---|---|
| `.github/workflows/pr-pipeline.yml` | `f522371642255ef583936cfbbf2284978204e13c` | 1776 |
| `.github/workflows/_stage-1-format.yml` | `a60022513af8d08d12c00ba0b783b6de13df145b` | 231 |
| `.github/workflows/_stage-2-lint.yml` | `db4a988219da4bc4ae7a688bca5f1d2c7a809b7f` | 225 |
| `.github/workflows/_stage-3-typecheck.yml` | `656309f8e6e19df1a820256c24fefd0ca398c6f0` | 240 |
| `.github/workflows/_stage-5-test.yml` | `05f06a1120bff2c51877aefc4283808218ad3f9c` | 225 |
| `.github/workflows/_stage-7-integration.yml` | `acc603665ea0c7e50d3ba642d0882d60cb83f951` | 246 |
