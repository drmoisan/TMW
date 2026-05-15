# implement-classify-selected-message — Spec

- **Issue:** #17
- **Parent (optional):** none
- **Owner:** drmoisan
- **Last Updated:** 2026-05-13
- **Status:** Active
- **Version:** 1.0

---

## Overview

The task pane currently displays the subject and sender of the selected message but performs no
classification. This feature establishes the full classify-selected-message path: the task pane
captures the selected message identity and sends it to the backend, the backend normalizes the
fields and classifies the message via a keyword-based classifier, and the task pane presents the
result with "Confirm" and "Reject" training actions. User feedback is sent to a second endpoint,
which records it for future training signal.

The keyword classifier (`KeywordClassifier`) is a deterministic placeholder. It will be replaced
by a SpamBayes engine behind the `IMessageClassifier` interface in a later issue.

---

## Behavior

1. The task pane sends `POST /api/classify` with the message ID, subject, and optional body preview.
2. The backend normalizes the incoming fields into a `MailMessageSnapshot`, calls
   `IMessageClassifier.Classify`, and returns a JSON `ClassificationResult`.
3. The task pane renders the label and confidence percentage and exposes "Confirm" and "Reject"
   buttons.
4. When the user clicks "Confirm" or "Reject," the task pane sends `POST /api/classify/feedback`.
5. The backend calls `ITrainingRepository.RecordAsync` with the feedback and returns HTTP 204.

Both endpoints require an authenticated request (`RequireAuthorization()`). Unauthenticated
requests receive HTTP 401.

---

## Inputs / Outputs

### POST /api/classify

**Request body** (JSON):

```json
{
  "messageId": "string",
  "subject":   "string",
  "body":      "string | null"
}
```

- `messageId`: internet message ID from `Office.js item.internetMessageId`. Required; HTTP 422 if
  absent or whitespace-only.
- `subject`: subject line from `Office.js item.subject`. Required; HTTP 422 if absent or
  whitespace-only.
- `body`: body preview from `Office.js item.body.getAsync`. Optional; null when not loaded.

**Response body** (HTTP 200, JSON):

```json
{
  "label":      "string",
  "confidence": 0.0
}
```

- `label`: one of `"HighPriority"`, `"Promotional"`, `"General"` (values from `ClassificationLabel`).
- `confidence`: double in `[0.0, 1.0]`.

**Error responses:**

| Status | Condition |
|--------|-----------|
| 401    | Missing or invalid bearer token |
| 422    | `messageId` or `subject` is absent or whitespace-only |

---

### POST /api/classify/feedback

**Request body** (JSON):

```json
{
  "messageId": "string",
  "label":     "string",
  "confirmed": true
}
```

- `messageId`: internet message ID of the message the user reviewed.
- `label`: the label the user is confirming or correcting.
- `confirmed`: `true` if the user confirmed the classifier's label; `false` if overriding it.

**Response:** HTTP 204 No Content.

**Error responses:**

| Status | Condition |
|--------|-----------|
| 401    | Missing or invalid bearer token |

---

### Corpus fixtures (inputs to golden tests)

Location: `corpus/classifiers/keyword/` at repository root.

Format (each fixture is a JSON file):

```json
{
  "messageId":   "string",
  "subject":     "string",
  "bodyPreview": "string | null"
}
```

| Filename                    | Subject                                   | Expected label |
|-----------------------------|-------------------------------------------|----------------|
| `urgent-meeting-001.json`   | `"URGENT: Action required by Friday"`     | HighPriority   |
| `newsletter-promo-001.json` | `"Your weekly newsletter — unsubscribe"`  | Promotional    |
| `team-update-001.json`      | `"Team update for Q3 planning"`           | General        |

---

## New Types and Interfaces

All new C# types use file-scoped namespaces and are formatted with CSharpier.

### `TaskMaster.Application` — value objects and interfaces

