# **Pause**

### *Breathe deeper. Slow down. Return to yourself.*

<p align="center">
  <img src="https://img.shields.io/badge/Built%20with-SwiftUI-orange?logo=swift&logoColor=white" alt="Built with: SwiftUI">
  <img src="https://img.shields.io/badge/Platform-iOS_|_iPadOS-blue" alt="Platform: iOS | iPadOS">
</p>

---

## 🧭 Overview

<a id="overview"></a>

A clean, distraction-free meditation experience for iOS and iPadOS.

Pause is a beautifully simple breathing & meditation timer built entirely in Swift and SwiftUI. Designed to get out of your way, Pause helps you settle your mind, breathe intentionally, and take short restorative breaks throughout the day — without ads, clutter, or noise.

This project includes the full iOS app, accessory Lock Screen widgets, and a lightweight audio system for gentle chimes and session guidance.

## 💎 Core Features

| Feature | What it does |
| --- | --- |
| **Mindful sessions** | Choose a duration, breathing style, or ritual and deliberately begin. |
| **Gentle guidance** | Follow breathing phases and optional session chimes. |
| **Session insights** | Review completed sessions, reflections, and iCloud-backed insights. |
| **Lock Screen widget** | Glance at the shared session state on accessory widgets. |

<details>
<summary>Feature details and controls</summary>

<a id="core-features"></a>

🕊 Minimal Breathing Sessions

Pause offers preset session lengths — 5, 10, 15, and 20 minutes — powered by `SessionDurationPreset`. Each session is managed by `SessionViewModel`, which tracks:
- elapsed time
- remaining time
- start / pause / resume / end
- session completion
- persistent state during app backgrounding

Preset and custom duration controls now configure the upcoming session only. Starting is always a deliberate tap on the primary **Begin** action.

Pause also supports selectable breathing styles: **Quiet Timer**, **Box Breath**, **Calm Exhale**, and **Equal Breath**.

Optional ritual presets are available to quickly configure both duration and breathing style: **Reset**, **Focus**, **Unwind**, and **Sleep Wind Down**.

After a fully completed session, you can optionally add a one-tap reflection: **Calm**, **Okay**, or **Restless**.

🔔 Gentle Audio Chimes

A lightweight AudioChimePlayer wraps AVAudioPlayer to deliver soft, unobtrusive tones for:
- session start
- optional interval chimes
- session end

The audio system includes graceful error handling for missing or unsupported audio files during normal app use.
Halfway and completion chimes are scheduled as local notifications with the original chime sound so they can fire while the app is backgrounded or the Lock Screen is active without declaring background audio mode.

📊 Session Stats

Pause includes a Stats sheet with:
- a calendar that marks days with fully completed sessions
- your usual meditation time (based on completed sessions)
- your last completed meditation
- average completed session length
- iCloud sync for completed-session insights across devices on the same Apple ID

Partial or cancelled sessions are not recorded in the calendar or summary stats.

🏞 Custom SwiftUI Experience

Pause uses clean, modern SwiftUI views and a lightweight design system across:
- a single-screen session flow (idle, running/paused, completed)
- configuration cards for ritual, duration, and breathing style
- a breathing orb that expands on inhale, stays still during holds, and contracts on exhale; the smaller countdown stays steady
- a calm completion reflection step
- a card-based Insights sheet

Active sessions use a centered layout with quieter controls. Guided breathing always shows phase words alongside the pulsing circle; Reduce Motion keeps the words and uses a still orb. VoiceOver exposes the current breathing phase.

Rituals have subtle mint, cyan, warm orange, and midnight atmospheres. **Sleep Wind Down** uses a dark appearance and offers **Hide countdown / Show countdown** during the session. These are presentation changes; duration, bells, and deliberate Begin behavior remain the same. A settling prompt appears before Begin, and completion brings the circle to rest with a gentle reflection invitation.

Everything is intentionally minimal and soothing — nothing steals focus.

📱 Lock Screen Widget

The included Pause widget keeps session state glanceable and calm on accessory surfaces:
- ready state with a minimal “Ready to begin” cue
- active-session remaining time countdown when relevant
- accessory families: circular, rectangular, and inline
- shared state via PauseSessionStore (app-group compatible)
- WidgetKit timeline reload support

⚙️ Settings App Version Row

In iOS/iPadOS Settings (`Settings > Apps > Pause`), the app shows a single non-editable `Version` row formatted as `CFBundleShortVersionString (CFBundleVersion)`, sourced from the app bundle at launch.

