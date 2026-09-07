import SwiftUI

struct SessionView: View {
    @StateObject private var viewModel: SessionViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric(relativeTo: .largeTitle) private var heroBaseSize: CGFloat = 230

    @State private var customMinutesSelection: Int = 5
    @State private var isStatsSheetPresented: Bool = false
    @State private var hideCountdown = false

    init(viewModel: SessionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            MeditationColors.backgroundPrimary(for: sessionColorScheme)
                .overlay(ritualTint.opacity(sessionColorScheme == .dark ? 0.07 : 0.09))
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
                .presentationDetents(insightsPresentationDetents)
                .presentationDragIndicator(.visible)
        }
        .environment(\.colorScheme, sessionColorScheme)
        .onChange(of: viewModel.state) { _, newState in
            if newState == .idle { hideCountdown = false }
        }
    }

    // MARK: - Layout

    private func sessionLayout(minHeight: CGFloat) -> some View {
        VStack(spacing: isRegularWidth ? 22 : 18) {
            topRegion
            if isActive { Spacer(minLength: 24) }
            heroRegion

            if viewModel.state == .idle {
                configurationRegion
            }

            if viewModel.state == .completed {
                reflectionRegion
            }

            actionRegion
            if isActive { Spacer(minLength: 24) }
        }
        .padding(.horizontal, isRegularWidth ? 24 : 16)
        .padding(.top, isRegularWidth ? 18 : 14)
        .padding(.bottom, isRegularWidth ? 22 : 18)
        .frame(maxWidth: maxContentWidth)
        .frame(minHeight: max(0, minHeight - 40), alignment: .top)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(reduceMotion || viewModel.state != .completed ? nil : .easeOut(duration: 1.2), value: viewModel.state)
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var isRegularPortrait: Bool {
        isRegularWidth && verticalSizeClass != .compact
    }

    private var maxContentWidth: CGFloat {
        isRegularWidth ? 900 : 760
    }

    // MARK: - Regions

    private var topRegion: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Pause")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(MeditationColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

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
                    .font(.footnote.weight(.semibold))
                    .frame(minHeight: 30)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(MeditationColors.surfaceElevated(for: sessionColorScheme))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(MeditationColors.surfaceElevatedStroke(for: sessionColorScheme), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .foregroundColor(MeditationColors.textPrimary)
            .accessibilityHint(Text("Opens calendar and meditation stats."))
        }
    }

    private var isActive: Bool {
        viewModel.state == .running || viewModel.state == .paused
    }

    private var sessionColorScheme: ColorScheme {
        viewModel.selectedRitualPreset == .sleepWindDown ? .dark : colorScheme
    }

    private var ritualTint: Color {
        switch viewModel.selectedRitualPreset {
        case .reset: return .mint
        case .focus: return .cyan
        case .unwind: return .orange
        case .sleepWindDown: return .indigo
        case nil: return MeditationColors.accentPrimary
        }
    }

    private var heroRegion: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30,
                                paused: viewModel.state != .running || viewModel.breathingStyleForCurrentSession == .quietTimer)) { context in
            let phase = isActive ? viewModel.breathingStyleForCurrentSession.phase(
                elapsed: viewModel.breathingElapsed(at: context.date)) : nil
            VStack(spacing: 24) {
                breathingOrb(phase: phase)
                    .frame(width: heroDiameter, height: heroDiameter)
                    .frame(maxWidth: .infinity)

                if viewModel.state == .paused {
                    Text("Paused").font(.headline)
                } else if let phase {
                    Text(phase.cue).font(.headline)
                }

                if let heroSublabel {
                    Text(heroSublabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.top, isRegularPortrait && !isActive ? 32 : 0)
    }

    private var configurationRegion: some View {
        SessionConfigurationCard(
            isRegularWidth: isRegularWidth,
            colorScheme: sessionColorScheme,
            selectionDescription: selectionDescription
        ) {
            configurationSection(title: "Ritual") {
                ritualSelector
            }

            configurationDivider

            configurationSection(title: "Duration") {
                ViewThatFits(in: .horizontal) {
                    durationRow

                    ScrollView(.horizontal, showsIndicators: false) {
                        durationRow
                            .padding(.vertical, 2)
                    }
                }
            }

            configurationDivider

            configurationSection(title: "Breathing Style") {
                breathingStyleSelector

            }
        }
    }

    private var actionRegion: some View {
        VStack(spacing: 10) {
            if isActive && viewModel.selectedRitualPreset == .sleepWindDown {
                Button {
                    hideCountdown.toggle()
                } label: {
                    Text(hideCountdown ? "Show countdown" : "Hide countdown")
                        .font(.subheadline)
                        .frame(minHeight: 44)
                }
            }
            Button(action: primaryButtonTapped) {
                Text(primaryButtonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(isActive ? Color.primary.opacity(0.08) : MeditationColors.accentPrimary,
                                in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(primaryButtonAccessibilityLabel))
            .accessibilityHint(Text(primaryButtonAccessibilityHint))

            if viewModel.state == .running || viewModel.state == .paused {
                Button(role: .destructive) {
                    Haptics.destructive()
                    viewModel.cancel()
                } label: {
                    Text("End Session")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
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
        .frame(maxWidth: isActive ? 320 : actionMaxWidth)
    }

    private var reflectionRegion: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflection")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MeditationColors.textPrimary)

            Text("How do you feel right now?")
                .font(.footnote)
                .foregroundColor(MeditationColors.textSecondary)

            ViewThatFits(in: .horizontal) {
                reflectionRow

                ScrollView(.horizontal, showsIndicators: false) {
                    reflectionRow
                        .padding(.vertical, 2)
                }
            }

            if let selectedReflection = viewModel.selectedReflection {
                Text("Noted: \(selectedReflection.title).")
                    .font(.footnote)
                    .foregroundColor(MeditationColors.textSecondary)
            }
        }
        .padding(isRegularWidth ? 18 : 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(MeditationColors.surfacePrimary(for: sessionColorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(MeditationColors.surfaceStroke(for: sessionColorScheme), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    // MARK: - Pieces

    private func breathingOrb(phase: BreathingStyle.Phase?) -> some View {
        BreathingOrbView(
            progress: ringProgress,
            heroDiameter: heroDiameter,
            orbScale: reduceMotion ? 1 : CGFloat(0.68 + 0.32 * (phase?.expansion ?? 0.5)),
            reduceMotion: reduceMotion,
            colorScheme: sessionColorScheme,
            accent: ritualTint,
            timerText: viewModel.state == .completed ? "✓" : formattedTime(displayedInterval),
            timerFont: isActive ? .system(.title, design: .rounded).weight(.medium) : timerFont,
            centerCaption: centerCaption,
            hideCountdown: hideCountdown && isActive,
            accessibilityLabel: [phase?.cue, hideCountdown && isActive ? nil : "Time \(isActive ? "remaining" : "selected"): \(formattedAccessibleTime(displayedInterval))"].compactMap { $0 }.joined(separator: ". ")
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
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHint(Text("Selects a \(preset.label) session."))
            }

            DurationPill(
                title: "Custom…",
                isSelected: viewModel.selectedPreset == nil
            ) {
                customMinutesSelection = viewModel.customDurationMinutes
                viewModel.isCustomDurationSheetPresented = true
            }
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityHint(Text("Choose a custom duration."))
        }
    }

    private var ritualRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.ritualPresets) { ritual in
                DurationPill(
                    title: ritual.title,
                    isSelected: viewModel.selectedRitualPreset == ritual
                ) {
                    viewModel.selectRitualPreset(ritual)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHint(Text("Selects \(ritual.title) ritual preset."))
            }
        }
    }

    private var ritualSelector: some View {
        Group {
            if isRegularWidth {
                ViewThatFits(in: .horizontal) {
                    ritualRow

                    ScrollView(.horizontal, showsIndicators: false) {
                        ritualRow
                            .padding(.vertical, 2)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    ritualRow
                        .padding(.vertical, 2)
                }
            }
        }
    }

    private var breathingStyleRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.breathingStyles) { style in
                DurationPill(
                    title: style.title,
                    isSelected: viewModel.selectedBreathingStyle == style
                ) {
                    viewModel.selectBreathingStyle(style)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHint(Text("Selects \(style.title) breathing style."))
            }
        }
    }

    private var breathingStyleSelector: some View {
        Group {
            if isRegularWidth {
                ViewThatFits(in: .horizontal) {
                    breathingStyleRow

                    ScrollView(.horizontal, showsIndicators: false) {
                        breathingStyleRow
                            .padding(.vertical, 2)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    breathingStyleRow
                        .padding(.vertical, 2)
                }
            }
        }
    }

    private var reflectionRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.reflectionOptions) { reflection in
                DurationPill(
                    title: reflection.title,
                    isSelected: viewModel.selectedReflection == reflection
                ) {
                    viewModel.selectReflection(reflection)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHint(Text("Records \(reflection.title.lowercased()) reflection."))
            }
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

    private var heroSublabel: String? {
        switch viewModel.state {
        case .idle:
            return "Get comfortable. Begin when you’re ready."
        case .completed:
            return "Take your time. Notice how you feel."
        default:
            return nil
        }
    }

    private var selectionDescription: String {
        if let selectedRitual = viewModel.selectedRitualPreset {
            return "Ritual: \(selectedRitual.title) • \(selectedDurationLabel) • \(selectedBreathingStyleLabel)."
        }

        if viewModel.selectedPreset == nil {
            return "Custom duration: \(viewModel.customDurationMinutes) min. Style: \(selectedBreathingStyleLabel)."
        }
        return "Selected: \(selectedDurationLabel) with \(selectedBreathingStyleLabel)."
    }

    private var selectedDurationLabel: String {
        if let preset = viewModel.selectedPreset {
            return preset.label
        }
        return "\(viewModel.customDurationMinutes) min"
    }

    private var selectedBreathingStyleLabel: String {
        viewModel.selectedBreathingStyle.title
    }

    private var heroDiameter: CGFloat {
        if isRegularWidth {
            return min(heroBaseSize * 1.55, 400)
        }
        if verticalSizeClass == .compact {
            return min(heroBaseSize * 1.10, 260)
        }
        return min(heroBaseSize * 1.03, 290)
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

    private var timerFont: Font {
        if isRegularWidth {
            return .system(size: 60, weight: .medium, design: .rounded)
        }
        if verticalSizeClass == .compact {
            return .system(size: 52, weight: .medium, design: .rounded)
        }
        return .system(size: 50, weight: .medium, design: .rounded)
    }

    private var actionMaxWidth: CGFloat {
        if isRegularWidth {
            return 640
        }
        if verticalSizeClass == .compact {
            return 560
        }
        return .infinity
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
        InsightsSheetView(
            isPresented: $isStatsSheetPresented,
            isRegularWidth: isRegularWidth,
            shouldScroll: shouldScrollInsights,
            colorScheme: sessionColorScheme
        ) {
            insightsContent
        }
    }

    private var insightsContent: some View {
        VStack(alignment: .leading, spacing: isRegularWidth ? 12 : 14) {
            insightsHeaderCard
            insightsStatGrid
            insightsCalendarCard
        }
        .padding(.horizontal, isRegularWidth ? 26 : 16)
        .padding(.top, 8)
        .padding(.bottom, isRegularWidth ? 24 : 24)
        .frame(maxWidth: isRegularWidth ? 820 : maxContentWidth)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var insightsPresentationDetents: Set<PresentationDetent> {
        if isRegularWidth {
            return [.fraction(verticalSizeClass == .compact ? 0.98 : 0.97)]
        }
        return [.large]
    }

    private var shouldScrollInsights: Bool {
        !isRegularWidth || verticalSizeClass == .compact
    }

    private var insightsHeaderCard: some View {
        insightCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your rhythm")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundColor(MeditationColors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Text(insightsHeaderDescription)
                    .font(.body)
                    .foregroundColor(MeditationColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var insightsStatGrid: some View {
        let minimumWidth: CGFloat = horizontalSizeClass == .regular ? 180 : 160
        let columns = [GridItem(.adaptive(minimum: minimumWidth), spacing: 12, alignment: .top)]

        return LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            statsCard(
                title: "Sessions completed",
                value: "\(viewModel.completedSessionCount)"
            )
            statsCard(
                title: "Usually meditate",
                value: viewModel.usualMeditationTimeDescription
            )
            statsCard(
                title: "Last meditation",
                value: viewModel.lastMeditationDescription
            )
            statsCard(
                title: "Average session length",
                value: viewModel.averageSessionLengthDescription
            )
        }
    }

    private var insightsCalendarCard: some View {
        insightCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Completed sessions")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(MeditationColors.textPrimary)

                MultiDatePicker(
                    "Completed sessions",
                    selection: .constant(viewModel.completedSessionDates)
                )
                .labelsHidden()
                .allowsHitTesting(false)
                .accessibilityLabel(Text("Calendar of completed sessions"))

                Text(calendarCaption)
                    .font(.footnote)
                    .foregroundColor(MeditationColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Formatting

    private func statsCard(title: String, value: String) -> some View {
        insightCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(MeditationColors.textSecondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(MeditationColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func insightCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(MeditationColors.surfacePrimary(for: sessionColorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(MeditationColors.surfaceStroke(for: sessionColorScheme), lineWidth: 1)
            )
    }

    @ViewBuilder
    private func configurationSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MeditationColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            content()
        }
    }

    private var configurationDivider: some View {
        Divider()
            .overlay(MeditationColors.surfaceStroke(for: sessionColorScheme).opacity(0.48))
    }

    private var insightsHeaderDescription: String {
        if viewModel.completedSessionCount == 0 {
            return "No completed sessions yet. A short reset session is a good place to start."
        }
        return "A calm summary of your recent meditation history."
    }

    private var calendarCaption: String {
        if viewModel.completedSessionCount == 0 {
            return "Complete your first session to begin filling this calendar."
        }
        return "Only fully completed sessions are recorded."
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

private struct BreathingOrbView: View {
    let progress: CGFloat
    let heroDiameter: CGFloat
    let orbScale: CGFloat
    let reduceMotion: Bool
    let colorScheme: ColorScheme
    let accent: Color
    let timerText: String
    let timerFont: Font
    let centerCaption: String
    let hideCountdown: Bool
    let accessibilityLabel: String

    var body: some View {
        ZStack {
            Circle()
                .fill(MeditationColors.orbOuterGradient(for: colorScheme))
                .overlay(
                    Circle()
                        .stroke(MeditationColors.surfaceStroke(for: colorScheme), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.12),
                    radius: colorScheme == .dark ? 14 : 10,
                    x: 0,
                    y: 6
                )

            Circle()
                .fill(RadialGradient(colors: [accent.opacity(0.45), accent.opacity(0.12)], center: .center, startRadius: 0, endRadius: heroDiameter / 2))
                .padding(heroDiameter * 0.07)
                .scaleEffect(orbScale)

            Circle()
                .stroke(MeditationColors.ringTrack(for: colorScheme), lineWidth: 2)
                .padding(5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .foregroundStyle(MeditationColors.accentPrimary)
                .shadow(
                    color: MeditationColors.accentPrimary.opacity(0.18),
                    radius: 5,
                    x: 0,
                    y: 2
                )
                .rotationEffect(.degrees(-90))
                .padding(5)
                .opacity(progress == 0 ? 0.35 : 1)

            VStack(spacing: 6) {
                Text(timerText)
                    .font(timerFont)
                    .monospacedDigit()
                    .foregroundColor(MeditationColors.textPrimary)

                Text(centerCaption)
                    .font(.subheadline)
                    .foregroundColor(MeditationColors.textSecondary)
            }
            .padding(24)
            .opacity(hideCountdown ? 0 : 1)
        }
        .animation(reduceMotion || centerCaption != "Completed" ? nil : .easeOut(duration: 1.2), value: centerCaption)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text(hideCountdown ? "Countdown hidden" : centerCaption))
    }
}

private struct SessionConfigurationCard<Content: View>: View {
    let isRegularWidth: Bool
    let colorScheme: ColorScheme
    let selectionDescription: String
    let content: Content

    init(
        isRegularWidth: Bool,
        colorScheme: ColorScheme,
        selectionDescription: String,
        @ViewBuilder content: () -> Content
    ) {
        self.isRegularWidth = isRegularWidth
        self.colorScheme = colorScheme
        self.selectionDescription = selectionDescription
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content

            Text(selectionDescription)
                .font(.footnote)
                .foregroundColor(MeditationColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
                .padding(.top, 2)
        }
        .padding(.horizontal, isRegularWidth ? 24 : 18)
        .padding(.vertical, isRegularWidth ? 20 : 18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(MeditationColors.surfacePrimary(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(MeditationColors.surfaceStroke(for: colorScheme), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct InsightsSheetView<Content: View>: View {
    @Binding var isPresented: Bool
    let isRegularWidth: Bool
    let shouldScroll: Bool
    let colorScheme: ColorScheme
    let content: Content

    init(
        isPresented: Binding<Bool>,
        isRegularWidth: Bool,
        shouldScroll: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder content: () -> Content
    ) {
        _isPresented = isPresented
        self.isRegularWidth = isRegularWidth
        self.shouldScroll = shouldScroll
        self.colorScheme = colorScheme
        self.content = content()
    }

    var body: some View {
        ZStack {
            MeditationColors.backgroundPrimary(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if shouldScroll {
                    ScrollView(.vertical, showsIndicators: false) {
                        content
                    }
                } else {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .safeAreaPadding(.top, isRegularWidth ? 18 : 12)
            .safeAreaPadding(.bottom, isRegularWidth ? 12 : 8)
        }
    }

    private var header: some View {
        HStack {
            Text("Insights")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(MeditationColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 12)

            Button("Done") {
                isPresented = false
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(MeditationColors.surfaceElevated(for: colorScheme))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(MeditationColors.surfaceElevatedStroke(for: colorScheme), lineWidth: 1)
            )
            .buttonStyle(.plain)
            .foregroundColor(MeditationColors.textPrimary)
            .accessibilityHint(Text("Closes insights"))
        }
        .padding(.horizontal, isRegularWidth ? 26 : 16)
        .padding(.top, isRegularWidth ? 8 : 6)
        .padding(.bottom, 8)
    }
}

extension SessionViewModel {
    /// Convenience initializer for the app: wires up the default engine + chime player.
    convenience init() {
        let engine = MeditationTimerEngine()
        let chimePlayer = SystemAudioChimePlayer()
        let backgroundAudio: BackgroundAudioControlling = BackgroundAudioManager.shared
        let notificationScheduler: SessionNotificationScheduling = SessionNotificationScheduler()
        self.init(
            timerEngine: engine,
            chimePlayer: chimePlayer,
            backgroundAudio: backgroundAudio,
            notificationScheduler: notificationScheduler
        )
    }
}
