import Testing
@testable import Reforge
import Foundation

struct UnitConverterTests {

    // MARK: - Weight Conversions

    @Test func kgFromLbs_knownValue() {
        let result = UnitConverter.kgFromLbs(154.3)
        #expect(abs(result - 69.98) < 0.1)
    }

    @Test func lbsFromKg_knownValue() {
        let result = UnitConverter.lbsFromKg(70.0)
        #expect(abs(result - 154.3) < 0.1)
    }

    @Test func weight_roundTrip() {
        let original = 85.5
        let lbs = UnitConverter.lbsFromKg(original)
        let backToKg = UnitConverter.kgFromLbs(lbs)
        #expect(abs(backToKg - original) < 0.01)
    }

    @Test func weight_zero() {
        #expect(UnitConverter.kgFromLbs(0) == 0)
        #expect(UnitConverter.lbsFromKg(0) == 0)
    }

    // MARK: - Height Conversions

    @Test func metersFromFeetInches_fiveNine() {
        let result = UnitConverter.metersFromFeetInches(feet: 5, inches: 9)
        #expect(abs(result - 1.7526) < 0.01)
    }

    @Test func feetInchesFromMeters_175cm() {
        let (feet, inches) = UnitConverter.feetInchesFromMeters(1.75)
        #expect(feet == 5)
        #expect(inches == 9)
    }

    @Test func feetInchesFromMeters_exactFeet() {
        // 6'0" = 72 inches = 1.8288 m
        let (feet, inches) = UnitConverter.feetInchesFromMeters(1.8288)
        #expect(feet == 6)
        #expect(inches == 0)
    }

    @Test func height_roundTrip() {
        let originalMeters = UnitConverter.metersFromFeetInches(feet: 5, inches: 11)
        let (feet, inches) = UnitConverter.feetInchesFromMeters(originalMeters)
        #expect(feet == 5)
        #expect(inches == 11)
    }

    // MARK: - Distance Conversions

    @Test func milesFromKm_knownValue() {
        let result = UnitConverter.milesFromKm(5.0)
        #expect(abs(result - 3.107) < 0.01)
    }

    @Test func kmFromMiles_knownValue() {
        let result = UnitConverter.kmFromMiles(3.107)
        #expect(abs(result - 5.0) < 0.01)
    }

    @Test func distance_roundTrip() {
        let original = 10.0
        let miles = UnitConverter.milesFromKm(original)
        let backToKm = UnitConverter.kmFromMiles(miles)
        #expect(abs(backToKm - original) < 0.01)
    }

    @Test func distance_zero() {
        #expect(UnitConverter.milesFromKm(0) == 0)
        #expect(UnitConverter.kmFromMiles(0) == 0)
    }

    // MARK: - Temperature Conversions

    @Test func fahrenheitFromCelsius_bodyTemp() {
        let result = UnitConverter.fahrenheitFromCelsius(36.5)
        #expect(abs(result - 97.7) < 0.1)
    }

    @Test func celsiusFromFahrenheit_bodyTemp() {
        let result = UnitConverter.celsiusFromFahrenheit(97.7)
        #expect(abs(result - 36.5) < 0.1)
    }

    @Test func temperature_freezingPoint() {
        #expect(UnitConverter.fahrenheitFromCelsius(0) == 32.0)
        #expect(UnitConverter.celsiusFromFahrenheit(32.0) == 0)
    }

    @Test func temperature_boilingPoint() {
        #expect(abs(UnitConverter.fahrenheitFromCelsius(100.0) - 212.0) < 0.01)
        #expect(abs(UnitConverter.celsiusFromFahrenheit(212.0) - 100.0) < 0.01)
    }

    @Test func temperature_roundTrip() {
        let original = 37.0
        let f = UnitConverter.fahrenheitFromCelsius(original)
        let backToC = UnitConverter.celsiusFromFahrenheit(f)
        #expect(abs(backToC - original) < 0.01)
    }

    // MARK: - Display Weight

    @Test func displayWeight_metric() {
        let result = UnitConverter.displayWeight(70.0, unit: .metric)
        #expect(result == "70.0 kg")
    }

    @Test func displayWeight_imperial() {
        let result = UnitConverter.displayWeight(70.0, unit: .imperial)
        #expect(result == "154.3 lbs")
    }

    // MARK: - Display Height

    @Test func displayHeight_metric() {
        let result = UnitConverter.displayHeight(1.75, unit: .metric)
        #expect(result == "1.75 m")
    }

    @Test func displayHeight_imperial() {
        let result = UnitConverter.displayHeight(1.75, unit: .imperial)
        #expect(result == "5'9\"")
    }

    @Test func displayHeight_imperialExactFeet() {
        let result = UnitConverter.displayHeight(1.8288, unit: .imperial)
        #expect(result == "6'0\"")
    }

    // MARK: - Display Distance

    @Test func displayDistance_metric() {
        let result = UnitConverter.displayDistance(5200, unit: .metric)
        #expect(result == "5.2 km")
    }

    @Test func displayDistance_imperial() {
        let result = UnitConverter.displayDistance(5200, unit: .imperial)
        #expect(result == "3.2 mi")
    }

    // MARK: - Display Temperature

    @Test func displayTemperature_metric() {
        let result = UnitConverter.displayTemperature(36.5, unit: .metric)
        #expect(result == "36.5°C")
    }

    @Test func displayTemperature_imperial() {
        let result = UnitConverter.displayTemperature(36.5, unit: .imperial)
        #expect(result == "97.7°F")
    }
}
