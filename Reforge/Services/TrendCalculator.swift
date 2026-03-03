import Foundation

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
}
