# ✨ **Pause**

### *Breathe deeper. Slow down. Return to yourself.*

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-6.0-orange?logo=swift">
  <img src="https://img.shields.io/badge/Platform-iOS_|_iPadOS-blue">
  <img src="https://img.shields.io/badge/License-MIT-green">
</p>

⸻

🌿 Pause – A Minimal, Intentional Breathing & Mindfulness Timer

A clean, distraction-free meditation experience for iOS and iPadOS.

Pause is a beautifully simple breathing & meditation timer built entirely in Swift and SwiftUI. Designed to get out of your way, Pause helps you settle your mind, breathe intentionally, and take short restorative breaks throughout the day — without ads, clutter, or noise.

This project includes the full iOS app, accessory Lock Screen widgets, and a lightweight audio system for gentle chimes and session guidance.

⸻

✨ Features

🕊 Minimal Breathing Sessions

Pause offers preset session lengths — 5, 10, 15, and 20 minutes — powered by `SessionDurationPreset`. Each session is managed by `SessionViewModel`, which tracks:
	•	elapsed time
	•	remaining time
	•	start / pause / resume / end
	•	session completion
	•	persistent state during app backgrounding

Preset and custom duration controls now configure the upcoming session only. Starting is always a deliberate tap on the primary **Begin** action.

Pause also supports selectable breathing styles: **Quiet Timer**, **Box Breath**, **Calm Exhale**, and **Equal Breath**.

Optional ritual presets are available to quickly configure both duration and breathing style: **Reset**, **Focus**, **Unwind**, and **Sleep Wind Down**.

After a fully completed session, you can optionally add a one-tap reflection: **Calm**, **Okay**, or **Restless**.

🔔 Gentle Audio Chimes

A lightweight AudioChimePlayer wraps AVAudioPlayer to deliver soft, unobtrusive tones for:
	•	session start
	•	optional interval chimes
	•	session end

The audio system includes graceful error handling for missing or unsupported audio files during normal app use.
The app does not use background audio keep-alive; active-session timing is restored from persisted session dates when the app returns to the foreground.

📊 Session Stats

Pause includes a Stats sheet with:
	•	a calendar that marks days with fully completed sessions
	•	your usual meditation time (based on completed sessions)
	•	your last completed meditation
	•	average completed session length
	•	iCloud sync for completed-session insights across devices on the same Apple ID

Partial or cancelled sessions are not recorded in the calendar or summary stats.

🏞 Custom SwiftUI Experience

Pause uses clean, modern SwiftUI views and a lightweight design system across:
	•	a single-screen session flow (idle, running/paused, completed)
	•	configuration cards for ritual, duration, and breathing style
	•	a breathing-orb timer focal element with progress and optional phase cues
	•	a calm completion reflection step
	•	a card-based Insights sheet

Everything is intentionally minimal and soothing — nothing steals focus.

📱 Lock Screen Widget

The included Pause widget keeps session state glanceable and calm on accessory surfaces:
	•	ready state with a minimal “Ready to begin” cue
	•	active-session remaining time countdown when relevant
	•	accessory families: circular, rectangular, and inline
	•	shared state via PauseSessionStore (app-group compatible)
	•	WidgetKit timeline reload support

🛰 Live Activity Status

Pause does not currently ship a Live Activity. Template Live Activity scaffolding was removed until a production-ready ActivityKit lifecycle is implemented in the app target.

📦 Clean App Architecture

Pause uses a deliberately simple architecture:

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
│   ├── PauseSessionStore.swift     # Shared model for widgets & app
│   └── BackgroundAudioManager.swift# Background-audio compatibility shim
└── Views/
    └── SessionView.swift           # Main session + insights surfaces

The codebase avoids unnecessary complexity, making it approachable and ideal for learning modern SwiftUI patterns.

⌚ Background-Safe Timer Handling

MeditationTimerEngine uses Combine while the app is active, and PauseSessionStore preserves session dates so timing and widgets restore cleanly after backgrounding.

⸻

🧩 Technologies Used
	•	Swift 5 / SwiftUI
	•	Combine
	•	AVFoundation for audio
	•	WidgetKit
	•	App Groups for shared storage
	•	NSUbiquitousKeyValueStore for Insights sync
	•	Xcode 17+
	•	Clean MVVM-ish architecture

⸻

🚀 Getting Started

Clone the repo:

git clone https://github.com/yourusername/Pause.git
open Pause.xcodeproj

Make sure you have:
	•	Xcode 17 or newer
	•	an iOS Simulator runtime installed
	•	A team signing identity for running on a device

You can run Pause in the simulator, but sound playback and background behavior work best on a physical device.

⸻

🧱 App Structure Overview

SessionViewModel

The heart of Pause. Tracks:
	•	session duration
	•	state transitions (idle → running → paused → completed)
	•	timer lifecycle
	•	persisted session restoration for background-safe timing

MeditationTimerEngine

Lightweight Combine-powered engine updates time every second with minimal overhead.

AudioChimePlayer

Handles chime playback and formatting. Clean, compact, safe.

PauseSessionStore

Shared container used by both the app and the widget. It exposes:
	•	remaining time
	•	session state
	•	triggers widget timeline reloads

⸻

🎨 Design Philosophy

Pause tries to feel like a breath of fresh air:
	•	Soft tonal accent colors
	•	Minimal screen elements
	•	Clear, approachable typography
	•	No clutter, no gamification, no noise
	•	Just tap → breathe → finish

It’s a meditation timer that respects your attention.

⸻

🧪 Tests Included

The project includes unit tests for:
	•	session timing behavior
	•	state transitions
	•	persistence logic via PauseSessionStore

Run tests via:

⌘ + U


⸻

🤝 Contributing

Pull requests are welcome. If you’d like to improve animations, add additional breathing modes, or enhance widget functionality, open an issue and let’s talk.


🌟 Final Note

Pause is intentionally small — a tiny pocket of calm in a noisy world.
If this project inspires you, improves your day, or teaches you something about SwiftUI architecture, that makes it all worth it.

⸻
