import Foundation
import SwiftData

@Model
final class SetLog {
    var id: UUID
    var exerciseName: String
    var exerciseId: UUID
    var setNumber: Int
    var targetReps: String
    var actualReps: Int
    var completedAt: Date

    var workoutSession: WorkoutSession?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        exerciseId: UUID,
        setNumber: Int,
        targetReps: String,
        actualReps: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.exerciseId = exerciseId
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.completedAt = completedAt
    }
}
