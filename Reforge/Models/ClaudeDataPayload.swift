import Foundation

// MARK: - Top-Level Payload

struct ClaudeDataPayload: Codable {
    let date: String
    let userProfile: UserProfileContext
    let metrics: [MetricCategoryData]
    let workouts: [WorkoutData]
    let trendsNote: String
}

// MARK: - User Profile Context

struct UserProfileContext: Codable {
    let ageYears: Int
    let biologicalSex: String
    let heightDisplay: String
    let weightDisplay: String
    let heightMeters: Double
    let weightKg: Double
    let unitPreference: String
}

// MARK: - Metric Category

struct MetricCategoryData: Codable, Identifiable {
    var id: String { category }
    let category: String
    let metrics: [MetricData]
}

// MARK: - Individual Metric

struct MetricData: Codable, Identifiable {
    var id: String { name }
    let name: String
    let displayValue: String
    let unit: String
    let rawValue: Double?
    let rawMin: Double?
    let rawMax: Double?
    let trends: MetricTrends
}

// MARK: - Per-Metric Trends

struct MetricTrends: Codable {
    let dayOfWeekMedian: Double?
    let thisWeek: Double?
    let lastWeek: Double?
    let weekMedian: Double?
    let thisMonth: Double?
    let lastMonth: Double?
    let monthMedian: Double?

    static let placeholder = MetricTrends(
        dayOfWeekMedian: nil,
        thisWeek: nil,
        lastWeek: nil,
        weekMedian: nil,
        thisMonth: nil,
        lastMonth: nil,
        monthMedian: nil
    )
}

// MARK: - Workout

struct WorkoutData: Codable, Identifiable {
    var id: String { "\(type)-\(startTime)" }
    let type: String
    let durationMinutes: Double
    let energyBurnedKcal: Double?
    let distanceMeters: Double?
    let startTime: String
    let endTime: String
}

// MARK: - Builder

extension ClaudeDataPayload {

    static func build(
        date: Date,
        profile: UserProfile,
        summary: DailySummary,
        workouts: [WorkoutSummary],
        unitPref: UnitPreference
    ) -> ClaudeDataPayload {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        // Age
        let ageComponents = Calendar.current.dateComponents([.year], from: profile.dateOfBirth, to: date)
        let age = ageComponents.year ?? 0

        let userProfile = UserProfileContext(
            ageYears: age,
            biologicalSex: BiologicalSexOption.from(profile.biologicalSex).displayName,
            heightDisplay: UnitConverter.displayHeight(profile.height, unit: unitPref),
            weightDisplay: UnitConverter.displayWeight(profile.weight, unit: unitPref),
            heightMeters: profile.height,
            weightKg: profile.weight,
            unitPreference: unitPref.rawValue
        )

        // Build metrics by category
        let categoryGroups = buildMetricCategories(summary: summary, unitPref: unitPref)

        // Build workouts
        let workoutData = workouts.map { w in
            WorkoutData(
                type: w.workoutType,
                durationMinutes: w.duration,
                energyBurnedKcal: w.totalEnergyBurned,
                distanceMeters: w.totalDistance,
                startTime: isoFormatter.string(from: w.startTime),
                endTime: isoFormatter.string(from: w.endTime)
            )
        }

        return ClaudeDataPayload(
            date: dateFormatter.string(from: date),
            userProfile: userProfile,
            metrics: categoryGroups,
            workouts: workoutData,
            trendsNote: "Trend comparisons pending TrendCalculator (Phase 10). All trend values are null."
        )
    }

    // MARK: - Metric Extraction

    private struct MetricExtractor {
        let name: String
        let unit: String
        let extract: (DailySummary) -> (displayValue: String, rawValue: Double?, rawMin: Double?, rawMax: Double?)?
    }

