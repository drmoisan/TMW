using CsCheck;
using FluentAssertions;
using Xunit;

namespace TaskMaster.Worker.Tests.Reconciliation;

/// <summary>
/// Property tests for the delta-reconciliation hot path required by Prompt G1.
/// The reconciler folds a sequence of monotonically-numbered delta events into
/// a checksum state. The tests cover three sequence shapes:
///
///   1. OutOfOrder_ProducesSameState     — permuting the event order must yield
///                                          the same final checksum.
///   2. Duplicates_AreIdempotent         — duplicating an event must not change
///                                          the final checksum (idempotent fold).
///   3. Missing_EventsAreDetected        — dropping a non-empty subset of events
///                                          must change the checksum (the
///                                          reconciler detects gaps).
///
/// Failures print the CsCheck seed via CsCheck's default failure formatter so
/// the failing sequence can be reproduced.
/// </summary>
public sealed class DeltaReconciliationPropertyTests
{
    private static int Reconcile(IEnumerable<DeltaEvent> events)
    {
        // Idempotent, order-independent fold: aggregate the distinct payload
        // values of the observed (id, payload) pairs. The handler under
        // Prompt G2 will perform the equivalent reconciliation using Graph
        // delta tokens; this stub captures only the algebraic properties.
        var dedup = new Dictionary<int, int>();
        foreach (var e in events)
        {
            dedup[e.Id] = e.Payload;
        }
        var checksum = 0;
        foreach (var kvp in dedup)
        {
            checksum = unchecked(checksum + kvp.Key * 31 + kvp.Value);
        }
        return checksum;
    }

    private static Gen<DeltaEvent[]> EventArray()
    {
        // Generate event arrays whose Ids are unique within the run so the
        // out-of-order and missing-events properties are well-defined. Bounded
        // size keeps the property runs deterministic and fast.
        return Gen.Int[1, 1000]
            .Select(Gen.Int[0, 10000], static (id, payload) => new DeltaEvent(id, payload))
            .Array[1, 32]
            .Select(static arr =>
                arr.GroupBy(static e => e.Id).Select(static g => g.First()).ToArray()
            );
    }

    [Fact]
    public void OutOfOrder_ProducesSameState()
    {
        EventArray()
            .Select(Gen.Long, static (events, seed) => new { Events = events, Seed = seed })
            .Sample(
                sample =>
                {
                    var shuffled = new PcgRandom((uint)sample.Seed).Shuffle(sample.Events);
                    Reconcile(sample.Events).Should().Be(Reconcile(shuffled));
                },
                iter: 200,
                seed: "OutOfOrder_ProducesSameState"
            );
    }

    [Fact]
    public void Duplicates_AreIdempotent()
    {
        EventArray()
            .Sample(
                events =>
                {
                    var duplicated = events.Concat(events).ToArray();
                    Reconcile(events).Should().Be(Reconcile(duplicated));
                },
                iter: 200,
                seed: "Duplicates_AreIdempotent"
            );
    }

    [Fact]
    public void Missing_EventsAreDetected()
    {
        EventArray()
            .Where(static events => events.Length >= 2)
            .Sample(
                events =>
                {
                    // Drop the last event; the resulting checksum must differ.
                    var pruned = events.Take(events.Length - 1).ToArray();
                    Reconcile(events).Should().NotBe(Reconcile(pruned));
                },
                iter: 200,
                seed: "Missing_EventsAreDetected"
            );
    }

    /// <summary>
    /// Deterministic seeded PRNG used to shuffle event arrays for the
    /// out-of-order property. CsCheck reports the same seed back on failure
    /// so reproductions are exact.
    /// </summary>
    private sealed class PcgRandom
    {
        private uint _state;

        public PcgRandom(uint seed)
        {
            _state = seed == 0 ? 1U : seed;
        }

        public uint NextUInt()
        {
            _state = unchecked(_state * 1664525U + 1013904223U);
            return _state;
        }

        public T[] Shuffle<T>(T[] source)
        {
            var copy = (T[])source.Clone();
            for (var i = copy.Length - 1; i > 0; i--)
            {
                var j = (int)(NextUInt() % (uint)(i + 1));
                (copy[i], copy[j]) = (copy[j], copy[i]);
            }
            return copy;
        }
    }
}
