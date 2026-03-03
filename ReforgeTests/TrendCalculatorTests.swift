import Testing
@testable import Reforge

struct TrendCalculatorTests {

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
}
