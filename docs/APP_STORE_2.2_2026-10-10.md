# Pause App Store 2.2 (3) — October 10, 2026

## Target and source

- Project: `/Users/donnoel/Development/Pause`, branch `main`, configured remote `github` (`https://github.com/donnoel/Pause.git`). The initial worktree was clean at `49a98ca731dcb1c8f20fc0d31a885c5072b036d1`.
- Production scheme: `Pause`, Release configuration, iOS/iPadOS; developer team `H7LG8SK72M` (Don Noel).
- App Store Connect: **Pause for a Moment**, app `6755661954`, `dn.Pause`; included widget `dn.Pause.PauseWidget`, app group `group.dn.pause`. No Watch app or independent platform submission.
- Scoped release changes: marketing version 2.2 and build 3, plus required UserDefaults privacy manifests for the app (`CA92.1`, `1C8F.1`) and widget (`1C8F.1`). No app behavior or interaction changes in this release preparation.

## Published baseline and What's New

App Store Connect showed published 2.1 (1), uploaded May 23, 2026 at 10:50 AM, and no pending version before this run. The public App Store page showed 2.1, released May 24. The local May 23 archive also identifies 2.1 (1). Its exact Git revision is not recorded, so the baseline source association is date-based rather than an immutable release tag. September commits `16717fa` and `49a98ca` are clearly later and support the following notes.

> Guided breathing now pairs gentle expanding and contracting motion with clear inhale, hold, and exhale cues. Sleep Wind Down has a darker, calmer look and lets you hide the countdown. This update also refreshes the app icon.

English (U.S.) is the existing store localization. Existing screenshots and previews, description, keywords, promotional text, support/marketing URLs, privacy, age rating, pricing, availability, review contact and sign-in information were preserved. Automatic release after approval, immediate automatic updates, and existing ratings were retained. No events, purchases, or other assets are part of this submission.

## Validation and archive

- Warning-free production Release archive with `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES` and `GCC_TREAT_WARNINGS_AS_ERRORS=YES`. No warning suppression or dependency/signing reconfiguration.
- Existing build/test workflow passed on installed **iPhone 18 Pro, iOS 27.0 Simulator** (the documented iPhone 16 was unavailable): 26 distinct tests, 29 executions, zero failures or skips. No compiler or runtime warnings. Includes guided breathing and session-control UI coverage. No new tests, broad audit, or repeated physical-device/visual acceptance.
- App and widget actual bundle metadata verified as 2.2 (3), arm64 iOS, minimum OS 26.1. Both privacy manifests are packaged; only the expected WidgetKit extension is embedded.
- Archive and exported IPA signatures verified. Existing automatic signing exported using Apple Distribution: Don Noel (`H7LG8SK72M`) and existing iOS Team Store provisioning profiles. Distribution app has production push, expected iCloud KVS and app-group entitlements; app/widget `get-task-allow` is false.
- Plist validation and `git diff --check` passed.
- Archive: `/Users/donnoel/Library/Developer/Xcode/Archives/2026-10-10/Pause-2.2-3.xcarchive`.
- Evidence: `/Users/donnoel/.codex/automations/app-app-store-submission/evidence/2026-10-10/Pause/` (archive/test/export/upload logs, xcresult summary, distribution metadata and entitlements, archived-input SHA-256 map).

## Submission

Upload succeeded using `xcodebuild -exportArchive` with destination `upload`, existing automatic signing, and `manageAppVersionAndBuildNumber=false`. Apple processed exact build `ec77456a-09e2-41ee-9ed6-a02e17b079ac`; its live Build Metadata verified 2.2 (3), `dn.Pause`, validated state, production entitlements, and no non-exempt encryption. The required encryption answer was **None of the algorithms mentioned above**, based on current code and the prior build's established answer.

Both **Add for Review** and final **Submit for Review** completed. The live [submission detail](https://appstoreconnect.apple.com/apps/6755661954/distribution/reviewsubmissions/details/7dd27883-a83a-4c30-bd06-cc55703617af) showed **Waiting for Review**, exactly one App Version item **iOS App 2.2 / 2.2 (3)**, submitted October 10, 2026 at 4:39 PM PDT by Don Noel. Submission ID: `7dd27883-a83a-4c30-bd06-cc55703617af`.

Submitted is not approved or publicly released; 2.1 remains the published version at handoff. No remaining user action. The release commit containing this document is the source reference; all previously tracked inputs and both added manifests are SHA-256 checked against the pre-archive input map. This evidence document is not compiled into the app.

The automation remains **PAUSED**; no scheduling or review-status monitor was enabled.
