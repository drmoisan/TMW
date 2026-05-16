using BenchmarkDotNet.Running;

namespace TaskMaster.Benchmarks;

/// <summary>
/// Entry point for the BenchmarkDotNet runner. Delegates discovery to
/// <see cref="BenchmarkSwitcher"/> so individual benchmarks can be selected
/// via command-line filters (for example, <c>--filter "*ClassifierBenchmarks*"</c>).
/// </summary>
public static class Program
{
    public static int Main(string[] args)
    {
        BenchmarkSwitcher.FromAssembly(typeof(Program).Assembly).Run(args);
        return 0;
    }
}
