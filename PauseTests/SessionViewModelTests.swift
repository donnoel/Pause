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



