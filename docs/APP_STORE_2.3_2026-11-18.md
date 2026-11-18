# Pause 2.3 (5) — saved reflections

November 18, 2026. Saved session reflections and day-by-day Insights are implemented. The final Release build is installed and launched on Don's iPhone and iPad. **2.3 (5) is Waiting for Review**, verified live after both Add for Review and final Submit for Review. [App Review submission](https://appstoreconnect.apple.com/apps/6755661954/distribution/reviewsubmissions/details/6f391d97-344d-4991-b9aa-71aa1315c253).

## Scope and version

- App: Pause for a Moment, App Store Connect `6755661954`, iOS/iPadOS. Production scheme `Pause`, Release configuration, team `H7LG8SK72M`, app `dn.Pause`, included widget `dn.Pause.PauseWidget`, app group `group.dn.pause`.
- Published baseline verified live: 2.2.1 (4), Ready for Distribution, with no pending update. Version 2.3 continues the existing sequence using the owner's requested two-component marketing convention; the separate unused build number is 5. App and widget match in Debug/Release. This convention is recorded in `AGENTS.project.md`.
- Repository: `/Users/donnoel/Development/Pause`, `main`, configured remote `github` (`https://github.com/donnoel/Pause.git`). Work began clean at `41121b6`; the current remote's README-only update was fast-forwarded to `b3fb68fc3e190fae69e127efa11f46aa5cdcb105` before implementation. The app implementation at that baseline matches the published 2.2.1 release source. No unrelated changes were present or discarded.

## Behavior and persistence

Selecting Calm, Okay, or Restless after completion now saves the optional reflection with that particular completed session. It remains in history after starting another session or relaunching. Existing records decode without a reflection; no retrospective mood is invented. Approximate duplicate-session merging preserves reflection metadata and resolves competing updates by timestamp, with a deterministic tie-break. Existing session limits, storage keys, app group, and iCloud key-value history remain intact.

Insights now uses a native graphical day picker and shows that day's completed sessions, completion times, durations, and saved reflections. A day without sessions has an explicit empty message, and older sessions show “No reflection added.” The previous read-only, multi-selected calendar becomes an interactive single-day picker. Insights scrolls on iPad as well as iPhone so history remains reachable. Existing summary statistics and start/pause/resume/cancel behavior are preserved. Rows use scalable system fonts, flexible layouts, combined accessibility labels, and a semantic date picker; full VoiceOver and accessibility-size manual acceptance were not performed.

A real completion test exposed an existing main-thread audio-session warning. Chime player/session work and delegate cleanup now share a private serial queue, with completion cleanup also scheduled for a worker without a persistent run loop. Playback state is confined to that queue; stale completion callbacks do not clear a different player. Chime volume, file, fallback, and notification timing remain the same. No background audio mode was added. Final simulator and physical runs show no runtime warning.

Unit-test storage is isolated from app-group history and iCloud so synthetic test records cannot alter owner data. The physical UI checks use actual one-minute sessions without seeding, clock changes, or hidden production controls; those completed sessions remain in device history.

## Validation and delivery

