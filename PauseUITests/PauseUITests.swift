//
//  PauseUITests.swift
//  PauseUITests
//
//  Created by Don Noel on 11/22/25.
//

import XCTest
import AppIntents

final class PauseUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testBreathingRefreshControls() async throws {
        let app = XCUIApplication()
        app.launch()
        let end = app.buttons["End current session"]
        if end.waitForExistence(timeout: 2) { end.tap() }
        app.buttons["Sleep Wind Down"].tap()
        XCTAssertFalse(app.switches["Show breathing words"].exists)
        let begin = app.buttons["Begin selected session"]
        if !begin.isHittable { app.swipeUp() }
        begin.tap()
        XCTAssertTrue(app.buttons["Pause meditation"].waitForExistence(timeout: 3))
        app.buttons["Hide countdown"].tap()
        XCTAssertTrue(app.buttons["Show countdown"].exists)
        try await Task.sleep(for: .seconds(2))
        XCTAssertTrue(app.staticTexts["Inhale"].exists || app.staticTexts["Exhale"].exists)
        let running = XCTAttachment(screenshot: app.screenshot())
        running.name = "Night breathing session"
        running.lifetime = .keepAlways
        add(running)
        app.buttons["Pause meditation"].tap()
        XCTAssertTrue(app.buttons["Resume meditation"].exists)
        app.buttons["Resume meditation"].tap()
        app.buttons["Show countdown"].tap()
        XCTAssertTrue(app.buttons["Hide countdown"].exists)
        end.tap()
        XCTAssertTrue(app.buttons["Begin selected session"].exists)
        app.buttons["Focus"].tap()
        app.buttons["Begin selected session"].tap()
        try await Task.sleep(for: .seconds(2))
        let day = XCTAttachment(screenshot: app.screenshot())
        day.name = "Day breathing session"
        day.lifetime = .keepAlways
        add(day)
        XCTAssertTrue(app.buttons["Pause meditation"].exists)
        end.tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
