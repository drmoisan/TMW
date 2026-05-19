using BenchmarkDotNet.Configs;
using BenchmarkDotNet.Diagnosers;
using BenchmarkDotNet.Exporters.Json;
using BenchmarkDotNet.Jobs;

namespace TaskMaster.Benchmarks;

/// <summary>
/// Shared deterministic configuration for every benchmark class in this project.
/// Uses 5 warmup + 20 measurement iterations chosen so the gated median statistic
/// is stable against single-iteration jitter on shared CI runners. Includes the
/// memory diagnoser to capture allocations and the full JSON exporter for downstream analysis.
/// </summary>
public sealed class BenchmarkConfig : ManualConfig
{
    public BenchmarkConfig()
    {
        AddJob(Job.Default.WithWarmupCount(5).WithIterationCount(20).WithId("stage-10-stable"));
        AddDiagnoser(MemoryDiagnoser.Default);
        AddExporter(JsonExporter.Full);
    }
}
