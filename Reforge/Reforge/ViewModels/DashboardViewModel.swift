import Foundation
import SwiftData

struct WeeklyDayStatus: Identifiable {
    let id: UUID
    let dayOfWeek: Int
    let isCompleted: Bool
    let isToday: Bool
}

@Observable
class DashboardViewModel {
    var todaysWorkout: WorkoutDay?
    var streak: StreakRecord?
    var userName: String = ""
    var dayNumber: Int = 1
    var weeklyDayStatuses: [WeeklyDayStatus] = []
    var isLoaded: Bool = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Good night"
        }
    }

    @MainActor
    func loadDashboard(context: ModelContext) {
        // Fetch active plan
        let planDescriptor = FetchDescriptor<Plan>(predicate: #Predicate { $0.isActive })
        guard let plan = try? context.fetch(planDescriptor).first else { return }

        // Fetch user profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(profileDescriptor).first {
            userName = profile.name
        }

        // Compute day number since plan start
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let planStart = calendar.startOfDay(for: plan.startDate)
        dayNumber = max(1, (calendar.dateComponents([.day], from: planStart, to: today).day ?? 0) + 1)

        // Find today's workout
        let todayDOW = todayDayOfWeek()
        let workoutDays = plan.workoutDays.sorted { $0.orderIndex < $1.orderIndex }
        todaysWorkout = workoutDays.first { $0.dayOfWeek == todayDOW }

        // Fetch streak
        let streakDescriptor = FetchDescriptor<StreakRecord>()
        streak = try? context.fetch(streakDescriptor).first

        // Fetch this week's completed sessions
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? today
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.completed && session.date >= startOfWeek && session.date < endOfWeek
            }
        )
        let completedSessions = (try? context.fetch(sessionDescriptor)) ?? []
        let completedDayIds = Set(completedSessions.map { $0.workoutDayId })

        // Build weekly day statuses for scheduled workout days
        weeklyDayStatuses = workoutDays.map { day in
            WeeklyDayStatus(
                id: day.id,
                dayOfWeek: day.dayOfWeek,
                isCompleted: completedDayIds.contains(day.id),
                isToday: day.dayOfWeek == todayDOW
            )
        }

        isLoaded = true
    }

    func todayDayOfWeek() -> Int {
        let calendarWeekday = Calendar.current.component(.weekday, from: Date())
        // Convert: Sunday=1..Saturday=7 → Monday=1..Sunday=7
        return (calendarWeekday + 5) % 7 + 1
    }
}