```csharp
// MailMessageSnapshot.cs
namespace TaskMaster.Application;

/// <summary>
/// Immutable snapshot of a mail item's classifier-relevant fields.
/// </summary>
/// <param name="MessageId">Internet message ID from Office.js item.internetMessageId.</param>
/// <param name="Subject">Subject line, trimmed of leading/trailing whitespace.</param>
/// <param name="BodyPreview">Optional body text preview, trimmed. Null when not loaded.</param>
public sealed record MailMessageSnapshot(string MessageId, string Subject, string? BodyPreview)
{
    /// <summary>
    /// Creates a <see cref="MailMessageSnapshot"/> from raw input, trimming all string fields
    /// and guarding against null or empty required fields.
    /// </summary>
    public static MailMessageSnapshot Create(string messageId, string subject, string? bodyPreview)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(messageId);
        ArgumentException.ThrowIfNullOrWhiteSpace(subject);
        return new MailMessageSnapshot(
            messageId.Trim(),
            subject.Trim(),
            bodyPreview?.Trim()
        );
    }
}
```

```csharp
// ClassificationLabel.cs
namespace TaskMaster.Application;

/// <summary>Known classification label values.</summary>
public static class ClassificationLabel
{
    public const string HighPriority = "HighPriority";
    public const string Promotional  = "Promotional";
    public const string General      = "General";
}
```

```csharp
// ClassificationResult.cs
namespace TaskMaster.Application;

/// <summary>Result of classifying a mail message snapshot.</summary>
/// <param name="Label">One of the values from <see cref="ClassificationLabel"/>.</param>
/// <param name="Confidence">Score in [0.0, 1.0] indicating classifier certainty.</param>
public sealed record ClassificationResult(string Label, double Confidence);
```

```csharp
// IMessageClassifier.cs
namespace TaskMaster.Application;

/// <summary>
/// Classifies a mail message snapshot into a label and confidence score.
/// Implementations must be deterministic for the same input.
/// </summary>
public interface IMessageClassifier
{
    ClassificationResult Classify(MailMessageSnapshot snapshot);
}
```

```csharp
// TrainingFeedback.cs
namespace TaskMaster.Application;

/// <summary>
/// Captures a user's confirmed or corrected classification for training purposes.
/// </summary>
/// <param name="MessageId">Internet message ID identifying the classified message.</param>
/// <param name="Label">The label the user confirmed or assigned.</param>
/// <param name="Confirmed">
/// True if the user confirmed the classifier's label; false if the user overrode it.
/// </param>
/// <param name="RecordedAt">UTC timestamp set by the repository at write time.</param>
public sealed record TrainingFeedback(
    string MessageId,
    string Label,
    bool Confirmed,
    DateTimeOffset RecordedAt
);
```

```csharp
// ITrainingRepository.cs
namespace TaskMaster.Application;

/// <summary>Persistence contract for classifier training feedback.</summary>
public interface ITrainingRepository
{
    /// <summary>
    /// Records a training feedback entry.
    /// Implementations must set <see cref="TrainingFeedback.RecordedAt"/> to the current UTC time.
    /// </summary>
    Task RecordAsync(TrainingFeedback feedback, CancellationToken ct = default);
}
```

---

### `TaskMaster.Classifier` — implementation

```csharp
// KeywordClassifier.cs
namespace TaskMaster.Classifier;

/// <summary>
/// Deterministic keyword-based classifier. First-match wins on subject (case-insensitive).
/// Serves as a placeholder until a probabilistic engine is introduced.
/// </summary>
public sealed class KeywordClassifier : IMessageClassifier
{
    private static readonly (string Keyword, string Label, double Confidence)[] Rules =
    [
        ("urgent",          ClassificationLabel.HighPriority, 0.90),
        ("action required", ClassificationLabel.HighPriority, 0.85),
        ("unsubscribe",     ClassificationLabel.Promotional,  0.90),
        ("newsletter",      ClassificationLabel.Promotional,  0.85),
    ];

    public ClassificationResult Classify(MailMessageSnapshot snapshot)
    {
        ArgumentNullException.ThrowIfNull(snapshot);
        foreach (var (keyword, label, confidence) in Rules)
        {
            if (snapshot.Subject.Contains(keyword, StringComparison.OrdinalIgnoreCase))
                return new ClassificationResult(label, confidence);
        }
        return new ClassificationResult(ClassificationLabel.General, 0.50);
    }
}
```

