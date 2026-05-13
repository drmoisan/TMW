# User Story — Issue #7

As the TMW maintainer driving the No-COM modernization, I need a complete .NET CI foundation in place — with rule prose, agent definitions, skill files, analyzer stack, banned APIs, central package management, test SDK, architecture-test scaffold, and PR pipeline stages — before any backend code is written, so that every .NET commit from the first PR onward is validated against final-form quality gates and toolchain decisions remain consistent across rule files and enforcement artifacts.

## Persona

- Maintainer/orchestrator coordinating multi-language quality gates for the TaskMaster migration.

## Outcome

- A C# rule baseline that matches the No-COM toolchain (xUnit, NSubstitute, `dotnet build`, `TimeProvider`, analyzer stack, uniform coverage thresholds).
- A `.NET` solution skeleton where `dotnet csharpier check`, `dotnet build`, `dotnet test`, and architecture tests all gate the PR pipeline.
- Mirror discipline preserved between `.claude/rules/` <-> `.github/instructions/` and `.claude/skills/` <-> `.github/skills/`.