🛰 Live Activity Status

Pause does not currently ship a Live Activity. Template Live Activity scaffolding was removed until a production-ready ActivityKit lifecycle is implemented in the app target.

</details>

---

## 🚀 Getting Started

<a id="getting-started"></a>

Clone the repo:

```sh
git clone https://github.com/donnoel/Pause.git
cd Pause
open Pause.xcodeproj
```

Make sure you have:
- Xcode with the iOS 26.1 SDK or newer
- an iOS Simulator runtime installed
- A team signing identity for running on a device

You can run Pause in the simulator, but sound playback and background behavior work best on a physical device.

<a id="tests"></a>

### Tests

The project includes unit tests for:
- session timing behavior
- state transitions
- persistence logic via PauseSessionStore

Run tests via:

⌘ + U

## 🧠 How It Works

<details>
<summary>Architecture and component reference</summary>

<a id="architecture"></a>

### Architecture

Pause uses a deliberately simple architecture:

```text
PauseApp.swift
├── AppCoordinator.swift            # High-level flow
├── Componets/
│   └── SessionCoordinator.swift    # Root composition
├── ViewModels/
│   ├── SessionViewModel.swift      # Session lifecycle + configuration state
│   └── SessionModels.swift         # Session enums, breathing, rituals, stats models
├── Componets/
│   ├── AudioChimePlayer.swift      # Chime playback subsystem
│   ├── MeditationDesignSystem.swift# Shared colors/styles
│   ├── MeditationTimerEngine.swift # Core timing logic with Combine
│   ├── SessionNotificationScheduler.swift # Lock Screen chime notification scheduling
│   ├── PauseSessionStore.swift     # Shared model for widgets & app
│   └── BackgroundAudioManager.swift# Background-audio compatibility shim
└── Views/
    └── SessionView.swift           # Main session + insights surfaces
```

The codebase avoids unnecessary complexity, making it approachable and ideal for learning modern SwiftUI patterns.

<a id="background-safe-timer-handling"></a>

### Background-Safe Timer Handling

MeditationTimerEngine drives foreground updates while the app is active, PauseSessionStore preserves session dates so timing and widgets restore cleanly after backgrounding, and SessionNotificationScheduler schedules halfway/completion chime notifications without enabling background audio mode.

<a id="built-with"></a>

### Built With

- Swift 5 / SwiftUI
- Combine
- AVFoundation for audio
- WidgetKit
- App Groups for shared storage
- NSUbiquitousKeyValueStore for Insights sync
- Xcode with the iOS 26.1 SDK or newer
- Clean MVVM-ish architecture

<a id="core-components"></a>

### Core Components

SessionViewModel

The heart of Pause. Tracks:
- session duration
- state transitions (idle → running → paused → completed)
- timer lifecycle
- persisted session restoration for background-safe timing

MeditationTimerEngine

Lightweight Combine-powered engine updates time every second with minimal overhead.

AudioChimePlayer

Handles chime playback and formatting. Clean, compact, safe.

PauseSessionStore

Shared container used by both the app and the widget. It exposes:
- remaining time
- session state
- triggers widget timeline reloads

<a id="design-philosophy"></a>

### Design Philosophy

Pause tries to feel like a breath of fresh air:
- Soft tonal accent colors
- Minimal screen elements
- Clear, approachable typography
- No clutter, no gamification, no noise
- Just tap → breathe → finish

It’s a meditation timer that respects your attention.

</details>

## 🔒 Data and Privacy

Session dates are stored locally through `PauseSessionStore` for restoration and
widgets. Completed-session Insights synchronize through iCloud key-value storage.
Halfway and completion chimes use local notifications without declaring background
audio mode.

## 📚 Documentation

<a id="contributing"></a>

### Contributing

Pull requests are welcome. If you’d like to improve animations, add additional breathing modes, or enhance widget functionality, open an issue and let’s talk.

- [Repository guidance](AGENTS.md)
- [Project guide](AGENTS.project.md)

---

## 🤝 Credits

<a id="credits"></a>

Built with care by **Don Noel** and Codex collaboration.

<a id="final-note"></a>

### Final Note

Pause is intentionally small — a tiny pocket of calm in a noisy world.
If this project inspires you, improves your day, or teaches you something about SwiftUI architecture, that makes it all worth it.
