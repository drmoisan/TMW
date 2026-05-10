# TaskMaster Modern Architecture Migration Plan - No COM Target

## Executive Summary

This document is a COM-free replacement plan based on:

- `docs/TaskMaster-Modern-Architecture-Migrationresearch.md`
- `artifacts/research/20260509-com-free-modern-migration-research.md`

The original migration plan correctly identifies the legacy system as a Windows-only Outlook desktop add-in built on VSTO, Outlook object model automation, Ribbon callbacks, WinForms, global state, and local file persistence. The revised directive changes the strategy: the target architecture must not require COM interaction, must not introduce a classic Outlook adapter path, and must not port old Outlook object model assumptions into new code.

The recommended strategy is a **web-add-in-first product rebuild**. The legacy system should be treated as a reference for user outcomes and selected classifier behavior, not as a runtime dependency or architectural template.

Target architecture:

- Outlook web add-in task pane as the only Outlook client integration.
- Office.js for selected-item context, task pane lifecycle, commands, notifications, and client-supported category operations.
- Microsoft Graph for mailbox data operations such as message reads, folder lookup, message moves, metadata writes, and background processing.
- Backend service for classification, model training, user settings, audit, task metadata, folder prediction, and automation endpoints.
- Service-side persistent storage for classifier state, preferences, migration metadata, logs, and operational records.
- Optional offline import tools for legacy data files, provided they read data artifacts directly and do not invoke Outlook desktop automation.

Explicit exclusions from the designed architecture:

- No VSTO runtime dependency.
- No Outlook desktop object model dependency.
- No `Microsoft.Office.Interop.Outlook`.
- No `IRibbonExtensibility`.
- No `RequestComAddInAutomationService`.
- No COM-visible automation API.
- No in-process Outlook add-in host.
- No WinForms UI hosted by Outlook.
- No classic Outlook adapter phase.
- No reliance on Outlook user-defined fields as the primary application data model.

The migration should preserve primary user outcomes, not implementation mechanics. For example, "QuickFiler" should become a fast message triage and filing workflow in a pinnable task pane, not a recreation of a WinForms queue. Outlook item events should become Graph subscription and delta-processing workflows, not local event handlers. External automation should become authenticated service APIs, Power Automate-compatible endpoints, or explicitly unsupported legacy behavior.

## Current Repository State

The current checkout contains a TypeScript Office add-in scaffold rather than the legacy C# solution described by the original research document.

Observed files:

- `manifest.json`
- `src/taskpane/taskpane.ts`
- `src/taskpane/taskpane.html`
- `src/taskpane/taskpane.css`
- `src/commands/commands.ts`
- `package.json`

Current implementation findings:

- `manifest.json` uses a Microsoft 365 unified manifest.
- The mailbox permission is currently read-only: `MailboxItem.Read.User`.
- The task pane action is currently not pinnable.
- The visible ribbon labels are template labels rather than TaskMaster workflow labels.
- `src/taskpane/taskpane.ts` reads the current item subject only.
- `src/commands/commands.ts` shows a template notification only.
- There is no application service, Microsoft Graph integration, classifier pipeline, category application, folder picker, message move workflow, settings store, or training flow in `src`.

Legacy-code verification note:

The legacy C# projects referenced by the original research document were not present in this checkout. Legacy details in this document are therefore based on the existing migration research document and the follow-up research artifact.

## Strategy Change

### Previous Strategy To Replace

The original document selected a "shell-and-core extraction" approach that retained classic Outlook during migration and introduced a VSTO-host adapter path. That approach is not compatible with the new directive because it makes the legacy host and Outlook automation model part of the migration design.

The following concepts should be removed from the target plan:

- A classic-host adapter phase.
- Shared core designed around both the old add-in host and the new web add-in.
- Migration steps that route Ribbon callbacks into a command bus.
- Any target-state implementation that wraps Outlook desktop automation behind interfaces.
- Any target-state implementation that preserves external COM automation entry points.
- Any MVP definition that requires the old add-in to remain available for supported workflows.

### Revised Strategy

Use a **web-add-in-first rebuild**.

The implementation should begin from the modern Office add-in scaffold and add the capabilities required for selected TaskMaster outcomes. The old system should be used to answer product questions:

- What message decisions did users need to make quickly?
- What filing destinations were useful?
- What classifier outputs were useful?
- What metadata was worth preserving?
- What automation scenarios still matter?
- What training actions improved future classification?

The old system should not answer architecture questions:

