import Foundation
import SwiftData

@MainActor
enum StreakService {

    static func updateStreak(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Fetch or create StreakRecord
        let descriptor = FetchDescriptor<StreakRecord>()
        let streak: StreakRecord
        if let existing = try? context.fetch(descriptor).first {
            streak = existing
        } else {
            streak = StreakRecord()
            context.insert(streak)
        }

        // Weekly grace reset
        if let lastDate = streak.lastWorkoutDate {
            let lastWeek = calendar.dateInterval(of: .weekOfYear, for: lastDate)
            let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)
            if lastWeek != thisWeek {
                streak.graceUsedThisWeek = false
            }
        }

        // Streak logic
        if let lastDate = streak.lastWorkoutDate {
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: today).day ?? 0

            switch daysSince {
            case 0:
                // Same day — no change
                break
            case 1:
                streak.currentStreak += 1
                streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
            case 2 where !streak.graceUsedThisWeek:
                streak.graceUsedThisWeek = true
                streak.currentStreak += 1
                streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
            default:
                // 2 days (grace used) or 3+ days — reset
                streak.currentStreak = 1
            }
        } else {
            // First workout ever
            streak.currentStreak = 1
            streak.longestStreak = max(streak.longestStreak, 1)
        }

        streak.lastWorkoutDate = today
    }
}