    private static func buildMetricCategories(
        summary: DailySummary,
        unitPref: UnitPreference
    ) -> [MetricCategoryData] {

        // Formatting helpers
        func fmtInt(_ v: Double) -> String { String(format: "%.0f", v) }
        func fmt1(_ v: Double) -> String { String(format: "%.1f", v) }
        func fmt2(_ v: Double) -> String { String(format: "%.2f", v) }
        func fmtDistance(_ m: Double) -> String { UnitConverter.displayDistance(m, unit: unitPref) }
        func fmtWeight(_ kg: Double) -> String { UnitConverter.displayWeight(kg, unit: unitPref) }
        func fmtHeight(_ m: Double) -> String { UnitConverter.displayHeight(m, unit: unitPref) }
        func fmtTemp(_ c: Double) -> String { UnitConverter.displayTemperature(c, unit: unitPref) }
        func fmtPercent(_ v: Double) -> String { fmt1(v * 100) + "%" }

        // Simple extractors for Double? properties
        func simple(_ name: String, _ unit: String, _ value: Double?, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit) { _ in
                guard let v = value else { return nil }
                return (format(v), v, nil, nil)
            }
        }

        // Simple extractors for Int? properties
        func simpleInt(_ name: String, _ unit: String, _ value: Int?) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit) { _ in
                guard let v = value else { return nil }
                return ("\(v)", Double(v), nil, nil)
            }
        }

        // Avg/Min/Max extractor
        func avgMinMax(_ name: String, _ unit: String, avg: Double?, min: Double?, max: Double?, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit) { _ in
                guard let a = avg else { return nil }
                var display = format(a) + " avg"
                if let mn = min { display += " / " + format(mn) + " min" }
                if let mx = max { display += " / " + format(mx) + " max" }
                return (display, a, min, max)
            }
        }

        // Avg/Min extractor
        func avgMin(_ name: String, _ unit: String, avg: Double?, min: Double?, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit) { _ in
                guard let a = avg else { return nil }
                var display = format(a) + " avg"
                if let mn = min { display += " / " + format(mn) + " min" }
                return (display, a, min, nil)
            }
        }

        let s = summary

        let categories: [(String, [MetricExtractor])] = [
            ("Activity & Fitness", [
                simpleInt("Steps", "steps", s.steps),
                simple("Walking + Running Distance", "m", s.distanceWalkingRunning, format: fmtDistance),
                simple("Cycling Distance", "m", s.distanceCycling, format: fmtDistance),
                simple("Swimming Distance", "m", s.distanceSwimming, format: fmtDistance),
                simple("Resting Energy", "kcal", s.basalEnergyBurned, format: { fmtInt($0) + " kcal" }),
                simple("Active Energy", "kcal", s.activeEnergyBurned, format: { fmtInt($0) + " kcal" }),
                simpleInt("Flights Climbed", "flights", s.flightsClimbed),
                simple("Exercise Time", "min", s.appleExerciseTime, format: { fmtInt($0) + " min" }),
                simple("Move Time", "min", s.appleMoveTime, format: { fmtInt($0) + " min" }),
                simple("Stand Time", "min", s.appleStandTime, format: { fmtInt($0) + " min" }),
                simpleInt("Swimming Strokes", "strokes", s.swimmingStrokeCount),
                simple("Physical Effort", "APE", s.physicalEffort, format: { fmt1($0) + " APE" }),
                simple("VO2 Max", "mL/kg/min", s.vo2Max, format: { fmt1($0) + " mL/kg/min" }),
            ]),
            ("Running", [
                simple("Running Speed", "m/s", s.runningSpeed, format: { fmt2($0) + " m/s" }),
                simple("Running Power", "W", s.runningPower, format: { fmtInt($0) + " W" }),
                simple("Stride Length", "m", s.runningStrideLength, format: { fmt2($0) + " m" }),
                simple("Vertical Oscillation", "cm", s.runningVerticalOscillation, format: { fmt1($0) + " cm" }),
                simple("Ground Contact Time", "ms", s.runningGroundContactTime, format: { fmtInt($0) + " ms" }),
            ]),
            ("Cycling", [
                simple("Cycling Speed", "m/s", s.cyclingSpeed, format: { fmt2($0) + " m/s" }),
                simple("Cycling Power", "W", s.cyclingPower, format: { fmtInt($0) + " W" }),
                simple("Cycling FTP", "W", s.cyclingFTP, format: { fmtInt($0) + " W" }),
                simple("Cycling Cadence", "rpm", s.cyclingCadence, format: { fmtInt($0) + " rpm" }),
            ]),
            ("Heart", [
                avgMinMax("Heart Rate", "bpm", avg: s.heartRateAvg, min: s.heartRateMin, max: s.heartRateMax, format: { fmtInt($0) + " bpm" }),
                simple("Resting Heart Rate", "bpm", s.restingHeartRate, format: { fmtInt($0) + " bpm" }),
                simple("Walking Heart Rate", "bpm", s.walkingHeartRateAvg, format: { fmtInt($0) + " bpm" }),
                simple("Heart Rate Variability", "ms", s.hrv, format: { fmtInt($0) + " ms" }),
                simple("Heart Rate Recovery", "bpm", s.heartRateRecovery, format: { fmtInt($0) + " bpm" }),
                simple("AFib Burden", "%", s.atrialFibrillationBurden, format: fmtPercent),
                simple("Perfusion Index", "%", s.peripheralPerfusionIndex, format: fmtPercent),
            ]),
            ("Respiratory", [
                avgMinMax("Respiratory Rate", "brpm", avg: s.respiratoryRateAvg, min: s.respiratoryRateMin, max: s.respiratoryRateMax, format: { fmt1($0) + " brpm" }),
                avgMin("Blood Oxygen", "%", avg: s.oxygenSaturationAvg, min: s.oxygenSaturationMin, format: fmtPercent),
            ]),
            ("Body", [
                simple("Height", "m", s.height, format: fmtHeight),
                simple("Weight", "kg", s.bodyMass, format: fmtWeight),
                simple("BMI", "", s.bmi, format: { fmt1($0) }),
                avgMinMax("Wrist Temperature", "°C", avg: s.sleepingWristTempAvg, min: s.sleepingWristTempMin, max: s.sleepingWristTempMax, format: fmtTemp),
            ]),
            ("Mobility", [
                simple("Walking Speed", "m/s", s.walkingSpeed, format: { fmt2($0) + " m/s" }),
                simple("Walking Step Length", "m", s.walkingStepLength, format: { fmt2($0) + " m" }),
                simple("Walking Asymmetry", "%", s.walkingAsymmetry, format: fmtPercent),
                simple("Double Support Time", "%", s.walkingDoubleSupport, format: fmtPercent),
                simple("Stair Ascent Speed", "m/s", s.stairAscentSpeed, format: { fmt2($0) + " m/s" }),
                simple("Stair Descent Speed", "m/s", s.stairDescentSpeed, format: { fmt2($0) + " m/s" }),
                simple("Six-Minute Walk", "m", s.sixMinWalkDistance, format: fmtDistance),
            ]),
            ("Sleep", [
                simple("Total Sleep", "hours", s.sleepTotalHours, format: { fmt1($0) + " hrs" }),
                simple("In Bed", "hours", s.sleepInBedHours, format: { fmt1($0) + " hrs" }),
                simple("Awake", "hours", s.sleepAwakeHours, format: { fmt1($0) + " hrs" }),
                simple("Core", "hours", s.sleepCoreHours, format: { fmt1($0) + " hrs" }),
                simple("Deep", "hours", s.sleepDeepHours, format: { fmt1($0) + " hrs" }),
                simple("REM", "hours", s.sleepREMHours, format: { fmt1($0) + " hrs" }),
            ]),
            ("Events", [
                simpleInt("Stand Hours", "hours", s.standHoursCount),
                simple("Mindful Minutes", "min", s.mindfulMinutes, format: { fmtInt($0) + " min" }),
                simpleInt("High Heart Rate Events", "events", s.highHeartRateEvents),
                simpleInt("Low Heart Rate Events", "events", s.lowHeartRateEvents),
                simpleInt("Irregular Rhythm Events", "events", s.irregularRhythmEvents),
            ]),
        ]

        return categories.compactMap { (categoryName, extractors) in
            let metricData = extractors.compactMap { extractor -> MetricData? in
                guard let result = extractor.extract(summary) else { return nil }
                return MetricData(
                    name: extractor.name,
                    displayValue: result.displayValue,
                    unit: extractor.unit,
                    rawValue: result.rawValue,
                    rawMin: result.rawMin,
                    rawMax: result.rawMax,
                    trends: .placeholder
                )
            }
            guard !metricData.isEmpty else { return nil }
            return MetricCategoryData(category: categoryName, metrics: metricData)
        }
    }
}
