---
Timestamp: 2026-05-16T01-40
Command: dotnet test tests/TaskMaster.Infrastructure.Tests/TaskMaster.Infrastructure.Tests.csproj --no-build --filter "FullyQualifiedName~SchemaValidationPropagationTests"
EXIT_CODE: 0
---

## Output Summary

Passed! — Failed: 0, Passed: 2, Skipped: 0. Both SchemaValidationPropagationTests tests passed:

1. SaveAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException — PASS
2. RecordAsync_WhenSchemaValidationFails_PropagatesSchemaValidationException — PASS

Both tests confirmed that PayloadType is non-empty and ValidationErrors is non-empty (CollectErrors branch exercised).
