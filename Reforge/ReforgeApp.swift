import SwiftUI
import SwiftData
import UserNotifications

@main
struct ReforgeApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationDelegate: NotificationDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            UserProfile.self,
            DailySummary.self,
            WorkoutSummary.self,
            HealthInsight.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let delegate = NotificationDelegate(appState: _appState.wrappedValue)
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate

        BackgroundTaskManager.registerTask(container: sharedModelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && appState.isOnboardingComplete {
                performForegroundSync()
            }
        }
    }

    private func performForegroundSync() {
        guard !appState.isSyncing else { return }
        let container = sharedModelContainer
        appState.isSyncing = true
        Task {
            defer {
                Task { @MainActor in
                    appState.isSyncing = false
                }
            }
            let context = ModelContext(container)
            let yesterday = DateHelpers.yesterday()
            guard DailyDataService.needsCollection(for: yesterday, context: context) else {
                return
            }
            _ = try? await DailyDataService.collectData(for: yesterday, context: context)
            _ = try? await DailyDataService.collectMissedDays(context: context)
        }
    }
}
