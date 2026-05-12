using System.Text.Json;
using FluentAssertions;
using Microsoft.Extensions.Options;
using Microsoft.Extensions.Time.Testing;
using NSubstitute;
using TaskMaster.Application;
using TaskMaster.Infrastructure;

namespace TaskMaster.Infrastructure.Tests;

/// <summary>
/// Unit tests for <see cref="JsonFileUserSettingsRepository"/> using NSubstitute to mock
/// <see cref="IFileWriter"/>. No real filesystem access occurs in these tests.
/// </summary>
public sealed class JsonFileUserSettingsRepositoryTests
{
    private const string FilePath = "/fake/settings.json";
    private const string TempPath = "/fake/settings.json.tmp";

    private static readonly JsonSerializerOptions s_jsonOptions = new(JsonSerializerDefaults.Web);

    private static JsonFileUserSettingsRepository CreateSut(
        IFileWriter fileWriter,
        FakeTimeProvider? clock = null
    )
    {
        var options = Options.Create(new UserSettingsFileOptions { FilePath = FilePath });
        return new JsonFileUserSettingsRepository(
            options,
            fileWriter,
            clock ?? new FakeTimeProvider()
        );
    }

    private static string SerializeStore(Dictionary<string, UserSettings> store) =>
        JsonSerializer.Serialize(store, s_jsonOptions);

    [Fact]
    public async Task GetAsync_WhenFileNotFound_ReturnsNull()
    {
        // Arrange
        var fileWriter = Substitute.For<IFileWriter>();
        fileWriter.Exists(FilePath).Returns(false);
        using var sut = CreateSut(fileWriter);

        // Act
        var result = await sut.GetAsync("user1").ConfigureAwait(true);

        // Assert
        result.Should().BeNull();
    }

    [Fact]
    public async Task SaveAsync_WritesToTempFileAndCallsReplace()
    {
        // Arrange
        var fileWriter = Substitute.For<IFileWriter>();
        fileWriter.Exists(FilePath).Returns(true);
        fileWriter.ReadAllTextAsync(FilePath, default).Returns(SerializeStore([]));
        var clock = new FakeTimeProvider();
        using var sut = CreateSut(fileWriter, clock);
        var settings = new UserSettings("user1", true, false, default);

        // Act
        await sut.SaveAsync(settings).ConfigureAwait(true);

        // Assert
        await fileWriter
            .Received(1)
            .WriteAllTextAsync(TempPath, Arg.Any<string>(), Arg.Any<CancellationToken>())
            .ConfigureAwait(true);
        fileWriter.Received(1).Replace(TempPath, FilePath, null);
    }

    [Fact]
    public async Task DeleteAsync_RemovesEntryAndWritesBack()
    {
        // Arrange
        var userId = "user-to-delete";
        var existingSettings = new UserSettings(userId, true, true, DateTimeOffset.UtcNow);
        var store = new Dictionary<string, UserSettings>(StringComparer.Ordinal)
        {
            [userId] = existingSettings,
        };

        var fileWriter = Substitute.For<IFileWriter>();
        fileWriter.Exists(FilePath).Returns(true);
        fileWriter.ReadAllTextAsync(FilePath, default).ReturnsForAnyArgs(SerializeStore(store));
        using var sut = CreateSut(fileWriter);

        // Act
        await sut.DeleteAsync(userId).ConfigureAwait(true);

        // Assert — verify the content written to the temp file does not include the deleted user
        await fileWriter
            .Received(1)
            .WriteAllTextAsync(
                TempPath,
                Arg.Is<string>(json => !json.Contains(userId, StringComparison.Ordinal)),
                Arg.Any<CancellationToken>()
            )
            .ConfigureAwait(true);
    }
}
