namespace TaskMaster.Worker.Tests.Reconciliation;

/// <summary>
/// Minimal model of a Graph delta event used by the reconciliation property
/// tests. Until Prompt G2 introduces the production reconciliation handler
/// this stub captures only the algebraic shape: an ordered identifier and an
/// integer payload that is folded into the reconciled state.
/// </summary>
public sealed record DeltaEvent(int Id, int Payload);
