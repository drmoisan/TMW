# OpenAPI Emission Determinism Check

Timestamp: 2026-05-14T22-43
Command: `dotnet build src/TaskMaster.Api/TaskMaster.Api.csproj --no-incremental` run twice from a clean emission state
EXIT_CODE: 0 (both builds succeeded)

Output Summary:
The OpenAPI document was emitted twice, deleting `artifacts/openapi/current.json` before each `--no-incremental` build. Both runs produced a byte-identical file.

- Run 1 SHA-256: `3b2b12a4c31e944f1e1c3bd12460cfc6642db46da779e5f6657b9bf1732f7e89`
- Run 2 SHA-256: `3b2b12a4c31e944f1e1c3bd12460cfc6642db46da779e5f6657b9bf1732f7e89`
- `diff` between run 1 and run 2: no differences (BYTE_IDENTICAL: yes)

Emission is deterministic. No emit-ordering pinning was required beyond the default `Microsoft.Extensions.ApiDescription.Server` behavior.