```csharp
// ClassifierServiceCollectionExtensions.cs
namespace TaskMaster.Classifier;

/// <summary>
/// Extension methods for registering Classifier-layer services in the DI container.
/// </summary>
public static class ClassifierServiceCollectionExtensions
{
    /// <summary>
    /// Registers <see cref="IMessageClassifier"/> → <see cref="KeywordClassifier"/> (Singleton).
    /// KeywordClassifier is stateless; a Singleton lifetime is correct.
    /// </summary>
    public static IServiceCollection AddClassifierServices(this IServiceCollection services)
    {
        services.AddSingleton<IMessageClassifier, KeywordClassifier>();
        return services;
    }
}
```

---

### `TaskMaster.Infrastructure` — in-memory training repository

```csharp
// InMemoryTrainingRepository.cs
namespace TaskMaster.Infrastructure;

/// <summary>
/// Thread-safe, append-only in-memory implementation of <see cref="ITrainingRepository"/>.
/// Stores feedback for the current process lifetime only; no persistence across restarts.
/// </summary>
internal sealed class InMemoryTrainingRepository : ITrainingRepository
{
    private readonly ConcurrentQueue<TrainingFeedback> _store = new();
    private readonly TimeProvider _timeProvider;

    public InMemoryTrainingRepository(TimeProvider timeProvider)
    {
        ArgumentNullException.ThrowIfNull(timeProvider);
        _timeProvider = timeProvider;
    }

    public Task RecordAsync(TrainingFeedback feedback, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(feedback);
        var stamped = feedback with { RecordedAt = _timeProvider.GetUtcNow() };
        _store.Enqueue(stamped);
        return Task.CompletedTask;
    }
}
```

---

### `TaskMaster.Api` — DTOs

All DTOs are `internal sealed record` types in the `TaskMaster.Api` namespace, co-located with
`Program.cs`. They are not shared with other projects.

```csharp
internal sealed record ClassifyRequest(string? MessageId, string? Subject, string? Body);
internal sealed record ClassifyResponse(string Label, double Confidence);
internal sealed record FeedbackRequest(string? MessageId, string? Label, bool Confirmed);
```

---

## API Endpoint Signatures

Both endpoints are registered in `Program.cs` using minimal API `MapPost`. Both call
`RequireAuthorization()`. Neither routes through the command bus; `IMessageClassifier` and
`ITrainingRepository` are injected directly via the handler parameter list.

### POST /api/classify

```csharp
app.MapPost("/api/classify", (ClassifyRequest req, IMessageClassifier classifier) =>
{
    if (string.IsNullOrWhiteSpace(req.MessageId) || string.IsNullOrWhiteSpace(req.Subject))
        return Results.UnprocessableEntity();
    var snapshot = MailMessageSnapshot.Create(req.MessageId, req.Subject, req.Body);
    var result = classifier.Classify(snapshot);
    return Results.Ok(new ClassifyResponse(result.Label, result.Confidence));
}).RequireAuthorization();
```

### POST /api/classify/feedback

```csharp
app.MapPost("/api/classify/feedback",
    async (FeedbackRequest req, ITrainingRepository repo, CancellationToken ct) =>
    {
        var feedback = new TrainingFeedback(
            req.MessageId ?? string.Empty,
            req.Label ?? string.Empty,
            req.Confirmed,
            RecordedAt: default  // overwritten by repository
        );
        await repo.RecordAsync(feedback, ct).ConfigureAwait(false);
        return Results.NoContent();
    }).RequireAuthorization();
```

---

## TypeScript Module Design

### File: `src/taskpane/classifier-client.ts`

#### Exported interfaces

```typescript
export interface ClassifyRequest {
    messageId: string;
    subject:   string;
    body:      string | null;
}

export interface ClassifyResponse {
    label:      string;
    confidence: number;
}

export interface FeedbackRequest {
    messageId: string;
    label:     string;
    confirmed: boolean;
}
```

#### Pure functions (property-test targets)

