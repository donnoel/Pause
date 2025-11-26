import Foundation

public protocol MeditationTimerEngineProtocol: AnyObject {
    var onTick: ((TimeInterval) -> Void)? { get set }
    var onHalfway: (() -> Void)? { get set }
    var onCompleted: (() -> Void)? { get set }

    var isRunning: Bool { get }
    var remaining: TimeInterval { get }
    var total: TimeInterval { get }

    func start(duration: TimeInterval)
    func pause()
    func resume()
    func cancel()
}

public final class MeditationTimerEngine: MeditationTimerEngineProtocol {
    public var onTick: ((TimeInterval) -> Void)?
    public var onHalfway: (() -> Void)?
    public var onCompleted: (() -> Void)?

    public private(set) var isRunning: Bool = false
    public private(set) var remaining: TimeInterval = 0
    public private(set) var total: TimeInterval = 0

    private var timer: Timer?
    private var hasFiredHalfway: Bool = false
    private var halfwayPoint: TimeInterval = 0

    public init() {}

    public func start(duration: TimeInterval) {
        invalidate()

        total = max(1, duration)
        remaining = total
        halfwayPoint = total / 2
        hasFiredHalfway = false
        isRunning = true

        // initial state
        onTick?(remaining)

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.isRunning else { return }

            self.remaining = max(0, self.remaining - 1)

            let elapsed = self.total - self.remaining

            if !self.hasFiredHalfway && elapsed >= self.halfwayPoint {
                self.hasFiredHalfway = true
                #if DEBUG
                print("🔔 Halfway reached at \(elapsed)s")
                #endif
                self.onHalfway?()
            }

            self.onTick?(self.remaining)

            if self.remaining <= 0 {
                self.complete()
            }
        }

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    public func pause() {
        guard isRunning else { return }
        isRunning = false
    }

    public func resume() {
        guard !isRunning, timer != nil else { return }
        isRunning = true
    }

    public func cancel() {
        invalidate()
        remaining = 0
        total = 0
    }

    private func complete() {
        invalidate()
        #if DEBUG
        print("🔔 Timer completed")
        #endif
        onCompleted?()
    }

    private func invalidate() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        hasFiredHalfway = false
        halfwayPoint = 0
    }
}
