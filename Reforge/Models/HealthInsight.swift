import Foundation
import SwiftData

@Model
final class HealthInsight {
    // MARK: - Identity

    #Unique<HealthInsight>([\.date])

    var date: Date
    var overallScore: Int?
    var suggestionsJSON: String
    var promptTokens: Int?
    var responseTokens: Int?

    // MARK: - Metadata

    var createdAt: Date

    // MARK: - Initializer

    init(
        date: Date,
        overallScore: Int? = nil,
        suggestionsJSON: String = "[]",
        promptTokens: Int? = nil,
        responseTokens: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.overallScore = overallScore
        self.suggestionsJSON = suggestionsJSON
        self.promptTokens = promptTokens
        self.responseTokens = responseTokens
        self.createdAt = createdAt
    }
}