```typescript
/**
 * Normalizes raw message fields into a ClassifyRequest.
 * Pure function: no side effects. Trims whitespace; coerces undefined body to null.
 */
export function normalizeClassifyRequest(
    messageId: string,
    subject: string,
    body?: string
): ClassifyRequest {
    return {
        messageId: messageId.trim(),
        subject:   subject.trim(),
        body:      body !== undefined ? body.trim() : null,
    };
}

/**
 * Parses and validates an unknown JSON payload as ClassifyResponse.
 * Throws TypeError with a descriptive message when the shape is invalid.
 */
export function parseClassifyResponse(json: unknown): ClassifyResponse {
    if (
        typeof json !== "object" ||
        json === null ||
        typeof (json as Record<string, unknown>)["label"] !== "string" ||
        typeof (json as Record<string, unknown>)["confidence"] !== "number"
    ) {
        throw new TypeError("Invalid classify response shape");
    }
    return {
        label:      (json as Record<string, unknown>)["label"] as string,
        confidence: (json as Record<string, unknown>)["confidence"] as number,
    };
}
```

#### `ClassifierClient` class

```typescript
export class ClassifierClient {
    constructor(private readonly baseUrl: string) {}

    async classify(req: ClassifyRequest, bearerToken: string): Promise<ClassifyResponse> {
        const response = await fetch(`${this.baseUrl}/api/classify`, {
            method:  "POST",
            headers: {
                "Content-Type":  "application/json",
                "Authorization": `Bearer ${bearerToken}`,
            },
            body: JSON.stringify(req),
        });
        if (!response.ok) {
            throw new Error(`classify failed: HTTP ${response.status}`);
        }
        return parseClassifyResponse(await response.json());
    }

    async recordFeedback(req: FeedbackRequest, bearerToken: string): Promise<void> {
        const response = await fetch(`${this.baseUrl}/api/classify/feedback`, {
            method:  "POST",
            headers: {
                "Content-Type":  "application/json",
                "Authorization": `Bearer ${bearerToken}`,
            },
            body: JSON.stringify(req),
        });
        if (!response.ok) {
            throw new Error(`recordFeedback failed: HTTP ${response.status}`);
        }
    }
}
```

The auth token is accepted as a parameter per call rather than stored in the constructor, keeping
the client stateless and testable without an Office runtime. The call site in `taskpane.ts`
acquires the token via `Office.context.auth` and passes it through.

Tests use `msw` (`src/test-support/msw-server.ts` is already wired) to intercept `fetch` without
a real server.

---

## New Project Files

### `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <ImplicitUsings>enable</ImplicitUsings>
        <Nullable>enable</Nullable>
    </PropertyGroup>

    <ItemGroup>
        <InternalsVisibleTo Include="TaskMaster.Classifier.Tests" />
        <InternalsVisibleTo Include="DynamicProxyGenAssembly2" />
    </ItemGroup>

    <ItemGroup>
        <ProjectReference Include="..\TaskMaster.Application\TaskMaster.Application.csproj" />
    </ItemGroup>
</Project>
```

Depends on `TaskMaster.Application` only. Must not reference `TaskMaster.Infrastructure`,
`TaskMaster.Domain` directly, or any COM/VSTO/Office type.

---

### `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
    <PropertyGroup>
        <TargetFramework>net10.0</TargetFramework>
        <ImplicitUsings>enable</ImplicitUsings>
        <IsPackable>false</IsPackable>
        <RunSettingsFilePath>$(MSBuildProjectDirectory)/test.runsettings</RunSettingsFilePath>
    </PropertyGroup>

    <ItemGroup>
        <PackageReference Include="coverlet.collector" />
        <PackageReference Include="Microsoft.NET.Test.Sdk" />
        <PackageReference Include="Verify.XunitV3" />
        <PackageReference Include="xunit.runner.visualstudio" />
        <PackageReference Include="xunit.v3" />
        <PackageReference Include="FluentAssertions" />
        <PackageReference Include="NSubstitute" />
        <PackageReference Include="CsCheck" />
    </ItemGroup>

    <ItemGroup>
        <ProjectReference Include="..\..\src\TaskMaster.Classifier\TaskMaster.Classifier.csproj" />
    </ItemGroup>
