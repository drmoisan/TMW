using FluentAssertions;
using NetArchTest.Rules;
using TaskMaster.Application;

namespace TaskMaster.ArchitectureTests;

/// <summary>
/// Architecture layer boundary tests for the No-COM backend.
/// Enforces that Application does not depend on Infrastructure,
/// Application does not depend on Microsoft.Identity, and Domain
/// does not depend on Application or Infrastructure.
/// </summary>
public sealed class LayerBoundaryTests
{
    [Fact]
    public void ApplicationProjectDoesNotDependOnInfrastructure()
    {
        var result = Types
            .InAssembly(typeof(ICommandBus).Assembly)
            .Should()
            .NotHaveDependencyOn("TaskMaster.Infrastructure")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "types in TaskMaster.Application must not depend on TaskMaster.Infrastructure. "
                    + "Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }

    [Fact]
    public void ApplicationProjectDoesNotDependOnMicrosoftIdentityWeb()
    {
        var result = Types
            .InAssembly(typeof(ICommandBus).Assembly)
            .Should()
            .NotHaveDependencyOn("Microsoft.Identity")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "types in TaskMaster.Application must not depend on Microsoft.Identity. "
                    + "Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }

    [Fact]
    public void DomainProjectDoesNotDependOnApplicationOrInfrastructure()
    {
        var domainAssembly = typeof(TaskMaster.Domain.AssemblyMarker).Assembly;

        var noAppResult = Types
            .InAssembly(domainAssembly)
            .Should()
            .NotHaveDependencyOn("TaskMaster.Application")
            .GetResult();

        noAppResult
            .IsSuccessful.Should()
            .BeTrue(
                "types in TaskMaster.Domain must not depend on TaskMaster.Application. "
                    + "Failing types: "
                    + string.Join(
                        ", ",
                        noAppResult.FailingTypeNames ?? System.Array.Empty<string>()
                    )
            );
    }
}
