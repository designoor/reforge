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
        unitPref: UnitPreference,
        trendReport: TrendReport? = nil
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
        let categoryGroups = buildMetricCategories(summary: summary, unitPref: unitPref, trendReport: trendReport)

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
            trendsNote: trendReport != nil
                ? "Trends computed from stored daily summaries for \(dateFormatter.string(from: date))."
                : "Trend comparisons pending TrendCalculator (Phase 10). All trend values are null."
        )
    }

    // MARK: - Metric Extraction

    private struct MetricExtractor {
        let name: String
        let unit: String
        let metric: MetricDefinition?
        let extract: (DailySummary) -> (displayValue: String, rawValue: Double?, rawMin: Double?, rawMax: Double?)?
    }

    private static func buildMetricCategories(
        summary: DailySummary,
        unitPref: UnitPreference,
        trendReport: TrendReport? = nil
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
        func simple(_ name: String, _ unit: String, _ value: Double?, metric: MetricDefinition? = nil, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit, metric: metric) { _ in
                guard let v = value else { return nil }
                return (format(v), v, nil, nil)
            }
        }

        // Simple extractors for Int? properties
        func simpleInt(_ name: String, _ unit: String, _ value: Int?, metric: MetricDefinition? = nil) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit, metric: metric) { _ in
                guard let v = value else { return nil }
                return ("\(v)", Double(v), nil, nil)
            }
        }

        // Avg/Min/Max extractor
        func avgMinMax(_ name: String, _ unit: String, avg: Double?, min: Double?, max: Double?, metric: MetricDefinition? = nil, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit, metric: metric) { _ in
                guard let a = avg else { return nil }
                var display = format(a) + " avg"
                if let mn = min { display += " / " + format(mn) + " min" }
                if let mx = max { display += " / " + format(mx) + " max" }
                return (display, a, min, max)
            }
        }

        // Avg/Min extractor
        func avgMin(_ name: String, _ unit: String, avg: Double?, min: Double?, metric: MetricDefinition? = nil, format: @escaping (Double) -> String) -> MetricExtractor {
            MetricExtractor(name: name, unit: unit, metric: metric) { _ in
                guard let a = avg else { return nil }
                var display = format(a) + " avg"
                if let mn = min { display += " / " + format(mn) + " min" }
                return (display, a, min, nil)
            }
        }

        let s = summary

        let categories: [(String, [MetricExtractor])] = [
            ("Activity & Fitness", [
                simpleInt("Steps", "steps", s.steps, metric: .stepCount),
                simple("Walking + Running Distance", "m", s.distanceWalkingRunning, metric: .distanceWalkingRunning, format: fmtDistance),
                simple("Cycling Distance", "m", s.distanceCycling, metric: .distanceCycling, format: fmtDistance),
                simple("Swimming Distance", "m", s.distanceSwimming, metric: .distanceSwimming, format: fmtDistance),
                simple("Resting Energy", "kcal", s.basalEnergyBurned, metric: .basalEnergyBurned, format: { fmtInt($0) + " kcal" }),
                simple("Active Energy", "kcal", s.activeEnergyBurned, metric: .activeEnergyBurned, format: { fmtInt($0) + " kcal" }),
                simpleInt("Flights Climbed", "flights", s.flightsClimbed, metric: .flightsClimbed),
                simple("Exercise Time", "min", s.appleExerciseTime, metric: .appleExerciseTime, format: { fmtInt($0) + " min" }),
                simple("Move Time", "min", s.appleMoveTime, metric: .appleMoveTime, format: { fmtInt($0) + " min" }),
                simple("Stand Time", "min", s.appleStandTime, metric: .appleStandTime, format: { fmtInt($0) + " min" }),
                simpleInt("Swimming Strokes", "strokes", s.swimmingStrokeCount, metric: .swimmingStrokeCount),
                simple("Physical Effort", "APE", s.physicalEffort, metric: .physicalEffort, format: { fmt1($0) + " APE" }),
                simple("VO2 Max", "mL/kg/min", s.vo2Max, metric: .vo2Max, format: { fmt1($0) + " mL/kg/min" }),
            ]),
            ("Running", [
                simple("Running Speed", "m/s", s.runningSpeed, metric: .runningSpeed, format: { fmt2($0) + " m/s" }),
                simple("Running Power", "W", s.runningPower, metric: .runningPower, format: { fmtInt($0) + " W" }),
                simple("Stride Length", "m", s.runningStrideLength, metric: .runningStrideLength, format: { fmt2($0) + " m" }),
                simple("Vertical Oscillation", "cm", s.runningVerticalOscillation, metric: .runningVerticalOscillation, format: { fmt1($0) + " cm" }),
                simple("Ground Contact Time", "ms", s.runningGroundContactTime, metric: .runningGroundContactTime, format: { fmtInt($0) + " ms" }),
            ]),
            ("Cycling", [
                simple("Cycling Speed", "m/s", s.cyclingSpeed, metric: .cyclingSpeed, format: { fmt2($0) + " m/s" }),
                simple("Cycling Power", "W", s.cyclingPower, metric: .cyclingPower, format: { fmtInt($0) + " W" }),
                simple("Cycling FTP", "W", s.cyclingFTP, metric: .cyclingFunctionalThresholdPower, format: { fmtInt($0) + " W" }),
                simple("Cycling Cadence", "rpm", s.cyclingCadence, metric: .cyclingCadence, format: { fmtInt($0) + " rpm" }),
            ]),
            ("Heart", [
                avgMinMax("Heart Rate", "bpm", avg: s.heartRateAvg, min: s.heartRateMin, max: s.heartRateMax, metric: .heartRate, format: { fmtInt($0) + " bpm" }),
                simple("Resting Heart Rate", "bpm", s.restingHeartRate, metric: .restingHeartRate, format: { fmtInt($0) + " bpm" }),
                simple("Walking Heart Rate", "bpm", s.walkingHeartRateAvg, metric: .walkingHeartRateAverage, format: { fmtInt($0) + " bpm" }),
                simple("Heart Rate Variability", "ms", s.hrv, metric: .heartRateVariabilitySDNN, format: { fmtInt($0) + " ms" }),
                simple("Heart Rate Recovery", "bpm", s.heartRateRecovery, metric: .heartRateRecoveryOneMinute, format: { fmtInt($0) + " bpm" }),
                simple("AFib Burden", "%", s.atrialFibrillationBurden, metric: .atrialFibrillationBurden, format: fmtPercent),
                simple("Perfusion Index", "%", s.peripheralPerfusionIndex, metric: .peripheralPerfusionIndex, format: fmtPercent),
            ]),
            ("Respiratory", [
                avgMinMax("Respiratory Rate", "brpm", avg: s.respiratoryRateAvg, min: s.respiratoryRateMin, max: s.respiratoryRateMax, metric: .respiratoryRate, format: { fmt1($0) + " brpm" }),
                avgMin("Blood Oxygen", "%", avg: s.oxygenSaturationAvg, min: s.oxygenSaturationMin, metric: .oxygenSaturation, format: fmtPercent),
            ]),
            ("Body", [
                simple("Height", "m", s.height, metric: .height, format: fmtHeight),
                simple("Weight", "kg", s.bodyMass, metric: .bodyMass, format: fmtWeight),
                simple("BMI", "", s.bmi, metric: .bodyMassIndex, format: { fmt1($0) }),
                avgMinMax("Wrist Temperature", "°C", avg: s.sleepingWristTempAvg, min: s.sleepingWristTempMin, max: s.sleepingWristTempMax, metric: .appleSleepingWristTemperature, format: fmtTemp),
            ]),
            ("Mobility", [
                simple("Walking Speed", "m/s", s.walkingSpeed, metric: .walkingSpeed, format: { fmt2($0) + " m/s" }),
                simple("Walking Step Length", "m", s.walkingStepLength, metric: .walkingStepLength, format: { fmt2($0) + " m" }),
                simple("Walking Asymmetry", "%", s.walkingAsymmetry, metric: .walkingAsymmetryPercentage, format: fmtPercent),
                simple("Double Support Time", "%", s.walkingDoubleSupport, metric: .walkingDoubleSupportPercentage, format: fmtPercent),
                simple("Stair Ascent Speed", "m/s", s.stairAscentSpeed, metric: .stairAscentSpeed, format: { fmt2($0) + " m/s" }),
                simple("Stair Descent Speed", "m/s", s.stairDescentSpeed, metric: .stairDescentSpeed, format: { fmt2($0) + " m/s" }),
                simple("Six-Minute Walk", "m", s.sixMinWalkDistance, metric: .sixMinuteWalkTestDistance, format: fmtDistance),
            ]),
            ("Sleep", [
                simple("Total Sleep", "hours", s.sleepTotalHours, metric: .sleepAnalysis, format: { fmt1($0) + " hrs" }),
                simple("In Bed", "hours", s.sleepInBedHours, format: { fmt1($0) + " hrs" }),
                simple("Awake", "hours", s.sleepAwakeHours, format: { fmt1($0) + " hrs" }),
                simple("Core", "hours", s.sleepCoreHours, format: { fmt1($0) + " hrs" }),
                simple("Deep", "hours", s.sleepDeepHours, format: { fmt1($0) + " hrs" }),
                simple("REM", "hours", s.sleepREMHours, format: { fmt1($0) + " hrs" }),
            ]),
            ("Events", [
                simpleInt("Stand Hours", "hours", s.standHoursCount, metric: .appleStandHour),
                simple("Mindful Minutes", "min", s.mindfulMinutes, metric: .mindfulSession, format: { fmtInt($0) + " min" }),
                simpleInt("High Heart Rate Events", "events", s.highHeartRateEvents, metric: .highHeartRateEvent),
                simpleInt("Low Heart Rate Events", "events", s.lowHeartRateEvents, metric: .lowHeartRateEvent),
                simpleInt("Irregular Rhythm Events", "events", s.irregularRhythmEvents, metric: .irregularHeartRhythmEvent),
            ]),
        ]

        func resolveTrends(for definition: MetricDefinition?) -> MetricTrends {
            guard let definition, let report = trendReport,
                  let trend = report.trends[definition] else {
                return .placeholder
            }
            return MetricTrends(
                dayOfWeekMedian: trend.dayOfWeekMedian,
                thisWeek: trend.thisWeek,
                lastWeek: trend.lastWeek,
                weekMedian: trend.weekMedian,
                thisMonth: trend.thisMonth,
                lastMonth: trend.lastMonth,
                monthMedian: trend.monthMedian
            )
        }

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
                    trends: resolveTrends(for: extractor.metric)
                )
            }
            guard !metricData.isEmpty else { return nil }
            return MetricCategoryData(category: categoryName, metrics: metricData)
        }
    }
}
