import UIKit

enum Haptics {

    // Reuse generators to avoid repeated allocations and allow better system tuning.
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    static func primary() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }

    static func destructive() {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
    }
}
