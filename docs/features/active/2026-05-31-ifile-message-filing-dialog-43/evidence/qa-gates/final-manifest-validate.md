# Final QA — Manifest Validation Gate (Issue #43, cycle 2)

Timestamp: 2026-06-04T20-29

Command: npm run validate
EXIT_CODE: 0

Command: npm run validate:xml
EXIT_CODE: 0

Output Summary:
- `npm run validate` (office-addin-manifest validate manifest.json) exits 0. The unified manifest
  now carries a root-level `webApplicationInfo` (`id` = 2921bc0b-..., `resource` =
  api://taskmaster-ios-3000.use.devtunnels.ms/2921bc0b-...) and both Dev Tunnel domains
  (`taskmaster-ios-3000.use.devtunnels.ms`, `taskmaster-api-7287.use.devtunnels.ms`) in
  `validDomains`.
- `npm run validate:xml` (office-addin-manifest validate manifest.xml) exits 0 and reports
  "WebApplicationInfo is identified: The structure of WebApplicationInfo is correct" and
  "The manifest is valid." The XML manifest now carries `<WebApplicationInfo>` (with `<Id>`,
  `<Resource>`, and `<Scopes>` openid/profile/Mail.ReadBasic/Mail.ReadWrite/Files.ReadWrite) at the
  end of the inner VersionOverridesV1_1 block, plus both Dev Tunnel `<AppDomain>` entries
  (https://taskmaster-ios-3000.use.devtunnels.ms/, https://taskmaster-api-7287.use.devtunnels.ms/).
- No production domain was added; only Dev Tunnel hosts and non-secret identifiers are present.
