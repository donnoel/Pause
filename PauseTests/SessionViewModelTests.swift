import XCTest
@testable import Pause

final class MockTimerEngine: MeditationTimerEngineProtocol {
    var onTick: ((TimeInterval) -> Void)?
    var onHalfway: (() -> Void)?
    var onCompleted: (() -> Void)?

    private(set) var isRunning: Bool = false
    private(set) var remaining: TimeInterval = 0
    private(set) var total: TimeInterval = 0
    private(set) var startCallCount: Int = 0
    private(set) var restoreCallCount: Int = 0
    private(set) var lastRestoredTotal: TimeInterval = 0
    private(set) var lastRestoredRemaining: TimeInterval = 0

    func start(duration: TimeInterval) {
        total = duration
        remaining = duration
        isRunning = true
        startCallCount += 1
    }

    func restore(totalDuration: TimeInterval, remainingDuration: TimeInterval) {
        total = totalDuration
        remaining = remainingDuration
        isRunning = remainingDuration > 0
        restoreCallCount += 1
        lastRestoredTotal = totalDuration
        lastRestoredRemaining = remainingDuration
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        isRunning = true
    }

    func cancel() {
        isRunning = false
        remaining = 0
    }
}

final class MockChimePlayer: AudioChimePlaying {
    private(set) var playedChimes: [ChimeType] = []

    func play(chimeType: ChimeType) {
        playedChimes.append(chimeType)
    }
}

final class MockBackgroundAudioController: BackgroundAudioControlling {
    private(set) var startCount: Int = 0
    private(set) var stopCount: Int = 0

    func startKeepingAlive() {
        startCount += 1
    }

    func stopKeepingAlive() {
        stopCount += 1
    }
}

