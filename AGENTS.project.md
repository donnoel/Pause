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
xcodebuild -project Pause.xcodeproj -scheme Pause -destination "platform=iOS Simulator,name=iPhone 16" build
xcodebuild -project Pause.xcodeproj -scheme Pause -destination "platform=iOS Simulator,name=iPhone 16" test
```

If the named simulator is unavailable, use an installed iPhone simulator and report which one you used.

## Change checklist for this repo
1. Keep diffs small and focused.
2. Preserve user-visible session flows (start, pause/resume, cancel, completion).
3. Update docs when behavior changes (`README.md` and/or this file).
4. Run build/test and report results, including any skipped steps.

## CI reliability and local validation

- For ordinary changes, start with the narrowest relevant build, unit test or UI check. Expand for shared behavior, persistence, startup or release risk. Documentation and local tool-selection helper changes need scoped structural/contract checks; they do not require an application rebuild solely to repeat CI.
- Use `bash scripts/local-check.sh <command> [args...]` for local checks. It selects already-installed Xcode 26.6 for that command without changing global defaults, and preserves an explicit `DEVELOPER_DIR`. If unavailable, focused commands can use the existing compiler with the difference reported; the strict CI driver still rejects a mismatch.
- GitHub keeps Xcode 26.6 and Simulator 26.5. For deliberate complete reproduction use `bash scripts/local-check.sh bash scripts/ci.sh all <fresh-iOS-26.5-simulator-UDID>`. Fresh simulators are for isolated/full reproduction; preserve existing simulator data. Upgrade pinned baselines in a separate validated change.
- Run the complete affected suites when changing build/test workflow behavior, test harnesses or shared fixtures, or when reproducing a hosted failure. Full local CI is not a blanket prerequisite for every edit. Keep GitHub CI enabled and all existing suites/assertions; a focused pass is not a full-suite pass.
- Check installed tools and equivalent capabilities before proposing a download. Do not install or switch global tools merely to obtain exact CI parity for an unrelated change. Report local compiler/runtime/browser/OS differences and checks not run; only observed GitHub results establish hosted CI success.
- Keep the build, unit-test, and UI-test phases and all existing assertions. Build/test workflow, harness and shared-fixture changes require complete affected-suite evidence.
- Use explicit calendars/timezones for date fixtures, deterministic verified text replacement and readiness conditions for UI, and isolated cloud/Keychain fixtures where those services are not being tested. Repair a failing assumption across related tests rather than retrying or disabling it.
- Classify zero-step payment/spending-limit failures as unavailable execution evidence, separately from compilation, assertions, and deployment. Inspect annotations before editing code for an account block.
- Documentation-only pushes skip expensive CI; optional pull-request checks remain present. Superseded same-ref runs are cancelled. Change pinned compiler/runtime versions deliberately and validate the complete suite.
