namespace TaskMaster.Domain;

/// <summary>
/// Temporary probe: introduces a typed dependency from TaskMaster.Domain to
/// TaskMaster.Infrastructure.Probe so the architecture-test fact
/// `DomainProjectDoesNotDependOnInfrastructure` fails.
/// </summary>
public static class InfraLeak
{
    public static string Leak() => TaskMaster.Infrastructure.Probe.InfraMarker.Name;
}
