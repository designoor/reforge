import Foundation
import SwiftData

enum TrendCalculator {

    /// Returns the median of the given values, or `nil` if the array is empty.
    /// For an odd count, returns the middle element.
    /// For an even count, returns the average of the two middle elements.
    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let count = sorted.count
        if count.isMultiple(of: 2) {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
        } else {
            return sorted[count / 2]
        }
    }

    /// Returns the sum of all values, or `nil` if the array is empty.
    static func sum(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }

    /// Returns the arithmetic mean of all values, or `nil` if the array is empty.
    static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Day-of-Week Median

    /// Returns the median value of a `Double?` metric across all summaries matching the given day of week.
    /// Filters summaries by `dayOfWeek` (1 = Sunday … 7 = Saturday), extracts non-nil values, and returns the median.
    /// Returns `nil` if no matching summaries have a non-nil value for the metric.
    static func dayOfWeekMedian(
        for metric: KeyPath<DailySummary, Double?>,
        dayOfWeek: Int,
        from summaries: [DailySummary]
    ) -> Double? {
        let values = summaries
            .filter { $0.dayOfWeek == dayOfWeek }
            .compactMap { $0[keyPath: metric] }
        return median(values)
    }

    /// Returns the median value of an `Int?` metric across all summaries matching the given day of week.
    /// Converts integer values to `Double` before computing the median.
    static func dayOfWeekMedian(
        for metric: KeyPath<DailySummary, Int?>,
        dayOfWeek: Int,
        from summaries: [DailySummary]
    ) -> Double? {
        let values = summaries
            .filter { $0.dayOfWeek == dayOfWeek }
            .compactMap { $0[keyPath: metric] }
            .map { Double($0) }
        return median(values)
    }
}
