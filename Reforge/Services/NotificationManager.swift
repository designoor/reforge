import UserNotifications

enum NotificationManager {

    // MARK: - Permissions

    /// Requests notification authorization from the user.
    /// Returns `true` if permission was granted, `false` otherwise.
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Checks whether notification permission is currently granted.
    static func isPermissionGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedules a local notification with the given parameters.
    /// - Parameters:
    ///   - id: Unique identifier for the notification (used for canceling).
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - dateComponents: When to fire the notification.
    ///   - repeats: Whether the notification repeats on the same schedule.
    static func scheduleNotification(
        id: String,
        title: String,
        body: String,
        at dateComponents: DateComponents,
        repeats: Bool,
        userInfo: [String: String] = [:]
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancellation

    /// Cancels a specific pending notification by its identifier.
    static func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Cancels all pending notifications.
    static func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Querying

    /// Returns all currently pending notification requests.
    static func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}
