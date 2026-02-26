import Foundation

enum AppConstants {
    static let claudeAPIBaseURL = "https://api.anthropic.com/v1/messages"
    static let claudeModel = "claude-sonnet-4-20250514"
    static let maxTokens = 4096
}

enum ExerciseType: String, Codable, CaseIterable {
    case upperPush
    case upperPull
    case lowerBody
    case core
    case cardio
    case fullBodyHIIT
    case warmup
    case cooldown
}

enum GoalType: String, Codable, CaseIterable {
    case loseFat
    case buildMuscle
    case recomposition
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case active
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case none
    case vegetarian
    case vegan
    case glutenFree
    case dairyFree
    case lowCarb
}

enum DifficultyLevel: Int, Codable {
    case beginner = 1
    case intermediate = 2
    case advanced = 3
    case elite = 4
}
