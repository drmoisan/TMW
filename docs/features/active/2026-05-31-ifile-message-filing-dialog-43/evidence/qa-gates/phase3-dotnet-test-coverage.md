# Phase 3 QA — .NET Tests + Coverage (Issue #43)

Timestamp: 2026-06-01T00-00
Command: dotnet test (Application.Tests; Infrastructure.Tests; Api.Tests) each --collect:"XPlat Code Coverage"
EXIT_CODE: 0
Output Summary:
- Application.Tests: 43 passed.
- Infrastructure.Tests: 17 passed.
- Api.Tests: 28 passed (was 19; +9 iFile: 5 endpoint integration tests covering success/pre-move-failure POST shapes, GET flat leaf list, and 401 on both endpoints unauthenticated; +4 IFileOutcome.ToWire mapping cases).
- Architecture.Tests: 10 passed.
Coverage on new API code: FileMessageEndpointRequest/Response, FolderListResponse, FolderListItem at 100% line/branch; IFileOutcome.ToWire at 100% line after the dedicated mapping tests. New-code coverage meets line >= 85% / branch >= 75%; no regression on changed lines.

OpenAPI/generated client: artifacts/openapi/current.json contains /api/ifile/folders (GET, operationId IFileFolders) and /api/ifile/file (POST, operationId IFileFile) plus FileMessageEndpointRequest/Response, FolderListResponse, FolderListItem schemas. npm run generate:api regenerated src/api-client/v1.ts (contains both operations); npm run lint:openapi passed (EXIT 0, 3 pre-existing non-iFile warnings).
