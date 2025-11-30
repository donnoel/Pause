🌿 Pause – A Minimal, Intentional Breathing & Mindfulness Timer

A clean, distraction-free meditation experience for iOS and iPadOS.

Pause is a beautifully simple breathing & meditation timer built entirely in Swift and SwiftUI. Designed to get out of your way, Pause helps you settle your mind, breathe intentionally, and take short restorative breaks throughout the day — without ads, clutter, or noise.

This project includes the full iOS app, an accompanying Home Screen widget, and a lightweight audio system for gentle chimes and session guidance.

⸻

✨ Features

🕊 Minimal Breathing Sessions

Pause offers preset session lengths — 5, 10, 15, and 20 minutes — powered by a clean SessionDurationPreset model. Each session is fully managed by a simple but robust SessionViewModel that tracks:
	•	elapsed time
	•	remaining time
	•	play / pause / resume
	•	session completion
	•	persistent state during app backgrounding

🔔 Gentle Audio Chimes

A lightweight AudioChimePlayer wraps AVAudioPlayer to deliver soft, unobtrusive tones for:
	•	session start
	•	optional interval chimes
	•	session end

The audio system includes graceful error handling for missing or unsupported audio files and works beautifully in the background.

🏞 Custom SwiftUI Experience

Pause uses clean, modern SwiftUI views and a lightweight nap-friendly design system across:
	•	the main session view
	•	duration picker
	•	animated circular timer
	•	calming themed accent colors (Airy / Calm / Breath / Pause palettes)
	•	subtle haptic suggestions via the UI interactions

Everything is intentionally minimal and soothing — nothing steals focus.

📱 Home Screen Widget

The included PauseWidget brings quick-start functionality directly onto the Home Screen:
	•	tap to launch straight into a preferred session
	•	dynamically themed background
	•	shared state via PauseSessionStore
	•	WidgetKit timeline reload support

📦 Clean App Architecture

Pause uses a deliberately simple architecture:

PauseApp.swift
├── AppCoordinator.swift            # High-level flow
├── ViewModels/
│   ├── SessionViewModel.swift      # Drives session logic & duration tracking
│   └── SessionModels.swift         # Session enums & presets
├── Components/
│   ├── AudioChimePlayer.swift      # Chime playback subsystem
│   ├── PauseSessionStore.swift     # Shared model for widgets & app
│   ├── MeditationTimer.swift       # Core timing logic with Combine
└── Views/
    └── …                           # SwiftUI UI components

The codebase avoids unnecessary complexity, making it approachable and ideal for learning modern SwiftUI patterns.

⌚ Background-Safe Timer Handling

MeditationTimer uses Combine to keep accurate timing even when the app goes to the background, and hands off cleanly to PauseSessionStore for state persistence.

⸻

🧩 Technologies Used
	•	Swift 5 / SwiftUI
	•	Combine
	•	AVFoundation for audio
	•	WidgetKit
	•	App Groups for shared storage
	•	Xcode 15+
	•	Clean MVVM-ish architecture

⸻

🚀 Getting Started

Clone the repo:

git clone https://github.com/yourusername/Pause.git
open Pause.xcodeproj

Make sure you have:
	•	Xcode 15 or newer
	•	iOS 17 SDK
	•	A team signing identity for running on a device

You can run Pause in the simulator, but sound playback and background behavior work best on a physical device.

⸻

🧱 App Structure Overview

SessionViewModel

The heart of Pause. Tracks:
	•	session duration
	•	state transitions (idle → running → paused → completed)
	•	timer lifecycle
	•	background audio keep-alive

MeditationTimer

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

⸻

📄 License

Pause is available under the MIT license.
See LICENSE for details.

⸻

🌟 Final Note

Pause is intentionally small a tiny pocket of calm in a noisy world.
If this project inspires you, improves your day, or teaches you something about SwiftUI architecture, that makes it all worth it.

⸻
