using System.Diagnostics;
using FluentAssertions;
using Xunit;

namespace TaskMaster.Worker.Tests.SelfValidation;

/// <summary>
/// Self-validation gate for the benchmark regression comparator. Invokes
/// <c>scripts/benchmarks/compare-benchmarks.ps1</c> against the committed
/// synthetic latency-regression fixture and asserts the comparator exits
/// non-zero. This test belongs to the same self-validation lane as
/// <see cref="Subscriptions.NonIdempotentHandlerNegativeTests"/> and is
/// excluded from the default test lane by category trait. Both negative-path
/// self-validations together demonstrate AC7 (latency regression blocks PR)
/// and AC8 (non-idempotent handler is detected).
/// </summary>
[Trait("Category", "benchmark-gate-self-validation")]
public sealed class LatencyRegressionGateTests
{
    [Fact]
    public void Comparator_OnSyntheticLatencyRegressionFixture_ExitsNonZero()
    {
        var repoRoot = LocateRepoRoot();
        var baseline = Path.Combine(repoRoot, "artifacts", "benchmarks", "baseline.json");
        var fixture = Path.Combine(
            repoRoot,
            "tests",
            "TaskMaster.Benchmarks",
            "Fixtures",
            "SyntheticLatencyRegressionFixture.json"
        );
        var script = Path.Combine(repoRoot, "scripts", "benchmarks", "compare-benchmarks.ps1");

        File.Exists(baseline).Should().BeTrue($"baseline must exist at {baseline}");
        File.Exists(fixture).Should().BeTrue($"fixture must exist at {fixture}");
        File.Exists(script).Should().BeTrue($"comparator must exist at {script}");

        var psi = new ProcessStartInfo
        {
            FileName = "pwsh",
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            WorkingDirectory = repoRoot,
        };
        psi.ArgumentList.Add("-NoProfile");
        psi.ArgumentList.Add("-File");
        psi.ArgumentList.Add(script);
        psi.ArgumentList.Add("-BaselinePath");
        psi.ArgumentList.Add(baseline);
        psi.ArgumentList.Add("-CurrentPath");
        psi.ArgumentList.Add(fixture);
        psi.ArgumentList.Add("-T1BenchmarkIdPattern");
        psi.ArgumentList.Add("ClassifierBenchmarks");

        using var process = Process.Start(psi);
        process.Should().NotBeNull();
        process!.WaitForExit(60_000).Should().BeTrue("comparator must complete within 60s");

        process
            .ExitCode.Should()
            .NotBe(
                0,
                "comparator must fail on a synthetic median latency regression against a T1 benchmark id that exceeds both the 5% relative threshold and the absolute-delta floor"
            );
    }

    private static string LocateRepoRoot()
    {
        var dir = new DirectoryInfo(AppContext.BaseDirectory);
        while (dir is not null)
        {
            if (File.Exists(Path.Combine(dir.FullName, "TaskMaster.sln")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }
        throw new InvalidOperationException("Could not locate repo root from test base directory.");
    }
}
