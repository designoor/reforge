import Foundation
import SwiftData

struct MealOption: Codable {
    var title: String
    var ingredients: [String]
    var calories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var preparationNotes: String
}

@Model
final class Meal {
    var id: UUID
    var name: String
    var timeSlot: String
    var orderIndex: Int
    var optionsJSON: String

    var mealPlan: MealPlan?

    var options: [MealOption] {
        get {
            guard let data = optionsJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([MealOption].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                optionsJSON = "[]"
                return
            }
            optionsJSON = String(data: data, encoding: .utf8) ?? "[]"
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        timeSlot: String,
        orderIndex: Int,
        optionsJSON: String = "[]"
    ) {
        self.id = id
        self.name = name
        self.timeSlot = timeSlot
        self.orderIndex = orderIndex
        self.optionsJSON = optionsJSON
    }
}
