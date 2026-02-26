import Foundation
import SwiftData

@Model
final class WorkoutDay {
    var id: UUID
    var dayOfWeek: Int
    var title: String
    var type: String
    var orderIndex: Int
    var estimatedMinutes: Int

    @Relationship(deleteRule: .cascade, inverse: \Exercise.workoutDay)
    var exercises: [Exercise]

    var plan: Plan?

    init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        title: String,
        type: String,
        orderIndex: Int,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.title = title
        self.type = type
        self.orderIndex = orderIndex
        self.estimatedMinutes = estimatedMinutes
        self.exercises = []
    }
}
