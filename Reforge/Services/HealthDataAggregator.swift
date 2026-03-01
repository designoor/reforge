import Foundation
import HealthKit
import SwiftData

enum HealthDataAggregator {

    // MARK: - Error Resilience

    private static func safeQuery<T>(_ block: () async throws -> T?) async -> T? {
        do {
            return try await block()
        } catch {
            return nil
        }
    }

    // MARK: - Aggregate Day

    /// Creates a fully populated DailySummary for the given date by querying HealthKit
    /// for every metric. Individual metric failures are silently ignored (the property
    /// remains nil) so that one unavailable metric does not block the rest.
    static func aggregateDay(date: Date) async throws -> DailySummary {
        let (start, end) = DateHelpers.dateRange(for: date)
        let summary = DailySummary(date: date)

        // --- Activity (sum) ---

        summary.steps = await safeQuery {
            try await HealthKitManager.querySum(
                for: .stepCount, unit: .count(), start: start, end: end
            ).map { Int($0) }
        }
        summary.distanceWalkingRunning = await safeQuery {
            try await HealthKitManager.querySum(
                for: .distanceWalkingRunning, unit: .meter(), start: start, end: end
            )
        }
        summary.distanceCycling = await safeQuery {
            try await HealthKitManager.querySum(
                for: .distanceCycling, unit: .meter(), start: start, end: end
            )
        }
        summary.distanceSwimming = await safeQuery {
            try await HealthKitManager.querySum(
                for: .distanceSwimming, unit: .meter(), start: start, end: end
            )
        }
        summary.basalEnergyBurned = await safeQuery {
            try await HealthKitManager.querySum(
                for: .basalEnergyBurned, unit: .kilocalorie(), start: start, end: end
            )
        }
        summary.activeEnergyBurned = await safeQuery {
            try await HealthKitManager.querySum(
                for: .activeEnergyBurned, unit: .kilocalorie(), start: start, end: end
            )
        }
        summary.flightsClimbed = await safeQuery {
            try await HealthKitManager.querySum(
                for: .flightsClimbed, unit: .count(), start: start, end: end
            ).map { Int($0) }
        }
        summary.appleExerciseTime = await safeQuery {
            try await HealthKitManager.querySum(
                for: .appleExerciseTime, unit: .minute(), start: start, end: end
            )
        }
        summary.appleMoveTime = await safeQuery {
            try await HealthKitManager.querySum(
                for: .appleMoveTime, unit: .minute(), start: start, end: end
            )
        }
        summary.appleStandTime = await safeQuery {
            try await HealthKitManager.querySum(
                for: .appleStandTime, unit: .minute(), start: start, end: end
            )
        }
        summary.swimmingStrokeCount = await safeQuery {
            try await HealthKitManager.querySum(
                for: .swimmingStrokeCount, unit: .count(), start: start, end: end
            ).map { Int($0) }
        }

        // --- Activity (avg) ---

        summary.physicalEffort = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .physicalEffort,
                unit: HKUnit.kilocalorie()
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .hour())),
                start: start, end: end
            )
        }
        summary.vo2Max = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .vo2Max,
                unit: HKUnit.literUnit(with: .milli)
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute())),
                start: start, end: end
            )
        }

        // --- Running (avg) ---

        summary.runningSpeed = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .runningSpeed,
                unit: HKUnit.meter().unitDivided(by: .second()),
                start: start, end: end
            )
        }
        summary.runningPower = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .runningPower, unit: .watt(), start: start, end: end
            )
        }
        summary.runningStrideLength = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .runningStrideLength, unit: .meter(), start: start, end: end
            )
        }
        summary.runningVerticalOscillation = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .runningVerticalOscillation, unit: .meterUnit(with: .centi),
                start: start, end: end
            )
        }
        summary.runningGroundContactTime = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .runningGroundContactTime, unit: .secondUnit(with: .milli),
                start: start, end: end
            )
        }

        // --- Cycling (avg) ---

        summary.cyclingSpeed = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .cyclingSpeed,
                unit: HKUnit.meter().unitDivided(by: .second()),
                start: start, end: end
            )
        }
        summary.cyclingPower = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .cyclingPower, unit: .watt(), start: start, end: end
            )
        }
        summary.cyclingFTP = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .cyclingFunctionalThresholdPower, unit: .watt(),
                start: start, end: end
            )
        }
        summary.cyclingCadence = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .cyclingCadence,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }

        // --- Heart (avg) ---

        summary.restingHeartRate = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .restingHeartRate,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }
        summary.walkingHeartRateAvg = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .walkingHeartRateAverage,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }
        summary.hrv = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .heartRateVariabilitySDNN, unit: .secondUnit(with: .milli),
                start: start, end: end
            )
        }
        summary.heartRateRecovery = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .heartRateRecoveryOneMinute,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }
        summary.atrialFibrillationBurden = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .atrialFibrillationBurden, unit: .percent(),
                start: start, end: end
            )
        }
        summary.peripheralPerfusionIndex = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .peripheralPerfusionIndex, unit: .percent(),
                start: start, end: end
            )
        }

        // --- Heart (avgMinMax) ---

        let heartRateResult = await safeQuery {
            try await HealthKitManager.queryMinMaxAvg(
                for: .heartRate,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }
        summary.heartRateAvg = heartRateResult?.avg
        summary.heartRateMin = heartRateResult?.min
        summary.heartRateMax = heartRateResult?.max

        // --- Respiratory (avgMinMax) ---

        let respResult = await safeQuery {
            try await HealthKitManager.queryMinMaxAvg(
                for: .respiratoryRate,
                unit: HKUnit.count().unitDivided(by: .minute()),
                start: start, end: end
            )
        }
        summary.respiratoryRateAvg = respResult?.avg
        summary.respiratoryRateMin = respResult?.min
        summary.respiratoryRateMax = respResult?.max

        // --- Oxygen Saturation (avgMin via queryMinMaxAvg, max ignored) ---

        let o2Result = await safeQuery {
            try await HealthKitManager.queryMinMaxAvg(
                for: .oxygenSaturation, unit: .percent(),
                start: start, end: end
            )
        }
        summary.oxygenSaturationAvg = o2Result?.avg
        summary.oxygenSaturationMin = o2Result?.min

        // --- Body (mostRecent) ---

        summary.height = await safeQuery {
            try await HealthKitManager.queryMostRecent(
                for: .height, unit: .meter(), before: end
            )
        }
        summary.bodyMass = await safeQuery {
            try await HealthKitManager.queryMostRecent(
                for: .bodyMass, unit: .gramUnit(with: .kilo), before: end
            )
        }
        summary.bmi = await safeQuery {
            try await HealthKitManager.queryMostRecent(
                for: .bodyMassIndex, unit: .count(), before: end
            )
        }

        // --- Body (avgMinMax) ---

        let wristTempResult = await safeQuery {
            try await HealthKitManager.queryMinMaxAvg(
                for: .appleSleepingWristTemperature, unit: .degreeCelsius(),
                start: start, end: end
            )
        }
        summary.sleepingWristTempAvg = wristTempResult?.avg
        summary.sleepingWristTempMin = wristTempResult?.min
        summary.sleepingWristTempMax = wristTempResult?.max

        // --- Mobility (avg) ---

        summary.walkingSpeed = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .walkingSpeed,
                unit: HKUnit.meter().unitDivided(by: .second()),
                start: start, end: end
            )
        }
        summary.walkingStepLength = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .walkingStepLength, unit: .meter(), start: start, end: end
            )
        }
        summary.walkingAsymmetry = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .walkingAsymmetryPercentage, unit: .percent(),
                start: start, end: end
            )
        }
        summary.walkingDoubleSupport = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .walkingDoubleSupportPercentage, unit: .percent(),
                start: start, end: end
            )
        }
        summary.stairAscentSpeed = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .stairAscentSpeed,
                unit: HKUnit.meter().unitDivided(by: .second()),
                start: start, end: end
            )
        }
        summary.stairDescentSpeed = await safeQuery {
            try await HealthKitManager.queryAvg(
                for: .stairDescentSpeed,
                unit: HKUnit.meter().unitDivided(by: .second()),
                start: start, end: end
            )
        }

        // --- Mobility (mostRecent) ---

        summary.sixMinWalkDistance = await safeQuery {
            try await HealthKitManager.queryMostRecent(
                for: .sixMinuteWalkTestDistance, unit: .meter(), before: end
            )
        }

        // --- Sleep ---

        let sleep = await safeQuery {
            try await HealthKitManager.querySleepAnalysis(start: start, end: end)
        }
        summary.sleepTotalHours = sleep?.total
        summary.sleepInBedHours = sleep?.inBed
        summary.sleepAwakeHours = sleep?.awake
        summary.sleepCoreHours = sleep?.core
        summary.sleepDeepHours = sleep?.deep
        summary.sleepREMHours = sleep?.rem

        // --- Category Counts ---

        summary.standHoursCount = await safeQuery {
            try await HealthKitManager.queryCategoryCount(
                for: .appleStandHour, start: start, end: end
            )
        }
        summary.mindfulMinutes = await safeQuery {
            try await HealthKitManager.queryMindfulMinutes(start: start, end: end)
        }
        summary.highHeartRateEvents = await safeQuery {
            try await HealthKitManager.queryCategoryCount(
                for: .highHeartRateEvent, start: start, end: end
            )
        }
        summary.lowHeartRateEvents = await safeQuery {
            try await HealthKitManager.queryCategoryCount(
                for: .lowHeartRateEvent, start: start, end: end
            )
        }
        summary.irregularRhythmEvents = await safeQuery {
            try await HealthKitManager.queryCategoryCount(
                for: .irregularHeartRhythmEvent, start: start, end: end
            )
        }

        return summary
    }

    // MARK: - Backfill History

    /// Backfills historical data from startDate to endDate (inclusive).
    /// Creates one DailySummary per day (with real HealthKit data), skipping days that already exist.
    /// Also saves WorkoutSummary objects for each day.
    /// Reports progress via callback: (daysProcessed, totalDays).
    static func backfillHistory(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext,
        progress: @escaping (Int, Int) -> Void
    ) async throws {
        let calendar = Calendar.current
        let start = DateHelpers.startOfDay(for: startDate)
        let end = DateHelpers.startOfDay(for: endDate)

        guard let totalDays = calendar.dateComponents(
            [.day], from: start, to: end
        ).day.map({ $0 + 1 }), totalDays > 0 else {
            return
        }

        var currentDate = start
        var daysProcessed = 0

        while currentDate <= end {
            let targetDate = currentDate
            let descriptor = FetchDescriptor<DailySummary>(
                predicate: #Predicate<DailySummary> { $0.date == targetDate }
            )

            if try context.fetchCount(descriptor) == 0 {
                let summary = try await aggregateDay(date: currentDate)
                context.insert(summary)

                let (dayStart, dayEnd) = DateHelpers.dateRange(for: currentDate)
                let workouts = (try? await HealthKitManager.queryWorkouts(
                    start: dayStart, end: dayEnd
                )) ?? []
                for workout in workouts {
                    context.insert(workout)
                }
            }

            daysProcessed += 1
            progress(daysProcessed, totalDays)

            await Task.yield()

            if daysProcessed % 50 == 0 {
                try context.save()
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        try context.save()
    }
}
