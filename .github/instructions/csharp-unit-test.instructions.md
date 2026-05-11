---
applyTo: "**/*.cs"
name: csharp-unit-test-policy
description: "C#-specific unit test rules, layered on top of the general unit test policy"
---

# C# Unit Test Policy

This policy **extends** `general-unit-test.instructions.md` and applies to all C# unit tests in this repo.

You must follow **both**:

- The general unit test policy, and
- The C#-specific rules below.

If there is any conflict between these documents, halt and notify the user.

---

## 1. Framework Selection

- **Testing framework**
  - Use **xUnit** for C# unit tests in this repository.
  - Use `[Fact]` for parameterless tests and `[Theory]` with `[InlineData]` for parameterized tests.
  - Use `IClassFixture<T>` to share expensive setup across tests within a class.

---

## 2. C#-Specific Libraries and Conventions

- **Mocking library**
  - Use **NSubstitute** for test doubles. Example: `var sut = Substitute.For<IService>(); sut.Get().Returns(value);`.

- **Assertion library**
  - Prefer **FluentAssertions** for assertions.
  - Use xUnit `Assert` APIs only when FluentAssertions is not practical for a specific assertion shape.

- **xUnit attributes**
  - Use `[Fact]`, `[Theory]`, `[InlineData]`, and `[MemberData]` from xUnit (`Xunit` namespace).
  - Use `IClassFixture<T>` for shared expensive setup.

---

## 3. C# Toolchain Command Selection

- For C# work, use these concrete commands for the general policy toolchain loop:
  1. `dotnet tool restore`
  2. `dotnet csharpier check .`
  3. `dotnet build` (analyzers and nullable analysis enforced via `Directory.Build.props`)
  4. `dotnet test tests/*.ArchitectureTests/*.csproj --no-build` (architecture tests)
  5. `dotnet test --collect:"XPlat Code Coverage"` (unit tests with coverage)

- The loop behavior (restart rules, must-pass requirements, and audit expectations) is defined by `general-code-change.instructions.md` and is intentionally not repeated here.

---

## 4. Coverage and Determinism

- Line coverage line >= 85% and branch coverage branch >= 75% uniform across all tiers (T1–T4).
- Mutation score mutation >= 75% on T1 modules (via Stryker.NET).
- Coverage regression on changed lines is a blocking finding.

### Deterministic Clock Seam

- Inject `TimeProvider` rather than calling `DateTime.UtcNow` or `DateTime.Now` directly.
- In tests, inject `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing` to advance simulated time deterministically.

This file is intentionally limited to C#-specific framework/library/tool selection. Cross-language testing principles and policy requirements are defined in `general-unit-test.instructions.md` and `general-code-change.instructions.md`.
