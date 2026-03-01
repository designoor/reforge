import Foundation
import SwiftData

@Model
final class WorkoutSummary {
    // MARK: - Identity

    var date: Date
    var workoutType: String
    var duration: Double
    var totalEnergyBurned: Double?
    var totalDistance: Double?
    var startTime: Date
    var endTime: Date

    // MARK: - Metadata

    var createdAt: Date

    // MARK: - Initializer

    init(
        date: Date,
        workoutType: String,
        duration: Double,
        totalEnergyBurned: Double? = nil,
        totalDistance: Double? = nil,
        startTime: Date,
        endTime: Date,
        createdAt: Date = Date()
    ) {
        self.date = DateHelpers.startOfDay(for: date)
        self.workoutType = workoutType
        self.duration = duration
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }
}
