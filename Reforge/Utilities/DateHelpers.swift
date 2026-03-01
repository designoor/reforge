import Foundation

// MARK: - DateHelpers

/// Static utility functions for date manipulation throughout the app.
/// Uses `Calendar.current` to respect the user's locale and timezone settings.
enum DateHelpers {

    // MARK: - Day-Level

    /// Normalizes a date to midnight (start of day) in the current calendar.
    static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Returns the full-day range: midnight to 23:59:59 for the given date.
    static func dateRange(for date: Date) -> (start: Date, end: Date) {
        let start = startOfDay(for: date)
        let end = Calendar.current.date(
            byAdding: DateComponents(day: 1, second: -1),
            to: start
        )!
        return (start, end)
    }

    /// Returns the weekday number: 1 = Sunday, 7 = Saturday.
    static func dayOfWeek(for date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    /// Returns midnight of yesterday in the current calendar.
    static func yesterday() -> Date {
        let today = startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: -1, to: today)!
    }

    /// Returns midnight of the date `n` days before `date`.
    static func daysAgo(_ n: Int, from date: Date = Date()) -> Date {
        let start = startOfDay(for: date)
        return Calendar.current.date(byAdding: .day, value: -n, to: start)!
    }

    // MARK: - Week-Level

    /// Returns midnight of the first day of the calendar week containing `date`.
    /// Respects the user's locale for which day starts the week.
    static func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    /// Returns the full-week range: start of week to end of week (last day at 23:59:59).
    static func dateRangeForWeek(containing date: Date) -> (start: Date, end: Date) {
        let start = startOfWeek(for: date)
        let end = Calendar.current.date(
            byAdding: DateComponents(day: 7, second: -1),
            to: start
        )!
        return (start, end)
    }

    // MARK: - Month-Level

    /// Returns midnight of the first day of the month containing `date`.
    static func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components)!
    }

    /// Returns the full-month range: 1st of month at midnight to last day at 23:59:59.
    static func dateRangeForMonth(containing date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = startOfMonth(for: date)
        let end = calendar.date(
            byAdding: DateComponents(month: 1, second: -1),
            to: start
        )!
        return (start, end)
    }
}