</Project>
```

Uses `xunit.v3` (not `xunit` 2.9.3). Do not mix `xunit` and `xunit.v3` in the same project; they
are incompatible. Pattern follows `TaskMaster.PlaceholderGolden.Tests`.

---

## Golden Test Design

### Module initializer

`tests/TaskMaster.Classifier.Tests/VerifyInit.cs`:

```csharp
namespace TaskMaster.Classifier.Tests;

public static class VerifyInit
{
    [ModuleInitializer]
    public static void Initialize() => VerifierSettings.UseStrictJson();
}
```

### Test class

`tests/TaskMaster.Classifier.Tests/KeywordClassifierGoldenTests.cs`:

```csharp
[UsesVerify]
public sealed class KeywordClassifierGoldenTests
{
    private static readonly KeywordClassifier Classifier = new();

    [Theory]
    [InlineData("urgent-meeting-001.json")]
    [InlineData("newsletter-promo-001.json")]
    [InlineData("team-update-001.json")]
    public async Task Classify_CorpusFixture_MatchesVerifiedOutput(string filename)
    {
        var path = Path.Combine(
            AppContext.BaseDirectory,
            "..", "..", "..", "..", "..", // up to repo root
            "corpus", "classifiers", "keyword",
            filename
        );
        var json = await File.ReadAllTextAsync(path);
        var fixture = JsonSerializer.Deserialize<CorpusFixture>(json)!;
        var snapshot = MailMessageSnapshot.Create(
            fixture.MessageId,
            fixture.Subject,
            fixture.BodyPreview
        );

        var result = Classifier.Classify(snapshot);

        await Verify(result).UseParameters(filename);
    }
}
```

- `[UsesVerify]` is required for Verify.XunitV3 to wire the test output directory.
- `Verify(result)` serializes the `ClassificationResult` to a `.verified.json` file.
- `.UseParameters(filename)` makes each corpus entry produce its own named `.verified.json`.
- Committed `.verified.json` files are the golden baselines; they must be checked in alongside the
  test.
- `VerifierSettings.UseStrictJson()` is set by the module initializer.

Verified output example (`KeywordClassifierGoldenTests.Classify_CorpusFixture_MatchesVerifiedOutput_urgent-meeting-001.json.verified.json`):

```json
{
  "Label": "HighPriority",
  "Confidence": 0.9
}
```

### Corpus fixture C# record

```csharp
internal sealed record CorpusFixture(string MessageId, string Subject, string? BodyPreview);
```

---

## Property Test Design

### .NET (CsCheck, in `KeywordClassifierTests.cs`)

**Property: confidence is always in [0.0, 1.0]**

```csharp
[Fact]
public void Classify_AnyValidSnapshot_ConfidenceInRange()
{
    Gen.Select(Gen.String, Gen.String, Gen.String.Null)
        .Sample((messageId, subject, body) =>
        {
            if (string.IsNullOrWhiteSpace(messageId) || string.IsNullOrWhiteSpace(subject))
                return; // MailMessageSnapshot.Create would throw — not the property under test
            var snapshot = MailMessageSnapshot.Create(messageId, subject, body);
            var result = new KeywordClassifier().Classify(snapshot);
            result.Confidence.Should().BeInRange(0.0, 1.0);
        });
}
```

**Property: normalization produces trimmed fields**

```csharp
[Fact]
public void MailMessageSnapshot_Create_TrimsFields()
{
    Gen.Select(Gen.String[1, 50], Gen.String[1, 50])
        .Sample((id, subject) =>
        {
            var padded = $"  {id}  ";
            var paddedSubject = $"\t{subject}\t";
            var snapshot = MailMessageSnapshot.Create(padded, paddedSubject, null);
            snapshot.MessageId.Should().Be(id.Trim());
            snapshot.Subject.Should().Be(subject.Trim());
        });
}
```

### TypeScript (fast-check, in `classifier-client.test.ts`)

**Property: `normalizeClassifyRequest` trims all string inputs**

```typescript
test.prop([fc.string(), fc.string(), fc.option(fc.string(), { nil: undefined })])(
    "normalizeClassifyRequest trims messageId, subject, and body",
    (messageId, subject, body) => {
        const result = normalizeClassifyRequest(messageId, subject, body);
        expect(result.messageId).toBe(messageId.trim());
        expect(result.subject).toBe(subject.trim());
        if (body !== undefined) {
            expect(result.body).toBe(body.trim());
        } else {
            expect(result.body).toBeNull();
        }
    }
);
```

**Property: `parseClassifyResponse` round-trips valid shapes**

```typescript
test.prop([fc.string(), fc.double({ min: 0, max: 1 })])(
    "parseClassifyResponse returns correct fields for valid input",
    (label, confidence) => {
        const result = parseClassifyResponse({ label, confidence });
        expect(result.label).toBe(label);
        expect(result.confidence).toBe(confidence);
    }
);
```

---

## Stryker.NET Configuration

File: `tests/TaskMaster.Classifier.Tests/stryker-config.json`

```json
{
  "stryker-config": {
    "project": "TaskMaster.Classifier.csproj",
    "test-projects": ["TaskMaster.Classifier.Tests.csproj"],
    "mutation-level": "Standard",
    "thresholds": {
      "high": 90,
      "low": 75,
      "break": 75
    },
    "reporters": ["html", "json", "progress"],
    "output-path": "StrykerOutput"
  }
}
```

The `break: 75` threshold causes Stryker to exit with a non-zero code when mutation score
falls below 75%, which blocks the pre-merge pipeline stage.

---

## pre-merge-pipeline.yml Changes

### Stage 8 — Mutation testing (replace stub)

The current Stage 8 stub reads:

```yaml
# Stage 8: Mutation (stub — no T1 module present yet)
- name: stage-8-mutation-stub
  run: echo "No T1 module present; skipping mutation."
