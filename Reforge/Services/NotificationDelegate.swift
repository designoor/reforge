import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        if let action = userInfo["action"] as? String, action == "logWeight" {
            Task { @MainActor in
                appState.pendingAction = .logWeight
            }
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
