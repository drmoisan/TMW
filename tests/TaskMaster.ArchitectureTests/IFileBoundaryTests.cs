using FluentAssertions;
using NetArchTest.Rules;
using TaskMaster.Application.IFile;
using TaskMaster.Infrastructure.IFile;

namespace TaskMaster.ArchitectureTests;

/// <summary>
/// Architecture-boundary tests for the iFile feature (AC-10, HC-6). The Graph/OneDrive
/// adapter types live only in TaskMaster.Infrastructure, and TaskMaster.Application.IFile
/// does not reference the Microsoft Graph SDK.
/// </summary>
public sealed class IFileBoundaryTests
{
    [Fact]
    public void ApplicationIFileNamespaceDoesNotDependOnGraphSdk()
    {
        var result = Types
            .InAssembly(typeof(FileMessageCommand).Assembly)
            .That()
            .ResideInNamespace("TaskMaster.Application.IFile")
            .Should()
            .NotHaveDependencyOn("Microsoft.Graph")
            .GetResult();

        result
            .IsSuccessful.Should()
            .BeTrue(
                "TaskMaster.Application.IFile must not reference the Microsoft Graph SDK. "
                    + "Failing types: "
                    + string.Join(", ", result.FailingTypeNames ?? System.Array.Empty<string>())
            );
    }

    [Fact]
    public void IFileGraphAdaptersResideOnlyInInfrastructure()
    {
        // The concrete Graph adapter types must live in the Infrastructure assembly.
        typeof(GraphMessageMover).Assembly.GetName().Name.Should().Be("TaskMaster.Infrastructure");
        typeof(GraphOneDriveFolderWriter)
            .Assembly.GetName()
            .Name.Should()
            .Be("TaskMaster.Infrastructure");
        typeof(GraphFolderTreeReader)
            .Assembly.GetName()
            .Name.Should()
            .Be("TaskMaster.Infrastructure");
        typeof(GraphAttachmentSource)
            .Assembly.GetName()
            .Name.Should()
            .Be("TaskMaster.Infrastructure");
    }

    [Fact]
    public void ApplicationIFileAdapterInterfacesAreNotImplementedInApplication()
    {
        // No concrete IMessageMover/IOneDriveFolderWriter implementation may live in Application.
        var applicationImplementations = typeof(FileMessageCommand)
            .Assembly.GetTypes()
            .Where(t =>
                t is { IsClass: true, IsAbstract: false }
                && (
                    typeof(IMessageMover).IsAssignableFrom(t)
                    || typeof(IOneDriveFolderWriter).IsAssignableFrom(t)
                    || typeof(IFolderTreeReader).IsAssignableFrom(t)
                    || typeof(IAttachmentSource).IsAssignableFrom(t)
                )
            )
            .ToList();

        applicationImplementations
            .Should()
            .BeEmpty(
                "the Graph/OneDrive adapter implementations must reside in Infrastructure, not Application."
            );
    }
}