```

Replace with a real Stryker.NET invocation:

```yaml
- name: stage-8-mutation-classifier
  run: |
    dotnet tool restore
    dotnet stryker --config-file tests/TaskMaster.Classifier.Tests/stryker-config.json
  working-directory: ${{ github.workspace }}
```

### Stage 9 — Golden tests (extend)

The current Stage 9 runs only `TaskMaster.PlaceholderGolden.Tests`. Extend to also run
`TaskMaster.Classifier.Tests`:

```yaml
- name: stage-9-golden
  run: |
    dotnet test tests/TaskMaster.PlaceholderGolden.Tests/TaskMaster.PlaceholderGolden.Tests.csproj --no-build
    dotnet test tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj --no-build
```

---

## Architecture Boundary Test Update

### `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj`

Add a project reference:

```xml
<ProjectReference Include="..\..\src\TaskMaster.Classifier\TaskMaster.Classifier.csproj" />
```

### New fact in `LayerBoundaryTests.cs`

```csharp
[Fact]
public void ClassifierProjectDoesNotDependOnInfrastructure()
{
    var result = Types
        .InAssembly(typeof(KeywordClassifier).Assembly)
        .Should()
        .NotHaveDependencyOn("TaskMaster.Infrastructure")
        .GetResult();

    result.IsSuccessful.Should().BeTrue();
}
```

The `NoComArchitectureTests` block that loads all `TaskMaster.*` assemblies via
`AppDomain.CurrentDomain.GetAssemblies()` automatically covers `TaskMaster.Classifier` once the
architecture test project holds the project reference; no additional `NoComArchitecture` fact is
required.

---

## DI Registration Changes

### `src/TaskMaster.Api/Program.cs`

Add a call to `AddClassifierServices()` and a `using` directive for `TaskMaster.Classifier`:

```csharp
using TaskMaster.Classifier;
// ...
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddClassifierServices();   // new
```

### `src/TaskMaster.Infrastructure/InfrastructureServiceCollectionExtensions.cs`

Add `ITrainingRepository → InMemoryTrainingRepository` (Singleton, same lifetime pattern as
`InMemoryUserSettingsRepository`):

```csharp
services.AddSingleton<ITrainingRepository>(_ => new InMemoryTrainingRepository(
    TimeProvider.System
));
```

---

## quality-tiers.yml Additions

```yaml
- name: TaskMaster.Classifier
  path: src/TaskMaster.Classifier
  language: csharp
  tier: t1
  rationale: |
    T1 classifier engine. KeywordClassifier is the deterministic placeholder for the
    message classification pipeline. Mis-classification bugs affect downstream triage
    decisions silently; T1 rigor is required. Mutation score >= 75% enforced in pre-merge.

