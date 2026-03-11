import SwiftUI

struct SessionView: View {
    @StateObject private var viewModel: SessionViewModel
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    
    @State private var customMinutesSelection: Int = 5
    @State private var isStatsSheetPresented: Bool = false
    
    init(viewModel: SessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            MeditationColors.backgroundPrimary(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                header
                
                // Vertical gap between the header and the ring; larger on iPad so the ring sits lower
                Spacer()
                    .frame(height: horizontalSizeClass == .regular ? 250 : 48)
                
                timeDisplay
                
                // Single flexible spacer below the ring pushes content down,
                // which visually lifts the ring higher on taller screens.
                Spacer()
                
                presetRow
                
                primaryControls
            }
            .padding(24)
        }
        .sheet(isPresented: $viewModel.isCustomDurationSheetPresented) {
            customDurationSheet
        }
        .sheet(isPresented: $isStatsSheetPresented) {
            statsSheet
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 12) {
            Text("Stillness")
                .font(.title2.weight(.semibold))
                .foregroundColor(MeditationColors.textPrimary)
            
            Text("Choose a duration and rest in silence.\nA soft bell will ring halfway and at the end.")
                .font(.subheadline)
                .foregroundColor(MeditationColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                isStatsSheetPresented = true
            } label: {
                Label("Insights", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(MeditationColors.backgroundSecondary)
                    )
            }
            .buttonStyle(.plain)
            .foregroundColor(MeditationColors.textPrimary)
            .accessibilityHint(Text("Opens calendar and meditation stats."))
        }
        .accessibilityElement(children: .contain)
    }
    
    private var timeDisplay: some View {
        let ringSize: CGFloat = (horizontalSizeClass == .regular) ? 260 : 200

        return VStack(spacing: 12) {
            progressRing
                .frame(width: ringSize, height: ringSize)

            if viewModel.state == .completed {
                Text("Session complete")
                    .font(.headline)
                    .foregroundColor(MeditationColors.textSecondary)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25),
                   value: viewModel.state)
    }
    
    private var progressRing: some View {
        let progress: CGFloat
        if viewModel.total > 0 {
            progress = 1 - CGFloat((viewModel.remaining) / viewModel.total)
        } else {
            progress = 0
        }
        
        return ZStack {
            // Background track – soft but clearly visible
            Circle()
                .stroke(lineWidth: 10)
                .foregroundStyle(
                    Color.white.opacity(0.35)
                )

            // Active progress – accent color with a gentle glow
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundStyle(MeditationColors.accentPrimary)
                .shadow(
                    color: MeditationColors.accentPrimary.opacity(0.30),
                    radius: 10,
                    x: 0,
                    y: 6
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.3),
                    value: progress
                )

            // Timer text centered inside the ring
            Text(formattedTime(viewModel.remaining > 0 ? viewModel.remaining : viewModel.total))
                .font(timerFont)
                .monospacedDigit()
                .foregroundColor(MeditationColors.textPrimary)
                .accessibilityLabel(
                    Text(
                        "Time \(viewModel.state == .running || viewModel.state == .paused ? "remaining" : "selected"): \(formattedAccessibleTime(viewModel.remaining > 0 ? viewModel.remaining : viewModel.total))"
                    )
                )
        }
    }
    
    @ViewBuilder
    private var presetRow: some View {
        if horizontalSizeClass == .regular {
            // iPad / regular width: centered, no scroll (they all fit nicely)
            presetRowContent
                .frame(maxWidth: .infinity)          // takes full width
                .padding(.horizontal, 24)            // matches the Start button area visually
        } else {
            // iPhone / compact width: keep horizontal scrolling + left-ish behavior
            ScrollView(.horizontal, showsIndicators: false) {
                presetRowContent
                    .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private var presetRowContent: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presets) { preset in
                DurationPill(
                    title: preset.label,
                    isSelected: viewModel.selectedPreset == preset
                ) {
                    viewModel.startPreset(preset)
                }
                .accessibilityHint(Text("Starts a \(preset.label) meditation timer."))
            }

            DurationPill(
                title: "Custom…",
                isSelected: viewModel.selectedPreset == nil && viewModel.state != .idle
            ) {
                customMinutesSelection = viewModel.customDurationMinutes
                viewModel.isCustomDurationSheetPresented = true
            }
            .accessibilityHint(Text("Choose a custom meditation duration."))
        }
    }
    
    private var primaryControls: some View {
        VStack(spacing: 12) {
            Button(action: primaryButtonTapped) {
                Text(primaryButtonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(Text(primaryButtonAccessibilityLabel))
            
            if viewModel.state == .running || viewModel.state == .paused {
                Button(role: .destructive) {
                    Haptics.destructive()
                    viewModel.cancel()
                } label: {
                    Text("Cancel session")
                        .font(.body)
                }
                .accessibilityLabel(Text("Cancel current session"))
            } else if viewModel.state == .completed {
                Button {
                    viewModel.resetCompletion()
                } label: {
                    Text("New session")
                        .font(.body)
                        .foregroundColor(MeditationColors.textSecondary)
                }
                .accessibilityLabel(Text("Start a new session"))
            }
        }
    }
    
    private var primaryButtonTitle: String {
        switch viewModel.state {
        case .idle, .completed:
            return "Start"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        }
    }
    
    private var primaryButtonAccessibilityLabel: String {
        switch viewModel.state {
        case .idle, .completed:
            return "Start meditation"
        case .running:
            return "Pause meditation"
        case .paused:
            return "Resume meditation"
        }
    }
    
    private func primaryButtonTapped() {
        switch viewModel.state {
        case .idle, .completed:
            Haptics.primary()
            if let preset = viewModel.selectedPreset {
                viewModel.startPreset(preset)
            } else {
                viewModel.isCustomDurationSheetPresented = true
            }
        case .running, .paused:
            Haptics.selection()
            viewModel.togglePause()
        }
    }
    
    private var timerFont: Font {
        if horizontalSizeClass == .regular {
            // iPad
            return .system(size: 54, weight: .medium, design: .rounded)
        } else {
            // iPhone (unchanged)
            return .system(.largeTitle, design: .rounded)
        }
    }
    
    private var customDurationSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section("Minutes") {
                        Picker("Duration", selection: $customMinutesSelection) {
                            ForEach(1..<61) { minute in
                                Text("\(minute) minutes")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .labelsHidden()
                    }
                }
                
                Button {
                    viewModel.startCustomDuration(minutes: customMinutesSelection)
                    viewModel.isCustomDurationSheetPresented = false
                } label: {
                    Text("Start \(customMinutesSelection)-minute session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isCustomDurationSheetPresented = false
                    }
                }
            }
        }
    }

    private var statsSheet: some View {
        NavigationStack {
            List {
                Section("Calendar") {
                    MultiDatePicker(
                        "Completed sessions",
                        selection: .constant(viewModel.completedSessionDates)
                    )
                    .labelsHidden()
                    .allowsHitTesting(false)
                    .accessibilityLabel(Text("Calendar of completed sessions"))

                    Text("Only fully completed sessions are recorded.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Details") {
                    statsRow(
                        title: "Sessions completed",
                        value: "\(viewModel.completedSessionCount)"
                    )
                    statsRow(
                        title: "Usually meditate",
                        value: viewModel.usualMeditationTimeDescription
                    )
                    statsRow(
                        title: "Last meditation",
                        value: viewModel.lastMeditationDescription
                    )
                    statsRow(
                        title: "Average session length",
                        value: viewModel.averageSessionLengthDescription
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isStatsSheetPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Formatting

    @ViewBuilder
    private func statsRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(MeditationColors.textSecondary)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundColor(MeditationColors.textPrimary)
        }
        .padding(.vertical, 2)
    }
    
    private func formattedTime(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "0:00" }
        let totalSeconds = Int(interval.rounded(.up))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formattedAccessibleTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval.rounded(.up))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 && seconds > 0 {
            return "\(minutes) minutes, \(seconds) seconds"
        } else if minutes > 0 {
            return "\(minutes) minutes"
        } else {
            return "\(seconds) seconds"
        }
    }
}

extension SessionViewModel {
    /// Convenience initializer for the app: wires up the default engine + chime player.
    convenience init() {
        let engine = MeditationTimerEngine()
        let chimePlayer = SystemAudioChimePlayer()
        self.init(timerEngine: engine, chimePlayer: chimePlayer)
    }
}
