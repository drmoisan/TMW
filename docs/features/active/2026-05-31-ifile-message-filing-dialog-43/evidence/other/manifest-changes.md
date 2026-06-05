# Manifest Changes — SSO App Info and Dev Tunnel Domains

Timestamp: 2026-06-04T20-29

## manifest.json (unified manifest — desktop/web only)

Added a root-level `webApplicationInfo` object and two Dev Tunnel domains to `validDomains` (research section 3.2 and 3.5):

```json
"validDomains": [
    "localhost",
    "https://www.contoso.com",
    "taskmaster-ios-3000.use.devtunnels.ms",
    "taskmaster-api-7287.use.devtunnels.ms"
],
"webApplicationInfo": {
    "id": "2921bc0b-4518-4547-b8ca-f937713688ec",
    "resource": "api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec"
}
```

Caveat (recorded here because JSON manifests cannot carry comments): The unified manifest
(`manifest.json`) is NOT operative on Outlook iOS (verified in prior research
`2026-05-19-outlook-ios-mobile-support-research.md`, cited in research section 3.2). The
`webApplicationInfo` field in the unified manifest therefore affects only the desktop/web
experience. For iOS, the XML manifest (`manifest.xml`) is the operative manifest, where the
`<WebApplicationInfo>` block is added by [P5-T2].

`validDomains` entries follow the existing scheme-less convention used by the `localhost` entry.

## Identifiers (non-secret)

- `id` / `webApplicationInfo.id` = `2921bc0b-4518-4547-b8ca-f937713688ec` (Application/Client ID — not a secret).
- `resource` = `api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-4518-4547-b8ca-f937713688ec` (Application ID URI — not a secret).

No production domain was added. The Dev Tunnel hosts are session-scoped; production-domain
substitution is recorded as an out-of-scope follow-up in the plan.

## Validation

- `npm run validate` (office-addin-manifest validate manifest.json) — EXIT_CODE 0.
