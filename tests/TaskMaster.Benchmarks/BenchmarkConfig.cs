using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Diagnosers;
using BenchmarkDotNet.Exporters.Json;
using BenchmarkDotNet.Jobs;

namespace TaskMaster.Benchmarks;

/// <summary>
/// Shared deterministic configuration for every benchmark class in this project.
/// The configuration favors short, repeatable runs so the comparator in stage 10
/// produces stable inputs: a single fixed-seed short-run job, the memory diagnoser
/// to capture allocations, and the full JSON exporter so percentile statistics
/// (used by <c>scripts/benchmarks/compare-benchmarks.ps1</c>) are emitted.
/// </summary>
public sealed class BenchmarkConfig : ManualConfig
{
    public BenchmarkConfig()
    {
        AddJob(Job.ShortRun.WithId("short-deterministic"));
        AddDiagnoser(MemoryDiagnoser.Default);
        AddExporter(JsonExporter.Full);
    }
}
