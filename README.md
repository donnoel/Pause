✨ Pause

Breathe deeper. Slow down. Return to yourself.

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-6.0-orange?logo=swift">
  <img src="https://img.shields.io/badge/Platform-iOS_18_|_iPadOS_18-blue">
  <img src="https://img.shields.io/badge/License-MIT-green">
</p>



⸻

🌟 What is Pause?

Pause is a minimal, calming meditation & breathing timer built with SwiftUI, Combine, and WidgetKit.
It’s designed to be soft, soothing, and distraction-free — no gamification, no clutter, just a gentle way to take a moment for yourself.

Pause helps you breathe, rest, and reset.

⸻

💎 Core Features

A gentle meditation experience:

Feature	Description
🕊 Clean, Minimal Design	A quiet and intentional interface that supports your breathing without demanding attention.
⏱️ Simple Session Durations	Choose from preset lengths (5, 10, 15, 20 minutes).
🔔 Soft Chime Playback	Gentle bell sounds for session start, intervals, and completion.
🧘 Beautiful Timer UI	Circular progress, subtle animations, and calm color palettes.
🔄 Pause, Resume & Restore	Session state persists across app backgrounding and interruptions.
📲 Home Screen Widget	Quick-launch your favorite session directly from your Home Screen.
💾 Shared App Groups	Syncs state between the main app and the widget.
🌗 Adaptive Themes	Light, Dark, high-contrast, and dynamic color responsiveness.
🪄 Haptic Suggestions	Optional, gentle tactile feedback during interactions.


⸻

🛠 Built With
	•	Swift 6
	•	SwiftUI
	•	Combine
	•	WidgetKit
	•	AVFoundation (for chimes)
	•	App Groups (data sharing)
	•	State-driven MVVM architecture

⸻

🧭 Experience Flow

Pause keeps the interaction intentionally small:
	1.	Launch the app 🌿
	2.	Pick a session duration ⏱️
	3.	Tap to begin ✨
	4.	Rest while the circular timer progresses 🧘
	5.	Gentle chime marks the end 🔔

The UI emphasizes calm, presence, and clarity.

⸻

📁 Project Structure

Pause/
├── App/
│   └── PauseApp.swift
├── Coordinator/
│   └── AppCoordinator.swift
├── Domain/
│   ├── SessionDurationPreset.swift
│   ├── MeditationTimer.swift
│   └── AudioChimePlayer.swift
├── ViewModels/
│   └── SessionViewModel.swift
├── Views/
│   ├── SessionView.swift
│   ├── DurationPickerView.swift
│   ├── TimerCircleView.swift
│   └── Components/
│       ├── PauseButton.swift
│       └── ChimeToggleRow.swift
├── Widget/
│   ├── PauseWidget.swift
│   └── PauseWidgetBundle.swift
├── Store/
│   └── PauseSessionStore.swift
└── Resources/
    └── Chimes/
        ├── bell-soft.wav
        ├── bell-end.wav
        └── …


⸻

🧩 Core Components

SessionViewModel

Manages all meditation session logic:
	•	session lifecycle (idle → running → paused → completed)
	•	time tracking
	•	background safe-keeping
	•	haptic coordination

MeditationTimer
	•	Built with Combine
	•	Emits tick updates every second
	•	Survives background transitions gracefully
	•	Extremely lightweight

AudioChimePlayer
	•	Wraps AVAudioPlayer
	•	Plays soft chimes for start, midpoint, and completion
	•	Error-safe and background aware

PauseSessionStore
	•	Bridges the main app and the widget
	•	Stores remaining time & session status
	•	Uses App Groups for reliability

Widget
	•	Quick-start a session with one tap
	•	Dynamically updates via shared store
	•	Clean, simple widget design

⸻

⚡ Performance

Pause is tuned to stay feather-light:
	•	Combine-driven timer (minimal overhead)
	•	No extra view recomposition
	•	Cached chime players
	•	Clean animation curves for smoothness
	•	Shared store avoids duplicate work
	•	Efficient state updates for WidgetKit

The app stays whisper-fast even on older devices or extension-heavy setups.

⸻

🧪 Tests

Pause includes focused tests for:
	•	Session timing transitions
	•	Pause/resume logic
	•	Session completion calculations
	•	AudioChimePlayer safety
	•	Shared store behavior
	•	Widget timeline generation

⸻

🧩 Roadmap
	•	Custom breathing patterns (box, 4-7-8, resonance)
	•	Interval chime customization
	•	Visual themes (forest, ocean, sunrise)
	•	Lock screen widgets
	•	Long-form session journaling
	•	iPad layouts + Stage Manager support

⸻

❤️ Credits

Built with intention by Don Noel,
with engineering support from Bella, my AI collaborator ✨

⸻

📄 License

MIT License

⸻

Pause is a breath in app form — quiet, grounding, and always there when you need a moment.
