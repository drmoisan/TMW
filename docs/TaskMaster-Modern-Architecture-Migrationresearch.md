# TaskMaster Modern Architecture Migration Plan

## Executive Summary

- `TaskMaster` is a Windows-only Outlook desktop add-in built on VSTO/.NET Framework 4.8.1, with the add-in entrypoint in `TaskMaster/ThisAddIn.cs` and a large supporting library ecosystem (QuickFiler, ToDoModel, UtilitiesCS, etc.). 
- The current UX surface is a custom Ribbon defined by `TaskMaster/Ribbon/RibbonExplorer.xml` and implemented via an `IRibbonExtensibility` COM-visible ribbon class (`RibbonViewer`) that delegates almost all behavior to a centralized `RibbonController`.   
- The add-in relies on a “global object graph” (`ApplicationGlobals`) that aggregates Outlook interop access, file system locations, task/to-do data, auto-fileing artifacts, engines, and event hooks, loaded via background/idle scheduling. 
- There is explicit COM automation exposure for cross-Office/VBA invocation via `RequestComAddInAutomationService()` and the `AddInUtilities` COM-visible interface/class.    
- The dominant high-value user workflows are: “Quick Filer” (keyboard-driven filing/queueing), “SpamBayes” and “Triage” trainable classifiers, tagging (people/project/topic), and task visualization/tree operations.      
- Core coupling hotspots are: Outlook COM interop types flowing through domain objects (`ToDoItem`, `ToDoEvents`), WinForms UI embedded in feature logic, and global/static state (VSTO `Globals`, `Properties.Settings.Default`, static threading helpers).      
- Modernization is time-critical because per Microsoft documentation, COM and VSTO add-ins aren’t supported in the new Outlook on Windows; they remain supported in classic Outlook. citeturn1search0 citeturn0search0  
- The repository already aligns with a “dual-run” modernization pattern: many behaviors are in libraries (not only the VSTO project) and there is test coverage + interfaces (e.g., `IApplicationGlobals`) used with mocks.    
- Recommended target is an Outlook web add-in (Office.js) task pane experience (pinnable) backed by a service that hosts the reusable core and ML engines, while keeping the existing VSTO add-in operational during migration and using Microsoft’s “shared code library” migration approach. citeturn0search0 citeturn2search0 citeturn1search5  
- Key feasibility enablers for parity: Office.js category APIs for applying categories (read mode) and Microsoft Graph for message move operations; custom per-item or per-user data can be persisted using add-in metadata (roaming settings/custom properties) or Graph extended properties as needed. citeturn4search0 citeturn5search0 citeturn5search1turn5search3  
- MVP should focus on the “fastest portable value”: a task pane that can classify + categorize a selected message and move it to a chosen folder (QuickFiler-lite), while deferring deep Outlook-object-model features (custom UDFs on items, rich WinForms viewers, ToDo folder event-based automations) to later phases or classic-Outlook-only compatibility.   citeturn4search0turn5search0  
- Migration strategy selected: **shell-and-core extraction** (core libraries + explicit adapters) because it matches the repo’s existing library-heavy layout and keeps behavior stable while enabling a new host to replace VSTO.  citeturn0search0  
- Primary execution risk: some current capabilities rely on APIs that don’t exist in Outlook web add-ins (e.g., direct access to arbitrary stores/folders/selection events, user-defined fields, and in-proc COM event streams). This must be explicitly triaged feature-by-feature with parity decisions.  citeturn1search0  

## Repository and Solution Structure

**Output 2: Repository / Solution Structure**

Top-level solutions:

- `TaskMaster.sln` (main) includes the VSTO add-in plus multiple supporting libraries and test projects.   
- `UtilitiesSwordfish/Swordfish.NET.sln` exists as a separate solution for the Swordfish utilities subset.   

Projects in `TaskMaster.sln` (from solution file + repo README):

- `TaskMaster` (VSTO add-in): Outlook entrypoint + Ribbon wiring + global orchestration.    
- `UtilitiesCS`: shared utilities including Outlook helpers, threading, serialization, and EmailIntelligence (SpamBayes/Triage/etc).   
- `ToDoModel`: task/to-do model and Outlook-to-task mapping utilities (but strongly coupled to Outlook interop and WinForms in places).   
- `QuickFiler`: filing UI/controllers for high-throughput email filing.   
- `TaskVisualization`, `TaskTree`, `Tags`, `SVGControl`, `VBFunctions`, plus corresponding `*.Test` projects.    

Key add-in entry points and lifecycle:

- Add-in startup hook: `ThisAddIn_Startup` in `TaskMaster/ThisAddIn.cs`.   
- Additional lifecycle: `Application.Startup += Application_Startup;` (delays heavy initialization until Outlook’s Application startup event).   
- Ribbon injection: override `CreateRibbonExtensibilityObject()` returning `new RibbonViewer(_ribbonController)`.   
- COM automation service exposure: override `RequestComAddInAutomationService()` returning `AddInUtilities`.   
- “Shutdown event not raised” comment exists in `ThisAddIn_Shutdown`, which matters for cleanup assumptions.   

Ribbon definitions and handlers:

- Ribbon XML: `TaskMaster/Ribbon/RibbonExplorer.xml`.   
- Ribbon class implementing `IRibbonExtensibility`: `TaskMaster/Ribbon/RibbonViewer.cs` (COM-visible).   
- Primary action handler hub: `TaskMaster/Ribbon/RibbonController.cs`.   

Custom UI surfaces present in repo:

- WinForms UIs across several projects, e.g. QuickFiler “home controller” uses a `QfcFormViewer`, background worker patterns, and shows a maximized form/workflow.   
- Task/tree UIs: `TaskTreeController` powers a `TreeListView`-based UI for task tree manipulation.   
- Tag selection UI: `Tags/TagViewer` invoked via `TagLauncher`.   
- Folder inspection UI: `FolderInfoViewer` in UtilitiesCS.   
- VSTO custom task pane usage is implied by VSTO’s `CustomTaskPanes` support in the generated designer and by a “progress tracker pane” infrastructure in UtilitiesCS threading helpers.    

COM-visible interfaces/classes:

- `TaskMaster/AddInUtilities.cs` defines `[ComVisible(true)]` interface `IAddInUtilities` and class `AddInUtilities`.   
- `TaskMaster/Ribbon/RibbonViewer.cs` is also `[ComVisible(true)]`. 

Async/background execution patterns and threading constraints:

- Deferred initialization: `IdleAsyncQueue.AddEntry(...)` is used during `Application_Startup()` to load globals on idle.    
- Central UI thread capture + dispatch: `UiThread.Init()` creates a hidden WinForms form and captures a `SynchronizationContext` and a `Dispatcher`, used by other components for marshaling.   
- Highly asynchronous controllers: QuickFiler uses async init pipelines, background worker completion callbacks, and queue pipelines.   

