import Foundation
import SwiftData

// MARK: - BiologicalSexOption

enum BiologicalSexOption: String, CaseIterable, Identifiable {
    case male
    case female
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }

    static func from(_ string: String) -> BiologicalSexOption {
        BiologicalSexOption(rawValue: string) ?? .other
    }
}

// MARK: - UserProfile

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

    // MARK: - Notification Preferences
    var dailyCollectionNotification: Bool
    var weightReminderEnabled: Bool
    var weightReminderTime: Date

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
        updatedAt: Date = Date(),
        dailyCollectionNotification: Bool = false,
        weightReminderEnabled: Bool = false,
        weightReminderTime: Date = {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }()
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
        self.dailyCollectionNotification = dailyCollectionNotification
        self.weightReminderEnabled = weightReminderEnabled
        self.weightReminderTime = weightReminderTime
    }
}