- It should not dictate object models.
- It should not dictate threading.
- It should not dictate UI shape.
- It should not dictate persistence format.
- It should not dictate automation surfaces.
- It should not dictate event processing.

## Target Architecture

### Component Map

| Component | Responsibility | Technology |
|---|---|---|
| Outlook add-in UI | Task pane, command buttons, selected-item context, notifications, lightweight client actions | Office.js, TypeScript |
| Backend API | Application commands, classification orchestration, settings, training, filing decisions, audit | ASP.NET Core or equivalent service framework |
| Mailbox data adapter | Message reads, message moves, folders, metadata, background mailbox events | Microsoft Graph |
| Classifier service | Triage, spam/ham, folder prediction, training, model versioning | Service-side .NET or Python implementation |
| Data store | User preferences, classifier state, task metadata, migration records, audit events | SQL database or equivalent durable store |
| Background workers | Graph subscription processing, delta reconciliation, scheduled maintenance | Hosted workers |
| Legacy import utility | Optional offline migration of old settings/model files | Standalone tool, no Outlook automation |

### Client Responsibilities

The Office add-in should do only client-appropriate work:

- Open and pin a task pane where supported.
- Track selected item changes.
- Read selected item identifiers and lightweight item context.
- Request classification from the backend.
- Display classification and filing recommendations.
- Apply a category where Office.js supports the operation.
- Send move, train, and settings commands to the backend.
- Show clear success and failure notifications.

The client should not contain classifier state, full mailbox traversal logic, file-system persistence, or legacy Outlook object wrappers.

### Backend Responsibilities

The backend should own application behavior:

- Resolve Graph identities and mailbox resources.
- Read normalized message snapshots.
- Run classification and folder prediction.
- Persist classifier state and user preferences.
- Execute message move commands through Graph.
- Store task metadata and app-specific message metadata.
- Process Graph change notifications.
- Reconcile missed changes through Graph delta queries where required.
- Expose authenticated automation endpoints for non-UI workflows.

### Domain Model

The new domain should be based on TaskMaster concepts rather than Outlook desktop objects.

Recommended value objects and entities:

- `MessageIdentity`
- `MessageSnapshot`
- `MailboxFolder`
- `FilingDestination`
- `ClassificationResult`
- `ClassifierTrainingExample`
- `TaskMasterTag`
- `TaskMetadata`
- `UserPreference`
- `AutomationRequest`
- `AuditEvent`

The domain model should not expose Outlook desktop object types, item event types, Ribbon callback types, or local UI types.

## Data Plane

### Selected Message Context

Office.js should provide the selected item context and identifiers. The backend should use Microsoft Graph when it needs full message data, message body, headers, folder relationships, or durable mailbox operations.

### Message Filing

Use Microsoft Graph message move operations for filing. The design must account for the fact that a Graph move creates a new message copy in the destination folder and removes the original message.

Design implication:

- Do not rely on stable legacy entry IDs.
- Store app-level correlation IDs separately when needed.
- Treat move as a command that returns a new message identity.
- Record move audit events using both source and destination identities when available.

### Folder Selection

Use Microsoft Graph mail folder APIs to build the folder tree and resolve destination folder IDs. Cache user-specific folder metadata in the backend to improve response time, with a refresh mechanism for folder changes.

### Categories

Use Office.js category APIs where supported for read-mode item classification signals. For backend-only or cross-client operations, use Graph-supported message metadata and categories where available.

Design limitation:

- Compose-mode category behavior differs by client. Workflows that require tagging while composing should be redesigned or excluded from the first release.

### Custom Metadata

Use Graph open extensions for general app-specific metadata. Use Graph extended properties only when a specific Outlook/MAPI compatibility requirement is documented.

Recommended metadata categories:

- App classification result.
- TaskMaster task metadata.
- Migration provenance.
- Folder prediction confidence.
- Training state references.

Avoid modeling the new application around legacy Outlook user-defined fields. If legacy data must be migrated, convert it into a versioned TaskMaster metadata schema.

## UI Model

### Primary Experience

The primary experience should be a pinnable Outlook task pane optimized for repeated message processing.

Core task pane states:

- No message selected.
- Message loading.
- Message ready.
- Classification available.
- Filing destination selected.
- Move in progress.
- Training in progress.
- Error with corrective action.

Primary controls:

- Classify.
- File to recommended folder.
- Choose folder.
- Train triage label.
- Mark spam or ham, if SpamBayes remains in scope.
- Apply or remove TaskMaster tags.
- Open settings.

