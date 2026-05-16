# `metadata-schema-evolution-infra` — User Story

- Issue: #22
- Owner: drmoisan
- Status: Draft
- Last Updated: 2026-05-15

## Story Statements

- As a developer shipping a metadata payload change, I want the PR pipeline to block on a breaking schema change without a version bump, so that incompatible changes cannot reach production undetected.
- As a release engineer, I want the nightly pipeline to verify forward and backward compatibility across the last three schema versions, so that data written by prior deployments remains readable after an upgrade.

## Problem / Why

TaskMaster metadata payloads (classification results, user settings, training-state references, and planned types including task metadata and migration provenance) are serialized and persisted with no schema versioning and no compatibility gate. A developer can remove a required field, rename a property, or narrow a type and the change reaches production silently. Data written by an older deployment becomes unreadable by a newer one with no signal before or after deployment.

Before any metadata is written at scale to Microsoft Graph open extensions or a backend store, the write paths need schema validation and the CI pipeline needs a gate that catches breaking schema changes at the point of code review.

## Personas & Scenarios

### Persona: Developer shipping a metadata payload change

- **Who they are:** A backend developer modifying one of the Application-layer payload types (`ClassificationResult`, `UserSettings`, `TrainingFeedback`, or a future type).
- **What they care about:** Catching mistakes early, in their own PR, before they affect teammates or production data.
- **Their constraints:** They do not want to maintain schema version directories manually for every additive change — only breaking changes should require a version bump.
- **Goals:** Ship payload changes confidently, knowing that if they accidentally break compatibility the pipeline will tell them before merge.
- **Frustrations:** Silent failures where corrupt data is written and only discovered at runtime or by a downstream consumer.

**Scenario — Breaking change caught at PR:**

1. The developer removes the `confidence` field from `ClassificationResult` to simplify the type.
2. They open a PR. Stage 6 of the PR pipeline runs the schema-contract action.
3. The action extracts the baseline `classification-result.schema.json` from `origin/main` and compares it to the current file.
4. The action detects that `confidence` was a required property and is now absent — a breaking change.
5. The PR pipeline fails with a clear message: "Breaking change detected in `schemas/v1/classification-result.schema.json`: required property `confidence` removed. Create `schemas/v2/` to allow this change."
6. The developer either restores `confidence` or creates `/schemas/v2/classification-result.schema.json` with the evolved shape, adds a v2 fixture, and updates the PR. The pipeline passes.

**Scenario — Additive change passes without version bump:**

1. The developer adds an optional `sourceMailboxId` field to `user-settings.schema.json` in place (no v2 directory).
2. Stage 6 runs the schema-contract action. The action classifies the change as non-breaking (new optional property).
3. The pipeline passes without requiring a version bump.

### Persona: Release engineer

- **Who they are:** The engineer responsible for verifying that a new deployment does not corrupt or lose access to data written by the prior deployment.
- **What they care about:** Knowing that old on-disk `UserSettings` files and any future Graph-persisted payloads are still readable after upgrading the application.
- **Their constraints:** They need a repeatable, automated check — they cannot manually validate every payload type against every prior schema version before every release.
- **Goals:** Confidence that the nightly build will surface any forward- or backward-compatibility regression introduced during the day's development.
- **Frustrations:** Discovering compatibility breaks post-deployment, after data has been written in an incompatible format.

**Scenario — Nightly forward-compat regression detected:**

1. During the previous day, a developer modifies `user-settings.schema.json` in a way that passes the PR-time breaking-change check (it was classified as non-breaking), but inadvertently causes the new C# deserializer to reject fixtures written under v1.
2. The nightly pipeline runs `stage-14-schema-evolution`, which executes `SchemaCompatibilityTests` in `tests/TaskMaster.Schema.Tests`.
3. `SchemaCompatibilityTests.V1Fixture_PassesV2Schema` fails because the v1 `user-settings.valid.json` fixture contains a field that the v2 schema now rejects under `additionalProperties: false`.
4. The release engineer sees the failing stage, identifies the regression, and the team resolves it before any user-facing deployment.

**Scenario — All versions compatible; nightly passes:**

1. No schema changes were made during the day.
2. The nightly pipeline runs `stage-14-schema-evolution`. All fixture-vs-schema combinations pass.
3. The release engineer has a green signal that the current build is forward- and backward-compatible with prior deployments.

## Acceptance Criteria

- [x] `/schemas/v1/` contains JSON Schema files for: classification result, task metadata, tag set, training-state reference, migration provenance.
- [x] Backend write paths reject payloads that fail schema validation (test coverage required).
- [x] Forward-compat tests: v1 fixtures are readable by v1 code (baseline); on introduction of v2, v1 fixtures are readable by v2 code.
- [x] Backward-compat tests: payloads written by current code pass the N-1 schema.
- [x] PR pipeline stage 6 blocks merge on a breaking schema change without a version bump.
- [x] Nightly pipeline stage 14 runs schema-evolution tests against the last three schema versions.
- [x] An incompatible schema change without a version bump is detected and blocks the build (validation scenario).
- [x] A version bump combined with the appropriate compat fixture passes (validation scenario).

## Non-Goals

- Defining or implementing `TodoItem`, `TaskMetadata`, `TaskMasterTag`, `ClassifierTrainingExample`, or `AuditEvent` as C# types. This feature creates stub schemas for two of these types but does not implement the runtime types.
- Implementing a Graph open extension write path. Schemas for Graph-persisted payloads are defined here, but the adapter that writes them to Graph is out of scope.
- Automating schema migration or data backfill. When a breaking change is introduced, developers create a new version directory and fixture manually. No migration tooling is generated by this feature.
- Runtime schema negotiation or version detection at the application layer. All schema version selection is compile-time; there is no runtime schema registry or version-header negotiation in this feature.
- Coverage of `MailMessageSnapshot`. This type is a classifier input, not a persisted metadata payload, and is excluded from the schema-evolution infrastructure.
