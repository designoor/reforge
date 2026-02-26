import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var workoutDayId: UUID
    var durationSeconds: Int
    var completed: Bool
    var difficultyRating: Int?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.workoutSession)
    var setLogs: [SetLog]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        workoutDayId: UUID,
        durationSeconds: Int = 0,
        completed: Bool = false,
        difficultyRating: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.workoutDayId = workoutDayId
        self.durationSeconds = durationSeconds
        self.completed = completed
        self.difficultyRating = difficultyRating
        self.notes = notes
        self.setLogs = []
    }
}
