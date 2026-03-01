import HealthKit

enum HealthKitManager {
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
}
