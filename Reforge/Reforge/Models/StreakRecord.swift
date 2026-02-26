import Foundation
import SwiftData

@Model
final class StreakRecord {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastWorkoutDate: Date?
    var freezesAvailable: Int
    var graceUsedThisWeek: Bool

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastWorkoutDate: Date? = nil,
        freezesAvailable: Int = 0,
        graceUsedThisWeek: Bool = false
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastWorkoutDate = lastWorkoutDate
        self.freezesAvailable = freezesAvailable
        self.graceUsedThisWeek = graceUsedThisWeek
    }
}
