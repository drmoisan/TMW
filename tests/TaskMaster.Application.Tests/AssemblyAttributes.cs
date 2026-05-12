using System.Runtime.CompilerServices;

// Allow Castle.DynamicProxy (used by NSubstitute) to generate proxies for
// internal types in this test assembly.
[assembly: InternalsVisibleTo("DynamicProxyGenAssembly2")]
