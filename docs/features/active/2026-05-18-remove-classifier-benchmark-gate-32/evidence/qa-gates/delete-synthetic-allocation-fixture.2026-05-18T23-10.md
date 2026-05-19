---
Timestamp: 2026-05-18T23-10
Command: Get-FileHash -Algorithm SHA256 tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json; Remove-Item tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json
EXIT_CODE: 0
Output Summary: pre-delete SHA256=F1728DD5FAB7FEAFDAA089A274B1ABBFCE0DBC95E0F653F09378127F3EF574C6; Remove-Item succeeded; Test-Path returns False (file deleted).
---

Pre-delete SHA256: `F1728DD5FAB7FEAFDAA089A274B1ABBFCE0DBC95E0F653F09378127F3EF574C6`
Path: `tests/TaskMaster.Benchmarks/Fixtures/SyntheticAllocationRegressionFixture.json`
Post-delete verification: `Test-Path` returns `False`.