### Command Surface

Use Office add-in commands to open the task pane or trigger short actions where appropriate. Do not recreate the old Ribbon command model. Command labels should be workflow-oriented and minimal.

Suggested commands:

- Open TaskMaster.
- Classify Message.
- File Message.
- Train Classification.

### QuickFiler Redesign

Legacy outcome:

- Quickly review messages and move them to useful destinations.

Modern implementation:

- Show the current message and recommended destination in a pinned task pane.
- Provide keyboard-accessible actions within the web UI.
- Use recent folders, predicted folders, and search.
- Move through Graph.
- Record decisions to improve future recommendations.

Non-goal:

- Recreate the WinForms window, desktop queue mechanics, or Outlook object event flow.

## Automation Model

### Replacement For Local Event Processing

Use Microsoft Graph subscriptions for background triggers and delta reconciliation for durability.

Background processing should:

- Receive change notifications.
- Validate and renew subscriptions.
- Fetch changed message data through Graph.
- Apply classifier or automation rules in the backend.
- Record decisions and failures.
- Reconcile missed changes through delta queries.

### Replacement For External Automation

External automation should be redesigned as authenticated service interactions.

Supported patterns:

- Backend REST endpoints.
- Power Automate-compatible HTTP triggers.
- Scheduled backend jobs.
- Graph subscription triggered jobs.
- Administrative import or maintenance commands.

Do not provide a COM-compatible automation surface in the new architecture.

## Persistence Model

### User Settings

Store durable user preferences in the backend. Use Office add-in roaming settings only for lightweight client settings that do not need central reporting, model training, or server-side automation.

Examples:

- Preferred view mode.
- Last selected workflow tab.
- Client display preferences.

Backend settings:

- Enabled classifiers.
- Folder prediction preferences.
- Training preferences.
- Privacy settings.
- Automation rules.

### Classifier State

Store classifier state in the backend with versioning.

Requirements:

- Per-user or tenant-level model ownership must be explicit.
- Training examples must be auditable.
- Model changes must be reversible or reproducible enough for support.
- Data retention and privacy behavior must be documented before implementation.

### Task Metadata

Store TaskMaster task metadata in a versioned schema. Use Graph metadata only for item-level references that must travel with the mailbox item. Store richer relational state in the backend.

## Feature Inventory And Target Mapping

| Legacy Feature | User Outcome | No-COM Target Pattern | MVP |
|---|---|---|---|
| QuickFiler | Fast filing of selected messages | Pinned task pane, folder prediction, Graph move | Yes |
| Triage classifier | Prioritize or classify selected messages | Backend classifier, Office.js/Graph category or metadata update | Yes |
| Triage training | Improve future classification | Task pane training actions, backend model state | Yes |
| SpamBayes training | Improve spam/ham classification | Backend classifier and training workflow | Later |
| Tagging | Mark people, projects, topics, contexts | TaskMaster tag schema, categories where useful, backend metadata | Partial |
| Task visualization | Understand task relationships and state | Web task pane or standalone web view backed by service metadata | Later |
| Task tree editor | Manage hierarchy | Web hierarchy editor backed by service data | Later |
| ToDo ID maintenance | Maintain durable task identifiers | Service-side ID allocator and metadata schema | Later |
| Folder info viewer | Inspect folder structure | Graph folder tree and diagnostics view | Later |
| Inbox auto-processing | Apply rules/classifiers without manual action | Graph subscriptions and backend workers | Later |
| External automation | Trigger workflows outside UI | Authenticated APIs, Power Automate, scheduled jobs | Later |
| Local diagnostics | Support troubleshooting | Service logs, client telemetry, correlation IDs | Yes |

## MVP Definition

### MVP Goal

Deliver a standalone Outlook web add-in workflow that works in new Outlook on Windows and Outlook on the web for fast message classification and filing without any dependency on the legacy desktop add-in.

### Included

- Pinnable task pane where supported.
- Selected-message change handling.
- Message snapshot retrieval.
- Backend classify command.
- Triage training action.
- Folder picker with recent and searched folders.
- Graph message move.
- Category or metadata update for classification result where supported.
- User settings stored in the backend.
- Client-visible error handling.
- Service-side logging with correlation IDs.

### Excluded

- Legacy Ribbon parity.
- WinForms parity.
- Classic Outlook host integration.
- External COM automation.
- Full task tree editor.
- Full ToDo UDF parity.
- Calendar metrics writing.
- Automatic inbox processing.
- Local file-based classifier persistence.

