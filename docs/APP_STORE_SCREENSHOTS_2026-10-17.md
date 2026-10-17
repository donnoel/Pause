# Pause App Store screenshots and Description — October 17, 2026

Pause for a Moment **2.2.1 (4)** was submitted and verified **Waiting for Review** on October 17, 2026 at 9:11 AM PDT. The [submission](https://appstoreconnect.apple.com/apps/6755661954/distribution/reviewsubmissions/details/26bc7e55-7f97-40e8-9601-cc833e1d820d) contains exactly one App Version item. Submitted does not mean approved or publicly released; 2.2 (3) remains the published baseline at this verification.

## Target and approved scope

- Repository: `/Users/donnoel/Development/Pause`, branch `main`, remote `github` (`https://github.com/donnoel/Pause.git`), initially clean at `cedc1d10ebabb179dcbf745e02394870690bd3a2`.
- App Store Connect app `6755661954`, app bundle `dn.Pause`, included widget `dn.Pause.PauseWidget`, team `H7LG8SK72M`, app group `group.dn.pause`. The production scheme is `Pause`, Release configuration, iPhone/iPad. No Apple TV or independent Watch submission applies.
- The user reviewed the complete local gallery and approved the direction and Description with “appproved.” Approval and exact export/Description hashes are preserved in the package.
- Live inspection found 2.2 (3) already published with no editable version. The smallest required release step was explained before creating 2.2.1 (4). Only marketing/build values in `Pause.xcodeproj/project.pbxproj` changed; no app behavior, implementation, dependency, SDK, or signing configuration changed.

## Screenshot package

`docs/app-store/screenshot-redesign-2026-10-17/` preserves ten approved exports, ten raw native captures, captions, crop/scale rectangles, source information, SHA-256 hashes, contact sheets, an enlarged-preview gallery, the approved Description, and submission evidence. `tools/AppStoreScreenshots/` contains the dependency-free native renderer, validator, and capture instructions.

| Platform | Count | Exact dimensions | Store behavior |
| --- | ---: | --- | --- |
| iPhone | 5 | 1320 × 2868 | Large Dynamic Island master; required medium display inherits the five assets |
| iPad | 5 | 2064 × 2752 | 13-inch master; smaller sizes inherit as supported |

The sequence is deliberate: choose a breathing break, follow the breathing cues, wind down at night, reflect after completion, then see completed-session rhythm. Captions describe verified functionality. Light aqua, soft lavender, and teal follow Pause's native appearance; dark styling is reserved for its actual nighttime experience. Each composition uses large genuine app imagery without device frames or reconstructed controls. iPad compositions retain its native tablet layout.

Captures came from unchanged `cedc1d1` / 2.2 (3), using iPhone 18 Pro Max and iPad Pro 13-inch (M5), iOS 27 simulators. Reflection and Insights show actual sessions completed normally during capture; no seeded history, altered clock, or fixture UI. Source hashes establish that the subsequent 2.2.1 (4) release uses the same app implementation.

[Apple's current screenshot requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) were checked October 17. All ten exports pass accepted dimensions, opaque 8-bit RGB PNG, sRGB, unique hashes, crop bounds, and uniform scaling. The approved bytes remain unchanged after upload. The existing four iPhone and one iPad screenshots were replaced only in the new version; Apple retains the old assets in its Asset Library. There were no previews to replace.

## Store copy and preserved fields

The approved English (U.S.) Description is `description-en-US.txt` (1,331 characters). It describes actual breathing styles, deliberate Begin, 1–60 minute durations, pause/resume, chimes, Sleep Wind Down, optional reflection, Insights, iCloud history, and the Lock Screen countdown widget without promised health outcomes. English (U.S.) remains the only existing store localization.

What's New was copied exactly from 2.2 because the implementation is unchanged:

> Guided breathing now pairs gentle expanding and contracting motion with clear inhale, hold, and exhale cues. Sleep Wind Down has a darker, calmer look and lets you hide the countdown. This update also refreshes the app icon.

Promotional text, keywords, support/marketing URLs, copyright, review contact and sign-in information, privacy, age rating, pricing, availability, automatic release after approval, immediate automatic updates, and existing ratings were retained. No new legal agreement was accepted, and no events, purchases, account, financial, or distribution settings were changed.

## Archive and validation

- Production Release archive completed without warnings, with Swift/C warnings treated as errors. App and widget both identify 2.2.1 (4), expected bundle IDs, team/app group, and packaged privacy manifests.
- Archive and exported distribution IPA signatures verified. Existing automatic signing produced production push and `get-task-allow=false` for distribution. Development entitlements in the original archive are replaced by the existing distribution export workflow.
- Existing build/test workflow passed on installed iPhone 18 Pro Max, iOS 27 Simulator (the documented iPhone 16 was unavailable): 26 distinct tests, 29 executions, zero failures, skips, compiler warnings, or runtime warnings. No new tests or broad audit.
- Renderer compiled with warnings treated as errors; format/hash validator passed all ten approved images. Project plist and Git whitespace checks passed. Gallery enlarged previews, navigation, and contact sheets were inspected. No physical-device installation was requested or performed.
- Archive: `/Users/donnoel/Library/Developer/Xcode/Archives/2026-10-17/Pause-2.2.1-4.xcarchive`.
- Full build/test/export/upload logs and xcresult: `/Users/donnoel/.codex/automations/app-app-store-submission/evidence/2026-10-17/Pause/`. Portable validation summaries and the 84-file pre-archive SHA-256 map are copied into the screenshot package's `evidence/` directory. Every archived input is checked against the release commit; new screenshot documents and tooling are not compiled into the app.

## Submission evidence

Upload succeeded once using the existing `xcodebuild -exportArchive` upload workflow, with automatic signing and `manageAppVersionAndBuildNumber=false`. Apple processed build `b5f590a5-ed90-4d91-a35e-fc99d928a160`. Its live metadata showed **Validated**, version 2.2.1, build 4, bundle `dn.Pause`, iPhone/iPad family, production entitlements, and no non-exempt encryption. The required encryption answer reused the established, code-supported “None of the algorithms mentioned above” answer.

Both **Add for Review** and final **Submit for Review** completed. Submission `26bc7e55-7f97-40e8-9601-cc833e1d820d` shows **Waiting for Review**, one App Version item **iOS App 2.2.1 / 2.2.1 (4)**. `submission.json` and `evidence/waiting-for-review.png` preserve the exact result. No prior pending submission needed cancellation.

The commit containing this document is the release source reference. Only the version/build change, screenshot assets, capture/render tooling, and release documentation are included. Final local/tracking/live-remote parity is checked after pushing `github/main`. The automation remains **PAUSED**; no scheduling or review-status monitor was enabled. No remaining user action is required for this submission.
