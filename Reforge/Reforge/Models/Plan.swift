import Foundation
import SwiftData

@Model
final class Plan {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var difficulty: Int
    var weekCount: Int
    var isActive: Bool
    var rawJSON: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutDay.plan)
    var workoutDays: [WorkoutDay]

    @Relationship(deleteRule: .cascade, inverse: \MealPlan.plan)
    var mealPlan: MealPlan?

    var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        difficulty: Int = DifficultyLevel.beginner.rawValue,
        weekCount: Int = 4,
        isActive: Bool = true,
        rawJSON: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.difficulty = difficulty
        self.weekCount = weekCount
        self.isActive = isActive
        self.rawJSON = rawJSON
        self.createdAt = createdAt
        self.workoutDays = []
    }
}
