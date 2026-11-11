# AGENTS.project.md

Project-specific guidance for contributors working in this repository.

## Targets
- `Pause` (iOS/iPadOS app)
- `PauseWidgetExtension` (WidgetKit extension)
- `PauseTests` / `PauseUITests`

## Current architecture map
- App entry: `Pause/App/PauseApp.swift`
- Root flow: `Pause/App/AppCoordinator.swift` → `Pause/Componets/SessionCoordinator.swift`
- Main UI: `Pause/Views/SessionView.swift`
- Session domain models/view model: `Pause/ViewModels/SessionModels.swift`, `Pause/ViewModels/SessionViewModel.swift`
- Timer/audio/services: `Pause/Componets/MeditationTimerEngine.swift`, `Pause/Componets/AudioChimePlayer.swift`, `Pause/Componets/BackgroundAudioManager.swift`, `Pause/Componets/SessionNotificationScheduler.swift`
- Shared persistence for app/widget: `Pause/Componets/PauseSessionStore.swift`
- Widget surface: `PauseWidget/PauseWidget.swift` (accessory circular/rectangular/inline)

## Project constraints
- Keep timer behavior deterministic: session state must move cleanly across `idle/running/paused/completed`.
- Never regress lock-screen/background timing behavior.
- Background chimes rely on local notification alert+sound requests plus persisted session dates; do not add `UIBackgroundModes` audio for halfway/end chimes.
- Maintain widget compatibility when changing anything in `PauseSessionStore`.
- Preserve app-group compatibility (`group.dn.pause`) and shared key usage (`currentSession`) for app/widget countdown sync.
- Additions to persistence must be backward compatible with existing stored data.
- Preserve Insights history sync behavior across devices (iCloud KVS + local app-group storage fallback).
- Keep UI logic in SwiftUI views and business/state logic in view models/services/stores.
- Preserve configuration semantics: duration/ritual/breathing selections configure the next session and do not auto-start.
- Keep active-session configuration distinct from editable idle/completed configuration state.
- Live Activity is not currently shipped; do not reintroduce template ActivityKit scaffolding without full app-side lifecycle wiring.

## Build and test commands
Use these commands before handing off changes:

```bash
xcodebuild -project Pause.xcodeproj -scheme Pause -destination "platform=iOS Simulator,id=4B92A000-EEE2-4682-B9C5-882C4178A250" build
xcodebuild -project Pause.xcodeproj -scheme Pause -destination "platform=iOS Simulator,id=4B92A000-EEE2-4682-B9C5-882C4178A250" test
```

If the pinned simulator is unavailable, report it and repair the shared selection once; do not choose a substitute.

## Change checklist for this repo
1. Keep diffs small and focused.
2. Preserve user-visible session flows (start, pause/resume, cancel, completion).
3. Update docs when behavior changes (`README.md` and/or this file).
4. Run build/test and report results, including any skipped steps.

## CI reliability and local validation

- For ordinary changes, start with the narrowest relevant build, unit test or UI check. Expand for shared behavior, persistence, startup or release risk. Documentation and local tool-selection helper changes need scoped structural/contract checks; they do not require an application rebuild solely to repeat CI.
- Use `bash scripts/local-check.sh <command> [args...]` for local checks. It selects the fixed local Xcode 27.0 (27A266a), rejects conflicting compiler selections, and never installs or switches global tools. Use the shared Apple target helper for concrete destinations. Hosted CI baselines remain separate.
- GitHub keeps Xcode 26.6 and Simulator 26.5. Its strict `ci.sh` may reject the local Xcode 27 compiler; this is a documented baseline difference. Do not switch local compilers or create a fresh simulator automatically. Historical matched-CI reproduction must be explicitly requested and scoped separately; keep existing hosted checks intact.
- Run the complete affected suites when changing build/test workflow behavior, test harnesses or shared fixtures, or when reproducing a hosted failure. Full local CI is not a blanket prerequisite for every edit. Keep GitHub CI enabled and all existing suites/assertions; a focused pass is not a full-suite pass.
- Check installed tools and equivalent capabilities before proposing a download. Do not install or switch global tools merely to obtain exact CI parity for an unrelated change. Report local compiler/runtime/browser/OS differences and checks not run; only observed GitHub results establish hosted CI success.
- Keep the build, unit-test, and UI-test phases and all existing assertions. Build/test workflow, harness and shared-fixture changes require complete affected-suite evidence.
- Use explicit calendars/timezones for date fixtures, deterministic verified text replacement and readiness conditions for UI, and isolated cloud/Keychain fixtures where those services are not being tested. Repair a failing assumption across related tests rather than retrying or disabling it.
- Classify zero-step payment/spending-limit failures as unavailable execution evidence, separately from compilation, assertions, and deployment. Inspect annotations before editing code for an account block.
- Documentation-only pushes skip expensive CI; optional pull-request checks remain present. Superseded same-ref runs are cancelled. Change pinned compiler/runtime versions deliberately and validate the complete suite.

## Session summaries for Tix

When Don says **"summary please,"** return only the following format:

**Description:** One short sentence describing the problem addressed or work
accomplished.

**Summary:** A concise paragraph covering the cause, changes, verification, and
any outstanding follow-up. Include release versions and deployment status when
relevant.

**Commit:** Short commit hash and exact commit subject. List multiple commits
when applicable; state "No commits made" when appropriate.

Cover the current working session. Report only verified results, distinguishing
completed work from pending checks or acceptance. The Description goes into
Tix's description field; Summary and Commit go into its notes.
