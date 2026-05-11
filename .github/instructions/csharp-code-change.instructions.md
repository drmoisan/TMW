---
applyTo: "**/*.cs,**/*.csproj,**/*.props,**/*.targets"
name: csharp-code-change-policy
description: "C#-specific code change rules layered on top of the general code change policy"
---

# C# Code Change Policy

This policy **extends** `general-code-change.instructions.md` and applies to all **C# source, test, and build-configuration files** (`*.cs`, `*.csproj`, `*.props`, `*.targets`) in this repo.

You must:

- Apply **all** rules in the general code change policy.
- Apply **all** C#-specific rules in this file.
- Apply the unit test policies (`general-unit-test.instructions.md` and `csharp-unit-test.instructions.md`) for any work involving tests.

If you encounter any conflicting instructions between these documents, **halt and notify the user.**

---

## 1. Tooling & Baseline for C#

These are the required tools for C# code in this repo:

1. **Formatting — `csharpier`**

   - All C# source files (`*.cs`) must be formatted with `csharpier`.
   - Do **not** use `dotnet format`.
   - `csharpier` is file-based and formats only `*.cs` without touching project files.
   - Do not hand-format; if a diff disagrees with `csharpier`, formatter output wins.
   - Approved commands:
     - `dotnet tool restore`
     - `dotnet csharpier check .` (CI) or `dotnet csharpier .` (auto-format)

2. **Linting / Static Analysis — .NET analyzers**

   - C# code must pass Roslyn/.NET analyzer diagnostics configured by `.editorconfig`, `.globalconfig`, `Directory.Build.props`, and project properties.
   - Analyzer enforcement is centralized in `Directory.Build.props` (`AnalysisLevel=latest-all`, `AnalysisMode=All`, `TreatWarningsAsErrors=true`). Do not duplicate these settings per project.
   - Prefer fixing diagnostics over suppressing them.
   - Approved command:
     - `dotnet build` (analyzers run as part of the build; `TreatWarningsAsErrors=true` fails on any analyzer or compiler warning).

3. **Type Checking — C# compiler + nullable analysis**

   - Treat C# compiler diagnostics and nullable-flow warnings as first-class type-safety checks.
   - Nullable reference types are enabled solution-wide via `Directory.Build.props` (`Nullable=enable`).
   - Avoid introducing nullable warnings; fix the root null-state issue instead.
   - Approved command:
     - `dotnet build` (with `TreatWarningsAsErrors=true` set in `Directory.Build.props`, nullable warnings fail the build).

### Analyzer Stack

All projects reference the following analyzer packages via `<PackageReference>` with `PrivateAssets="all"`, with versions pinned centrally in `Directory.Packages.props` and the shared `<ItemGroup>` declared in `Directory.Build.props`:

- `Meziantou.Analyzer`
- `SonarAnalyzer.CSharp`
- `Roslynator.Analyzers`
- `AsyncFixer`
- `SecurityCodeScan.VS2019`
- `Microsoft.CodeAnalysis.BannedApiAnalyzers`

### Banned APIs

The following APIs are banned outside an explicit allowlist; enforcement uses `Microsoft.CodeAnalysis.BannedApiAnalyzers` against `BannedSymbols.txt` (at solution root, wired via `Directory.Build.props` `<AdditionalFiles>`):

- `DateTime.Now`, `DateTime.UtcNow` (use `TimeProvider`)
- `Random.Shared` (inject a seeded `Random`)
- `Thread.Sleep`, `Task.Delay` (banned in production paths; tests use `FakeTimeProvider`)

### DI Seams

- **`TimeProvider`** is the preferred clock seam for new code (since .NET 8).
- Test code injects `FakeTimeProvider` from **`Microsoft.Extensions.TimeProvider.Testing`**.
- `IClock` is acceptable only in legacy or pre-.NET 8 code paths.

### Coverage

- Line coverage line >= 85% and branch coverage branch >= 75% uniform across all tiers (T1–T4).
- Mutation score mutation >= 75% on T1 modules (via Stryker.NET).

### Property-Based, Mutation, and Golden Tests

