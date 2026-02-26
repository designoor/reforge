import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var heightCm: Double
    var weightKg: Double
    var age: Int
    var biologicalSex: String
    var activityLevel: String
    var goal: String
    var dietaryRestrictions: [String]
    var availableDaysPerWeek: Int
    var sessionLengthMinutes: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Plan.userProfile)
    var activePlan: Plan?

    var bmi: Double {
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    init(
        id: UUID = UUID(),
        name: String,
        heightCm: Double,
        weightKg: Double,
        age: Int,
        biologicalSex: String,
        activityLevel: String,
        goal: String,
        dietaryRestrictions: [String] = [],
        availableDaysPerWeek: Int,
        sessionLengthMinutes: Int,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.age = age
        self.biologicalSex = biologicalSex
        self.activityLevel = activityLevel
        self.goal = goal
        self.dietaryRestrictions = dietaryRestrictions
        self.availableDaysPerWeek = availableDaysPerWeek
        self.sessionLengthMinutes = sessionLengthMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