- Fixed local compiler: Xcode 27.0 (27A266a), through `scripts/local-check.sh`. Fixed Local iPhone / iPhone 17 Pro, iOS 27.0, through the shared serial helper; no substitute simulator, new runtime, or compiler switch.
- Final complete scheme run: **31 distinct tests / 34 executions passed**, zero failures/skips/compiler warnings/runtime warnings. Covers legacy decoding, JSON round trip, stale cloud duplicates in either order, latest reflection updates, relaunch persistence, timezone day selection, existing session controls, and a real one-minute end-to-end UI session.
- Initial checks identified the audio warning and an inherited landscape orientation in an existing UI test. Audio work moved off the main thread; the relevant UI tests explicitly select portrait. One earlier simulator runner stalled after its test suites finished; only that owned command was stopped. The final complete run exited successfully. No assertions or suites were disabled.
- Physical **Don's iPhone — iPhone 15 Pro Max, iOS 27.2.1** and **iPad — iPad Pro 13-inch (M4), iOS 27.2.1** each passed the save/reflection/relaunch/Insights flow. Their final runs show no runtime warnings. Captured history demonstrates reflections syncing in both directions. The final archived Release app 2.3 (5) was then installed and launched on both devices. Owner hands-on acceptance and subjective sound acceptance remain separate.
- Warning-free Release archive, app/widget actual version/build, strict signatures, team/app group, expected entitlements, and both privacy manifests verified. The existing automatic distribution export has production push and `get-task-allow=false`. No signing reconfiguration, dependency installation, or beta-only behavior.
- Archive: `/Users/donnoel/Library/Developer/Xcode/Archives/2026-11-18/Pause-2.3-5-final.xcarchive`. Exported distribution IPA SHA-256: `e9acfe58973c1ad9cfd3affa6ee60393ee4f694a9e5cd44b47d1d0f6bb1760f4`.
- [Portable validation and archived source hashes](releases/2.3/): all 72 app/project/widget input hashes match current source. Full logs, xcresults, a source patch, and private device captures remain in ignored `Build/ReflectionRelease/`, `Build/ReflectionReleaseTests-verified.xcresult`, `Build/Reflection-iPhone.xcresult`, and `Build/Reflection-iPad-final.xcresult`.
- Plist validation and `git diff --check` passed. Hosted CI was not run because no new commit/push was requested; its Xcode 26.6 / Simulator 26.5 baseline is separate from local evidence.

## Store update

What's New:

> Your Calm, Okay, or Restless reflection is now saved with each completed session. Choose a day in Insights to review your sessions, durations, and reflections. Saved reflections sync with your session history through iCloud.

English (U.S.) remains the existing localization. Five iPhone images with required-medium inheritance, five iPad images, zero previews, Description, promotional text, keywords, URLs, review information, privacy, pricing, availability, automatic release after approval, immediate automatic updates, and existing ratings are retained. No new legal agreement, financial/account change, or distribution setting change was made. No scheduling or review monitor was enabled.

Upload succeeded once using the existing supported `xcodebuild -exportArchive` upload workflow and existing signing. `manageAppVersionAndBuildNumber=false`; Apple received 2.3 (5). Apple processed exact build `2ce9a81d-7008-4137-b06a-77fa9607733c`; live metadata verified Validated, 2.3 (5), `dn.Pause`, iPhone/iPad family, expected production entitlements, and no non-exempt encryption. The established, code-supported encryption answer was “None of the algorithms mentioned above.”

Apple required refreshed age-rating responses before Add for Review. Social Media and Social Media Disabled for Users Under 13 are No because Pause has no social capabilities. Medical/Treatment Information remains None; Health or Wellness Topics is Yes for its breathing/self-care content. Other content answers remain None/No. Apple calculated **9+** for 172 regions, **12+** in Vietnam, and the existing Brazil/Korea regional classifications; earlier-than-26 operating systems retain a global 4+ rating. No age override or Made for Kids designation was selected. This evidence-backed required questionnaire update is the exception to preserved metadata.

Both Add for Review and final Submit for Review completed. The [live submission](https://appstoreconnect.apple.com/apps/6755661954/distribution/reviewsubmissions/details/6f391d97-344d-4991-b9aa-71aa1315c253) shows **Waiting for Review**, Items Submitted (1), exact **iOS App 2.3 / 2.3 (5)**, submitted November 18, 2026 at **11:18 AM PST** by Don Noel. Submission ID `6f391d97-344d-4991-b9aa-71aa1315c253`. [Saved proof](releases/2.3/waiting-for-review.png). Submitted is not approved or publicly released; published 2.2.1 (4) remains distinct.

The release source is the commit containing this document. The archived-input hash map and source patch preserve its exact provenance; all 72 app/project/widget inputs are verified against the commit before publication to `github/main`. Final push and remote parity are checked at handoff.