Persistence/configuration:

- Logging: log4net configured by assembly attribute in `ThisAddIn.cs` plus `TaskMaster/log4net.config` that writes rolling logs under a relative `logs\` location.    
- App settings: heavy usage of `Properties.Settings.Default` (example: QuickFiler settings wrapper).   
- User dictionaries and model state: multiple components load/serialize to disk via “AppData” and “PythonStaging” special folders and custom serializable collections/dictionaries.   
- EmailIntelligence configuration: `IntelligenceConfig` loads configuration from embedded resources (`IntelligenceResources`) and includes a path that writes back to `IntelligenceResources.resx` in the assembly directory (a deployment-sensitive behavior).   

External integrations:

- Outlook object model (Microsoft.Office.Interop.Outlook) is used throughout TaskMaster and several libraries (QuickFiler, ToDoModel, Tags, TaskTree, TaskVisualization).        
- The UtilitiesCS package set includes Microsoft Graph and Microsoft Identity Client libraries (presence indicates intent/capability, but actual Graph usage must be validated in-code).   

**Output 1 requirement: Repository Analysis (required depth) — subsystem register**

| Subsystem | Purpose | Trigger | Upstream dependencies | Downstream dependencies | Key files/classes |
|---|---|---|---|---|---|
| Add-in host & lifecycle | Load add-in; initialize DPI/logging/threading; bootstrap globals and ribbon controller | Outlook loads COM add-in; VSTO startup; Outlook `Application.Startup` | VSTO runtime; Outlook interop `Application` | `ApplicationGlobals` load; `RibbonController` globals; COM automation service | `TaskMaster/ThisAddIn.cs` (`ThisAddIn_Startup`, `Application_Startup`, `CreateRibbonExtensibilityObject`, `RequestComAddInAutomationService`)  |
| Ribbon UI “Explorer” surface | Expose commands for filing, tagging, classifiers, utilities | User clicks Ribbon controls | Outlook ribbon framework calls callbacks | Delegates to feature controllers (QuickFiler, SpamBayes, Triage, etc.) | `TaskMaster/Ribbon/RibbonExplorer.xml`, `RibbonViewer`, `RibbonController`    |
| Central orchestration globals | Provide “service locator” of all core components: Outlook wrappers, file paths, models, events, engines | Created in `Application_Startup` then loaded on idle | Outlook interop, settings, file system | QuickFiler, Tagging, ML engines, event processing | `TaskMaster/AppGlobals/ApplicationGlobals.cs` + `App*` modules  |
| Outlook object model wrapper | Centralizes session/store/folder access and wrappers | Accessed via `Globals.Ol.*` from features | Outlook interop | Folder/tree utilities; filing; category/tag handling | `TaskMaster/AppGlobals/AppOlObjects.cs`  |
| Event hooks & background processing | Hook mailbox item events; auto-process new mail/tasks | Manual toggle from Ribbon; or load-time hook | Outlook Items events; `AppItemEngines` classifier registry | Classification actions, UDF/category updates, persistence | `TaskMaster/AppGlobals/AppEvents.cs`, `TaskMaster/AppGlobals/AppItemEngines.cs`   |
| Email intelligence configuration | Load/track classifier configurations and serialization settings | `ApplicationGlobals` load | Embedded resources; JSON serialization | Engine initialization; People dictionary serialization | `UtilitiesCS/EmailIntelligence/IntelligenceConfig.cs`  |
| QuickFiler workflow | High-throughput, keyboard-centric email queue + move operations + metrics | Ribbon command “Quick File” / controllers call `LaunchAsync` | Outlook interop, synchronization context, file system | Moves emails; writes metrics; may write calendar entries | `QuickFiler/Controllers/QfcHomeController.cs`  |
| ToDo/task model & sync | Represent Outlook items as task entities; manage IDs/UDFs; sync changes | ToDo items change/add events; user actions (flag, tree edits) | Outlook interop; UDF schema; category parsing | Tree views; auto-code IDs; persistence | `ToDoModel/Data Model/ToDo/ToDoItem.cs`, `ToDoModel/Data Model/ToDo/ToDoEvents.cs`   |
| Task visualization and flagging UI | Provide UI to flag and tag selection; auto-assign projects/people/context | Ribbon “Flag Task” / “Populate UDF” | Outlook selection; ToDoModel; Tags | Writes categories/UDFs; creates tasks if none selected | `TaskVisualization/FlagTasks.cs`  |
| Task tree editor | Drag/drop hierarchy editor and selection activation | Ribbon “Load Tree”; user operations | Tree model + Outlook activation | ID renumbering; open/display selected items | `TaskTree/TaskTreeController.cs`  |
| Tag selection | UI to select/apply tags & auto-suggest people | Used by ToDo objects and task workflows | Outlook mail parsing; people dictionary; category creation | Updates tags/categories; supports “launch & select/match” | `Tags/TagLauncher.cs`  |
| Threading infrastructure | Capture UI context; schedule idle actions; track progress | Called early in add-in startup and multiple controllers | WinForms/Dispatcher; timers | Enables background loading without blocking UI | `UtilitiesCS/Threading/UiThread.cs`, `UtilitiesCS/Threading/IdleAsyncQueue.cs`   |
| COM automation surface | Expose limited actions for external automation (e.g., VBA) | Another Office app calls COM automation service | COM interop; ribbon controller | Delegates to same feature actions as ribbon | `TaskMaster/AddInUtilities.cs`  |

## Current-State Architecture Map and Feature Inventory

**Output 3: Current-State Architecture Map**

Component list (current state):

- Outlook Desktop (classic) loads VSTO add-in (`TaskMaster`) which hosts:
  - `ThisAddIn` (startup/lifecycle + ribbon + COM automation service)   
  - Ribbon XML UI (`RibbonExplorer.xml`) + ribbon bridge (`RibbonViewer`) + action hub (`RibbonController`)     
  - Global service graph (`ApplicationGlobals` and submodules)   
- Internal libraries:
  - Email intelligence engines/config (`UtilitiesCS.EmailIntelligence.*`)   
  - QuickFiler UI + controllers (`QuickFiler.*`)   
  - ToDo model/event sync (`ToDoModel.*`)    
  - Task visualization/tree (`TaskVisualization.*`, `TaskTree.*`)    
  - Tagging UI/controller (`Tags.*`)   

Control flow (simplified, current):

1) Outlook loads add-in → `ThisAddIn_Startup()` → captures DPI + UI thread context → registers `Application_Startup`.   
2) Outlook raises `Application.Startup` → `Application_Startup()` constructs `ApplicationGlobals`, wires it into `RibbonController` and `AddInUtilities`, and schedules `Globals.LoadAsync()` through `IdleAsyncQueue`.     
3) User clicks a Ribbon action → Outlook calls `RibbonViewer` callback → `RibbonViewer` delegates to `RibbonController` → controller invokes feature-specific controllers in other projects (QuickFiler, Triage, SpamBayes, TaskTree, TaskVisualization, etc.).     
4) Optional automation: other Office clients call the COM automation service exposed by `AddInUtilities`, which delegates into the same `RibbonController` actions.   

Data flow (simplified, current):

- Outlook Items/Selection → wrapped as helper types (e.g., `ToDoItem`, `MailItemHelper`, folder wrappers) → classifiers and utilities compute tags/decisions → results written back via:
  - Outlook Categories and UserProperties (UDF schema in ToDoModel)   
  - Moves to folders / filing actions (QuickFiler; also exposes “move entire conversation” setting)    
  - Disk persistence (serialized dictionaries/lists, classifier state, diagnostics/logs)    

UI surfaces (current):

- Ribbon (Explorer-level) commands + toggles + menus.   
- WinForms windows: QuickFiler, Tag Viewer, Task Viewer, Task Tree, Folder Info, etc.       
- VSTO custom task panes exist at runtime (designer includes `CustomTaskPanes` and the repo includes a progress tracker pane infrastructure).    

VSTO/COM boundaries (current):

- VSTO host (`ThisAddIn`) ↔ Outlook COM object model (PIA types in interop namespace).   
- Ribbon extensibility is COM-driven (`IRibbonExtensibility`) and `RibbonViewer` is COM-visible.   
- COM automation surface (`AddInUtilities`) is COM-visible and returned from `RequestComAddInAutomationService()`.    

Explicit labeling (current code classification):

- Pure / mostly business logic (candidate reusable):
  - Portions of classifier logic and supporting data structures in `UtilitiesCS.EmailIntelligence.*` (but note: current “engine” layer frequently accepts Outlook-bound helpers like `MailItemHelper`).   
  - Some concurrency/data structures and helpers (e.g., `IdleAsyncQueue`, progress trackers) are generic but currently depend on `UiThread` and UI primitives.    
- Adapter/glue code:
  - `TaskMaster/ThisAddIn.cs` (bootstrapping, Ribbon injection, COM automation service exposure).   
  - `RibbonViewer` (callback glue).   
  - Big parts of `RibbonController` (orchestration across many subsystems).   
- Tightly coupled code (hard to reuse cross-host):
  - `ToDoItem` and `ToDoEvents` rely on Outlook item primitives, categories, and UDF persistence.    
  - QuickFiler UI and workflow use Outlook PIA + WinForms + synchronization-context constraints.   
  - TaskTree and FlagTasks are WinForms and directly activate Outlook items.    
- Reusable code (with refactor):
  - Interface-driven globals already appear in tests (`IApplicationGlobals` mocked in `TaskMaster.Test`), enabling systematic extraction behind adapters.   

Coupling hotspots, global/static dependencies, testability blockers:

- **Global service graph**: `ApplicationGlobals` centralizes state, and many features reach into `Globals.*` (in the “application globals” sense) rather than receiving explicit dependencies (DI).    
- **Static settings**: `Properties.Settings.Default` is used as mutable configuration storage in multiple places (example: QuickFiler settings wrapper).   
- **Static UI/thread helpers**: `UiThread` and “idle queue” are static and create hidden forms/dispatchers; this complicates unit tests and introduces hidden ordering dependencies in startup.    
- **Outlook COM types in domain**: `ToDoItem` constructors take Outlook-bound objects (`IOutlookItem`, `IOutlookItemFlaggable`) and directly read/write categories and UDFs.   
- **Event reentrancy/workarounds**: `ToDoEvents` maintains a global `Editing` dictionary to prevent recursion/re-entry during changes; this indicates tight coupling to Outlook event sequencing.   

**Output 4: Feature Inventory**

Scope note (non-fabrication): The list below is anchored to features explicitly present in the Ribbon XML, the add-in bootstrapping, and the major controllers. Some “TryFunctionality…” commands exist as experimental scaffolding and are treated as **non-MVP** unless validated as production-critical.    

| Feature | User purpose | Trigger | Code location | Dependencies | VSTO coupling | MVP priority | Migration difficulty | Reusable logic | Target implementation pattern |
|---|---|---|---|---|---|---|---|---|---|
| Add-in startup/bootstrap | Ensure add-in loads, initializes threading/DPI/logging, schedules global load | Outlook load + `Application.Startup` | `TaskMaster/ThisAddIn.cs` | VSTO runtime, Outlook interop, `UiThread`, `IdleAsyncQueue` | High | Must | High | Partial | New host bootstrap + DI container; keep VSTO during coexistence |
| Ribbon command surface | Present “TaskMaster” features in Ribbon UI | User clicks Ribbon controls | `RibbonExplorer.xml`, `RibbonViewer.cs`, `RibbonController.cs` | Outlook Ribbon COM callbacks; global controller | High | Must | High | Partial | Office add-in command(s) + task pane; map commands to application layer |
| COM automation service | Allow VBA/other Office apps to trigger actions | External COM caller | `AddInUtilities.cs` + `ThisAddIn.RequestComAddInAutomationService()` | COM automation, ribbon controller | High | Later | High | Partial | Replace with web API endpoints + Office add-in UI, or keep classic-only |
| QuickFiler (windowed) | Rapid keyboard-driven email queue + filing | Ribbon “Quick File” | `QuickFiler/Controllers/QfcHomeController.cs` (and related controllers/viewers) | Outlook interop `MailItem`, WinForms, sync context, file system | High | Should (MVP-lite) | High | Partial | Rebuild UI as pinnable task pane; move operations via Graph + service |
| QuickFiler settings | Toggle behaviors like moving conversation, saving attachments/pictures/copy | Ribbon settings controls | `TaskMaster/AppGlobals/AppQuickFilerSettings.cs` | `Properties.Settings.Default` + UI | Med | Must | Med | Yes | Move to add-in settings store (roaming settings) + service config |
| SpamBayes train (spam/ham) | Improve spam classifier | Ribbon buttons | `RibbonViewer` delegates → `RibbonController` → engines | EmailIntelligence engine + persistence | Med/High | Should | High | Partial | Extract model + training pipeline to shared core; store state server-side |
| SpamBayes enable/disable | Toggle spam engine activation | Ribbon toggle | `AppItemEngines.ToggleEngineAsync` via ribbon | Engine config, manager | Med | Should | Med | Yes | Feature flag in service config + per user state |
| Triage training (A/B/C) | Train a priority classifier | Ribbon buttons | Ribbon → controller → triage engine logic | EmailIntelligence triage logic; item tagging | Med | Must | High | Partial | Shared classifier core; UI in task pane; apply category via Office.js |
| Triage enable/disable + precision | Control classifier behavior | Ribbon toggle/menu | Engine config + triage logic | Config persistence | Med | Must | Med | Partial | Per-user config (service + roaming settings) |
| Apply categories/tags/flag task | Mark selected items as tasks, apply flags and tags | Ribbon “Flag Task”, “Populate UDF” | `TaskVisualization/FlagTasks.cs`, `ToDoModel/ToDoItem.cs` | Outlook selection, UDF schema, tags UI | High | Should (reduced) | High | Partial | Replace UDF usage with Graph extended properties + categories; UI in task pane |
| ToDo ID maintenance (Refresh/Split/Auto-code) | Maintain hierarchical ToDo IDs and splits | Ribbon utilities; ToDo events | `AppToDoObjects.cs`, `ToDoEvents.cs`, `ToDoItem.cs` | Outlook view filters, UDF writes, IDList | High | Later | High | Partial | Replace with service-side ID allocator + Graph extended props |
| TaskTree viewer/editor | View and manipulate task hierarchy | Ribbon “Load Tree” | `TaskTree/TaskTreeController.cs` | WinForms TreeListView + Outlook activation | High | Later | High | Partial | Rebuild as web UX; item open via deep links; hierarchy stored in service |
| Folder info viewer | Inspect folder tree/wrappers | Ribbon folder info | `FolderInfoViewer.cs` + folder wrappers utilities | Outlook folder traversal | High | Later | Med/High | Partial | Implement via Graph mailFolders list + UI tree |
| Auto-processing on inbox events | Auto-process incoming items (classifiers/actions) | Hook/unhook + inbox events | `AppEvents.cs`, `AppItemEngines.cs` | Outlook Items events + engines | High | Later | High | Partial | Replace with Graph subscriptions/webhooks + backend processing |
| Logging | Diagnose runtime + reliability | Always on | `log4net.config` + log usage across code | File logging | Med | Must | Med | Partial | Replace with structured logging in service; keep minimal client logs |
| Threading/idle scheduling | Avoid UI freezes while loading heavy data | Startup | `UiThread`, `IdleAsyncQueue` | WinForms/Dispatcher | High | Must | High | Partial | In Office add-in: async JS + service; in classic: keep until retired |

Cross-cutting features explicitly present:

- Config and settings: `Properties.Settings.Default` usage and wrappers + resource-based intelligence configuration.    
- Logging: log4net configured in `ThisAddIn.cs` and `log4net.config`.    
- Threading assumptions: explicit sync context creation and UI dispatchers in `UiThread`, plus async `Task.Run` usage throughout controllers.    

**Output 5: Coupling & Portability Analysis**

Portability classification (project-level, anchored to concrete dependencies observed in key files):

Portable (extractable with low friction):

- `UtilitiesSwordfish.NET.General` (utility library; treated as portable in repo documentation; validate by scanning for Outlook/WinForms references before extraction).   
- Portions of `UtilitiesCS` that do not depend on Outlook interop, WinForms, or UI thread primitives (requires deliberate split because current UtilitiesCS packages and code mix many concerns).    

Semi-portable (needs refactor / split):

- `UtilitiesCS.EmailIntelligence.*` engines: algorithmic components are reusable, but current engine orchestration uses Outlook-bound helpers (`MailItemHelper`) and global application state.   
- `TaskMaster/AppGlobals/*`: already interface-driven in places (tests mock `IApplicationGlobals`), but the actual implementations embed Outlook interop and file system assumptions.    
- `QuickFiler` controllers: contains domain ideas (queue, grouping, move diagnostics) but is interleaved with WinForms + Outlook PIA + metrics that write to disk and Outlook calendar.   

Non-portable (rewrite required for modern host):

- VSTO host `TaskMaster` project itself (VSTO runtime and Outlook desktop COM integration).   
- WinForms-first UI projects as a whole (`TaskTree`, `TaskVisualization`, `Tags` UI components), because Office web add-ins require web UX (HTML/JS) rather than WinForms.     

Hard VSTO dependencies (examples directly in code):

- VSTO Ribbon injection and COM automation service overrides in `ThisAddIn`.   
- VSTO-generated `CustomTaskPanes` infrastructure in `ThisAddIn.Designer.cs`.   

Outlook object model constraints (examples):

- Direct calls to `ActiveExplorer()`, selection, view/query filters, and Items events in ToDo and Try features.    
- Core domain model types (`ToDoItem`) writing to Categories and UserProperties/UDFs, implying a reliance on MAPI property behavior and Outlook persistence semantics.   

COM constraints:

- COM-visible classes and interfaces must remain stable for any existing external automation callers (VBA).   

UI binding constraints:

- Controllers assume WinForms UI thread and use `SynchronizationContext` and `UiThread.Dispatcher` for cross-thread UI updates.    

## Target Architecture and Migration Strategy

**Output 6: Target Architecture**

Target state: **Outlook web add-in (Office.js) + shared .NET core + backend service**, with an explicit coexistence bridge for classic Outlook during migration.

Platform choices:

- Outlook extensibility target: Outlook web add-in (Office.js) because COM/VSTO isn’t supported in the new Outlook on Windows; a web add-in is the supported extensibility model there. citeturn1search0turn1search1  
- Web UX shape: pinnable task pane to approximate the “persistent workflow” characteristic of QuickFiler/triage use. citeturn2search0  
- Backend: .NET (modern) service that hosts ML engines and data persistence; Office Add-ins are sandboxed and can’t rely on in-proc DLL install semantics. citeturn3search0turn1search0  

UI model:

- Replace Ribbon-heavy command model with:
  - Add-in commands (buttons/menus) that open a task pane.
  - Task pane provides: queue view, classification outputs, folder selection, training actions.
- Rationale: Ribbon callbacks in COM/VSTO are tied to `IRibbonExtensibility` and in-proc COM; Office.js uses manifest + web UI runtime. citeturn1search0turn0search5  

Layering (proposed codebase shape):

- **Domain layer (`TaskMaster.Domain`)**
  - Mail item abstraction (not Outlook PIA): subject/body/sender/recipients/headers + derived token streams
  - Classifier domain objects (SpamBayes, Triage, Folder/Category predictions)
  - ToDo/Tag domain concepts (Project/People/Context/Topic tags) without direct UDF writes
- **Application layer (`TaskMaster.Application`)**
  - Command handlers: `ClassifySelectedMessage`, `TrainSpam`, `TrainHam`, `TrainTriageA/B/C`, `MoveMessage`, `ApplyTags`, etc.
  - Orchestrates persistence and adapter calls
- **Infrastructure layer (`TaskMaster.Infrastructure`)**
  - Storage adapters for model state and dictionaries (replacing current “AppData/PythonStaging” file patterns)
  - Logging adapters
  - Optional “compat export/import” to read/write existing serialized artifacts during coexistence
- **Host adapters**
  - `TaskMaster.Outlook.VstoHost` (existing) becomes a thin shell: maps Ribbon actions → application commands through adapters
  - `TaskMaster.Outlook.WebAddin` (new) task pane UI + JavaScript-to-service calls

Why these decisions remove risk / enable incremental migration (repo-anchored):

- Today’s giant orchestrator pattern (`RibbonController` + `ApplicationGlobals`) concentrates dependencies; extracting command handlers reduces the surface area that must be rewritten per feature.    
- Replacing “Outlook-in-domain” (`ToDoItem` directly mutating UDFs/categories) with adapters prevents cross-thread COM access bugs and enables Graph-based implementations in the web add-in path.   
- Office.js provides supported APIs for categories (read mode) and Graph provides supported APIs to move messages; these directly map to QuickFiler-lite and classifier outcomes being reflected in Outlook. citeturn4search0turn5search0  
- For per-item metadata now stored as UDFs, Graph extended properties create a viable replacement mechanism for MAPI-like custom properties across clients. citeturn5search3turn5search2  
- For per-user settings currently in `Properties.Settings.Default`, Outlook add-in metadata options (roaming settings, custom properties, session data) provide a supported path for user-scoped configuration where appropriate.  citeturn5search1  

DI approach:

- Use explicit constructor injection in new `Domain/Application` projects; keep interfaces already present (e.g., `IApplicationGlobals`) as an initial seam, but progressively replace the global graph with smaller interfaces (e.g., `IMailStore`, `IClassifierStore`, `ISettingsStore`).   

Config strategy:

- Short-term (coexistence): keep log4net and `Properties.Settings` inside VSTO shell; translate into the new settings model at the boundary.    
- Long-term: service-side config and per-user config using add-in metadata options (roaming settings/custom properties) as needed. citeturn5search1  

Logging/telemetry:

- Preserve log4net behavior for classic add-in while introducing structured logging in the backend service; do not depend on writing to local relative `logs\` paths from a web add-in runtime.  citeturn3search0  

State/storage:

- Replace file-based classifier state (currently spread across “special folders” and serializable collections) with service-backed persistence; optionally include a migration job that imports existing serialized state.   
- Store per-message learned flags/tags via:
  - categories (`Office.Categories`) for lightweight marking where feasible citeturn4search0  
  - Graph extended properties for structured data where needed (ToDoID, hierarchy hints) citeturn5search3  

Testing strategy:

- Preserve MSTest + Moq patterns already used in repo tests, but move tests toward pure application-layer command handlers and domain logic; keep Outlook interop behind mocks/adapters.   

Deployment model:

- Web add-in: manifest + hosted web app; requires network connectivity and runs in a sandboxed runtime. citeturn1search0turn3search0  
- Classic Outlook coexistence: maintain VSTO until parity; Microsoft explicitly warns that COM and web add-ins can interfere if both operate on the same surface unless configured as equivalents. citeturn1search5turn1search0  

Coexistence model:

- Phase-based: classic Outlook users keep VSTO while new Outlook users get the web add-in; treat the web add-in as the forward path, and progressively route shared functionality through the extracted core/service. citeturn1search0turn0search0  

**Output 7: Migration Strategy (choose + justify one approach)**

Selected approach: **Shell-and-core extraction**.

Justification anchored to repo realities:

- The solution already isolates significant logic in non-VSTO class library projects (`UtilitiesCS`, `ToDoModel`, `QuickFiler`, `TaskTree`, etc.), making “core extraction” structurally aligned with the codebase.    
- There is a single orchestration choke point (`RibbonController` + `ApplicationGlobals`) where you can systematically replace direct calls with application-layer command handlers without rewriting every library at once.    
- Microsoft provides a first-party migration pattern explicitly about sharing code between VSTO and Office Add-ins using a shared code library, matching the “coexistence” requirement. citeturn0search0  
- Parallel rebuild would require reimplementing multiple WinForms-heavy workflows (QuickFiler, TaskTree, FlagTasks) from scratch before any user value is delivered, while extraction allows partial reuse and controlled parity.     
- Adapter-first alone doesn’t solve the fundamental “Outlook-in-domain” coupling (e.g., `ToDoItem` writing UDFs directly). Shell-and-core extraction forces the creation of domain models and adapters as part of the extraction step.   
- MVP speed: extraction allows delivering a web add-in MVP that reuses classifiers and moves messages via Graph, while the classic add-in continues to serve advanced users. citeturn5search0turn4search0 citeturn1search0  

**Output 8: Ordered Migration Phases**

Phase sequencing is strict and optimized for fastest MVP with minimal rework.

### Phase A — Baseline and seams

Objective  
Create an execution-safe baseline and identify the minimal seams to extract without breaking behavior.

Scope  
Startup, Ribbon dispatch, `ApplicationGlobals` construction, logging, and test harness stabilization.

Prerequisites  
Buildable `TaskMaster.sln` and passing test suite in current state.    

Tasks  
- Add a “command inventory” map document that ties each Ribbon control `onAction` to a specific `RibbonViewer` callback and `RibbonController` method (source: `RibbonExplorer.xml`, `RibbonViewer.cs`, `RibbonController.cs`).     
- Introduce a narrow `ICommandBus` interface inside the VSTO project that the Ribbon delegates to, without moving any logic yet (keeps behavior stable while creating a routing seam). (Anchor: RibbonViewer is the glue layer today.)   
- Add integration “smoke” tests around `RibbonController`-level orchestration where feasible using existing mocks (pattern demonstrated in `AppToDoObjectsTests`).   

Architecture changes  
- Add a new “routing” layer but no behavior changes; log command invocation with existing log4net.   

Acceptance criteria  
- Opening Outlook loads the add-in and Ribbon with no regression.
- All existing tests pass.

Risks + mitigation  
- Risk: hidden ordering dependencies in startup (`UiThread.Init` + `IdleAsyncQueue`). Mitigate by adding deterministic logging around each startup step.     

Definition of done  
- A documented “command map” exists and every Ribbon command has a traced execution path from XML → callback → controller.

### Phase B — Extract the “core contracts” and mail abstractions

Objective  
Create a shared library that can be used by both the VSTO shell and the future web add-in.

Scope  
Introduce new projects: `TaskMaster.Domain` and `TaskMaster.Application` with **no Outlook PIA references**.

Prerequisites  
Phase A routing seam exists.

Tasks  
- Define a “mail item DTO” that captures only the fields needed for existing classification and tagging flows (subject/body/sender/recipients/headers, etc.). (Anchor: current code uses Outlook-bound helpers like `MailItemHelper` and `ToDoItem`; the goal is to replace those in core.)    
- Define interfaces:
  - `IMailStore` (operations: get selected message, list folders, move message)
  - `ICategoryWriter` (apply/remove categories)
  - `IClassifierStore` (load/save model state)
  - `ISettingsStore`  
  These directly correspond to current hard dependencies: Outlook interop, categories/UDF writes, file persistence, and `Properties.Settings`.     
- Move (copy first, then migrate) classifier algorithm code from `UtilitiesCS.EmailIntelligence.*` into the new core where it does not require Outlook types; keep Outlook-binding glue in UtilitiesCS or VSTO host temporarily.   

Architecture changes  
- New core libraries become the only place where “decisions” are made; host projects only provide adapters and UI.

Acceptance criteria  
- Core projects build without Outlook PIA references.
- Unit tests cover at least one classification pipeline end-to-end using DTOs.

Risks + mitigation  
- Risk: classifier code is entangled with Outlook-bound `MailItemHelper`. Mitigate by introducing a strict boundary: first implement a mapper from `MailItemHelper` → DTO.   

Definition of done  
- A compiled core with DTO + adapters + at least one migrated classifier path.

### Phase C — Refactor classic VSTO shell to call the new core

Objective  
Convert classic add-in to be a thin compatibility host while preserving behavior.

Scope  
Ribbon actions, QuickFiler-lite operations, and triage/spam engine toggles.

Prerequisites  
Phase B core exists.

Tasks  
- Replace `RibbonController` direct calls for:
  - triage train and toggle flows (currently configured via `AppItemEngines`)   
  - spam train and toggle flows  
  with `TaskMaster.Application` command invocations.
- Introduce a VSTO-host adapter implementation of `IMailStore` that wraps Outlook interop calls already used (ActiveExplorer selection patterns exist broadly).   
- Keep `AddInUtilities` delegating into the same command bus for backward compatibility.   

Architecture changes  
- `RibbonController` becomes orchestration-only; business logic migrates into core command handlers.

Acceptance criteria  
- Classic add-in still works and produces the same categories/tags and filing behavior for migrated features.
- Existing log outputs preserved.

Risks + mitigation  
- Risk: hidden UI thread assumptions. Mitigate by ensuring VSTO adapter methods that touch COM are explicitly marshaled using current `UiThread`/sync context patterns until removed.   

Definition of done  
- For selected features, VSTO host contains no business logic beyond mapping and UI.

### Phase D — Implement the web add-in MVP shell

Objective  
Deliver a working Outlook web add-in that runs in new Outlook on Windows and Outlook on the web, mapping to core commands.

Scope  
New Outlook add-in manifest + task pane + minimal backend endpoints.

Prerequisites  
Phase B core exists and Phase C yields stable command handlers.

Tasks  
- Implement Office add-in task pane UI with pinnable behavior to keep workflow open across message selection. citeturn2search0  
- Implement category application in read mode using Office.js categories APIs (respect limitations in compose mode). citeturn4search0  
- Implement message move using Microsoft Graph `message: move` endpoint from the backend. citeturn5search0  
- Implement per-user configuration storage using Outlook add-in metadata options (roaming settings for user-level configuration, custom properties if needed per item). citeturn5search1  

Architecture changes  
- Introduce service boundary; front-end becomes thin and delegates to backend/core.

Acceptance criteria  
- In new Outlook on Windows, user can open task pane, classify a selected message, apply category, and move the message to a folder.

Risks + mitigation  
- Risk: installing/running both COM and web add-ins can cause interference; mitigate by explicit coexistence configuration and phased rollout. citeturn1search5turn1search0  
- Risk: Office add-in sandbox prevents direct access to many local capabilities; mitigate by shifting to backend service + Graph. citeturn3search0turn1search0  

Definition of done  
- A working MVP web add-in exists and can be deployed to test tenants.

### Phase E — Feature expansion and parity decisions

Objective  
Iteratively migrate high-value workflows beyond MVP, while explicitly deciding what remains classic-only.

Scope  
QuickFiler queue UX, training UX parity, tagging UX, limited ToDo and hierarchy representation.

Prerequisites  
MVP shipped.

Tasks  
- Implement QuickFiler-lite → QuickFiler queue:
  - Queue of messages in task pane
  - Folder suggestions (initially “recents” list from service rather than local serialized lists)
- Replace UDF-backed ToDo fields with Graph extended properties for cross-client storage where required (ToDoID, hierarchy knobs). citeturn5search3turn5search2  
- Implement background automation (inbox processing) using Graph subscriptions/webhooks (requires architecture and permissions work; keep out of MVP).

Acceptance criteria  
- Measurable parity for defined features; ensure regressions are controlled by side-by-side tests and user verification.

Risks + mitigation  
- Risk: not all UDF semantics map cleanly to Graph extended properties; mitigate by scoping which properties are truly required and versioning the schema.  citeturn5search3  

Definition of done  
- Feature table (below) shows migrated features with “web add-in” support and classic-only ones clearly labeled.

### Phase F — Decommission VSTO (classic-only retirement)

Objective  
Remove dependency on VSTO and COM add-in where feasible.

Scope  
Only after web add-in parity and user adoption.

Prerequisites  
Phase E parity meets business needs; “equivalent add-in” coexistence resolved.

Tasks  
- Remove or freeze COM automation service exposures; provide alternative automation endpoints.
- Archive classic-only WinForms experiences or reimplement as web UX if still required.

Acceptance criteria  
- Users on new Outlook and web can accomplish the defined workflow set without classic add-in.

Risks + mitigation  
- Risk: long-tail features in WinForms may be expensive to reproduce; mitigate by explicit “won’t migrate” policy and/or leaving a classic-only support lane.   

Definition of done  
- VSTO add-in is no longer required for supported user workflows.

**Output 10: MVP Definition**

MVP goal  
Deliver a web add-in that supports “triage + file quickly” in **new Outlook on Windows** and **Outlook on the web** while classic Outlook retains the existing VSTO add-in.

Included MVP features (explicit):

- Task pane (pinnable) that:
  - Reads the currently selected message context
  - Runs **Triage classification** and applies a category to the message in read mode citeturn4search0turn2search0  
  - Provides a folder picker and moves the message to the chosen folder using Graph `message: move` citeturn5search0  
- Enable/disable triage engine per user (stored via roaming settings / service config). citeturn5search1   
- Minimal logging and error reporting (service logs; client shows actionable errors).  citeturn3search0  

Excluded (explicitly not in MVP):

- Full QuickFiler windowed/keyboard-accelerated queue UX and metrics-to-calendar writing.   
- SpamBayes training workflows (can follow after MVP once storage and training UX is validated).   
- UDF-backed ToDo model parity (`ToDoID`, `EC2`, `AB`, hierarchy/visible tree state) and `TaskTree` drag/drop editor.    
- Inbox ItemAdd event-driven auto-processing (`AppEvents`) until replaced by Graph subscriptions/webhooks.   

Legacy components retained (explicit):

- Entire VSTO add-in for classic Outlook continues operating for advanced workflows during MVP rollout.  citeturn1search0  

Known technical debt accepted in MVP:

- Temporary duplication of configuration between classic (Properties.Settings/log4net) and new service-based config, until a unified settings store is implemented.    

## Migration Tables, Codex Prompts, and Risk Register

**Output 9: Feature Migration Table**

| Feature | Current Location | User Value | Dependencies | VSTO Coupling | Reusable Logic | Rewrite Scope | Target Location | MVP Priority | Migration Phase | Risk | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Add-in bootstrap | `TaskMaster/ThisAddIn.cs` | Add-in loads and is stable | VSTO + Outlook interop + UI thread helpers | High | Partial | Split | `VstoHost` thin shell + `WebAddin` host | Must | A/C/D | Med | Classic and web hosts diverge; keep shared core minimal  |
| Ribbon command surface | `RibbonExplorer.xml`, `RibbonViewer.cs` | Access to features | COM Ribbon callbacks | High | Partial | Rewrite (web) | Office add-in manifest + task pane UI | Must | A/D | High | Command mapping doc created in Phase A  |
| QuickFiler launch | `RibbonController` → `QfcHomeController.LaunchAsync` | Fast filing | Outlook PIA + WinForms | High | Partial | Large | Task pane “QuickFiler-lite” first | Should | D/E | High | Preserve semantics, not WinForms UX  |
| Move message to folder | QuickFiler internals | Core workflow | Outlook COM move | High | Yes | Medium | Backend uses Graph `message: move` | Must | D | Med | Graph move creates new copy/removes original; validate parity expectations citeturn5search0 |
| Apply category (triage) | Triage logic + ToDo tags | Visual signals | Outlook categories | Med | Yes | Low/Med | Office.js `Office.Categories` (read mode) | Must | D | Med | Compose-mode limits in new Outlook/web add-in citeturn4search0 |
| Triage training A/B/C | Ribbon actions → triage engine | Better prioritization | Classifier + persistence | Med | Partial | Medium | Core classifier + service state + UI | Must | D/E | High | Must confirm training inputs and storage formats  |
| SpamBayes training | Ribbon actions → engine | Better spam decisions | Classifier + persistence | Med | Partial | Medium | Core classifier + service state + UI | Later | E | High | Not MVP; storage design required  |
| QuickFiler settings | `AppQuickFilerSettings.cs` | User control of behavior | Settings.Default | Med | Yes | Medium | Roaming settings + service config | Must | B/D | Med | Map each setting to new store  |
| COM automation service | `AddInUtilities.cs` | External automation | COM interface | High | Partial | Large | Replace with service API + UI | Later | F | High | Might be classic-only indefinite  |
| ToDo UDF schema | `ToDoItem.cs` | Persistent structured tags/IDs | UDFs + categories | High | Partial | Large | Graph extended properties | Later | E | High | Requires schema mapping + migration tooling  citeturn5search3 |
| TaskTree editor | `TaskTreeController.cs` | Hierarchy management | WinForms + Outlook activation | High | Partial | Large | Web UX + service hierarchy | Later | E/F | High | Explicit parity decision required  |
| Inbox auto-processing | `AppEvents.cs` | Automation | Items events + engines | High | Partial | Large | Graph subscriptions/webhooks | Later | E | High | Different trigger model vs COM events  |
| Logging | log4net config | Diagnostics | File system | Med | Partial | Medium | Service logging + minimal client logs | Must | A/D | Med | Maintain classic logs; avoid reliance on local paths in web add-in  |

**Output 11: Codex Feature Prompts**

---

Feature: Add-in bootstrap and globals initialization

Goal:  
Ensure the classic VSTO add-in continues to load reliably while introducing a thin bootstrap that routes all feature execution through a new application-layer command bus.

Read first:  
- TaskMaster/ThisAddIn.cs  
- TaskMaster/AppGlobals/ApplicationGlobals.cs  
- UtilitiesCS/Threading/UiThread.cs  
- UtilitiesCS/Threading/IdleAsyncQueue.cs

Current behavior to preserve:  
- Initializes DPI settings and UI thread context early in startup  
- Registers Application.Startup and constructs ApplicationGlobals  
- Uses IdleAsyncQueue to load globals asynchronously on idle  
- Wires globals into RibbonController and AddInUtilities

Target destination:  
- UI: N/A (bootstrap only)  
- Application layer: ICommandBus + command handlers entry  
- Domain layer: N/A  
- Infrastructure: VSTO host adapter implementations

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: Ribbon command routing seam

Goal:  
Create a single routing seam so every Ribbon command in RibbonExplorer.xml is dispatched through a command bus rather than directly executing business logic inside RibbonController.

Read first:  
- TaskMaster/Ribbon/RibbonExplorer.xml  
- TaskMaster/Ribbon/RibbonViewer.cs  
- TaskMaster/Ribbon/RibbonController.cs

Current behavior to preserve:  
- All Ribbon actions still invoke the same feature behaviors  
- No UI regressions in the Ribbon surface  
- Existing log statements and error behaviors remain intact

Target destination:  
- UI: Ribbon callbacks remain in RibbonViewer (classic only)  
- Application layer: ICommandBus.Dispatch(command)  
- Domain layer: N/A  
- Infrastructure: VSTO adapter maps selection/context into command inputs

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: QuickFiler-lite move selected message

Goal:  
Implement “move selected message to chosen folder” using a host-agnostic application command that can be called from both classic VSTO and the new web add-in.

Read first:  
- QuickFiler/Controllers/QfcHomeController.cs  
- TaskMaster/Ribbon/RibbonController.cs  
- TaskMaster/AppGlobals/AppQuickFilerSettings.cs

Current behavior to preserve:  
- User initiates filing from a TaskMaster command surface  
- Uses user settings that affect filing behavior (where applicable)  
- Produces a clear success/failure signal and logs errors

Target destination:  
- UI: Office add-in task pane “Move” action (web) + Ribbon button (classic)  
- Application layer: MoveMessageCommandHandler  
- Domain layer: MailItemId + FolderId abstractions  
- Infrastructure: Graph adapter (web) + Outlook interop adapter (classic)

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: Triage classify and apply category

Goal:  
Given the currently selected message, run the existing Triage classifier logic and apply the resulting category to the message in read mode.

Read first:  
- TaskMaster/AppGlobals/AppItemEngines.cs  
- TaskMaster/AppGlobals/AppEvents.cs  
- TaskMaster/Ribbon/RibbonController.cs  
- UtilitiesCS/EmailIntelligence/ClassifierGroups/Triage/* (starting at Triage_OlLogic.cs)

Current behavior to preserve:  
- Triage engine can be enabled/disabled  
- Classification outputs are reflected on the message (currently via Outlook semantics)  
- Training actions A/B/C exist and affect future results

Target destination:  
- UI: Office add-in task pane “Classify” + “Apply” button  
- Application layer: ClassifyMessageCommandHandler + ApplyCategoryCommandHandler  
- Domain layer: TriageLabel (A/B/C) + CategoryName mapping  
- Infrastructure: Office.js category writer (read mode) + model state store

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: QuickFiler settings migration

Goal:  
Migrate QuickFiler settings (MoveEntireConversation, SaveAttachments, SavePictures, SaveEmailCopy) from Properties.Settings.Default to a host-agnostic settings store usable by both classic and web add-ins.

Read first:  
- TaskMaster/AppGlobals/AppQuickFilerSettings.cs  
- TaskMaster/Ribbon/RibbonExplorer.xml  
- TaskMaster/Ribbon/RibbonController.cs

Current behavior to preserve:  
- Setting toggles persist across sessions  
- Ribbon toggles reflect current values  
- Changes are saved immediately

Target destination:  
- UI: Task pane settings panel (web) + Ribbon toggles (classic during coexistence)  
- Application layer: SettingsQuery + SettingsUpdate commands  
- Domain layer: QuickFilerSettings aggregate  
- Infrastructure: Roaming settings or backend config store (web); bridge adapter for classic

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: Replace ToDo UDF persistence with Graph extended properties

Goal:  
Create a compatibility layer that stores and retrieves ToDo-related metadata (e.g., ToDoID and related split fields) using Graph extended properties, enabling web add-in parity for key ToDo metadata.

Read first:  
- ToDoModel/Data Model/ToDo/ToDoItem.cs  
- ToDoModel/Data Model/ToDo/ToDoEvents.cs  
- TaskMaster/AppGlobals/AppToDoObjects.cs

Current behavior to preserve:  
- ToDoID is stored on the underlying Outlook item  
- SplitID populates derived fields/levels  
- ToDo-related updates avoid re-entrancy loops via Editing markers

Target destination:  
- UI: Task pane ToDo metadata view/edit (web)  
- Application layer: ToDoMetadataRead/Write commands  
- Domain layer: ToDoId + ToDoHierarchyMetadata value objects  
- Infrastructure: Graph extended properties adapter + schema/version definition

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

Feature: COM automation service replacement plan

Goal:  
Preserve existing automation entrypoints while introducing a forward-compatible service API that can replace VBA-driven COM calls for new Outlook/web scenarios.

Read first:  
- TaskMaster/AddInUtilities.cs  
- TaskMaster/ThisAddIn.cs  
- TaskMaster/Ribbon/RibbonController.cs

Current behavior to preserve:  
- External automation can launch QuickFiler, sort email, flag as task, and maximize QuickFiler window  
- Calls delegate into the same operational paths as Ribbon actions

Target destination:  
- UI: N/A  
- Application layer: Service endpoints mirror automation commands  
- Domain layer: N/A  
- Infrastructure: Web API endpoints + auth layer

Execution steps:  
1. identify entry points  
2. trace dependencies  
3. separate VSTO glue from logic  
4. extract or recreate logic  
5. implement adapters  
6. implement UI/command surface  
7. wire end-to-end  
8. add tests  
9. validate vs legacy

Constraints:  
- no unrelated refactors  
- preserve behavior  
- isolate changes  
- maintain compatibility if needed

Non-goals:  
- no system-wide redesign  
- no unrelated feature migration

Validation:  
- behavior matches legacy  
- tests pass  
- logging present  
- errors handled

Deliverables:  
- code  
- tests  
- migration notes  
- remaining legacy dependencies

---

**Output 12: Risks / Unknowns / Assumptions**

Risks (execution-impacting):

- **Support gap risk (new Outlook)**: COM/VSTO add-ins aren’t supported in new Outlook on Windows; if users transition, the current add-in becomes unusable without a web add-in replacement. citeturn1search0turn1search1  
- **Feature parity risk**: several workflows are built on Outlook COM events and UDF persistence (`ToDoEvents`, `ToDoItem`), which do not have direct one-to-one equivalents in Office.js; parity requires Graph-based redesign (extended properties + subscriptions).   citeturn5search3  
- **Data loss / semantic mismatch**: Graph `message: move` creates a new copy and removes the original; validate whether current QuickFiler behavior depends on EntryID stability or other COM identity semantics. citeturn5search0   
- **Compose-mode limitations**: Office.js categories cannot be managed in compose mode in Outlook on the web and new Outlook on Windows; workflows that expect tagging during compose must be redesigned. citeturn4search0  
- **Security/runtime constraints**: Office Add-ins run in a sandboxed web runtime with governed resources and without installing/hosting DLLs in-proc; any design relying on local file paths or in-proc COM access won’t port. citeturn3search0turn1search0  
- **Config persistence risk**: `IntelligenceConfig` includes functionality to write back to an assembly `.resx` file path at runtime, which is fragile in real deployment; migrating to a service-backed config store is likely mandatory.   

Unknowns (must validate; not assumed):

- Whether the Graph and MSAL dependencies in `UtilitiesCS/packages.config` are actively used in current runtime paths or are dormant/tooling-only.   
- The exact on-disk schema and locations for classifier state, “recents”, and other serialized structures referenced by `AppToDoObjects` and related globals (needs file-path tracing and sample data capture).   
- Which Ribbon buttons are “production” vs “experimental” (the presence of `TryFunctionalityInConstruction` indicates a mix).    
- Whether any external users depend on the COM automation service (`IAddInUtilities`) and how breaking changes would affect them.   

Assumptions (explicit):

- Assumption: primary mailbox types are Microsoft 365/Exchange accounts where Graph operations and Outlook add-ins are supported; if users rely on non-Microsoft accounts, Outlook add-in support varies and may block the web add-in approach. citeturn1search0  
- Assumption: classification can be hosted in a backend service and storing model state server-side is acceptable (privacy posture must be validated because the current add-in runs locally).  citeturn3search0  

Attribution note: The repository is authored/maintained by entity["people","Dan Moisan","TaskMaster author"] as indicated in the repo license header.   

Primary platform constraint source: entity["company","Microsoft","software company"] documents that COM/VSTO add-ins are not supported in new Outlook on Windows, which is the driving constraint behind the recommended target architecture. citeturn1search0  

Source control platform: The codebase is hosted on entity["company","GitHub","software hosting"] and analyzed directly from repository artifacts. 