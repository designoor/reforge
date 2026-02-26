import Foundation
import SwiftData

@Model
final class Exercise {
    var id: UUID
    var name: String
    var sets: Int
    var targetReps: String
    var restSeconds: Int
    var formCues: String
    var modelId: String
    var orderIndex: Int
    var muscleGroups: [String]

    var workoutDay: WorkoutDay?

    init(
        id: UUID = UUID(),
        name: String,
        sets: Int,
        targetReps: String,
        restSeconds: Int,
        formCues: String,
        modelId: String = "",
        orderIndex: Int,
        muscleGroups: [String] = []
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.formCues = formCues
        self.modelId = modelId
        self.orderIndex = orderIndex
        self.muscleGroups = muscleGroups
    }
}
