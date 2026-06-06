# Runbook: Entra Delegated-Scope Grant and Admin Consent (iFile, Issue #43)

This runbook is a human-execution exception artifact produced under the autonomous-execution
mandate (issue #45). It covers a step that cannot be completed agentically in this deployment:
granting tenant admin consent for the Microsoft Graph delegated scopes the iFile server-side
filing workflow requires.

- Feature: iFile message-filing (issue #43, PR #44)
- Requirement id: HI-1 (response: exception)
- Classification: human-gated (no scripted Global Administrator credential is available in CI;
  the permission *declarations* are automatable, the admin-consent grant is not). See the
  automation-feasibility assessment in
  `artifacts/research/2026-06-01T13-50-autonomous-execution-human-runbooks-research.md`.

## Cue

Perform these steps once, before on-device verification of iFile (PR #44), and before the iFile
filing workflow is used against a real mailbox. The trigger is: the iFile branch is merged or
deployed to a tenant and a live filing operation (message move + OneDrive attachment mirror) is
about to be exercised. If a live filing call returns an authorization/consent error
(`AADSTS65001` "user or administrator has not consented") this runbook is also the remediation.

## Prerequisites

- An account with the **Global Administrator** role in the target Microsoft Entra tenant (only
  Global Administrator can grant admin consent; the Application Developer role can add the
  declarations but cannot consent).
- The iFile add-in's **application (client) ID** in that tenant.
- Access to the [Microsoft Entra admin center](https://entra.microsoft.com), or the Azure CLI
  (`az`) signed in as Global Administrator.

## Step-by-step Instructions

### Option A — Microsoft Entra admin center (portal)

Add the delegated permissions:

1. Sign in to the Microsoft Entra admin center (https://entra.microsoft.com) with the Global
   Administrator account.
2. Go to **Entra ID** > **App registrations**, then select the iFile app registration.
3. In the left panel under **Manage**, select **API permissions**.
4. Select **Add a permission**.
5. In the **Request API permissions** flyout, select **Microsoft Graph**.
6. Select **Delegated permissions**.
7. Search for and check each of: `Mail.ReadWrite`, `Files.ReadWrite`, `Mail.ReadBasic`.
8. Select **Add permissions**.

Grant admin consent:

9. On the **API permissions** page, select **Grant admin consent for \<tenant name\>**.
10. Select **Yes** in the confirmation dialog.
11. Select **Refresh**.

### Option B — Azure CLI (Global Administrator session)

```bash
# Add the three delegated Microsoft Graph permissions
az ad app permission add \
  --id <app-client-id> \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions \
    e2a3a72e-5f79-4c64-b1b1-878b674786c9=Scope \
    863451e7-0667-486c-a5d6-d135439485f0=Scope \
    b11fa0e7-fdb7-4dc9-b1f1-59facd463480=Scope

# Grant admin consent (requires Global Administrator login)
az ad app permission admin-consent --id <app-client-id>
```

(GUID mapping: `e2a3a72e-...` = `Mail.ReadWrite`, `863451e7-...` = `Files.ReadWrite`,
`b11fa0e7-...` = `Mail.ReadBasic`. Confirm the current GUIDs against the Microsoft Graph
permissions reference if the CLI reports an unknown id.)

## Verification

You have completed this correctly when all of the following hold:

1. On the app registration **API permissions** page, each of `Mail.ReadWrite`, `Files.ReadWrite`,
   and `Mail.ReadBasic` shows **Granted for \<tenant name\>** in the **Status** column (green
   check), not "Not granted".
2. (CLI) `az ad app permission list-grants --id <app-client-id>` lists the three scopes.
3. A live iFile filing operation against a real mailbox completes end-to-end (the message moves to
   the chosen folder and non-inline attachments appear in the mirrored OneDrive folder) without an
   `AADSTS65001` consent error. Record the result against AC-19 in
   `../evidence/other/manual-verification.md`.

If any scope still shows "Not granted", repeat the **Grant admin consent** step with a Global
Administrator account.

## Source and Citation

- Microsoft Entra — Register an application / API permissions and admin consent:
  https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app
  (Microsoft Learn, updated 2026-05-14; accessed 2026-06-01).
- Azure CLI `az ad app permission` reference:
  https://learn.microsoft.com/en-us/cli/azure/ad/app/permission
  (Microsoft Learn, updated 2026-04-07; accessed 2026-06-01).

Sourcing note: UI navigation and command syntax above were obtained via web retrieval of the
current Microsoft Learn documentation on 2026-06-01, not from model training data, per the
human-exception-runbook contract (MCP-first, web-second).
