import Foundation

// MARK: - Request Payload

struct OnboardingPayload: Codable, Sendable {
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

// MARK: - Response Types

struct PlanResponse: Codable, Sendable {
    let exercisePlan: ExercisePlanData
    let mealPlan: MealPlanData
    let metadata: PlanMetadata
}

struct ExercisePlanData: Codable, Sendable {
    let weekCount: Int
    let difficulty: Int
    let workoutDays: [WorkoutDayData]
}

struct WorkoutDayData: Codable, Sendable {
    let dayOfWeek: Int
    let title: String
    let type: String
    let estimatedMinutes: Int
    let exercises: [ExerciseData]
}

struct ExerciseData: Codable, Sendable {
    let name: String
    let sets: Int
    let targetReps: String
    let restSeconds: Int
    let formCues: String
    let muscleGroups: [String]
}

struct MealPlanData: Codable, Sendable {
    let dailyCalories: Int
    let dailyProteinG: Int
    let dailyCarbsG: Int
    let dailyFatG: Int
    let meals: [MealData]
}

struct MealData: Codable, Sendable {
    let name: String
    let timeSlot: String
    let options: [MealOptionData]
}

struct MealOptionData: Codable, Sendable {
    let title: String
    let ingredients: [String]
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let preparationNotes: String
}

struct PlanMetadata: Codable, Sendable {
    let estimatedWeeklyMinutes: Int
    let focusAreas: [String]
    let notes: String
}
