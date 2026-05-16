using BenchmarkDotNet.Attributes;
using TaskMaster.Application;
using TaskMaster.Classifier;

namespace TaskMaster.Benchmarks;

/// <summary>
/// Benchmarks for the Prompt D2 classifier hot paths. Three benchmarks are
/// declared corresponding to the spec's hot-path enumeration:
///   1. Classify_Command — invokes <see cref="KeywordClassifier.Classify"/>
///      on a pre-built <see cref="MailMessageSnapshot"/>.
///   2. InputNormalization_EdgePath — exercises
///      <see cref="MailMessageSnapshot.Create(string, string, string?)"/> with
///      inputs that require trimming and conditional body-preview handling.
///   3. TrainingState_Update — drives an in-memory training repository through
///      a record-feedback cycle so the bench captures dictionary allocation
///      and lookup costs that the production training path will exercise.
/// All inputs are constructed once in <see cref="GlobalSetup"/> and reused so
/// the measured region exercises only the path under test.
/// </summary>
[Config(typeof(BenchmarkConfig))]
public class ClassifierBenchmarks
{
    private KeywordClassifier _classifier = null!;
    private MailMessageSnapshot _snapshot = null!;
    private InMemoryTrainingRepository _trainingRepository = null!;
    private TrainingFeedback _feedback = null!;

    [GlobalSetup]
    public void GlobalSetup()
    {
        _classifier = new KeywordClassifier();
        _snapshot = new MailMessageSnapshot(
            "msg-0001",
            "URGENT: action required on quarterly report",
            "Please review the attached report and confirm by EOD."
        );
        _trainingRepository = new InMemoryTrainingRepository();
        _feedback = new TrainingFeedback(
            "msg-0001",
            ClassificationLabel.HighPriority,
            true,
            new DateTimeOffset(2026, 5, 15, 12, 0, 0, TimeSpan.Zero)
        );
    }

    [Benchmark]
    public ClassificationResult Classify_Command()
    {
        return _classifier.Classify(_snapshot);
    }

    [Benchmark]
    public MailMessageSnapshot InputNormalization_EdgePath()
    {
        return MailMessageSnapshot.Create(
            "  msg-0001  ",
            "  URGENT: action required  ",
            "  Please review the attached report.  "
        );
    }

    [Benchmark]
    public int TrainingState_Update()
    {
        _trainingRepository.Record(_feedback);
        return _trainingRepository.Count;
    }

    private sealed class InMemoryTrainingRepository
    {
        private readonly Dictionary<string, TrainingFeedback> _store = new(StringComparer.Ordinal);

        public int Count => _store.Count;

        public void Record(TrainingFeedback feedback)
        {
            _store[feedback.MessageId] = feedback;
        }
    }
}