### MVP Acceptance Criteria

- The add-in runs in Outlook on the web and new Outlook on Windows.
- A user can open a pinned task pane, select a message, classify it, train the classifier, select a folder, and move the message.
- The implementation performs mailbox writes through Microsoft Graph or supported Office.js APIs.
- No target component references VSTO, Outlook desktop automation, or COM-visible interfaces.
- The backend persists user settings and classifier state.
- Errors include actionable messages and correlation IDs.

## Migration Phases

### Phase A - Outcome Definition And Scope Control

Objective:

Define the product outcomes that replace the legacy implementation.

Tasks:

- Inventory legacy workflows by user outcome, not by button or class.
- Identify which workflows are MVP, later, or explicitly out of scope.
- Define privacy and data residency requirements for classifier state.
- Define mailbox permission requirements.
- Define supported clients and requirement sets.
- Define non-goals for old UI and automation parity.

Deliverables:

- Outcome-based requirements.
- MVP scope.
- Permission model.
- Data handling decision record.

### Phase B - Add-in Scaffold Hardening

Objective:

Turn the current Office add-in scaffold into a TaskMaster shell.

Tasks:

- Replace template metadata, labels, and descriptions in `manifest.json`.
- Set task pane pinning where supported.
- Implement selected-item change handling.
- Replace template UI with TaskMaster workflow UI.
- Add client-side service API wrapper.
- Add structured client error handling.
- Validate manifest permissions and requirement sets.

Deliverables:

- TaskMaster-branded manifest.
- Functional task pane shell.
- Selected-message lifecycle handling.
- Development validation instructions.

### Phase C - Backend And Authentication Foundation

Objective:

Create the service foundation required for mailbox operations and classifier state.

Tasks:

- Create backend API project.
- Configure authentication and Microsoft Graph access.
- Implement user profile and settings storage.
- Implement Graph mailbox access wrapper.
- Implement audit logging and correlation IDs.
- Add health checks and local development configuration.

Deliverables:

- Authenticated backend service.
- Graph access path.
- Durable settings store.
- Operational logging.

### Phase D - Classification MVP

Objective:

Support triage classification and training for the selected message.

Tasks:

- Define `MessageSnapshot` schema.
- Implement message snapshot retrieval.
- Implement baseline triage classifier.
- Implement classify command.
- Implement train command.
- Persist training examples and model state.
- Display classification results in the task pane.

Deliverables:

- Classification endpoint.
- Training endpoint.
- Task pane classification workflow.
- Classifier state storage.

### Phase E - Filing MVP

Objective:

Support fast folder selection and message move.

Tasks:

- Implement Graph folder tree retrieval.
- Implement recent folder storage.
- Implement folder search.
- Implement move command.
- Return post-move identity and audit record.
- Update task pane state after move.
- Record filing decisions for future recommendations.

Deliverables:

- Folder picker.
- Graph-backed message move.
- Move audit records.
- Filing decision history.

### Phase F - Metadata And Tags

Objective:

Represent TaskMaster tags and task metadata without legacy item fields.

Tasks:

- Define versioned TaskMaster metadata schema.
- Choose Graph open extensions or backend-only storage per metadata type.
- Implement tag read/write commands.
- Implement category application where supported.
- Add migration mapping for any legacy metadata that must be imported.

Deliverables:

- Metadata schema.
- Tag workflow.
- Category and metadata update path.
- Migration mapping documentation.

### Phase G - Background Automation

Objective:

Replace local event-driven processing with service-side processing.

Tasks:

- Implement Graph subscriptions.
- Implement subscription lifecycle handling.
- Implement delta reconciliation.
- Implement background classification policies.
- Add idempotency and retry handling.
- Add administrative controls for automation rules.

Deliverables:

- Background worker.
- Subscription lifecycle handling.
- Delta reconciliation.
- Automation rule store.

### Phase H - Legacy Data Import

Objective:

Import useful legacy data without invoking Outlook desktop automation.

Tasks:

- Identify legacy settings and classifier files that matter.
- Document file formats.
- Build import tool that reads files directly.
- Convert imported data into the new service schema.
- Validate imported data with dry-run mode.

Deliverables:

- Import specification.
- Offline import utility.
- Dry-run validation report.
- Rollback procedure.

## Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| Full legacy parity may not be achievable | Some old workflows may be removed or redesigned | Scope by user outcome and document explicit non-goals |
| Graph move changes message identity | Stored references may become stale after move | Treat move as identity-changing and return the new identity |
| Category support varies by client and mode | Classification signal may not always appear as a category | Use backend metadata as source of truth; categories are a client-facing signal |
| Mailbox permissions require tenant consent | Deployment may be delayed | Define permission model early and test in target tenant |
| Classifier state moves from local to service | Privacy and compliance requirements change | Document data handling, retention, and user controls before implementation |
| Graph subscriptions require lifecycle handling | Missed events can lead to stale automation | Implement lifecycle notifications and delta reconciliation |
| Legacy data formats may be incomplete or inconsistent | Import quality may vary | Provide dry-run validation and manual review reports |
| Current scaffold is template-level | MVP requires significant implementation | Treat scaffold hardening as an explicit phase |

## Architecture Rules

The following rules are acceptance criteria for the no-COM architecture:

- New runtime code must not reference VSTO APIs.
- New runtime code must not reference Outlook desktop automation APIs.
- New runtime code must not expose COM-visible interfaces.
- New runtime code must not use Ribbon extensibility callbacks from the desktop object model.
- New runtime code must not depend on local Outlook event streams.
- New runtime code must not depend on Outlook user-defined fields as the primary state store.
- New runtime code must access mailbox data through Office.js or Microsoft Graph.
- Business behavior must be implemented in the backend or in host-neutral domain/application modules.
- Client UI must be implemented as web UI.
- Legacy integration, if required, must be limited to offline data import from files or exported data.

## Implementation Prompts

### Prompt A0 — Establish Repository Hygiene Baseline

Goal:

Establish baseline repository-wide controls that protect commits, dependencies, and PR flow before any TaskMaster code is written.

Read first:

- `package.json`
- `.gitignore`
- Existing `.github/` workflows, if any

Required outcome:

- Pre-commit framework installed and required (lefthook or equivalent single-binary multi-language hook runner).
- Secret scanning runs on every commit (gitleaks or equivalent) and blocks commits containing credentials.
- Conventional Commits enforced via commit-msg hook.
- Dependency update bot configured (Renovate) covering npm, NuGet, GitHub Actions, and Docker in a single config.
- Baseline GitHub Actions workflow exists with reusable composite actions for stages that will be filled in by later prompts (format, lint, typecheck, architecture, test, contract, integration). Stages are defined as no-ops or scoped to existing files until the matching tooling lights up.
- Branch protection rules require the PR pipeline to pass.
- A `quality-tiers.yml` file at repo root defines T1 through T4 tier mappings; CI fails if a project is added without a tier.

Validation:

- A test commit containing a fake secret is rejected.
- A non-conformant commit message is rejected.
- An unclassified project added to `quality-tiers.yml` causes CI to fail.

---

### Prompt B1 — Establish TypeScript Quality Gates

Goal:

Stand up the TypeScript CI toolchain before any TaskMaster-specific task pane code is written, so Prompt B2 commits are validated against final-form gates from the first PR.

Read first:

- `package.json`
- `webpack.config.js`
- `manifest.json`
- `src/taskpane/taskpane.ts`
- `src/commands/commands.ts`

Required outcome:

