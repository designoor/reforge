import Foundation
import Testing
@testable import Reforge

struct TrendCalculatorTests {

    // MARK: - Helpers

    /// Creates a `DailySummary` for the given date with optional metric values.
    private func makeSummary(
        year: Int, month: Int, day: Int,
        steps: Int? = nil,
        heartRateAvg: Double? = nil
    ) -> DailySummary {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
        return DailySummary(date: date, steps: steps, heartRateAvg: heartRateAvg)
    }

    // MARK: - median

    @Test func median_oddCount() {
        #expect(TrendCalculator.median([3, 1, 4, 1, 5]) == 3.0)
    }

    @Test func median_evenCount() {
        #expect(TrendCalculator.median([1, 2]) == 1.5)
    }

    @Test func median_emptyArray() {
        #expect(TrendCalculator.median([]) == nil)
    }

    @Test func median_singleElement() {
        #expect(TrendCalculator.median([5]) == 5.0)
    }

    @Test func median_alreadySorted() {
        #expect(TrendCalculator.median([1, 2, 3, 4, 5]) == 3.0)
    }

    @Test func median_duplicateValues() {
        #expect(TrendCalculator.median([7, 7, 7]) == 7.0)
    }

    // MARK: - sum

    @Test func sum_multipleValues() {
        #expect(TrendCalculator.sum([1, 2, 3, 4, 5]) == 15.0)
    }

    @Test func sum_emptyArray() {
        #expect(TrendCalculator.sum([]) == nil)
    }

    @Test func sum_singleElement() {
        #expect(TrendCalculator.sum([42]) == 42.0)
    }

    @Test func sum_withDecimals() {
        let result = TrendCalculator.sum([1.5, 2.5])!
        #expect(abs(result - 4.0) < 1e-10)
    }

    // MARK: - average

    @Test func average_multipleValues() {
        #expect(TrendCalculator.average([2, 4, 6]) == 4.0)
    }

    @Test func average_emptyArray() {
        #expect(TrendCalculator.average([]) == nil)
    }

    @Test func average_singleElement() {
        #expect(TrendCalculator.average([10]) == 10.0)
    }

    @Test func average_withDecimals() {
        let result = TrendCalculator.average([1.0, 2.0, 3.0])!
        #expect(abs(result - 2.0) < 1e-10)
    }

    // MARK: - dayOfWeekMedian (Int? keypath)

    @Test func dayOfWeekMedian_tenFridaysSteps() {
        // 10 Fridays (dayOfWeek = 6) with step counts
        let fridayDates: [(Int, Int, Int)] = [
            (2026, 1, 2), (2026, 1, 9), (2026, 1, 16), (2026, 1, 23), (2026, 1, 30),
            (2026, 2, 6), (2026, 2, 13), (2026, 2, 20), (2026, 2, 27), (2026, 3, 6),
        ]
        let stepValues = [8000, 9000, 10000, 11000, 12000, 7000, 9500, 10500, 11500, 8500]
        let summaries = zip(fridayDates, stepValues).map { date, steps in
            makeSummary(year: date.0, month: date.1, day: date.2, steps: steps)
        }

        let result = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 6, from: summaries)
        // Sorted: 7000, 8000, 8500, 9000, 9500, 10000, 10500, 11000, 11500, 12000
        // Median of even count: (9500 + 10000) / 2 = 9750
        #expect(result == 9750.0)
    }

    @Test func dayOfWeekMedian_skipsNilValues() {
        // 5 Fridays, 2 with nil steps
        let summaries = [
            makeSummary(year: 2026, month: 1, day: 2, steps: 8000),
            makeSummary(year: 2026, month: 1, day: 9, steps: nil),
            makeSummary(year: 2026, month: 1, day: 16, steps: 10000),
            makeSummary(year: 2026, month: 1, day: 23, steps: nil),
            makeSummary(year: 2026, month: 1, day: 30, steps: 12000),
        ]

        let result = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 6, from: summaries)
        // Non-nil values: [8000, 10000, 12000] → median = 10000
        #expect(result == 10000.0)
    }

    @Test func dayOfWeekMedian_noDataForWeekday() {
        // Only Friday data, but query for Monday (dayOfWeek = 2)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: 2, steps: 8000),
            makeSummary(year: 2026, month: 1, day: 9, steps: 9000),
        ]

        let result = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 2, from: summaries)
        #expect(result == nil)
    }

    @Test func dayOfWeekMedian_mixedWeekdays_filtersCorrectly() {
        // Mix of Fridays (6), Mondays (2), and Wednesdays (4)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: 2, steps: 8000),   // Friday
            makeSummary(year: 2026, month: 1, day: 5, steps: 5000),   // Monday
            makeSummary(year: 2026, month: 1, day: 7, steps: 6000),   // Wednesday
            makeSummary(year: 2026, month: 1, day: 9, steps: 10000),  // Friday
            makeSummary(year: 2026, month: 1, day: 12, steps: 4000),  // Monday
        ]

        // Friday median: [8000, 10000] → 9000
        let fridayResult = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 6, from: summaries)
        #expect(fridayResult == 9000.0)

        // Monday median: [5000, 4000] → 4500
        let mondayResult = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 2, from: summaries)
        #expect(mondayResult == 4500.0)
    }

    @Test func dayOfWeekMedian_emptySummaries() {
        let result = TrendCalculator.dayOfWeekMedian(for: \.steps, dayOfWeek: 6, from: [])
        #expect(result == nil)
    }

    // MARK: - dayOfWeekMedian (Double? keypath)

    @Test func dayOfWeekMedian_doubleKeypath() {
        let summaries = [
            makeSummary(year: 2026, month: 1, day: 2, heartRateAvg: 72.0),  // Friday
            makeSummary(year: 2026, month: 1, day: 9, heartRateAvg: 68.0),  // Friday
            makeSummary(year: 2026, month: 1, day: 16, heartRateAvg: 75.0), // Friday
        ]

        let result = TrendCalculator.dayOfWeekMedian(for: \.heartRateAvg, dayOfWeek: 6, from: summaries)
        // Sorted: [68, 72, 75] → median = 72
        #expect(result == 72.0)
    }

    @Test func dayOfWeekMedian_allNilForMetric() {
        // Fridays exist but heartRateAvg is nil for all of them
        let summaries = [
            makeSummary(year: 2026, month: 1, day: 2, steps: 8000),
            makeSummary(year: 2026, month: 1, day: 9, steps: 9000),
        ]

        let result = TrendCalculator.dayOfWeekMedian(for: \.heartRateAvg, dayOfWeek: 6, from: summaries)
        #expect(result == nil)
    }
}
