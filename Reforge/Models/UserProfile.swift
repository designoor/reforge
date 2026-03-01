import Foundation
import SwiftData

@Model
final class UserProfile {
    var dateOfBirth: Date
    var biologicalSex: String
    var height: Double
    var weight: Double
    var unitPreference: String
    var timeZone: String
    var wakeTime: Date
    var createdAt: Date
    var updatedAt: Date

    init(
        dateOfBirth: Date = Date(),
        biologicalSex: String = "other",
        height: Double = 1.70,
        weight: Double = 70.0,
        unitPreference: String = "metric",
        timeZone: String = TimeZone.current.identifier,
        wakeTime: Date = {
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.dateOfBirth = dateOfBirth
        self.biologicalSex = biologicalSex
        self.height = height
        self.weight = weight
        self.unitPreference = unitPreference
        self.timeZone = timeZone
        self.wakeTime = wakeTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
