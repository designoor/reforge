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
}
