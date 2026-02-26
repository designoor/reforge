import Foundation
import SwiftData

@Observable
class OnboardingViewModel {
    static let totalSteps = 5

    // Step tracking
    var currentStep: Int = 0

    // Screen 1: Body Stats
    var name: String = ""
    var heightCm: Double = 170.0
    var weightKg: Double = 70.0
    var age: Int = 25
    var biologicalSex: String = "male"

    // Screen 2: Goals
    var goal: GoalType = .recomposition

    // Screen 3: Lifestyle
    var activityLevel: ActivityLevel = .moderatelyActive
    var availableDays: Int = 4
    var sessionLength: Int = 30
    var dietaryRestrictions: Set<DietaryRestriction> = []

    var bmi: Double {
        let heightM = heightCm / 100.0
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }

    var canProceed: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
                && heightCm >= 140 && heightCm <= 220
                && weightKg >= 40 && weightKg <= 200
                && age >= 16 && age <= 80
        case 2:
            return true
        case 3:
            return availableDays >= 3 && availableDays <= 6
                && [20, 30, 45].contains(sessionLength)
        case 4:
            return false
        default:
            return false
        }
    }

    @discardableResult
    func saveProfile(context: ModelContext) -> UserProfile {
        let restrictionStrings = dietaryRestrictions.isEmpty
            ? [DietaryRestriction.none.rawValue]
            : dietaryRestrictions.map(\.rawValue)

        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            heightCm: heightCm,
            weightKg: weightKg,
            age: age,
            biologicalSex: biologicalSex,
            activityLevel: activityLevel.rawValue,
            goal: goal.rawValue,
            dietaryRestrictions: restrictionStrings,
            availableDaysPerWeek: availableDays,
            sessionLengthMinutes: sessionLength
        )
        context.insert(profile)
        try? context.save()
        return profile
    }

    func toPromptPayload() -> OnboardingPayload {
        OnboardingPayload(
            name: name.trimmingCharacters(in: .whitespaces),
            heightCm: heightCm,
            weightKg: weightKg,
            age: age,
            biologicalSex: biologicalSex,
            activityLevel: activityLevel.rawValue,
            goal: goal.rawValue,
            dietaryRestrictions: dietaryRestrictions.isEmpty
                ? [DietaryRestriction.none.rawValue]
                : dietaryRestrictions.map(\.rawValue),
            availableDaysPerWeek: availableDays,
            sessionLengthMinutes: sessionLength
        )
    }
}
