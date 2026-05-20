# QA Gate — dist Icon Emission & manifest.xml URL Substitution

- Timestamp: 2026-05-19T22-42
- Tasks: [P4-T1], [P4-T2], [P4-T3]
- Command: `npm run build` (`webpack --mode production`) then `Get-ChildItem dist/assets`
- EXIT_CODE: 0 (build compiled successfully in ~1.85s)

## P4-T1 — CopyWebpackPlugin assets glob

Determination: the existing `CopyWebpackPlugin` pattern `from: "assets/*"` is a glob that
captures every file directly under `assets/`, including the nine new mobile icons. No
config change was required for icon copy. Build emitted "9 assets" under `assets/*.png`.

## P4-T2 — manifest.xml in webpack output with urlProd substitution

The `manifest*.json` copy pattern glob was extended to `manifest*.{json,xml}` so the same
`urlDev` -> `urlProd` transform applies to `manifest.xml` in production mode and leaves it
unchanged in dev mode. Production build verification on `dist/manifest.xml`:
- `https://localhost:3000/` occurrences remaining: 0
- `https://www.contoso.com/` (urlProd) occurrences: 16

## P4-T3 — Nine mobile icons emitted to dist/assets at declared URLs

All nine mobile icon files are present in `dist/assets/`:

| File | In dist/assets | manifest.xml resid | URL (post-substitution) |
|---|---|---|---|
| icon-25.png | yes | Icon.Mobile.25x25 | https://www.contoso.com/assets/icon-25.png |
| icon-25@2x.png | yes | Icon.Mobile.25x25@2x | https://www.contoso.com/assets/icon-25@2x.png |
| icon-25@3x.png | yes | Icon.Mobile.25x25@3x | https://www.contoso.com/assets/icon-25@3x.png |
| icon-32-mobile.png | yes | Icon.Mobile.32x32 | https://www.contoso.com/assets/icon-32-mobile.png |
| icon-32-mobile@2x.png | yes | Icon.Mobile.32x32@2x | https://www.contoso.com/assets/icon-32-mobile@2x.png |
| icon-32-mobile@3x.png | yes | Icon.Mobile.32x32@3x | https://www.contoso.com/assets/icon-32-mobile@3x.png |
| icon-48.png | yes | Icon.Mobile.48x48 | https://www.contoso.com/assets/icon-48.png |
| icon-48@2x.png | yes | Icon.Mobile.48x48@2x | https://www.contoso.com/assets/icon-48@2x.png |
| icon-48@3x.png | yes | Icon.Mobile.48x48@3x | https://www.contoso.com/assets/icon-48@3x.png |

Every `<bt:Image>` URL in `dist/manifest.xml` (12 total: nine mobile + three desktop
16/32/80) resolves to a file present in `dist/assets/` (ALL_RESOLVE=True). Maps to spec
CI-AC "emitted to the dist bundle at the URLs declared in manifest.xml" and the
Build-output Seeded Test Condition.

Note on dev vs prod: in dev builds the urlProd substitution is intentionally skipped, so a
dev `manifest.xml` retains `https://localhost:3000/` URLs (unchanged), per P4-T2 acceptance.
