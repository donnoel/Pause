import SwiftUI

struct SessionView: View {
    @StateObject private var viewModel: SessionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .largeTitle) private var heroBaseSize: CGFloat = 230

    @State private var customMinutesSelection: Int = 5
    @State private var isStatsSheetPresented: Bool = false
    @State private var isOrbExpanded: Bool = false

    init(viewModel: SessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            MeditationColors.backgroundPrimary(for: colorScheme)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    sessionLayout(minHeight: proxy.size.height)
                }
            }
        }
        .sheet(isPresented: $viewModel.isCustomDurationSheetPresented) {
            customDurationSheet
        }
        .sheet(isPresented: $isStatsSheetPresented) {
            statsSheet
        }
        .onAppear {
            updateOrbMotionState()
        }
        .onChange(of: viewModel.state) { _, _ in
            updateOrbMotionState()
        }
        .onChange(of: reduceMotion) { _, _ in
            updateOrbMotionState()
        }
    }

    // MARK: - Layout

    private func sessionLayout(minHeight: CGFloat) -> some View {
        VStack(spacing: 24) {
            topRegion
            heroRegion

            if viewModel.state == .idle {
                configurationRegion
            }

            actionRegion
        }
        .padding(.horizontal, horizontalSizeClass == .regular ? 32 : 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: maxContentWidth)
        .frame(minHeight: minHeight, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var maxContentWidth: CGFloat {
        horizontalSizeClass == .regular ? 580 : 680
    }

    // MARK: - Regions

    private var topRegion: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pause")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(MeditationColors.textPrimary)

                Text(contextLine)
                    .font(.subheadline)
                    .foregroundColor(MeditationColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let supportingLine {
                    Text(supportingLine)
                        .font(.footnote)
                        .foregroundColor(MeditationColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Button {
                isStatsSheetPresented = true
            } label: {
                Label("Insights", systemImage: "chart.bar")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(MeditationColors.surfacePrimary(for: colorScheme))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(MeditationColors.surfaceStroke(for: colorScheme), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .foregroundColor(MeditationColors.textPrimary)
            .accessibilityHint(Text("Opens calendar and meditation stats."))
        }
    }

    private var heroRegion: some View {
        VStack(spacing: 12) {
            breathingOrb
                .frame(width: heroDiameter, height: heroDiameter)
                .frame(maxWidth: .infinity)

            if let phaseCueText {
                Text(phaseCueText)
                    .font(.headline.weight(.medium))
                    .foregroundColor(MeditationColors.textPrimary)
                    .transition(.opacity)
            }

            if let heroSublabel {
                Text(heroSublabel)
                    .font(.footnote)
                    .foregroundColor(MeditationColors.textSecondary)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: viewModel.state)
    }

    private var configurationRegion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MeditationColors.textPrimary)

            ViewThatFits(in: .horizontal) {
                durationRow

                ScrollView(.horizontal, showsIndicators: false) {
                    durationRow
                        .padding(.vertical, 2)
                }
            }

            Text(selectionDescription)
                .font(.footnote)
                .foregroundColor(MeditationColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(MeditationColors.surfacePrimary(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MeditationColors.surfaceStroke(for: colorScheme), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private var actionRegion: some View {
        VStack(spacing: 12) {
            Button(action: primaryButtonTapped) {
                Text(primaryButtonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(Text(primaryButtonAccessibilityLabel))
            .accessibilityHint(Text(primaryButtonAccessibilityHint))

            if viewModel.state == .running || viewModel.state == .paused {
                Button(role: .destructive) {
                    Haptics.destructive()
                    viewModel.cancel()
                } label: {
                    Text("End Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel(Text("End current session"))
            } else if viewModel.state == .completed {
                Button {
                    viewModel.resetCompletion()
                } label: {
                    Text("New Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(MeditationColors.accentPrimary)
                .accessibilityLabel(Text("Prepare a new session"))
            }
        }
    }

    // MARK: - Pieces

    private var breathingOrb: some View {
        let progress = ringProgress

        return ZStack {
            Circle()
                .fill(MeditationColors.orbOuterGradient(for: colorScheme))
                .overlay(
                    Circle()
                        .stroke(MeditationColors.surfaceStroke(for: colorScheme), lineWidth: 1)
                )
                .shadow(
                    color: MeditationColors.accentPrimary.opacity(colorScheme == .dark ? 0.24 : 0.18),
                    radius: colorScheme == .dark ? 18 : 14,
                    x: 0,
                    y: 8
                )

            Circle()
                .fill(MeditationColors.orbInnerGradient(for: colorScheme))
                .padding(heroDiameter * 0.12)
                .scaleEffect(orbScale)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: isOrbExpanded)

            Circle()
                .stroke(MeditationColors.ringTrack(for: colorScheme), lineWidth: 9)
                .padding(4)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 9,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundStyle(MeditationColors.accentPrimary)
                .shadow(
                    color: MeditationColors.accentPrimary.opacity(0.28),
                    radius: 9,
                    x: 0,
                    y: 4
                )
                .rotationEffect(.degrees(-90))
                .padding(4)
                .opacity(progress == 0 ? 0.35 : 1)

            VStack(spacing: 6) {
                Text(formattedTime(displayedInterval))
                    .font(timerFont)
                    .monospacedDigit()
                    .foregroundColor(MeditationColors.textPrimary)

                Text(centerCaption)
                    .font(.subheadline)
                    .foregroundColor(MeditationColors.textSecondary)
            }
            .padding(24)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                "Time \(viewModel.state == .running || viewModel.state == .paused ? "remaining" : "selected"): \(formattedAccessibleTime(displayedInterval))"
            )
        )
    }

    private var durationRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presets) { preset in
                DurationPill(
                    title: preset.label,
                    isSelected: viewModel.selectedPreset == preset
                ) {
                    viewModel.selectPreset(preset)
                }
                .accessibilityHint(Text("Selects a \(preset.label) session."))
            }

            DurationPill(
                title: "Custom…",
                isSelected: viewModel.selectedPreset == nil
            ) {
                customMinutesSelection = viewModel.customDurationMinutes
                viewModel.isCustomDurationSheetPresented = true
            }
            .accessibilityHint(Text("Choose a custom duration."))
        }
    }

    // MARK: - Text and State

    private var contextLine: String {
        switch viewModel.state {
        case .idle:
            return "Take a few minutes to reset."
        case .running:
            return "Stay with your breath."
        case .paused:
            return "Session paused."
        case .completed:
            return "Session complete."
        }
    }

    private var supportingLine: String? {
        if viewModel.state == .idle {
            return "Gentle bells ring halfway and at the end."
        }
        return nil
    }

    private var centerCaption: String {
        if viewModel.state == .idle {
            return selectedDurationLabel
        }
        if viewModel.state == .completed {
            return "Completed"
        }
        return "Remaining"
    }

    private var phaseCueText: String? {
        switch viewModel.state {
        case .running:
            return breathingCue
        case .paused:
            return "Paused"
        default:
            return nil
        }
    }

    private var heroSublabel: String? {
        switch viewModel.state {
        case .idle:
            return "Ready when you are"
        case .completed:
            return "Finished \(formattedTime(viewModel.total))"
        default:
            return nil
        }
    }

    private var selectionDescription: String {
        if viewModel.selectedPreset == nil {
            return "Custom duration: \(viewModel.customDurationMinutes) min selected."
        }
        return "Selected: \(selectedDurationLabel)."
    }

    private var selectedDurationLabel: String {
        if let preset = viewModel.selectedPreset {
            return preset.label
        }
        return "\(viewModel.customDurationMinutes) min"
    }

    private var breathingCue: String {
        guard viewModel.total > 0 else { return "Breathe" }
        let elapsed = max(0, viewModel.total - viewModel.remaining)
        let phaseSecond = Int(elapsed.rounded(.down)) % 12

        switch phaseSecond {
        case 0...3:
            return "Inhale"
        case 4...5:
            return "Hold"
        case 6...9:
            return "Exhale"
        default:
            return "Hold"
        }
    }

    private var heroDiameter: CGFloat {
        horizontalSizeClass == .regular ? heroBaseSize * 1.25 : heroBaseSize
    }

    private var orbScale: CGFloat {
        guard !reduceMotion, viewModel.state == .idle else { return 1.0 }
        return isOrbExpanded ? 1.03 : 0.97
    }

    private var displayedInterval: TimeInterval {
        switch viewModel.state {
        case .running, .paused:
            return viewModel.remaining
        case .idle:
            return viewModel.selectedDuration
        case .completed:
            return viewModel.total
        }
    }

    private var ringProgress: CGFloat {
        switch viewModel.state {
        case .completed:
            return 1
        case .running, .paused:
            guard viewModel.total > 0 else { return 0 }
            let ratio = 1 - (viewModel.remaining / viewModel.total)
            return CGFloat(min(max(ratio, 0), 1))
        case .idle:
            return 0
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.state {
        case .idle:
            return "Begin"
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .completed:
            return "Start Another"
        }
    }

    private var primaryButtonAccessibilityLabel: String {
        switch viewModel.state {
        case .idle:
            return "Begin selected session"
        case .running:
            return "Pause meditation"
        case .paused:
            return "Resume meditation"
        case .completed:
            return "Start another session"
        }
    }

    private var primaryButtonAccessibilityHint: String {
        switch viewModel.state {
        case .idle, .completed:
            return "Starts the selected duration"
        case .running:
            return "Pauses the active session"
        case .paused:
            return "Resumes the active session"
        }
    }

    private func primaryButtonTapped() {
        switch viewModel.state {
        case .idle, .completed:
            Haptics.primary()
            viewModel.startSelectedSession()
        case .running, .paused:
            Haptics.selection()
            viewModel.togglePause()
        }
    }

    private func updateOrbMotionState() {
        guard !reduceMotion, viewModel.state == .idle else {
            isOrbExpanded = false
            return
        }

        guard !isOrbExpanded else { return }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            isOrbExpanded = true
        }
    }

    private var timerFont: Font {
        if horizontalSizeClass == .regular {
            return .system(size: 58, weight: .medium, design: .rounded)
        } else {
            return .system(size: 50, weight: .medium, design: .rounded)
        }
    }

    // MARK: - Sheets

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

                VStack(spacing: 8) {
                    Button {
                        viewModel.selectCustomDuration(minutes: customMinutesSelection)
                        viewModel.isCustomDurationSheetPresented = false
                    } label: {
                        Text("Use \(customMinutesSelection)-minute duration")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Text("Tap Begin on the session screen when you're ready.")
                        .font(.footnote)
                        .foregroundColor(MeditationColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
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
