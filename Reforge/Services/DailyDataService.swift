import Foundation
import SwiftData

enum DailyDataService {

    // MARK: - Collect Data

    /// Collects and stores a DailySummary for the given date.
    /// Idempotent: returns the existing summary if one already exists.
    static func collectData(for date: Date, context: ModelContext) async throws -> DailySummary {
        let targetDate = DateHelpers.startOfDay(for: date)

        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate<DailySummary> { $0.date == targetDate }
        )
        if let existing = try context.fetch(descriptor).first {
            return existing
        }

        let summary = try await HealthDataAggregator.aggregateDay(date: targetDate)
        context.insert(summary)

        let (dayStart, dayEnd) = DateHelpers.dateRange(for: targetDate)
        let workouts = (try? await HealthKitManager.queryWorkouts(
            start: dayStart, end: dayEnd
        )) ?? []
        for workout in workouts {
            context.insert(workout)
        }

        try context.save()
        return summary
    }

    // MARK: - Needs Collection

    /// Returns true if no DailySummary exists for the given date.
    static func needsCollection(for date: Date, context: ModelContext) -> Bool {
        let targetDate = DateHelpers.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailySummary>(
            predicate: #Predicate<DailySummary> { $0.date == targetDate }
        )
        do {
            return try context.fetchCount(descriptor) == 0
        } catch {
            return true
        }
    }

    // MARK: - Collect Missed Days

    /// Fills gaps between the most recent stored DailySummary and yesterday.
    /// Caps at 30 days to avoid excessive HealthKit queries.
    /// Returns the number of days collected.
    static func collectMissedDays(context: ModelContext) async throws -> Int {
        var descriptor = FetchDescriptor<DailySummary>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let mostRecent = try context.fetch(descriptor).first else {
            return 0
        }

        let calendar = Calendar.current
        let yesterday = DateHelpers.yesterday()

        guard let dayAfterMostRecent = calendar.date(byAdding: .day, value: 1, to: mostRecent.date),
              dayAfterMostRecent <= yesterday else {
            return 0
        }

        // Cap at 30 days
        let cappedStart: Date
        if let daysGap = calendar.dateComponents([.day], from: dayAfterMostRecent, to: yesterday).day,
           daysGap >= 30 {
            cappedStart = calendar.date(byAdding: .day, value: -29, to: yesterday)!
        } else {
            cappedStart = dayAfterMostRecent
        }

        var collected = 0
        var currentDate = DateHelpers.startOfDay(for: cappedStart)

        while currentDate <= yesterday {
            _ = try await collectData(for: currentDate, context: context)
            collected += 1
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return collected
    }
}
