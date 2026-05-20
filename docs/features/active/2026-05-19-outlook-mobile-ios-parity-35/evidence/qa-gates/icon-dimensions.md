# QA Gate — Mobile Icon Dimensions Verification

- Timestamp: 2026-05-19T22-42
- Task: [P1-T2]
- Command (PowerShell, per file): `Add-Type -AssemblyName System.Drawing; (New-Object System.Drawing.Bitmap "<path>").Size` (batched verification of width/height + PNG raw format)
- EXIT_CODE: 0
- Output Summary: All nine mobile icon files are valid PNGs at their declared physical pixel dimensions.

| File | Measured | Expected | PNG | Result |
|---|---|---|---|---|
| assets/icon-25.png | 25x25 | 25x25 | yes | OK |
| assets/icon-25@2x.png | 50x50 | 50x50 | yes | OK |
| assets/icon-25@3x.png | 75x75 | 75x75 | yes | OK |
| assets/icon-32-mobile.png | 32x32 | 32x32 | yes | OK |
| assets/icon-32-mobile@2x.png | 64x64 | 64x64 | yes | OK |
| assets/icon-32-mobile@3x.png | 96x96 | 96x96 | yes | OK |
| assets/icon-48.png | 48x48 | 48x48 | yes | OK |
| assets/icon-48@2x.png | 96x96 | 96x96 | yes | OK |
| assets/icon-48@3x.png | 144x144 | 144x144 | yes | OK |

All nine files report the expected physical pixel dimensions (25/32/48 logical px at scales 1/2/3). Source derived by high-quality bicubic downscale from existing `assets/icon-128.png`. Maps to spec CI-AC icon presence.
