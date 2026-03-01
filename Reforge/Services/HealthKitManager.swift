import HealthKit

enum HealthKitManager {
    typealias SleepBreakdown = (
        total: Double, inBed: Double, awake: Double,
        core: Double, deep: Double, rem: Double
    )

    private static let healthStore = HKHealthStore()

    static func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    static func requestAuthorization() async throws {
        let readTypes: Set<HKObjectType> = Set(
            MetricDefinition.allSampleTypes.compactMap { $0 as? HKObjectType }
        )
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    static func getDateOfBirth() throws -> Date? {
        let components = try healthStore.dateOfBirthComponents()
        return Calendar.current.date(from: components)
    }

    static func getBiologicalSex() throws -> HKBiologicalSex? {
        let biologicalSex = try healthStore.biologicalSex().biologicalSex
        return biologicalSex == .notSet ? nil : biologicalSex
    }

    static func getEarliestSampleDate() async throws -> Date? {
        guard isAvailable() else { return nil }

        let sampleType = HKQuantityType(.stepCount)
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.first?.startDate)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Quantity Queries

    private static func fetchStatistics(
        for identifier: HKQuantityTypeIdentifier,
        options: HKStatisticsOptions,
        start: Date,
        end: Date
    ) async throws -> HKStatistics? {
        let quantityType = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
    }

    static func querySum(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        let statistics = try await fetchStatistics(
            for: identifier,
            options: .cumulativeSum,
            start: start,
            end: end
        )
        return statistics?.sumQuantity()?.doubleValue(for: unit)
    }

    static func queryAvg(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> Double? {
        let statistics = try await fetchStatistics(
            for: identifier,
            options: .discreteAverage,
            start: start,
            end: end
        )
        return statistics?.averageQuantity()?.doubleValue(for: unit)
    }

    static func queryMinMaxAvg(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) async throws -> (avg: Double?, min: Double?, max: Double?) {
        let statistics = try await fetchStatistics(
            for: identifier,
            options: [.discreteAverage, .discreteMin, .discreteMax],
            start: start,
            end: end
        )
        return (
            avg: statistics?.averageQuantity()?.doubleValue(for: unit),
            min: statistics?.minimumQuantity()?.doubleValue(for: unit),
            max: statistics?.maximumQuantity()?.doubleValue(for: unit)
        )
    }

    static func queryMostRecent(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        before: Date
    ) async throws -> Double? {
        let quantityType = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(
            withStart: .distantPast,
            end: before,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Category Queries

    private static func fetchCategorySamples(
        for identifier: HKCategoryTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> [HKCategorySample] {
        let categoryType = HKCategoryType(identifier)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: categoryType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let categorySamples = (samples as? [HKCategorySample]) ?? []
                continuation.resume(returning: categorySamples)
            }
            healthStore.execute(query)
        }
    }

    private static func mergeIntervals(
        _ intervals: [(start: Date, end: Date)]
    ) -> [(start: Date, end: Date)] {
        guard var current = intervals.first else { return [] }
        var merged: [(start: Date, end: Date)] = []

        for interval in intervals.dropFirst() {
            if interval.start <= current.end {
                current.end = max(current.end, interval.end)
            } else {
                merged.append(current)
                current = interval
            }
        }
        merged.append(current)
        return merged
    }

    static func querySleepAnalysis(
        start: Date,
        end: Date
    ) async throws -> SleepBreakdown? {
        let samples = try await fetchCategorySamples(
            for: .sleepAnalysis, start: start, end: end
        )
        guard !samples.isEmpty else { return nil }

        var grouped: [Int: [(start: Date, end: Date)]] = [:]
        for sample in samples {
            grouped[sample.value, default: []].append(
                (start: sample.startDate, end: sample.endDate)
            )
        }

        func hours(for value: HKCategoryValueSleepAnalysis) -> Double {
            guard let intervals = grouped[value.rawValue] else { return 0 }
            let merged = mergeIntervals(intervals)
            let seconds = merged.reduce(0.0) {
                $0 + $1.end.timeIntervalSince($1.start)
            }
            return seconds / 3600
        }

        let inBed = hours(for: .inBed)
        let awake = hours(for: .awake)
        let core = hours(for: .asleepCore)
        let deep = hours(for: .asleepDeep)
        let rem = hours(for: .asleepREM)
        let unspecified = hours(for: .asleepUnspecified)
        let total = core + deep + rem + unspecified

        return (total: total, inBed: inBed, awake: awake,
                core: core, deep: deep, rem: rem)
    }

    static func queryCategoryCount(
        for identifier: HKCategoryTypeIdentifier,
        start: Date,
        end: Date
    ) async throws -> Int {
        let samples = try await fetchCategorySamples(
            for: identifier, start: start, end: end
        )
        if identifier == .appleStandHour {
            return samples.filter {
                $0.value == HKCategoryValueAppleStandHour.stood.rawValue
            }.count
        }
        return samples.count
    }

    static func queryMindfulMinutes(
        start: Date,
        end: Date
    ) async throws -> Double? {
        let samples = try await fetchCategorySamples(
            for: .mindfulSession, start: start, end: end
        )
        guard !samples.isEmpty else { return nil }
        let seconds = samples.reduce(0.0) {
            $0 + $1.endDate.timeIntervalSince($1.startDate)
        }
        return seconds / 60
    }

    // MARK: - Workout Queries

    private static func fetchWorkouts(
        start: Date,
        end: Date
    ) async throws -> [HKWorkout] {
        let workoutType = HKWorkoutType.workoutType()
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    private static func readableWorkoutType(
        _ activityType: HKWorkoutActivityType
    ) -> String {
        switch activityType {
        case .running: "Running"
        case .cycling: "Cycling"
        case .walking: "Walking"
        case .swimming: "Swimming"
        case .hiking: "Hiking"
        case .yoga: "Yoga"
        case .functionalStrengthTraining: "Strength Training"
        case .highIntensityIntervalTraining: "HIIT"
        case .dance: "Dance"
        case .cooldown: "Cooldown"
        case .coreTraining: "Core Training"
        case .elliptical: "Elliptical"
        case .rowing: "Rowing"
        case .stairClimbing: "Stair Climbing"
        case .pilates: "Pilates"
        case .tennis: "Tennis"
        case .basketball: "Basketball"
        case .soccer: "Soccer"
        default: "Workout"
        }
    }

    static func queryWorkouts(
        start: Date,
        end: Date
    ) async throws -> [WorkoutSummary] {
        let workouts = try await fetchWorkouts(start: start, end: end)
        return workouts.map { workout in
            WorkoutSummary(
                date: workout.startDate,
                workoutType: readableWorkoutType(workout.workoutActivityType),
                duration: workout.duration,
                totalEnergyBurned: workout.totalEnergyBurned?
                    .doubleValue(for: .kilocalorie()),
                totalDistance: workout.totalDistance?
                    .doubleValue(for: .meter()),
                startTime: workout.startDate,
                endTime: workout.endDate
            )
        }
    }
}
