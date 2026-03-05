import BackgroundTasks
import SwiftData

enum BackgroundTaskManager {

    // MARK: - Constants

    static let dailyCollectionIdentifier = "com.healthcoach.dailyCollection"

    // MARK: - Registration

    /// Registers the daily collection background task with the system.
    /// Must be called before the app finishes launching (i.e., in App.init()).
    static func registerTask(container: ModelContainer) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: dailyCollectionIdentifier,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleDailyCollection(task: processingTask, container: container)
        }
    }

    // MARK: - Scheduling

    /// Schedules the next daily collection task.
    /// Sets `earliestBeginDate` to 00:01 in the given timezone.
    /// If 00:01 today has already passed, schedules for 00:01 tomorrow.
    static func scheduleNextCollection(timeZone: TimeZone = .current) {
        let request = BGProcessingTaskRequest(identifier: dailyCollectionIdentifier)

        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        var targetTime = calendar.date(byAdding: .minute, value: 1, to: startOfToday)!
        if targetTime <= now {
            targetTime = calendar.date(byAdding: .day, value: 1, to: targetTime)!
        }

        request.earliestBeginDate = targetTime
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BackgroundTaskManager: Failed to schedule next collection: \(error)")
        }
    }

    // MARK: - Task Handling

    /// Handles the daily collection background task.
    private static func handleDailyCollection(task: BGProcessingTask, container: ModelContainer) {
        let workTask = Task {
            let context = ModelContext(container)

            // Determine user's timezone for computing "yesterday"
            let userTimeZone: TimeZone
            if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first,
               let tz = TimeZone(identifier: profile.timeZone) {
                userTimeZone = tz
            } else {
                userTimeZone = .current
            }

            var calendar = Calendar.current
            calendar.timeZone = userTimeZone
            let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: Date()))!

            _ = try await DailyDataService.collectData(for: yesterday, context: context)
            _ = try await DailyDataService.collectMissedDays(context: context)
        }

        task.expirationHandler = {
            workTask.cancel()
        }

        Task {
            let success: Bool
            do {
                try await workTask.value
                success = true
            } catch {
                print("BackgroundTaskManager: Daily collection failed: \(error)")
                success = false
            }
            scheduleNextCollection()
            task.setTaskCompleted(success: success)
        }
    }
}
