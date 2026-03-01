import Foundation
import SwiftData

enum HealthDataAggregator {

    /// Creates a DailySummary for the given date.
    /// Phase 5: placeholder with nil metrics. Phase 6 will add real HealthKit queries.
    static func aggregateDay(date: Date) -> DailySummary {
        DailySummary(date: date)
    }

    /// Backfills historical data from startDate to endDate (inclusive).
    /// Creates one DailySummary per day, skipping days that already exist.
    /// Reports progress via callback: (daysProcessed, totalDays).
    static func backfillHistory(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        let calendar = Calendar.current
        let start = DateHelpers.startOfDay(for: startDate)
        let end = DateHelpers.startOfDay(for: endDate)

        guard let totalDays = calendar.dateComponents(
            [.day], from: start, to: end
        ).day.map({ $0 + 1 }), totalDays > 0 else {
            return
        }

        var currentDate = start
        var daysProcessed = 0

        while currentDate <= end {
            let targetDate = currentDate
            let descriptor = FetchDescriptor<DailySummary>(
                predicate: #Predicate<DailySummary> { $0.date == targetDate }
            )

            if try context.fetchCount(descriptor) == 0 {
                let summary = aggregateDay(date: currentDate)
                context.insert(summary)
            }

            daysProcessed += 1
            progress(daysProcessed, totalDays)

            await Task.yield()

            if daysProcessed % 50 == 0 {
                try context.save()
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        try context.save()
    }
}
