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
- Timer/audio/services: `Pause/Componets/MeditationTimerEngine.swift`, `Pause/Componets/AudioChimePlayer.swift`, `Pause/Componets/BackgroundAudioManager.swift`
- Shared persistence for app/widget: `Pause/Componets/PauseSessionStore.swift`
- Widget surface: `PauseWidget/PauseWidget.swift` (accessory circular/rectangular/inline)

## Project constraints
- Keep timer behavior deterministic: session state must move cleanly across `idle/running/paused/completed`.
- Never regress lock-screen/background timing behavior.
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