- name: TaskMaster.Classifier.Tests
  path: tests/TaskMaster.Classifier.Tests
  language: csharp
  tier: t4
  rationale: |
    Test scaffolding (T4): xunit.v3 + Verify.XunitV3 + CsCheck tests for
    TaskMaster.Classifier. Tier reflects test-infrastructure role; production
    code under test (KeywordClassifier) is tiered T1.
```

---

## Complete Inputs / Outputs Table

| Component | Input | Output |
|-----------|-------|--------|
| `POST /api/classify` | JSON: `messageId`, `subject`, `body?` | JSON: `label`, `confidence` or HTTP 422/401 |
| `POST /api/classify/feedback` | JSON: `messageId`, `label`, `confirmed` | HTTP 204 or HTTP 401 |
| `MailMessageSnapshot.Create` | Raw strings (messageId, subject, body?) | Trimmed `MailMessageSnapshot` or throws |
| `KeywordClassifier.Classify` | `MailMessageSnapshot` | `ClassificationResult` (label + confidence) |
| `InMemoryTrainingRepository.RecordAsync` | `TrainingFeedback` | Side effect: enqueues stamped feedback |
| `normalizeClassifyRequest` (TS) | `messageId`, `subject`, `body?` | `ClassifyRequest` with trimmed fields |
| `parseClassifyResponse` (TS) | `unknown` JSON payload | `ClassifyResponse` or throws `TypeError` |
| `ClassifierClient.classify` (TS) | `ClassifyRequest`, bearer token | `Promise<ClassifyResponse>` or throws |
| `ClassifierClient.recordFeedback` (TS) | `FeedbackRequest`, bearer token | `Promise<void>` or throws |
| Golden test runner | Corpus fixture JSON | `.verified.json` diff (pass/fail) |
| Stryker.NET | `TaskMaster.Classifier` assembly | Mutation score (break at 75%) |

---

## Constraints and Risks

- `KeywordClassifier` is a deterministic placeholder. It will be replaced behind
  `IMessageClassifier` in a later issue. Do not add state, ML model loading, or I/O to it.
- `TaskMaster.Classifier` must not reference `TaskMaster.Infrastructure`, Outlook PIA, VSTO,
  or any COM type. This is enforced by the architecture boundary test.
- `MailMessageSnapshot.BodyPreview` is optional. Normalization must handle null/empty body;
  the keyword classifier falls back to `General` when no keyword matches in the subject.
- `POST /api/classify` requires `RequireAuthorization()`. Tests use `TestAuthHandler` from
  `TaskMaster.Api.Tests`.
- All new .NET code must pass `dotnet csharpier check .` and produce zero analyzer warnings
  under `TreatWarningsAsErrors=true`.
- Coverage floor: line >= 85%, branch >= 75% across all tiers (T1–T4).
- `xunit.v3` and `xunit` 2.9.3 must not appear together in `TaskMaster.Classifier.Tests.csproj`;
  they are binary-incompatible.
- `ICommandBus` is not widened by this feature. Classification routes directly through
  `IMessageClassifier`; training feedback routes directly through `ITrainingRepository`.
- No new NuGet packages are required. All needed packages (`xunit.v3`, `Verify.XunitV3`,
  `CsCheck`, `FluentAssertions`, `NSubstitute`, `coverlet.collector`) are already pinned in
  `Directory.Packages.props`.

---

## Implementation Scope (Complete File List)

### New production files

| Path | Purpose |
|------|---------|
| `src/TaskMaster.Application/MailMessageSnapshot.cs` | Value object with `Create` factory |
| `src/TaskMaster.Application/ClassificationLabel.cs` | String constants |
| `src/TaskMaster.Application/ClassificationResult.cs` | Result record |
| `src/TaskMaster.Application/IMessageClassifier.cs` | Classifier interface |
| `src/TaskMaster.Application/TrainingFeedback.cs` | Feedback value object |
| `src/TaskMaster.Application/ITrainingRepository.cs` | Training persistence interface |
| `src/TaskMaster.Classifier/TaskMaster.Classifier.csproj` | T1 project file |
| `src/TaskMaster.Classifier/KeywordClassifier.cs` | Deterministic keyword classifier |
| `src/TaskMaster.Classifier/ClassifierServiceCollectionExtensions.cs` | DI registration |
| `src/TaskMaster.Infrastructure/InMemoryTrainingRepository.cs` | In-memory feedback store |
| `src/taskpane/classifier-client.ts` | TypeScript fetch client |

### Modified files

| Path | Change |
|------|--------|
| `src/TaskMaster.Infrastructure/InfrastructureServiceCollectionExtensions.cs` | Register `ITrainingRepository` |
| `src/TaskMaster.Api/Program.cs` | Add both endpoints; call `AddClassifierServices()` |
| `tests/TaskMaster.ArchitectureTests/LayerBoundaryTests.cs` | Add classifier boundary fact |
| `tests/TaskMaster.ArchitectureTests/TaskMaster.ArchitectureTests.csproj` | Add classifier project reference |
| `quality-tiers.yml` | Add two new entries |
| `TaskMaster.sln` | Add both new projects |
| `.github/workflows/pre-merge-pipeline.yml` | Replace Stage 8 stub; extend Stage 9 |

### New test files

| Path | Purpose |
|------|---------|
| `tests/TaskMaster.Classifier.Tests/TaskMaster.Classifier.Tests.csproj` | xunit.v3 + Verify project |
| `tests/TaskMaster.Classifier.Tests/VerifyInit.cs` | Module initializer |
| `tests/TaskMaster.Classifier.Tests/KeywordClassifierTests.cs` | Unit + CsCheck property tests |
| `tests/TaskMaster.Classifier.Tests/KeywordClassifierGoldenTests.cs` | Corpus-driven golden tests |
| `tests/TaskMaster.Classifier.Tests/Generators/MailMessageSnapshotGen.cs` | CsCheck generator |
| `tests/TaskMaster.Classifier.Tests/*.verified.json` (3 files) | Committed golden baselines |
| `tests/TaskMaster.Classifier.Tests/stryker-config.json` | Stryker configuration |
| `tests/TaskMaster.Api.Tests/ClassifyEndpointTests.cs` | Integration tests for `/api/classify` |
| `tests/TaskMaster.Api.Tests/FeedbackEndpointTests.cs` | Integration tests for `/api/classify/feedback` |
| `src/taskpane/classifier-client.test.ts` | Vitest unit + property tests |
| `corpus/classifiers/keyword/urgent-meeting-001.json` | Corpus fixture |
| `corpus/classifiers/keyword/newsletter-promo-001.json` | Corpus fixture |
| `corpus/classifiers/keyword/team-update-001.json` | Corpus fixture |

---

## Definition of Done

- [ ] All acceptance criteria in `issue.md` are satisfied and checked off.
- [ ] `dotnet build TaskMaster.sln` passes with 0 errors and 0 warnings.
- [ ] `dotnet test TaskMaster.sln` passes (all tests green, line >= 85%, branch >= 75%).
- [ ] `npm run test` passes (all TypeScript tests green).
- [ ] `dotnet csharpier check .` passes with no formatting violations.
- [ ] Architecture boundary tests pass (classifier must not reference Infrastructure, PIA, or VSTO).
- [ ] `.verified.json` files for all three corpus fixtures are committed.
- [ ] `stryker-config.json` is present in `tests/TaskMaster.Classifier.Tests/`.
- [ ] `quality-tiers.yml` includes entries for `TaskMaster.Classifier` (t1) and
      `TaskMaster.Classifier.Tests` (t4).
- [ ] pre-merge pipeline Stage 8 stub is replaced with a real Stryker.NET run.
- [ ] pre-merge pipeline Stage 9 runs both golden test projects.
