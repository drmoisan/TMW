# Phase R0 — Architecture Tests Baseline

- Timestamp: 2026-05-10T22-30
- Task: [PR0-T7]
- File: `tests/TaskMaster.ArchitectureTests/NoComArchitectureTests.cs`

```csharp
using System.Linq;
using FluentAssertions;
using NetArchTest.Rules;

namespace TaskMaster.ArchitectureTests;

/// <summary>
/// No-COM architecture-rule facts enforced via NetArchTest.Rules against the
/// loaded assemblies of the TaskMaster solution.
///
/// Categories:
///   (a) no project depends on Microsoft.Office.Interop.Outlook (COM ban)
///   (b) no project depends on System.Windows.Forms, System.Web, or Microsoft.VisualBasic
///   (c) projects whose namespace starts with TaskMaster.Domain do not depend on TaskMaster.Infrastructure*
/// </summary>
public class NoComArchitectureTests
{
    private static System.Reflection.Assembly[] LoadTaskMasterAssemblies()
    {
        var domain = typeof(TaskMaster.Domain.AssemblyMarker).Assembly;
        return System
            .AppDomain.CurrentDomain.GetAssemblies()
            .Where(a =>
                a.GetName().Name?.StartsWith("TaskMaster", System.StringComparison.Ordinal) == true
            )
            .Append(domain)
            .Distinct()
            .ToArray();
    }

    [Fact]
    public void NoProjectDependsOnOutlookInterop()
    {
        var assemblies = LoadTaskMasterAssemblies();
        var result = Types
            .InAssemblies(assemblies)
            .Should()
            .NotHaveDependencyOn("Microsoft.Office.Interop.Outlook")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "no TaskMaster.* project may depend on Microsoft.Office.Interop.Outlook (No-COM architecture). Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }

    [Fact]
    public void NoProjectDependsOnForbiddenLegacyNamespaces()
    {
        var assemblies = LoadTaskMasterAssemblies();
        var result = Types
            .InAssemblies(assemblies)
            .Should()
            .NotHaveDependencyOnAny("System.Windows.Forms", "System.Web", "Microsoft.VisualBasic")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "no TaskMaster.* project may depend on System.Windows.Forms, System.Web, or Microsoft.VisualBasic. Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }

    [Fact]
    public void DomainProjectDoesNotDependOnInfrastructure()
    {
        var domainAssembly = typeof(TaskMaster.Domain.AssemblyMarker).Assembly;
        var result = Types
            .InAssembly(domainAssembly)
            .That()
            .ResideInNamespaceStartingWith("TaskMaster.Domain")
            .Should()
            .NotHaveDependencyOn("TaskMaster.Infrastructure")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "types in TaskMaster.Domain.* may not depend on TaskMaster.Infrastructure*. Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }
}
```