- Prettier retained with `office-addin-prettier-config`.
- ESLint flat config with `typescript-eslint` strict-type-checked and stylistic-type-checked rule sets, type-aware parsing enabled.
- `eslint-plugin-office-addins`, `eslint-plugin-promise`, `eslint-plugin-import`, and `eslint-plugin-security` configured.
- `no-floating-promises`, `no-misused-promises`, `no-unsafe-*` rules set to error for source files; relaxed only for tests with documented justification.
- `tsconfig.json` enables `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, and `noPropertyAccessFromIndexSignature`.
- Vitest configured with MSW for HTTP stubbing; an Office.js fake module is wired in as a path alias for unit tests.
- `dependency-cruiser` configured with skeleton rules: forbid cycles, forbid orphaned modules, forbid `src/taskpane` from importing `src/commands` and vice versa. Layer rules are stubs to be populated by later prompts.
- `no-restricted-syntax` rules ban `Date.now`, `setTimeout`, `setInterval`, and `Math.random` outside an explicit allowlist of infrastructure files.
- PR pipeline stages 1 (format), 2 (lint), 3 (typecheck), 4 (architecture), 5 (unit tests) execute on every PR push.
- All gates pass on the unmodified scaffold.

Validation:

- `npm run lint`, `npm run typecheck`, `npm test`, and `npx depcruise src` all pass.
- A representative violation introduced into each category is detected and blocks the build.

---

### Prompt B2 — Harden The Office Add-in Shell

Goal:

Convert the scaffold into a TaskMaster task pane shell with selected-message lifecycle handling.

Read first:

- `manifest.json`
- `src/taskpane/taskpane.ts`
- `src/taskpane/taskpane.html`
- `src/taskpane/taskpane.css`
- `src/commands/commands.ts`

Required outcome:

- Task pane is TaskMaster-specific.
- Task pane can remain open while processing messages where supported.
- Item changes update task pane state.
- Template labels and placeholder actions are removed.
- No desktop Outlook automation APIs are introduced.

Validation:

- `npm run build`
- `npm run validate`
- All Prompt B1 PR-pipeline gates pass.

---

### Prompt C1 — Establish .NET Quality Gates

Goal:

Stand up the .NET CI toolchain before any backend code is written.

Read first:

- Existing `.editorconfig`, if any
- The repository `quality-tiers.yml`

Required outcome:

- A solution-level `Directory.Build.props` enables `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<AnalysisLevel>latest-all</AnalysisLevel>`, and `<AnalysisMode>All</AnalysisMode>` for T1/T2 projects.
- A `Directory.Packages.props` central package management file pins versions for the analyzer stack.
- Analyzer stack referenced via `<PackageReference>` with `PrivateAssets="all"`: Meziantou.Analyzer, SonarAnalyzer.CSharp, Roslynator.Analyzers, AsyncFixer, SecurityCodeScan.VS2019, Microsoft.CodeAnalysis.BannedApiAnalyzers.
- `BannedSymbols.txt` bans `DateTime.Now`, `DateTime.UtcNow`, `Random.Shared`, `Thread.Sleep`, and `Task.Delay` outside an allowlist of infrastructure files; tests must use `TimeProvider`.
- CSharpier installed as a local tool; `.editorconfig` covers naming, file-scoped namespaces, and using-directive ordering.
- xUnit, FluentAssertions, NSubstitute referenced for the test SDK.
- A `*.ArchitectureTests` project exists with `NetArchTest.Rules` and a skeleton rule set: no project depends on `Microsoft.Office.Interop.Outlook`; no project depends on a forbidden namespace list (`System.Windows.Forms`, `System.Web`, `Microsoft.VisualBasic`); domain projects do not depend on infrastructure projects.
- WireMock.Net referenced for Graph stubbing in integration tests; Testcontainers referenced for real database tests; `Microsoft.AspNetCore.Mvc.Testing` referenced for in-process host tests.
- `Microsoft.Extensions.TimeProvider.Testing` referenced; tests inject `TimeProvider` rather than calling `DateTime` APIs directly.
- NSwag (or equivalent) configured to emit OpenAPI from controllers at build time and write to `artifacts/openapi/current.json`.
- PR pipeline stages 1–5 extended with the .NET solution; `dotnet csharpier check`, `dotnet build`, `dotnet test`, and the architecture-test project all gate the PR.
- All gates pass on an empty solution skeleton.

Validation:

- `dotnet build` succeeds with zero warnings.
- `dotnet csharpier check .`, `dotnet test`, and the architecture tests all pass.
- A representative violation introduced into each category (banned API, architecture rule, analyzer rule) is detected and blocks the build.

---

### Prompt C2 — Add Backend API Foundation

Goal:

Create the backend service that owns user settings, classifier state, Graph access, and audit logging.

Required outcome:

- Authenticated API.
- Graph access path.
- User settings storage.
- Correlation IDs.
- Health endpoint.
- No dependency on desktop Outlook automation.

Validation:

- Unit tests for settings and command routing.
- Integration test or documented manual test for authentication and Graph token flow.
- All Prompt C1 PR-pipeline gates pass on the new projects.

---

### Prompt D1 — Establish Behavior-Correctness Test Infrastructure

Goal:

Stand up the test categories that constrain classifier behavior — property-based tests, golden snapshots, and mutation testing — before classifier code lands.

Read first:

- `quality-tiers.yml`
- The test SDK references in `Directory.Packages.props`
- Existing test project structure

Required outcome:

- `fast-check` referenced from the TS test SDK; example property test exists for any pure helper.
- `CsCheck` referenced from the .NET test SDK; example property test exists for any pure helper.
- `Verify.Xunit` referenced for .NET snapshot tests; diff tool integration documented for local development. `vitest` snapshot mode used on the TS side.
- Stryker.NET configured to run only on T1 projects in the pre-merge pipeline; mutation score threshold set to 75% for T1 with a documented escape valve for explicit no-impact mutations.
- StrykerJS configured for any TS module classified T1.
- A separate `corpus/` artifact location is established (Git LFS or DVC submodule) with a documented contribution policy: corpus updates are separate PRs and require diff review.
- Synthetic data generators for property tests live under `tests/generators/` (TS) and `Tests/Generators/` (.NET) and are versioned with the test code.
- Pre-merge pipeline stage 8 (mutation) and stage 9 (golden) light up.
- Every T1 module added in subsequent prompts must include at least one property test and one golden test before merge.

Validation:

- An example property test, an example snapshot test, and an example mutation run all execute on a placeholder T1 module.
- The corpus location is reachable from CI.
- Stryker mutation score is reported as a PR comment.

---

### Prompt D2 — Implement Classify Selected Message

Goal:

Classify the selected message through the backend and display the result in the task pane.

Required outcome:

- Client sends selected message identity to backend.
- Backend retrieves or receives normalized message snapshot.
- Backend returns classification result.
- Client displays classification and available training actions.
- Training updates service-side model state.

Validation:

- Unit tests for classifier command.
- Property tests covering input normalization edge cases (per Prompt D1 infrastructure).
- Golden tests covering classifier output on a fixed corpus slice.
- Mutation score on classifier modules meets the T1 threshold.
- UI test or manual validation for selected-message classification.

---

### Prompt E1 — Establish Boundary Contract And E2E Infrastructure

Goal:

Stand up the host↔service contract gates and the E2E lane before the filing workflow exercises both.

Read first:

- The OpenAPI artifact emitted by Prompt C1 (`artifacts/openapi/current.json`)
- The TS API client wrapper from Prompt B2

Required outcome:

- TS API client is generated from the backend's OpenAPI document via `openapi-typescript` or `orval`; manual hand-written types in `src` are forbidden by an ESLint rule in the API client folder.
- `oasdiff` runs in the PR pipeline against the OpenAPI document committed at the previous merge base; breaking changes block the PR unless the API version is bumped.
- Spectral lints the OpenAPI document; rule set includes "operations have descriptions", "responses have schemas", "no inline anonymous schemas".
- Playwright is installed; a smoke E2E suite runs against a test M365 tenant on a label-gated CI job, using a service-principal auth flow rather than interactive login.
- A `tests/e2e/smoke.spec.ts` placeholder exists and is wired into the pre-merge pipeline behind a label such as `e2e:run`.
- Pre-merge pipeline stage 11 (E2E smoke) and PR-pipeline stage 6 (contract/schema compat) light up.

Validation:

- Editing a controller signature without bumping the API version causes the PR to fail with a specific error pointing to the offending field.
- The Playwright smoke job runs successfully against the test tenant when the gating label is applied.

---

### Prompt E2 — Implement Filing Workflow

Goal:

Move the selected message to a chosen folder through Microsoft Graph.

Required outcome:

- Folder picker uses Graph-backed folder data.
- Move command uses Graph.
- Move response records source and destination identities where available.
- Task pane reports success or failure.
- Filing decision is stored for future recommendations.

Validation:

- Unit tests for move command request/response mapping.
- Property tests covering destination-id collisions and move-to-self edge cases.
- Contract tests confirm the move endpoint matches the OpenAPI document.
- Playwright smoke covers the happy-path filing workflow.
- Manual validation against a test mailbox.

---

### Prompt F1 — Establish Metadata Schema-Evolution Test Infrastructure

Goal:

Stand up the schema-evolution gates before any TaskMaster metadata is written to Graph open extensions or the backend store.

Read first:

- The Phase F task list
- `quality-tiers.yml`

Required outcome:

- A `/schemas/v{n}/` directory holds versioned JSON Schema files for every TaskMaster metadata payload (classification result, task metadata, tag set, training-state reference, migration provenance).
- Backend write paths validate payloads against the current-version schema before persisting; tests confirm reject-on-invalid behavior.
- Forward-compat tests: every prior schema version's fixtures must still be readable by the current code.
- Backward-compat tests: every payload written by the current code must be parseable by a documented N-1 reader.
- `json-schema-diff-validator` (or equivalent) runs in the PR pipeline; a breaking schema change without a version bump blocks the PR.
- Nightly pipeline stage 14 (schema evolution) runs against the last three schema versions.

Validation:

- An incompatible schema change without a version bump is detected and blocks the build.
- A version bump combined with the appropriate compat fixture passes.

---

### Prompt G1 — Establish Idempotency And Benchmark Infrastructure

Goal:

Stand up the gates that protect Graph-subscription processing — idempotency property tests and benchmark regression — before background-automation code lands.

Read first:

- The Phase G task list
- The classifier hot paths from Prompt D2

Required outcome:

- BenchmarkDotNet referenced from a dedicated `*.Benchmarks` project; baseline runs are recorded in `artifacts/benchmarks/baseline.json`.
- Pre-merge pipeline stage 10 (benchmark regression) compares each PR's results to the baseline; p99 latency regression > 5% on T1 hot paths or allocation regression > 10% blocks the PR.
- An idempotency test fixture is provided that runs the same Graph-subscription notification through the worker N times and asserts the post-state matches a single-execution post-state, using `FakeTimeProvider` and a deterministic message-id seed.
- Property tests for delta-reconciliation cover out-of-order, duplicate, and missing-event sequences.
- Idempotency assertions are added to the test base class so any subscription handler test inherits the property check.

Validation:

- Introducing an artificial 10% latency regression on a benchmarked hot path blocks the PR.
- A non-idempotent handler is detected by the property test on its first run.

---

### Prompt G2 — Replace Automation Scenarios

Goal:

Replace legacy external automation with service-native automation.

Required outcome:

- Each automation scenario is mapped to an authenticated endpoint, Power Automate-compatible trigger, scheduled job, Graph subscription workflow, or explicit non-support decision.
- No COM-compatible API is created.
- Automation audit records are stored.

Validation:

- Scenario mapping document.
- Endpoint or worker tests for supported scenarios.
- Idempotency property tests pass for every subscription handler (per Prompt G1).
- Benchmark thresholds hold for the delta-reconciliation hot path.

---

### Prompt H1 — Establish Legacy Import Test Infrastructure

Goal:

Stand up the gates that prove the offline import utility reads legacy artifacts correctly without invoking Outlook automation, before importer code lands.

Read first:

- The Phase H task list
- `Verify.Xunit` configuration from Prompt D1

Required outcome:

- Verify-based snapshot tests cover parsing of every documented legacy file format (settings, classifier state, dictionary serializations, resource files).
- Anonymized fixtures of representative legacy artifacts live under `tests/fixtures/legacy/` and are versioned alongside the parser code.
- Dry-run mode for the importer emits a structured report (counts, warnings, schema mismatches) that is checked into `artifacts/import/dry-run.json` on every test run; CI fails if the report deviates from the committed expected report without an accompanying explicit update.
- Architecture rule added: the importer project has zero references to Outlook desktop automation namespaces.
- Round-trip tests confirm that importer output validated against the Phase F TaskMaster metadata schemas.

Validation:

- A change to a parser that alters output triggers a snapshot diff and is rejected unless the snapshot is intentionally updated.
- The dry-run report regenerates deterministically across runs.

## Source Notes

External sources used by the research artifact:

- Microsoft Outlook add-ins overview: `https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/outlook-add-ins-overview`
- New Outlook guidance: `https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/one-outlook`
- Pinnable task pane guidance: `https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/pinnable-taskpane`
- Office.js categories API: `https://learn.microsoft.com/en-us/javascript/api/outlook/office.categories`
- Microsoft Graph message move API: `https://learn.microsoft.com/en-us/graph/api/message-move`
- Microsoft Graph extended properties overview: `https://learn.microsoft.com/en-us/graph/api/resources/extended-properties-overview`
- Microsoft Graph change notifications lifecycle: `https://learn.microsoft.com/en-us/graph/change-notifications-lifecycle-events`
- Outlook add-in metadata guidance: `https://learn.microsoft.com/en-us/office/dev/add-ins/outlook/metadata-for-an-outlook-add-in`
- Office add-in state and settings guidance: `https://learn.microsoft.com/en-us/office/dev/add-ins/develop/persisting-add-in-state-and-settings`

## Definition Of Done

This migration plan is complete when:

- The target architecture contains no required COM interaction.
- The MVP is deliverable without the legacy desktop add-in.
- Primary workflows are mapped to Office.js, Microsoft Graph, backend service, and service storage responsibilities.
- Legacy-only implementation mechanics are either excluded, redesigned, or limited to offline data import.
- The plan gives implementers concrete phases, acceptance criteria, and risk controls for building the modern TaskMaster experience.
