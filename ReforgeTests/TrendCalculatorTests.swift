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

    // MARK: - weeklyAggregate

    @Test func weeklyAggregate_sumFullWeek() {
        // Use startOfWeek to be locale-independent
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        )
        let summaries = (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: weekStart)!
            let day = Calendar.current.component(.day, from: date)
            let month = Calendar.current.component(.month, from: date)
            return makeSummary(year: 2026, month: month, day: day, steps: 10000)
        }
        let result = TrendCalculator.weeklyAggregate(
            for: \.steps, aggregation: .sum, weekStart: weekStart, from: summaries
        )
        #expect(result == 70000.0)
    }

    @Test func weeklyAggregate_avgFullWeek() {
        // 7 days of heart rate data in the same week
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        )
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = (0..<7).map { offset in
            makeSummary(year: 2026, month: 1, day: weekStartDay + offset, heartRateAvg: 70.0 + Double(offset))
        }
        let result = TrendCalculator.weeklyAggregate(
            for: \.heartRateAvg, aggregation: .avg, weekStart: weekStart, from: summaries
        )
        // avg of 70,71,72,73,74,75,76 = 73
        #expect(result == 73.0)
    }

    @Test func weeklyAggregate_partialWeek() {
        // Only 3 days have step data in the week
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        )
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: weekStartDay, steps: 8000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 2, steps: 10000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 4, steps: 12000),
        ]
        let result = TrendCalculator.weeklyAggregate(
            for: \.steps, aggregation: .sum, weekStart: weekStart, from: summaries
        )
        #expect(result == 30000.0)
    }

    @Test func weeklyAggregate_emptyWeek() {
        // No summaries in range
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        )
        // Summaries are in a different week
        let summaries = [
            makeSummary(year: 2026, month: 2, day: 1, steps: 5000),
        ]
        let result = TrendCalculator.weeklyAggregate(
            for: \.steps, aggregation: .sum, weekStart: weekStart, from: summaries
        )
        #expect(result == nil)
    }

    @Test func weeklyAggregate_skipsNilMetricValues() {
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        )
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: weekStartDay, steps: 8000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 1, steps: nil),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 2, steps: 12000),
        ]
        let result = TrendCalculator.weeklyAggregate(
            for: \.steps, aggregation: .sum, weekStart: weekStart, from: summaries
        )
        #expect(result == 20000.0)
    }

    @Test func weeklyAggregate_doubleKeypath() {
        let weekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        )
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: weekStartDay, heartRateAvg: 65.0),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 1, heartRateAvg: 70.0),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 2, heartRateAvg: 75.0),
        ]
        let result = TrendCalculator.weeklyAggregate(
            for: \.heartRateAvg, aggregation: .avg, weekStart: weekStart, from: summaries
        )
        #expect(result == 70.0)
    }

    // MARK: - thisWeek / lastWeek

    @Test func thisWeek_returnsCorrectSum() {
        // Create data for "this week" relative to Jan 7, 2026
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        let weekStart = DateHelpers.startOfWeek(for: referenceDate)
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = (0..<7).map { offset in
            makeSummary(year: 2026, month: 1, day: weekStartDay + offset, steps: 10000)
        }
        let result = TrendCalculator.thisWeek(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        #expect(result == 70000.0)
    }

    @Test func lastWeek_returnsCorrectSum() {
        // Create data for the week BEFORE the week containing Jan 14, 2026
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 14))!
        let thisWeekStart = DateHelpers.startOfWeek(for: referenceDate)
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart)!
        let lastWeekStartDay = Calendar.current.component(.day, from: lastWeekStart)
        let lastWeekStartMonth = Calendar.current.component(.month, from: lastWeekStart)

        let summaries = (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: lastWeekStart)!
            let day = Calendar.current.component(.day, from: date)
            let month = Calendar.current.component(.month, from: date)
            return makeSummary(year: 2026, month: month, day: day, steps: 8000)
        }
        let result = TrendCalculator.lastWeek(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        #expect(result == 56000.0)
    }

    @Test func thisWeek_partialData() {
        // Only 3 days have data in the current week
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        let weekStart = DateHelpers.startOfWeek(for: referenceDate)
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: weekStartDay, steps: 5000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 1, steps: 6000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 2, steps: 7000),
        ]
        let result = TrendCalculator.thisWeek(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        #expect(result == 18000.0)
    }

    @Test func thisWeek_intKeypath() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        let weekStart = DateHelpers.startOfWeek(for: referenceDate)
        let weekStartDay = Calendar.current.component(.day, from: weekStart)
        let summaries = [
            makeSummary(year: 2026, month: 1, day: weekStartDay, steps: 5000),
            makeSummary(year: 2026, month: 1, day: weekStartDay + 1, steps: 6000),
        ]
        let result = TrendCalculator.thisWeek(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        #expect(result == 11000.0)
    }

    // MARK: - weekMedian

    @Test func weekMedian_fourWeeks() {
        // Create 4 full weeks of step data with different weekly totals
        var summaries: [DailySummary] = []
        let dailyValues = [9000, 10000, 11000, 12000]

        // Align base to a week boundary
        let baseWeekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        )
        for weekIndex in 0..<4 {
            let weekStart = Calendar.current.date(byAdding: .day, value: weekIndex * 7, to: baseWeekStart)!
            for dayOffset in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!
                let day = Calendar.current.component(.day, from: date)
                let month = Calendar.current.component(.month, from: date)
                summaries.append(makeSummary(year: 2026, month: month, day: day, steps: dailyValues[weekIndex]))
            }
        }

        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let result = TrendCalculator.weekMedian(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        // Weekly sums: [63000, 70000, 77000, 84000] → median of even = (70000 + 77000) / 2 = 73500
        #expect(result == 73500.0)
    }

    @Test func weekMedian_skipsWeeksWithNoMetricData() {
        // 3 weeks: week 1 has steps, week 2 has no steps (only heartRate), week 3 has steps
        var summaries: [DailySummary] = []
        let baseWeekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        )

        // Week 1: steps = 10000/day
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: baseWeekStart)!
            let day = Calendar.current.component(.day, from: date)
            let month = Calendar.current.component(.month, from: date)
            summaries.append(makeSummary(year: 2026, month: month, day: day, steps: 10000))
        }

        // Week 2: only heartRate, no steps
        let week2Start = Calendar.current.date(byAdding: .day, value: 7, to: baseWeekStart)!
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week2Start)!
            let day = Calendar.current.component(.day, from: date)
            let month = Calendar.current.component(.month, from: date)
            summaries.append(makeSummary(year: 2026, month: month, day: day, heartRateAvg: 72.0))
        }

        // Week 3: steps = 14000/day
        let week3Start = Calendar.current.date(byAdding: .day, value: 14, to: baseWeekStart)!
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: week3Start)!
            let day = Calendar.current.component(.day, from: date)
            let month = Calendar.current.component(.month, from: date)
            summaries.append(makeSummary(year: 2026, month: month, day: day, steps: 14000))
        }

        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let result = TrendCalculator.weekMedian(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: summaries
        )
        // Only 2 weeks with step data: [70000, 98000] → median = 84000
        #expect(result == 84000.0)
    }

    @Test func weekMedian_emptySummaries() {
        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        let result = TrendCalculator.weekMedian(
            for: \.steps, aggregation: .sum, relativeTo: referenceDate, from: []
        )
        #expect(result == nil)
    }

    @Test func weekMedian_doubleKeypath() {
        // 3 weeks of heart rate averages
        var summaries: [DailySummary] = []
        let baseWeekStart = DateHelpers.startOfWeek(
            for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 7))!
        )
        let weeklyAvgs: [Double] = [68.0, 72.0, 76.0]

        for weekIndex in 0..<3 {
            let weekStart = Calendar.current.date(byAdding: .day, value: weekIndex * 7, to: baseWeekStart)!
            for dayOffset in 0..<7 {
                let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: weekStart)!
                let day = Calendar.current.component(.day, from: date)
                let month = Calendar.current.component(.month, from: date)
                summaries.append(makeSummary(year: 2026, month: month, day: day, heartRateAvg: weeklyAvgs[weekIndex]))
            }
        }

        let referenceDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        let result = TrendCalculator.weekMedian(
            for: \.heartRateAvg, aggregation: .avg, relativeTo: referenceDate, from: summaries
        )
        // Weekly avgs: [68, 72, 76] → median = 72
        #expect(result == 72.0)
    }
}
