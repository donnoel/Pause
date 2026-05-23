import Foundation
import UserNotifications

protocol SessionNotificationScheduling {
    func requestAuthorizationIfNeeded()
    func scheduleSessionCompletionNotification(after timeInterval: TimeInterval)
    func cancelPendingSessionNotifications()
}

final class SessionNotificationScheduler: SessionNotificationScheduling {
    private let center: UNUserNotificationCenter
    private let requestIdentifier = "pause.session.completed"
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: self.authorizationOptions) { _, _ in }
        }
    }

    func scheduleSessionCompletionNotification(after timeInterval: TimeInterval) {
        let clampedInterval = max(1, timeInterval)

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Session complete"
            content.body = "Your Pause session has finished."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: clampedInterval, repeats: false)
            let request = UNNotificationRequest(identifier: self.requestIdentifier, content: content, trigger: trigger)

            self.center.removePendingNotificationRequests(withIdentifiers: [self.requestIdentifier])
            self.center.add(request) { _ in }
        }
    }

    func cancelPendingSessionNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [requestIdentifier])
    }
}
