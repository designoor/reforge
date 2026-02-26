import Foundation

struct OnboardingPayload: Codable {
    let name: String
    let heightCm: Double
    let weightKg: Double
    let age: Int
    let biologicalSex: String
    let activityLevel: String
    let goal: String
    let dietaryRestrictions: [String]
    let availableDaysPerWeek: Int
    let sessionLengthMinutes: Int
}
