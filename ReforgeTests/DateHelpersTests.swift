import Testing
@testable import Reforge
import Foundation

struct DateHelpersTests {

    // MARK: - Helper

    private func makeDate(
        year: Int, month: Int, day: Int,
        hour: Int = 0, minute: Int = 0, second: Int = 0
    ) -> Date {
        let components = DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second
        )
        return Calendar.current.date(from: components)!
    }

    // MARK: - startOfDay

    @Test func startOfDay_normalizesToMidnight() {
        let afternoon = makeDate(year: 2025, month: 6, day: 15, hour: 14, minute: 30)
        let result = DateHelpers.startOfDay(for: afternoon)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: result)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func startOfDay_preservesDate() {
        let afternoon = makeDate(year: 2025, month: 6, day: 15, hour: 14)
        let result = DateHelpers.startOfDay(for: afternoon)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2025)
        #expect(components.month == 6)
        #expect(components.day == 15)
    }

    @Test func startOfDay_alreadyMidnight() {
        let midnight = makeDate(year: 2025, month: 3, day: 1)
        let result = DateHelpers.startOfDay(for: midnight)
        #expect(result == midnight)
    }

    // MARK: - dateRange

    @Test func dateRange_startsAtMidnight() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 10)
        let range = DateHelpers.dateRange(for: date)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: range.start
        )
        #expect(components.year == 2025)
        #expect(components.month == 6)
        #expect(components.day == 15)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func dateRange_endsAt235959() {
        let date = makeDate(year: 2025, month: 6, day: 15, hour: 10)
        let range = DateHelpers.dateRange(for: date)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: range.end
        )
        #expect(components.day == 15)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    // MARK: - dayOfWeek

    @Test func dayOfWeek_knownSunday() {
        // June 15, 2025 is a Sunday
        let sunday = makeDate(year: 2025, month: 6, day: 15)
        #expect(DateHelpers.dayOfWeek(for: sunday) == 1)
    }

    @Test func dayOfWeek_knownSaturday() {
        // June 14, 2025 is a Saturday
        let saturday = makeDate(year: 2025, month: 6, day: 14)
        #expect(DateHelpers.dayOfWeek(for: saturday) == 7)
    }

    @Test func dayOfWeek_knownWednesday() {
        // June 18, 2025 is a Wednesday
        let wednesday = makeDate(year: 2025, month: 6, day: 18)
        #expect(DateHelpers.dayOfWeek(for: wednesday) == 4)
    }

    // MARK: - yesterday

    @Test func yesterday_isOneDayBeforeToday() {
        let result = DateHelpers.yesterday()
        let today = DateHelpers.startOfDay(for: Date())
        let diff = Calendar.current.dateComponents([.day], from: result, to: today)
        #expect(diff.day == 1)
    }

    @Test func yesterday_isMidnight() {
        let result = DateHelpers.yesterday()
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: result)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    // MARK: - daysAgo

    @Test func daysAgo_sevenDays() {
        let reference = makeDate(year: 2025, month: 6, day: 15)
        let result = DateHelpers.daysAgo(7, from: reference)
        let expected = makeDate(year: 2025, month: 6, day: 8)
        #expect(result == expected)
    }

    @Test func daysAgo_zeroDays() {
        let reference = makeDate(year: 2025, month: 6, day: 15)
        let result = DateHelpers.daysAgo(0, from: reference)
        #expect(result == DateHelpers.startOfDay(for: reference))
    }

    @Test func daysAgo_crossesMonthBoundary() {
        let reference = makeDate(year: 2025, month: 3, day: 2)
        let result = DateHelpers.daysAgo(5, from: reference)
        let components = Calendar.current.dateComponents([.month, .day], from: result)
        #expect(components.month == 2)
        #expect(components.day == 25)
    }

    @Test func daysAgo_crossesYearBoundary() {
        let jan2 = makeDate(year: 2025, month: 1, day: 2)
        let result = DateHelpers.daysAgo(5, from: jan2)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 28)
    }

    // MARK: - startOfWeek

    @Test func startOfWeek_resultIsFirstWeekday() {
        let wednesday = makeDate(year: 2025, month: 6, day: 18)
        let result = DateHelpers.startOfWeek(for: wednesday)
        let weekday = Calendar.current.component(.weekday, from: result)
        #expect(weekday == Calendar.current.firstWeekday)
    }

    @Test func startOfWeek_alreadyFirstDay() {
        // June 15, 2025 is a Sunday
        let sunday = makeDate(year: 2025, month: 6, day: 15)
        let result = DateHelpers.startOfWeek(for: sunday)
        if Calendar.current.firstWeekday == 1 {
            #expect(result == DateHelpers.startOfDay(for: sunday))
        }
    }

    @Test func startOfWeek_crossesYearBoundary() {
        // Jan 1, 2025 is a Wednesday. If week starts Sunday, start is Dec 29, 2024.
        let jan1 = makeDate(year: 2025, month: 1, day: 1)
        let result = DateHelpers.startOfWeek(for: jan1)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        if Calendar.current.firstWeekday == 1 {
            #expect(components.year == 2024)
            #expect(components.month == 12)
            #expect(components.day == 29)
        }
    }

    // MARK: - startOfMonth

    @Test func startOfMonth_midMonth() {
        let date = makeDate(year: 2025, month: 6, day: 15)
        let result = DateHelpers.startOfMonth(for: date)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2025)
        #expect(components.month == 6)
        #expect(components.day == 1)
    }

    @Test func startOfMonth_alreadyFirstDay() {
        let first = makeDate(year: 2025, month: 6, day: 1)
        let result = DateHelpers.startOfMonth(for: first)
        #expect(result == first)
    }

    // MARK: - dateRangeForWeek

    @Test func dateRangeForWeek_spansSevenDays() {
        let date = makeDate(year: 2025, month: 6, day: 18)
        let range = DateHelpers.dateRangeForWeek(containing: date)
        let days = Calendar.current.dateComponents([.day], from: range.start, to: range.end)
        // 6 days + 23:59:59 = full 7-day span
        #expect(days.day == 6)
    }

    @Test func dateRangeForWeek_startsOnFirstWeekday() {
        let date = makeDate(year: 2025, month: 6, day: 18)
        let range = DateHelpers.dateRangeForWeek(containing: date)
        let weekday = Calendar.current.component(.weekday, from: range.start)
        #expect(weekday == Calendar.current.firstWeekday)
    }

    // MARK: - dateRangeForMonth

    @Test func dateRangeForMonth_june() {
        let date = makeDate(year: 2025, month: 6, day: 15)
        let range = DateHelpers.dateRangeForMonth(containing: date)
        let startComponents = Calendar.current.dateComponents([.day], from: range.start)
        let endComponents = Calendar.current.dateComponents(
            [.month, .day, .hour, .minute, .second], from: range.end
        )
        #expect(startComponents.day == 1)
        #expect(endComponents.month == 6)
        #expect(endComponents.day == 30)
        #expect(endComponents.hour == 23)
        #expect(endComponents.minute == 59)
        #expect(endComponents.second == 59)
    }

    @Test func dateRangeForMonth_february_nonLeapYear() {
        let date = makeDate(year: 2025, month: 2, day: 10)
        let range = DateHelpers.dateRangeForMonth(containing: date)
        let endComponents = Calendar.current.dateComponents([.month, .day], from: range.end)
        #expect(endComponents.month == 2)
        #expect(endComponents.day == 28)
    }

    @Test func dateRangeForMonth_february_leapYear() {
        let date = makeDate(year: 2024, month: 2, day: 10)
        let range = DateHelpers.dateRangeForMonth(containing: date)
        let endComponents = Calendar.current.dateComponents([.month, .day], from: range.end)
        #expect(endComponents.month == 2)
        #expect(endComponents.day == 29)
    }

    @Test func dateRangeForMonth_december() {
        let date = makeDate(year: 2025, month: 12, day: 15)
        let range = DateHelpers.dateRangeForMonth(containing: date)
        let endComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: range.end
        )
        #expect(endComponents.year == 2025)
        #expect(endComponents.month == 12)
        #expect(endComponents.day == 31)
        #expect(endComponents.hour == 23)
        #expect(endComponents.minute == 59)
        #expect(endComponents.second == 59)
    }
}