final class SessionViewModelConfigurationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PauseSessionStore.clear()
    }

    override func tearDown() {
        PauseSessionStore.clear()
        super.tearDown()
    }

    @MainActor
    func testRunningSessionIgnoresConfigurationMutations() {
        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        viewModel.selectPreset(.five)
        viewModel.selectBreathingStyle(.calmExhale)
        viewModel.startSelectedSession()

        viewModel.selectPreset(.ten)
        viewModel.selectBreathingStyle(.equalBreath)
        viewModel.selectCustomDuration(minutes: 3)
        viewModel.selectRitualPreset(.focus)

        XCTAssertEqual(viewModel.selectedPreset, .five)
        XCTAssertEqual(viewModel.selectedBreathingStyle, .calmExhale)
        XCTAssertNil(viewModel.selectedRitualPreset)
        XCTAssertEqual(viewModel.breathingStyleForCurrentSession, .calmExhale)
    }

    @MainActor
    func testCancelClearsActiveSessionBreathingStyle() {
        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        viewModel.selectBreathingStyle(.boxBreath)
        viewModel.startSelectedSession()
        XCTAssertEqual(viewModel.breathingStyleForCurrentSession, .boxBreath)

        viewModel.cancel()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertNil(viewModel.activeSessionBreathingStyle)
        XCTAssertEqual(viewModel.breathingStyleForCurrentSession, .boxBreath)
    }

    @MainActor
    func testReflectionSelectionIgnoredOutsideCompletedState() {
        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        viewModel.selectReflection(.calm)
        XCTAssertNil(viewModel.selectedReflection)

        viewModel.startSelectedSession()
        viewModel.selectReflection(.okay)
        XCTAssertNil(viewModel.selectedReflection)
    }

    @MainActor
    func testCompletedSessionSupportsReflectionAndStartClearsIt() {
        PauseSessionStore.clear()
        let now = Date()
        PauseSessionStore.save(
            PauseSessionInfo(
                isActive: true,
                startDate: now.addingTimeInterval(-120),
                endDate: now.addingTimeInterval(-60)
            )
        )

        defer { PauseSessionStore.clear() }

        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        XCTAssertEqual(viewModel.state, .completed)

        viewModel.selectReflection(.restless)
        XCTAssertEqual(viewModel.selectedReflection, .restless)

        viewModel.startSelectedSession()
        XCTAssertEqual(viewModel.state, .running)
        XCTAssertNil(viewModel.selectedReflection)
    }

    @MainActor
    func testSelectingRitualAppliesBreathingStyleAndDurationConfiguration() {
        let viewModel = SessionViewModel(
            timerEngine: MockTimerEngine(),
            chimePlayer: MockChimePlayer(),
            backgroundAudio: MockBackgroundAudioController()
        )

        viewModel.selectRitualPreset(.reset)

        XCTAssertEqual(viewModel.selectedRitualPreset, .reset)
        XCTAssertEqual(viewModel.selectedBreathingStyle, .calmExhale)
        XCTAssertNil(viewModel.selectedPreset)
        XCTAssertEqual(viewModel.customDurationMinutes, 3)
    }

    @MainActor
    func testSelectingDurationPresetClearsRitualSelectionWithoutChangingBreathingStyle() {
        let viewModel = SessionViewModel(
            timerEngine: MockTimerEngine(),
            chimePlayer: MockChimePlayer(),
            backgroundAudio: MockBackgroundAudioController()
        )

        viewModel.selectRitualPreset(.focus)
        viewModel.selectPreset(.ten)

        XCTAssertNil(viewModel.selectedRitualPreset)
        XCTAssertEqual(viewModel.selectedPreset, .ten)
        XCTAssertEqual(viewModel.selectedBreathingStyle, .equalBreath)
    }

    @MainActor
    func testCustomDurationMatchingPresetSelectsPresetAndClearsRitual() {
        let viewModel = SessionViewModel(
            timerEngine: MockTimerEngine(),
            chimePlayer: MockChimePlayer(),
            backgroundAudio: MockBackgroundAudioController()
        )

        viewModel.selectRitualPreset(.focus)
        viewModel.selectCustomDuration(minutes: 5)

        XCTAssertNil(viewModel.selectedRitualPreset)
        XCTAssertEqual(viewModel.selectedPreset, .five)
        XCTAssertEqual(viewModel.customDurationMinutes, 5)
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testHandleSceneDidBecomeActiveReconcilesRunningSessionFromStore() {
        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        let startDate = Date().addingTimeInterval(-60)
        let endDate = Date().addingTimeInterval(120)
        PauseSessionStore.save(
            PauseSessionInfo(
                isActive: true,
                startDate: startDate,
                endDate: endDate
            )
        )

        viewModel.handleSceneDidBecomeActive()

        XCTAssertEqual(viewModel.state, .running)
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.restoreCallCount, 1)
        XCTAssertEqual(timer.lastRestoredTotal, endDate.timeIntervalSince(startDate), accuracy: 0.5)
        XCTAssertGreaterThan(timer.lastRestoredRemaining, 0)
        XCTAssertLessThanOrEqual(timer.lastRestoredRemaining, endDate.timeIntervalSince(Date()) + 1.0)
        XCTAssertEqual(viewModel.total, endDate.timeIntervalSince(startDate), accuracy: 0.5)
        XCTAssertGreaterThan(viewModel.remaining, 0)
        XCTAssertLessThanOrEqual(viewModel.remaining, endDate.timeIntervalSince(Date()) + 1.0)
    }

    @MainActor
    func testHandleSceneDidBecomeActiveCompletesExpiredStoredSessionAndPlaysEndChime() {
        let timer = MockTimerEngine()
        let chime = MockChimePlayer()
        let background = MockBackgroundAudioController()
        let viewModel = SessionViewModel(
            timerEngine: timer,
            chimePlayer: chime,
            backgroundAudio: background
        )

        let endDate = Date().addingTimeInterval(-5)
        let startDate = endDate.addingTimeInterval(-180)
        PauseSessionStore.save(
            PauseSessionInfo(
                isActive: true,
                startDate: startDate,
                endDate: endDate
            )
        )

        viewModel.handleSceneDidBecomeActive()

        XCTAssertEqual(viewModel.state, .completed)
        XCTAssertEqual(viewModel.remaining, 0)
        XCTAssertEqual(viewModel.total, 180, accuracy: 0.5)
        XCTAssertEqual(viewModel.completedSessionCount, 1)
        XCTAssertFalse(PauseSessionStore.load().isActive)
        XCTAssertEqual(background.stopCount, 1)
        XCTAssertEqual(chime.playedChimes, [.end])
    }
}

