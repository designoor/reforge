import Foundation

// MARK: - UnitPreference

/// Represents the user's preferred measurement system.
enum UnitPreference: String {
    case metric
    case imperial
}

// MARK: - UnitConverter

/// Static utility functions for metric ↔ imperial unit conversions.
/// All internal storage uses metric units; this utility handles display formatting
/// and input conversion for the user's preferred unit system.
enum UnitConverter {

    // MARK: - Constants

    private static let lbsPerKg = 2.20462
    private static let metersPerInch = 0.0254
    private static let inchesPerFoot = 12
    private static let metersPerMile = 1609.344
    private static let metersPerKm = 1000.0

    // MARK: - Display Functions

    /// Formats a weight stored in kilograms for display.
    /// - Returns: `"70.0 kg"` or `"154.3 lbs"` depending on preference.
    static func displayWeight(_ kg: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:
            return String(format: "%.1f kg", kg)
        case .imperial:
            return String(format: "%.1f lbs", lbsFromKg(kg))
        }
    }

    /// Formats a height stored in meters for display.
    /// - Returns: `"1.75 m"` or `"5'9\""` depending on preference.
    static func displayHeight(_ m: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:
            return String(format: "%.2f m", m)
        case .imperial:
            let (feet, inches) = feetInchesFromMeters(m)
            return "\(feet)'\(inches)\""
        }
    }

    /// Formats a distance stored in meters for display.
    /// - Returns: `"5.2 km"` or `"3.2 mi"` depending on preference.
    static func displayDistance(_ m: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:
            return String(format: "%.1f km", m / metersPerKm)
        case .imperial:
            return String(format: "%.1f mi", milesFromKm(m / metersPerKm))
        }
    }

    /// Formats a temperature stored in Celsius for display.
    /// - Returns: `"36.5°C"` or `"97.7°F"` depending on preference.
    static func displayTemperature(_ celsius: Double, unit: UnitPreference) -> String {
        switch unit {
        case .metric:
            return String(format: "%.1f°C", celsius)
        case .imperial:
            return String(format: "%.1f°F", fahrenheitFromCelsius(celsius))
        }
    }

    // MARK: - Weight Conversions

    /// Converts pounds to kilograms.
    static func kgFromLbs(_ lbs: Double) -> Double {
        lbs / lbsPerKg
    }

    /// Converts kilograms to pounds.
    static func lbsFromKg(_ kg: Double) -> Double {
        kg * lbsPerKg
    }

    // MARK: - Height Conversions

    /// Converts feet and inches to meters.
    static func metersFromFeetInches(feet: Int, inches: Int) -> Double {
        let totalInches = feet * inchesPerFoot + inches
        return Double(totalInches) * metersPerInch
    }

    /// Converts meters to feet and inches.
    static func feetInchesFromMeters(_ m: Double) -> (feet: Int, inches: Int) {
        let totalInches = Int((m / metersPerInch).rounded())
        let feet = totalInches / inchesPerFoot
        let inches = totalInches % inchesPerFoot
        return (feet, inches)
    }

    // MARK: - Distance Conversions

    /// Converts miles to kilometers.
    static func kmFromMiles(_ miles: Double) -> Double {
        miles * metersPerMile / metersPerKm
    }

    /// Converts kilometers to miles.
    static func milesFromKm(_ km: Double) -> Double {
        km * metersPerKm / metersPerMile
    }

    // MARK: - Temperature Conversions

    /// Converts Fahrenheit to Celsius.
    static func celsiusFromFahrenheit(_ f: Double) -> Double {
        (f - 32.0) * 5.0 / 9.0
    }

    /// Converts Celsius to Fahrenheit.
    static func fahrenheitFromCelsius(_ c: Double) -> Double {
        c * 9.0 / 5.0 + 32.0
    }
}
