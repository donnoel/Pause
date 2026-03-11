import XCTest
@testable import Pause

final class MockTimerEngine: MeditationTimerEngineProtocol {
    var onTick: ((TimeInterval) -> Void)?
    var onHalfway: (() -> Void)?
    var onCompleted: (() -> Void)?
    
    private(set) var isRunning: Bool = false
    private(set) var remaining: TimeInterval = 0
    private(set) var total: TimeInterval = 0
    
    func start(duration: TimeInterval) {
        total = duration
        remaining = duration
        isRunning = true
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
