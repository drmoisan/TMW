using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using TaskMaster.Application.IFile;

namespace TaskMaster.Api.Tests.IFile;

/// <summary>
/// Integration tests for the iFile endpoints (AC-10, AC-12). Uses an authenticated factory with
/// substituted folder reader and filing command handler so the endpoints exercise the
/// dispatch/response seam without real Graph. The unauthenticated cases assert 401.
/// </summary>
public sealed class IFileEndpointsTests : IClassFixture<FilingWebApplicationFactory>
{
    private static readonly Uri s_fileUri = new("/api/ifile/file", UriKind.Relative);
    private static readonly Uri s_foldersUri = new("/api/ifile/folders", UriKind.Relative);
    private readonly FilingWebApplicationFactory _factory;

    public IFileEndpointsTests(FilingWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task PostFile_Authenticated_ReturnsSuccessOutcome()
    {
        // Arrange
        _factory.HandlerResult = FileMessageResult.Success();
        using var client = CreateAuthenticatedClient();
        var payload = new
        {
            messageRestId = "msg-1",
            destinationFolderId = "acme",
            archiveRootDriveItemId = "drive-root",
        };

        // Act
        using var response = await client.PostAsJsonAsync(s_fileUri, payload).ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>().ConfigureAwait(true);
        body.GetProperty("outcome").GetString().Should().Be("success");
    }

    [Fact]
    public async Task PostFile_PreMoveFailure_ReturnsPreMoveFailureOutcome()
    {
        // Arrange
        _factory.HandlerResult = FileMessageResult.PreMoveFailure("OneDrive folder create failed");
        using var client = CreateAuthenticatedClient();
        var payload = new { messageRestId = "msg-1", destinationFolderId = "acme" };

        // Act
        using var response = await client.PostAsJsonAsync(s_fileUri, payload).ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>().ConfigureAwait(true);
        body.GetProperty("outcome").GetString().Should().Be("preMoveFailure");
        body.GetProperty("error").GetString().Should().Be("OneDrive folder create failed");
    }

    [Fact]
    public async Task GetFolders_Authenticated_ReturnsFlatLeafList()
    {
        // Arrange
        using var client = CreateAuthenticatedClient();

        // Act
        using var response = await client.GetAsync(s_foldersUri).ConfigureAwait(true);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>().ConfigureAwait(true);
        var folders = body.GetProperty("folders");
        folders.GetArrayLength().Should().Be(1);
        folders[0].GetProperty("displayName").GetString().Should().Be("Acme");
    }

    [Fact]
    public async Task PostFile_WithoutAuthorization_Returns401()
    {
        // Arrange
        var unauth = new UnauthenticatedWebApplicationFactory();
        await using (unauth.ConfigureAwait(false))
        {
            using var client = unauth.CreateClient(
                new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
            );

            // Act
            using var response = await client
                .PostAsJsonAsync(s_fileUri, new { messageRestId = "m", destinationFolderId = "d" })
                .ConfigureAwait(true);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }
    }

    [Fact]
    public async Task GetFolders_WithoutAuthorization_Returns401()
    {
        // Arrange
        var unauth = new UnauthenticatedWebApplicationFactory();
        await using (unauth.ConfigureAwait(false))
        {
            using var client = unauth.CreateClient(
                new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
            );

            // Act
            using var response = await client.GetAsync(s_foldersUri).ConfigureAwait(true);

            // Assert
            response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
        }
    }

    private HttpClient CreateAuthenticatedClient()
    {
        var client = _factory.CreateClient(
            new WebApplicationFactoryClientOptions { AllowAutoRedirect = false }
        );
        client.DefaultRequestHeaders.Add("Authorization", "Test");
        return client;
    }
}
