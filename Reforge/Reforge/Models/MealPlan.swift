import Foundation
import SwiftData

@Model
final class MealPlan {
    var id: UUID
    var dailyCalories: Int
    var dailyProteinG: Int
    var dailyCarbsG: Int
    var dailyFatG: Int

    @Relationship(deleteRule: .cascade, inverse: \Meal.mealPlan)
    var meals: [Meal]

    var plan: Plan?

    init(
        id: UUID = UUID(),
        dailyCalories: Int,
        dailyProteinG: Int,
        dailyCarbsG: Int,
        dailyFatG: Int
    ) {
        self.id = id
        self.dailyCalories = dailyCalories
        self.dailyProteinG = dailyProteinG
        self.dailyCarbsG = dailyCarbsG
        self.dailyFatG = dailyFatG
        self.meals = []
    }
}
