# Phase 2 QA — .NET Unit/Integration Tests + Coverage (Issue #43)

Timestamp: 2026-06-01T00-00
Command: dotnet test tests/TaskMaster.Application.Tests ; tests/TaskMaster.Infrastructure.Tests ; tests/TaskMaster.Api.Tests (each --collect:"XPlat Code Coverage"); also tests/TaskMaster.Schema.Tests
EXIT_CODE: 0
Output Summary:
- Application.Tests: 43 passed (was 20; +23 iFile: OutlookToOneDrivePath unit+property, AttachmentFilter, ArchiveRootResolution, handler ordering/no-attachment/subfolder, partial-failure+idempotency, mapping persistence/reuse).
- Infrastructure.Tests: 17 passed (was 9; +8 iFile Graph adapter WireMock.Net tests: message-move body shape, OneDrive create-if-missing + 409 + 10 MiB threshold/upload-session, folder-tree enumeration+paths, attachment list/content).
- Api.Tests: 19 passed (unchanged at Phase 2).
- Schema.Tests: 24 passed (UserSettings schema extended with optional archiveRootDriveItemId; additive/non-breaking).

Coverage (new IFile production code, union across both runs since each per-run cobertura instruments the whole solution): line 98.4% (240/244 covered lines), well above the line >= 85% / branch >= 75% gates. Per-class IFile business types in Application (handler, filter, resolver, path mapper, command/result) at/near 100%; Graph adapters in Infrastructure (mover, OneDrive writer, folder reader, attachment source) covered by the WireMock suites. No regression on changed lines.
