---
name: refresh-product-ui-instructions
description: For technical instructions that reference third-party product UI paths (Outlook on the web, M365, etc.), verify against the latest release instead of relying on training data.
metadata:
  type: feedback
---

When writing technical instructions that reference a third-party product's UI
navigation (menu paths, button labels, dialog names — e.g. Outlook on the web,
Microsoft 365, Office Add-in sideloading), do not rely on model training data.
Refresh against the latest authoritative documentation (Microsoft Learn) before
writing the steps.

**Why:** The user found a documented Outlook-on-the-web sideload path
("Get Add-ins → My add-ins → Add a custom add-in") that no longer matched the
shipped product. These vendor UIs change frequently and training data goes
stale, producing instructions that cannot be followed.

**How to apply:** Before authoring or editing any user-facing instruction that
names a vendor UI control or navigation path, delegate research (task-researcher
with WebFetch) to confirm the current path and cite the source page's
update date. Applies to README and docs/ content describing how to operate
external products, not to commands defined inside this repo (npm scripts, repo
CLIs), which are verifiable from source.