- **CsCheck**: at least one property-based test per pure function on T1 and T2 modules.
- **Stryker.NET**: mutation testing on T1 modules with mutation score mutation >= 75%.
- **Verify.Xunit**: golden tests for T1 classifier-output modules.

> **Testing tools and behavior are defined in the unit test policies.** Do not define test behavior here; instead, obey `general-unit-test.instructions.md` and `csharp-unit-test.instructions.md`.

---

## 2. C# Design & Type-Safety Principles

These refine the general design principles for C# code.

1. **Strong contracts and explicit APIs**

   - Public methods, constructors, and properties must express clear contracts.
   - Use explicit types at public boundaries; use `var` only when the type is obvious.

2. **Null-safety by default**

   - Keep nullable reference types enabled.
   - Model optional values explicitly with nullable annotations and guard clauses.
   - Use nullability attributes where needed to improve flow analysis.

3. **Prefer composition and focused types**

   - Keep classes cohesive and scoped to one core responsibility.
   - Favor composition over inheritance unless polymorphism is a clear requirement.

4. **Asynchrony and resource safety**

   - Use `async`/`await` for I/O-bound operations.
   - Prefer `using`/`await using` for disposable resources.

---

## 3. Classes, Methods, and APIs (C#-Specific Guidance)

### 3.1 Classes for domain concepts and workflows

Use classes/records when:

- Modeling domain concepts with state + behavior.
- Protecting invariants across related members.
- Providing multiple implementations behind interfaces.
- Orchestrating multi-step workflows that share context.

When using classes/records:

- Keep methods small and focused.
- Avoid god objects.
- Prefer immutable records/value objects for data-centric models where practical.

### 3.2 Methods and local functions for focused logic

Use methods/local functions when:

- Implementing narrow, deterministic behavior.
- Encapsulating reusable, stateless transformations.

Rules:

- Name methods by behavior.
- Keep branching shallow where possible.
- Extract helper methods instead of deeply nested conditionals.

### 3.3 Interfaces and contracts

- Use interfaces when multiple implementations are expected.
- Keep public APIs stable and avoid unnecessary breaking changes.
- Document non-obvious side effects and failure modes.

---

## 4. Error Handling, Logging, and Contracts (C#)

1. **Exceptions**

   - Fail fast with explicit exceptions when invariants are violated.
   - Avoid catching broad `Exception` unless at a clear boundary and with added context.

2. **Logging**

   - Use the repository/project logging pattern, not ad-hoc console output in production code.
   - Log actionable context at appropriate levels.

3. **Contracts / invariants**

   - Validate constructor and method preconditions.
   - Use `Debug.Assert` only for internal invariants, not user-facing validation.

---

## 5. Module & File Structure (C#)

1. **Cohesive files and namespaces**

   - Keep files focused on one responsibility area.
   - Keep file size under the repo limit in `general-code-change.instructions.md`.

2. **Public vs internal**

   - Keep public surface area intentional and minimal.
   - Prefer `internal` for non-public APIs.

3. **Imports and namespace hygiene**

   - Prefer explicit `using` directives at file scope.
   - Avoid circular dependencies.

---

## 6. Naming, Docs, and Comments (C#)

1. **Naming conventions**

   - `PascalCase` for types and public members.
   - `camelCase` for local variables and private fields/parameters.
   - Use descriptive names over abbreviations.

2. **Documentation comments**

   - Public APIs should include XML documentation comments when behavior or contract is non-obvious.

3. **Comments**

   - Comment **why**, not what.
   - Keep comments synchronized with behavior.

---

## 7. Dependencies and Analyzer Configuration (C#)

- Prefer built-in .NET SDK analyzers and configuration through `.editorconfig` / `.globalconfig`.
- Use project-level properties (`EnableNETAnalyzers`, `AnalysisLevel`, `AnalysisMode`, `EnforceCodeStyleInBuild`) rather than ad-hoc per-command behavior where possible.
- Avoid adding external dependencies unless unavoidable and approved by the project direction.
- If suppression is unavoidable, keep it as narrow as possible and document the rationale in-code.
