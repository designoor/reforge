import Foundation
import SwiftData

struct MetricTrend {
    let dayValue: Double?
    let dayOfWeekMedian: Double?
    let thisWeek: Double?
    let lastWeek: Double?
    let weekMedian: Double?
    let thisMonth: Double?
    let lastMonth: Double?
    let monthMedian: Double?
}

struct TrendReport {
    let date: Date
    let trends: [MetricDefinition: MetricTrend]
}

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

    // MARK: - Weekly Aggregates

    /// Aggregates a `Double?` metric over a 7-day window starting at `weekStart`.
    /// Uses `sum` for `.sum` aggregation, `average` for `.avg`/`.avgMinMax`/`.avgMin`,
    /// and the most recent non-nil value (by date) for `.mostRecent`.
    /// Returns `nil` if no summaries have a non-nil value in the window.
    static func weeklyAggregate(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        weekStart: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        let filtered = summaries.filter { $0.date >= weekStart && $0.date < weekEnd }
        let values = filtered.compactMap { $0[keyPath: metric] }
        guard !values.isEmpty else { return nil }

        switch aggregation {
        case .sum:
            return sum(values)
        case .avg, .avgMinMax, .avgMin:
            return average(values)
        case .mostRecent:
            return filtered
                .sorted { $0.date < $1.date }
                .last { $0[keyPath: metric] != nil }
                .flatMap { $0[keyPath: metric] }
        }
    }

    /// Aggregates an `Int?` metric over a 7-day window starting at `weekStart`.
    /// Converts integer values to `Double` before aggregating.
    static func weeklyAggregate(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        weekStart: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
        let filtered = summaries.filter { $0.date >= weekStart && $0.date < weekEnd }
        let values = filtered.compactMap { $0[keyPath: metric] }.map { Double($0) }
        guard !values.isEmpty else { return nil }

        switch aggregation {
        case .sum:
            return sum(values)
        case .avg, .avgMinMax, .avgMin:
            return average(values)
        case .mostRecent:
            return filtered
                .sorted { $0.date < $1.date }
                .last { $0[keyPath: metric] != nil }
                .flatMap { $0[keyPath: metric] }
                .map { Double($0) }
        }
    }

    /// Returns the aggregate of a `Double?` metric for the current calendar week containing `relativeTo`.
    static func thisWeek(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let weekStart = DateHelpers.startOfWeek(for: date)
        return weeklyAggregate(for: metric, aggregation: aggregation, weekStart: weekStart, from: summaries)
    }

    /// Returns the aggregate of an `Int?` metric for the current calendar week containing `relativeTo`.
    static func thisWeek(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let weekStart = DateHelpers.startOfWeek(for: date)
        return weeklyAggregate(for: metric, aggregation: aggregation, weekStart: weekStart, from: summaries)
    }

    /// Returns the aggregate of a `Double?` metric for the calendar week before the one containing `relativeTo`.
    static func lastWeek(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let thisWeekStart = DateHelpers.startOfWeek(for: date)
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart)!
        return weeklyAggregate(for: metric, aggregation: aggregation, weekStart: lastWeekStart, from: summaries)
    }

    /// Returns the aggregate of an `Int?` metric for the calendar week before the one containing `relativeTo`.
    static func lastWeek(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let thisWeekStart = DateHelpers.startOfWeek(for: date)
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: thisWeekStart)!
        return weeklyAggregate(for: metric, aggregation: aggregation, weekStart: lastWeekStart, from: summaries)
    }

    /// Returns the median of weekly aggregates for a `Double?` metric over the past year.
    /// Groups summaries into calendar weeks, computes the aggregate for each week,
    /// and returns the median of those weekly values. Weeks with no non-nil data are skipped.
    static func weekMedian(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -364, to: DateHelpers.startOfWeek(for: date))!
        let recentSummaries = summaries.filter { $0.date >= cutoff }

        let weekStarts = Set(recentSummaries.map { DateHelpers.startOfWeek(for: $0.date) })
        let weeklyValues = weekStarts.compactMap { weekStart in
            weeklyAggregate(for: metric, aggregation: aggregation, weekStart: weekStart, from: recentSummaries)
        }
        return median(weeklyValues)
    }

    /// Returns the median of weekly aggregates for an `Int?` metric over the past year.
    static func weekMedian(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -364, to: DateHelpers.startOfWeek(for: date))!
        let recentSummaries = summaries.filter { $0.date >= cutoff }

        let weekStarts = Set(recentSummaries.map { DateHelpers.startOfWeek(for: $0.date) })
        let weeklyValues = weekStarts.compactMap { weekStart in
            weeklyAggregate(for: metric, aggregation: aggregation, weekStart: weekStart, from: recentSummaries)
        }
        return median(weeklyValues)
    }

    // MARK: - Monthly Aggregates

    /// Aggregates a `Double?` metric over a calendar month starting at `monthStart`.
    /// Uses `sum` for `.sum` aggregation, `average` for `.avg`/`.avgMinMax`/`.avgMin`,
    /// and the most recent non-nil value (by date) for `.mostRecent`.
    /// Returns `nil` if no summaries have a non-nil value in the month.
    static func monthlyAggregate(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        monthStart: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
        let filtered = summaries.filter { $0.date >= monthStart && $0.date < monthEnd }
        let values = filtered.compactMap { $0[keyPath: metric] }
        guard !values.isEmpty else { return nil }

        switch aggregation {
        case .sum:
            return sum(values)
        case .avg, .avgMinMax, .avgMin:
            return average(values)
        case .mostRecent:
            return filtered
                .sorted { $0.date < $1.date }
                .last { $0[keyPath: metric] != nil }
                .flatMap { $0[keyPath: metric] }
        }
    }

    /// Aggregates an `Int?` metric over a calendar month starting at `monthStart`.
    /// Converts integer values to `Double` before aggregating.
    static func monthlyAggregate(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        monthStart: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let monthEnd = Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
        let filtered = summaries.filter { $0.date >= monthStart && $0.date < monthEnd }
        let values = filtered.compactMap { $0[keyPath: metric] }.map { Double($0) }
        guard !values.isEmpty else { return nil }

        switch aggregation {
        case .sum:
            return sum(values)
        case .avg, .avgMinMax, .avgMin:
            return average(values)
        case .mostRecent:
            return filtered
                .sorted { $0.date < $1.date }
                .last { $0[keyPath: metric] != nil }
                .flatMap { $0[keyPath: metric] }
                .map { Double($0) }
        }
    }

    /// Returns the aggregate of a `Double?` metric for the current calendar month containing `relativeTo`.
    static func thisMonth(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let monthStart = DateHelpers.startOfMonth(for: date)
        return monthlyAggregate(for: metric, aggregation: aggregation, monthStart: monthStart, from: summaries)
    }

    /// Returns the aggregate of an `Int?` metric for the current calendar month containing `relativeTo`.
    static func thisMonth(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let monthStart = DateHelpers.startOfMonth(for: date)
        return monthlyAggregate(for: metric, aggregation: aggregation, monthStart: monthStart, from: summaries)
    }

    /// Returns the aggregate of a `Double?` metric for the calendar month before the one containing `relativeTo`.
    static func lastMonth(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let thisMonthStart = DateHelpers.startOfMonth(for: date)
        let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: thisMonthStart)!
        return monthlyAggregate(for: metric, aggregation: aggregation, monthStart: lastMonthStart, from: summaries)
    }

    /// Returns the aggregate of an `Int?` metric for the calendar month before the one containing `relativeTo`.
    static func lastMonth(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let thisMonthStart = DateHelpers.startOfMonth(for: date)
        let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: thisMonthStart)!
        return monthlyAggregate(for: metric, aggregation: aggregation, monthStart: lastMonthStart, from: summaries)
    }

    /// Returns the median of monthly aggregates for a `Double?` metric over the past year.
    /// Groups summaries into calendar months, computes the aggregate for each month,
    /// and returns the median of those monthly values. Months with no non-nil data are skipped.
    static func monthMedian(
        for metric: KeyPath<DailySummary, Double?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .month, value: -12, to: DateHelpers.startOfMonth(for: date))!
        let recentSummaries = summaries.filter { $0.date >= cutoff }

        let monthStarts = Set(recentSummaries.map { DateHelpers.startOfMonth(for: $0.date) })
        let monthlyValues = monthStarts.compactMap { monthStart in
            monthlyAggregate(for: metric, aggregation: aggregation, monthStart: monthStart, from: recentSummaries)
        }
        return median(monthlyValues)
    }

    /// Returns the median of monthly aggregates for an `Int?` metric over the past year.
    static func monthMedian(
        for metric: KeyPath<DailySummary, Int?>,
        aggregation: MetricAggregation,
        relativeTo date: Date,
        from summaries: [DailySummary]
    ) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .month, value: -12, to: DateHelpers.startOfMonth(for: date))!
        let recentSummaries = summaries.filter { $0.date >= cutoff }

        let monthStarts = Set(recentSummaries.map { DateHelpers.startOfMonth(for: $0.date) })
        let monthlyValues = monthStarts.compactMap { monthStart in
            monthlyAggregate(for: metric, aggregation: aggregation, monthStart: monthStart, from: recentSummaries)
        }
        return median(monthlyValues)
    }

    // MARK: - Full Trend Report

    /// Computes all trend dimensions for all metrics on the given date.
    /// Fetches all summaries once and passes the array to each computation to avoid repeated queries.
    static func computeTrends(for date: Date, from summaries: [DailySummary]) -> TrendReport {
        let normalizedDate = DateHelpers.startOfDay(for: date)
        let daySummary = summaries.first { $0.date == normalizedDate }
        let dayOfWeek = DateHelpers.dayOfWeek(for: normalizedDate)

        var trends: [MetricDefinition: MetricTrend] = [:]

        for metric in MetricDefinition.allCases {
            guard let keyPath = metric.dailySummaryKeyPath else { continue }
            let aggregation = metric.aggregation

            let trend: MetricTrend
            switch keyPath {
            case .double(let kp):
                trend = MetricTrend(
                    dayValue: daySummary?[keyPath: kp],
                    dayOfWeekMedian: self.dayOfWeekMedian(for: kp, dayOfWeek: dayOfWeek, from: summaries),
                    thisWeek: self.thisWeek(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    lastWeek: self.lastWeek(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    weekMedian: self.weekMedian(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    thisMonth: self.thisMonth(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    lastMonth: self.lastMonth(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    monthMedian: self.monthMedian(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries)
                )
            case .int(let kp):
                trend = MetricTrend(
                    dayValue: daySummary?[keyPath: kp].map { Double($0) },
                    dayOfWeekMedian: self.dayOfWeekMedian(for: kp, dayOfWeek: dayOfWeek, from: summaries),
                    thisWeek: self.thisWeek(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    lastWeek: self.lastWeek(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    weekMedian: self.weekMedian(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    thisMonth: self.thisMonth(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    lastMonth: self.lastMonth(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries),
                    monthMedian: self.monthMedian(for: kp, aggregation: aggregation, relativeTo: normalizedDate, from: summaries)
                )
            }
            trends[metric] = trend
        }

        return TrendReport(date: normalizedDate, trends: trends)
    }
}
