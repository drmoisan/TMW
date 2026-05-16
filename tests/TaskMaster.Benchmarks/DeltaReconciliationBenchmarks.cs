using BenchmarkDotNet.Attributes;

namespace TaskMaster.Benchmarks;

/// <summary>
/// Disabled placeholder benchmark for the Phase G delta-reconciliation hot path.
/// Prompt G1 of the No-COM architecture migration requires that the slot exist
/// before Prompt G2 introduces the underlying handler; the benchmark is gated
/// behind the <c>ENABLE_G2_BENCHMARK</c> compile-time symbol so the benchmark
/// list visible to stage 10 remains stable until G2 enables it.
/// </summary>
[Config(typeof(BenchmarkConfig))]
[BenchmarkCategory("g2-pending")]
public class DeltaReconciliationBenchmarks
{
    // TODO(G2): enable once delta-reconciliation handler exists in production.
    [Benchmark]
    public int DeltaReconciliation_Apply()
    {
#if ENABLE_G2_BENCHMARK
        // Reserved for Prompt G2. The implementation will replay an in-memory
        // ordered batch of Graph delta events through the reconciliation
        // handler and return the post-state checksum.
        return 0;
#else
        throw new NotSupportedException("Disabled; awaiting Prompt G2");
#endif
    }
}
