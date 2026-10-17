# Pause screenshot workflow

The October 17, 2026 set was **approved and submitted** with Pause 2.2.1 (4), verified Waiting for Review. App implementation, behavior, and signing are unchanged. Published 2.2 (3) was no longer editable, requiring the approved version/build increment. See `docs/APP_STORE_SCREENSHOTS_2026-10-17.md` and the package's `submission.json` for exact evidence.

The complete review package is `docs/app-store/screenshot-redesign-2026-10-17/`: five iPhone PNGs, five iPad PNGs, the original captures, captions/crop manifest, source information, file hashes, contact sheets, a review gallery, and the approved English (U.S.) Description.

## Reproduce

Run from the repository root. Uses only existing Swift/AppKit/ImageIO and Python's standard library; no dependencies or signing changes.

```sh
swiftc -warnings-as-errors tools/AppStoreScreenshots/render.swift -o Build/render-pause-screenshots
Build/render-pause-screenshots
python3 tools/AppStoreScreenshots/validate.py
python3 -m http.server 8771 --bind 127.0.0.1 --directory docs/app-store/screenshot-redesign-2026-10-17
```

Open `http://127.0.0.1:8771/index.html`. Select an image for an enlarged preview, use arrow keys to browse, and choose Actual pixels to inspect the full-size PNG. Contact sheets and Description are included in the gallery. Escape closes the preview.

## Capture contract

- Build/launch the unchanged `Pause` scheme on iPhone 18 Pro Max and iPad Pro 13-inch (M5), iOS 27 simulators. Both are current native layouts, not an enlarged iPhone view on iPad.
- Use XcodeBuildMCP runtime snapshots and semantic taps to select actual controls. No fixture data, clock manipulation, fake text, generated screenshots, or altered app implementation.
- In each simulator, select Reset and capture its three-minute setup screen. For the breathing image, the iPhone uses a running Focus/Equal Breath session and the iPad uses Reset/Calm Exhale.
- Let the iPhone five-minute and iPad three-minute sessions finish normally. Capture the real completion/reflection screen, then open Insights and capture the one completed session. History was not seeded or fabricated.
- Select Sleep Wind Down, Begin, then Hide countdown. Capture the running state with its real phase word and Show countdown control. End the temporary session afterward.
- Capture full-resolution PNGs using `xcrun simctl io <observed-UDID> screenshot <raw-file>`. The MCP screenshot helper returns a downsampled JPEG, so it is used for inspection only, not production artwork.
- Render only outside the app: uniformly crop/scale genuine captured rectangles and add short captions. Remove system status bars and outer empty space; do not repaint, reconstruct, or move individual app controls. The iPad Insights image crops closely to the genuine sheet. Rounded crop boundaries are not device frames.

The renderer validates caption bounds. The validator checks ten unique exports, accepted platform dimensions, opaque 8-bit RGB PNG, sRGB profile, crop/draw bounds, uniform scaling, Description length, and SHA-256 hashes for raw sources and exports.

## Approval and upload record

The user approved the local gallery on October 17, 2026 (literal message: “appproved.”). `approval.json` records that checkpoint. `approved-hashes.json` freezes the exact ten export hashes and Description hash; the validator fails if those bytes change.

Published 2.2 (3) had no editable version. The required new release step was explained before creating 2.2.1 (4). Only project version/build values changed; the archive input map ties the submitted binary to the release commit. Both Add for Review and final Submit for Review completed for exactly one App Version item. See `submission.json` and `evidence/waiting-for-review.png`.

Five large-display iPhone assets are inherited by the required medium-display slot. Five iPad assets use the 13-inch master. English (U.S.) remains the only existing localization. Other metadata, previews, release behavior, and distribution settings were preserved. Old screenshots remain recoverable in Apple's Asset Library.

Future asset changes require a new review checkpoint; do not silently overwrite the approved hashes or upload new artwork. The automation remains paused with no review monitor.
