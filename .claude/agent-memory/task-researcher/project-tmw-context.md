---
name: project-tmw-context
description: TMW repo — No-COM architecture, net10.0, current solution state, active feature Issue #12
metadata:
  type: project
---

The TMW repository is at `C:\Users\DanMoisan\source\repos\TMW`.

**Why:** Building a Microsoft Outlook task management add-in using Office.js + ASP.NET Core backend with No-COM architecture (no VSTO/PIA).

**Current solution state (as of 2026-05-12):**
- Issue #7 (C1) established the .NET foundation: `TaskMaster.Api` (net10.0 minimal API), `TaskMaster.Domain` (empty placeholder), two test projects.
- Central Package Management (`Directory.Packages.props`) pins all versions.
- `Microsoft.AspNetCore.Mvc.Testing` is pinned at **9.0.10** — this needs upgrading to **10.0.7** for Issue #12 (net10.0 host compatibility).
- `BannedSymbols.txt` bans DateTime.Now/UtcNow, Random.Shared, Thread.Sleep, Task.Delay — always use injected TimeProvider.

**Issue #12 — Add Backend API Foundation (active, status: Draft):**
Adds `TaskMaster.Application` (T2) and `TaskMaster.Infrastructure` (T3) projects plus bearer token validation, correlation ID middleware, IUserSettingsRepository, ICommandBus, IGraphClientFactory.

Research artifact: `artifacts/research/2026-05-12T10-38-add-backend-api-foundation-research.md`

**How to apply:** When researching or planning for this repo, always verify package versions from NuGet (the environment has .NET SDK 10.0.x; only net10.0 TFM is valid for new projects). Architecture rules are strict — Application may not depend on Infrastructure.
