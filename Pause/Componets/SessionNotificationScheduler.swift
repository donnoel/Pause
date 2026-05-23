import Foundation
import UserNotifications

protocol SessionNotificationScheduling {
    func scheduleSessionSounds(halfwayAfter: TimeInterval?, completionAfter: TimeInterval)
    func cancelSessionSounds()
}

final class SessionNotificationScheduler: SessionNotificationScheduling {
    private let center: UNUserNotificationCenter
    private let halfwayIdentifier = "pause.session.halfway"
    private let completionIdentifier = "pause.session.completed"
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]
    private let notificationSoundName = UNNotificationSoundName("chime.caf")

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func scheduleSessionSounds(halfwayAfter: TimeInterval?, completionAfter: TimeInterval) {
        let halfwayInterval = halfwayAfter.map { max(1, $0) }
        let completionInterval = max(1, completionAfter)

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.addSessionSounds(halfwayAfter: halfwayInterval, completionAfter: completionInterval)
            case .notDetermined:
                self.center.requestAuthorization(options: self.authorizationOptions) { [weak self] granted, _ in
                    guard let self, granted else { return }
                    self.addSessionSounds(halfwayAfter: halfwayInterval, completionAfter: completionInterval)
                }
            default:
                return
            }
        }
    }

    func cancelSessionSounds() {
        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: notificationIdentifiers)
    }

    private var notificationIdentifiers: [String] {
        [halfwayIdentifier, completionIdentifier]
    }

    private func addSessionSounds(halfwayAfter: TimeInterval?, completionAfter: TimeInterval) {
        center.removePendingNotificationRequests(withIdentifiers: notificationIdentifiers)

        if let halfwayAfter, halfwayAfter < completionAfter {
            addSound(identifier: halfwayIdentifier, after: halfwayAfter, body: "Halfway")
        }

        addSound(identifier: completionIdentifier, after: completionAfter, body: "Session complete")
    }

    private func addSound(identifier: String, after timeInterval: TimeInterval, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Pause"
        content.body = body
        content.sound = UNNotificationSound(named: notificationSoundName)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { _ in }
    }
}
