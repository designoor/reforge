import Foundation
import SwiftData

@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var weightKg: Double
    var notes: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
    }
}
