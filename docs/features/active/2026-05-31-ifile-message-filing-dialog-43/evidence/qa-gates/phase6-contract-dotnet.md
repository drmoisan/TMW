# Phase 6 QA — .NET Contract Tests (Issue #43)

Timestamp: 2026-06-01T00-00
Command: dotnet test tests/TaskMaster.Infrastructure.Tests
EXIT_CODE: 0
Output Summary: 21 tests passed (includes the 2 new contract test classes).
- GraphMessageMoverContractTests (P6-T4, AC-12): POST /me/messages/{id}/move issued with a body of exactly { "destinationId": ... }, verified via WireMock.Net request log.
- GraphOneDriveContractTests (P6-T5, AC-13/AC-15): create-folder body carries the folder facet and "@microsoft.graph.conflictBehavior": "fail"; upload uses a simple PUT at exactly 10 MiB and an upload session at 10 MiB + 1 byte (threshold selection verified).