final class SessionStatsCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
    }

    func testSummaryCalculatesCalendarLastUsualAndAverage() throws {
        let first = CompletedMeditationSessionRecord(
            startDate: try makeDate(year: 2026, month: 3, day: 1, hour: 7, minute: 30),
            endDate: try makeDate(year: 2026, month: 3, day: 1, hour: 7, minute: 35),
            plannedDuration: 300
        )
        let second = CompletedMeditationSessionRecord(
            startDate: try makeDate(year: 2026, month: 3, day: 2, hour: 8, minute: 0),
            endDate: try makeDate(year: 2026, month: 3, day: 2, hour: 8, minute: 15),
            plannedDuration: 900
        )
        let third = CompletedMeditationSessionRecord(
            startDate: try makeDate(year: 2026, month: 3, day: 3, hour: 8, minute: 30),
            endDate: try makeDate(year: 2026, month: 3, day: 3, hour: 8, minute: 50),
            plannedDuration: 1200
        )

        let summary = SessionStatsCalculator.makeSummary(
            from: [first, second, third],
            calendar: calendar
        )

        XCTAssertEqual(summary.completedSessionCount, 3)
        XCTAssertEqual(summary.usualMeditationMinutesFromMidnight, 8 * 60)
        XCTAssertNotNil(summary.averageSessionLength)
        XCTAssertEqual(summary.averageSessionLength ?? 0, 800, accuracy: 0.001)
        XCTAssertEqual(summary.lastCompletedSession?.startDate, third.startDate)
        XCTAssertEqual(summary.lastCompletedSession?.endDate, third.endDate)
        XCTAssertEqual(summary.lastCompletedSession?.plannedDuration, third.plannedDuration)
        XCTAssertEqual(summary.completedDateComponents.count, 3)
        let includesMarchSecond = summary.completedDateComponents.contains { components in
            components.year == 2026 &&
            components.month == 3 &&
            components.day == 2
        }
        XCTAssertTrue(includesMarchSecond)
    }

    func testSummaryIsEmptyWhenNoRecordsExist() {
        let summary = SessionStatsCalculator.makeSummary(from: [], calendar: calendar)
        XCTAssertEqual(summary.completedSessionCount, 0)
        XCTAssertNil(summary.lastCompletedSession)
        XCTAssertNil(summary.usualMeditationMinutesFromMidnight)
        XCTAssertNil(summary.averageSessionLength)
        XCTAssertTrue(summary.completedDateComponents.isEmpty)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let date = calendar.date(from: components) else {
            throw NSError(domain: "SessionStatsCalculatorTests", code: 1)
        }

        return date
    }
}

final class CompletedSessionRecordMergerTests: XCTestCase {
    func testNormalizationRemovesApproximateDuplicatesAndSorts() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let first = CompletedMeditationSessionRecord(
            startDate: base,
            endDate: base.addingTimeInterval(300),
            plannedDuration: 300
        )
        // Duplicate within tolerance thresholds.
        let duplicate = CompletedMeditationSessionRecord(
            startDate: base.addingTimeInterval(0.2),
            endDate: base.addingTimeInterval(300.3),
            plannedDuration: 300.2
        )
        let second = CompletedMeditationSessionRecord(
            startDate: base.addingTimeInterval(600),
            endDate: base.addingTimeInterval(1200),
            plannedDuration: 600
        )

        let normalized = CompletedSessionRecordMerger.normalized(
            [second, duplicate, first],
            maxCount: 10
        )

        XCTAssertEqual(normalized.count, 2)
        XCTAssertEqual(normalized.first, first)
        XCTAssertEqual(normalized.last, second)
    }

    func testNormalizationAppliesMaxCountByKeepingMostRecent() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let records = (0..<5).map { index in
            CompletedMeditationSessionRecord(
                startDate: base.addingTimeInterval(TimeInterval(index * 60)),
                endDate: base.addingTimeInterval(TimeInterval(index * 60 + 30)),
                plannedDuration: 30
            )
        }

        let normalized = CompletedSessionRecordMerger.normalized(records, maxCount: 3)

        XCTAssertEqual(normalized.count, 3)
        XCTAssertEqual(normalized.first?.startDate, records[2].startDate)
        XCTAssertEqual(normalized.last?.startDate, records[4].startDate)
    }
}

final class RitualPresetTests: XCTestCase {
    func testRitualPresetMappingsMatchExpectedConfiguration() {
        XCTAssertEqual(RitualPreset.reset.durationMinutes, 3)
        XCTAssertEqual(RitualPreset.reset.breathingStyle, .calmExhale)

        XCTAssertEqual(RitualPreset.focus.durationMinutes, 5)
        XCTAssertEqual(RitualPreset.focus.breathingStyle, .equalBreath)

        XCTAssertEqual(RitualPreset.unwind.durationMinutes, 10)
        XCTAssertEqual(RitualPreset.unwind.breathingStyle, .quietTimer)

        XCTAssertEqual(RitualPreset.sleepWindDown.durationMinutes, 15)
        XCTAssertEqual(RitualPreset.sleepWindDown.breathingStyle, .calmExhale)
    }

    func testQuietTimerHasNoGuidedPhaseCue() {
        XCTAssertNil(BreathingStyle.quietTimer.phaseCue(elapsed: 0))
        XCTAssertNil(BreathingStyle.quietTimer.phaseCue(elapsed: 30))
    }
}
