import HealthKit

// MARK: - Supporting Types

enum MetricAggregation: String, CaseIterable, Codable {
    case sum
    case avg
    case mostRecent
    case avgMinMax
    case avgMin
}

enum MetricCategory: String, CaseIterable, Codable {
    case activity
    case running
    case cycling
    case heart
    case respiratory
    case body
    case mobility
    case sleep
    case events
    case workout
}

enum MetricKind {
    case quantity
    case category
    case workout
}

// MARK: - MetricDefinition

enum MetricDefinition: String, CaseIterable, Codable {

    // Activity & Fitness (13)
    case stepCount
    case distanceWalkingRunning
    case distanceCycling
    case distanceSwimming
    case basalEnergyBurned
    case activeEnergyBurned
    case flightsClimbed
    case appleExerciseTime
    case appleMoveTime
    case appleStandTime
    case swimmingStrokeCount
    case physicalEffort
    case vo2Max

    // Running (5)
    case runningSpeed
    case runningPower
    case runningStrideLength
    case runningVerticalOscillation
    case runningGroundContactTime

    // Cycling (4)
    case cyclingSpeed
    case cyclingPower
    case cyclingFunctionalThresholdPower
    case cyclingCadence

    // Heart (7)
    case heartRate
    case restingHeartRate
    case walkingHeartRateAverage
    case heartRateVariabilitySDNN
    case heartRateRecoveryOneMinute
    case atrialFibrillationBurden
    case peripheralPerfusionIndex

    // Respiratory (2)
    case respiratoryRate
    case oxygenSaturation

    // Body (4)
    case height
    case bodyMass
    case bodyMassIndex
    case appleSleepingWristTemperature

    // Mobility (7)
    case walkingSpeed
    case walkingStepLength
    case walkingAsymmetryPercentage
    case walkingDoubleSupportPercentage
    case stairAscentSpeed
    case stairDescentSpeed
    case sixMinuteWalkTestDistance

    // Sleep & Mindfulness (3)
    case sleepAnalysis
    case appleStandHour
    case mindfulSession

    // Heart Events (3)
    case highHeartRateEvent
    case lowHeartRateEvent
    case irregularHeartRhythmEvent

    // Workout (1)
    case workout
}

// MARK: - Computed Properties

extension MetricDefinition {

    var displayName: String {
        switch self {
        case .stepCount: "Steps"
        case .distanceWalkingRunning: "Walking + Running Distance"
        case .distanceCycling: "Cycling Distance"
        case .distanceSwimming: "Swimming Distance"
        case .basalEnergyBurned: "Resting Energy"
        case .activeEnergyBurned: "Active Energy"
        case .flightsClimbed: "Flights Climbed"
        case .appleExerciseTime: "Exercise Time"
        case .appleMoveTime: "Move Time"
        case .appleStandTime: "Stand Time"
        case .swimmingStrokeCount: "Swimming Strokes"
        case .physicalEffort: "Physical Effort"
        case .vo2Max: "VO2 Max"
        case .runningSpeed: "Running Speed"
        case .runningPower: "Running Power"
        case .runningStrideLength: "Running Stride Length"
        case .runningVerticalOscillation: "Running Vertical Oscillation"
        case .runningGroundContactTime: "Ground Contact Time"
        case .cyclingSpeed: "Cycling Speed"
        case .cyclingPower: "Cycling Power"
        case .cyclingFunctionalThresholdPower: "Cycling FTP"
        case .cyclingCadence: "Cycling Cadence"
        case .heartRate: "Heart Rate"
        case .restingHeartRate: "Resting Heart Rate"
        case .walkingHeartRateAverage: "Walking Heart Rate"
        case .heartRateVariabilitySDNN: "Heart Rate Variability"
        case .heartRateRecoveryOneMinute: "Heart Rate Recovery"
        case .atrialFibrillationBurden: "AFib Burden"
        case .peripheralPerfusionIndex: "Perfusion Index"
        case .respiratoryRate: "Respiratory Rate"
        case .oxygenSaturation: "Blood Oxygen"
        case .height: "Height"
        case .bodyMass: "Weight"
        case .bodyMassIndex: "BMI"
        case .appleSleepingWristTemperature: "Wrist Temperature"
        case .walkingSpeed: "Walking Speed"
        case .walkingStepLength: "Walking Step Length"
        case .walkingAsymmetryPercentage: "Walking Asymmetry"
        case .walkingDoubleSupportPercentage: "Double Support Time"
        case .stairAscentSpeed: "Stair Ascent Speed"
        case .stairDescentSpeed: "Stair Descent Speed"
        case .sixMinuteWalkTestDistance: "Six-Minute Walk"
        case .sleepAnalysis: "Sleep"
        case .appleStandHour: "Stand Hours"
        case .mindfulSession: "Mindful Minutes"
        case .highHeartRateEvent: "High Heart Rate Events"
        case .lowHeartRateEvent: "Low Heart Rate Events"
        case .irregularHeartRhythmEvent: "Irregular Rhythm Events"
        case .workout: "Workouts"
        }
    }

    var unit: HKUnit? {
        switch self {
        // Activity — counts & distances
        case .stepCount, .flightsClimbed, .swimmingStrokeCount:
            .count()
        case .distanceWalkingRunning, .distanceCycling, .distanceSwimming:
            .meter()
        case .basalEnergyBurned, .activeEnergyBurned:
            .kilocalorie()
        case .appleExerciseTime, .appleMoveTime, .appleStandTime:
            .minute()
        case .physicalEffort:
            HKUnit.kilocalorie()
                .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .hour()))
        case .vo2Max:
            HKUnit.literUnit(with: .milli)
                .unitDivided(by: HKUnit.gramUnit(with: .kilo).unitMultiplied(by: .minute()))

        // Running
        case .runningSpeed:
            HKUnit.meter().unitDivided(by: .second())
        case .runningPower:
            .watt()
        case .runningStrideLength:
            .meter()
        case .runningVerticalOscillation:
            .meterUnit(with: .centi)
        case .runningGroundContactTime:
            .secondUnit(with: .milli)

        // Cycling
        case .cyclingSpeed:
            HKUnit.meter().unitDivided(by: .second())
        case .cyclingPower:
            .watt()
        case .cyclingFunctionalThresholdPower:
            .watt()
        case .cyclingCadence:
            HKUnit.count().unitDivided(by: .minute())

        // Heart
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage,
             .heartRateRecoveryOneMinute:
            HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariabilitySDNN:
            .secondUnit(with: .milli)
        case .atrialFibrillationBurden, .peripheralPerfusionIndex:
            .percent()

        // Respiratory
        case .respiratoryRate:
            HKUnit.count().unitDivided(by: .minute())
        case .oxygenSaturation:
            .percent()

        // Body
        case .height:
            .meter()
        case .bodyMass:
            .gramUnit(with: .kilo)
        case .bodyMassIndex:
            .count()
        case .appleSleepingWristTemperature:
            .degreeCelsius()

        // Mobility
        case .walkingSpeed, .stairAscentSpeed, .stairDescentSpeed:
            HKUnit.meter().unitDivided(by: .second())
        case .walkingStepLength:
            .meter()
        case .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage:
            .percent()
        case .sixMinuteWalkTestDistance:
            .meter()

        // Category & Workout — no HKUnit
        case .sleepAnalysis, .appleStandHour, .mindfulSession,
             .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent,
             .workout:
            nil
        }
    }

    var aggregation: MetricAggregation {
        switch self {
        case .stepCount, .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
             .basalEnergyBurned, .activeEnergyBurned, .flightsClimbed,
             .appleExerciseTime, .appleMoveTime, .appleStandTime,
             .swimmingStrokeCount:
            .sum

        case .physicalEffort, .vo2Max,
             .runningSpeed, .runningPower, .runningStrideLength,
             .runningVerticalOscillation, .runningGroundContactTime,
             .cyclingSpeed, .cyclingPower, .cyclingFunctionalThresholdPower, .cyclingCadence,
             .restingHeartRate, .walkingHeartRateAverage,
             .heartRateRecoveryOneMinute,
             .atrialFibrillationBurden, .peripheralPerfusionIndex,
             .walkingSpeed, .walkingStepLength,
             .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage,
             .stairAscentSpeed, .stairDescentSpeed,
             .heartRateVariabilitySDNN:
            .avg

        case .heartRate, .appleSleepingWristTemperature:
            .avgMinMax

        case .respiratoryRate:
            .avgMinMax

        case .oxygenSaturation:
            .avgMin

        case .height, .bodyMass, .bodyMassIndex, .sixMinuteWalkTestDistance:
            .mostRecent

        case .sleepAnalysis, .appleStandHour, .mindfulSession,
             .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent,
             .workout:
            .sum
        }
    }

    var category: MetricCategory {
        switch self {
        case .stepCount, .distanceWalkingRunning, .distanceCycling, .distanceSwimming,
             .basalEnergyBurned, .activeEnergyBurned, .flightsClimbed,
             .appleExerciseTime, .appleMoveTime, .appleStandTime,
             .swimmingStrokeCount, .physicalEffort, .vo2Max:
            .activity

        case .runningSpeed, .runningPower, .runningStrideLength,
             .runningVerticalOscillation, .runningGroundContactTime:
            .running

        case .cyclingSpeed, .cyclingPower, .cyclingFunctionalThresholdPower, .cyclingCadence:
            .cycling

        case .heartRate, .restingHeartRate, .walkingHeartRateAverage,
             .heartRateVariabilitySDNN, .heartRateRecoveryOneMinute,
             .atrialFibrillationBurden, .peripheralPerfusionIndex:
            .heart

        case .respiratoryRate, .oxygenSaturation:
            .respiratory

        case .height, .bodyMass, .bodyMassIndex, .appleSleepingWristTemperature:
            .body

        case .walkingSpeed, .walkingStepLength, .walkingAsymmetryPercentage,
             .walkingDoubleSupportPercentage, .stairAscentSpeed, .stairDescentSpeed,
             .sixMinuteWalkTestDistance:
            .mobility

        case .sleepAnalysis, .mindfulSession:
            .sleep

        case .appleStandHour:
            .activity

        case .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent:
            .events

        case .workout:
            .workout
        }
    }

    var kind: MetricKind {
        switch self {
        case .sleepAnalysis, .appleStandHour, .mindfulSession,
             .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent:
            .category
        case .workout:
            .workout
        default:
            .quantity
        }
    }

    var sampleType: HKSampleType {
        switch kind {
        case .quantity:
            HKQuantityType(hkQuantityIdentifier)
        case .category:
            HKCategoryType(hkCategoryIdentifier)
        case .workout:
            HKWorkoutType.workoutType()
        }
    }

    /// All HKSampleTypes needed for HealthKit authorization.
    static var allSampleTypes: Set<HKSampleType> {
        Set(allCases.map(\.sampleType))
    }
}

// MARK: - HealthKit Identifiers

extension MetricDefinition {

    var hkQuantityIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .stepCount: .stepCount
        case .distanceWalkingRunning: .distanceWalkingRunning
        case .distanceCycling: .distanceCycling
        case .distanceSwimming: .distanceSwimming
        case .basalEnergyBurned: .basalEnergyBurned
        case .activeEnergyBurned: .activeEnergyBurned
        case .flightsClimbed: .flightsClimbed
        case .appleExerciseTime: .appleExerciseTime
        case .appleMoveTime: .appleMoveTime
        case .appleStandTime: .appleStandTime
        case .swimmingStrokeCount: .swimmingStrokeCount
        case .physicalEffort: .physicalEffort
        case .vo2Max: .vo2Max
        case .runningSpeed: .runningSpeed
        case .runningPower: .runningPower
        case .runningStrideLength: .runningStrideLength
        case .runningVerticalOscillation: .runningVerticalOscillation
        case .runningGroundContactTime: .runningGroundContactTime
        case .cyclingSpeed: .cyclingSpeed
        case .cyclingPower: .cyclingPower
        case .cyclingFunctionalThresholdPower: .cyclingFunctionalThresholdPower
        case .cyclingCadence: .cyclingCadence
        case .heartRate: .heartRate
        case .restingHeartRate: .restingHeartRate
        case .walkingHeartRateAverage: .walkingHeartRateAverage
        case .heartRateVariabilitySDNN: .heartRateVariabilitySDNN
        case .heartRateRecoveryOneMinute: .heartRateRecoveryOneMinute
        case .atrialFibrillationBurden: .atrialFibrillationBurden
        case .peripheralPerfusionIndex: .peripheralPerfusionIndex
        case .respiratoryRate: .respiratoryRate
        case .oxygenSaturation: .oxygenSaturation
        case .height: .height
        case .bodyMass: .bodyMass
        case .bodyMassIndex: .bodyMassIndex
        case .appleSleepingWristTemperature: .appleSleepingWristTemperature
        case .walkingSpeed: .walkingSpeed
        case .walkingStepLength: .walkingStepLength
        case .walkingAsymmetryPercentage: .walkingAsymmetryPercentage
        case .walkingDoubleSupportPercentage: .walkingDoubleSupportPercentage
        case .stairAscentSpeed: .stairAscentSpeed
        case .stairDescentSpeed: .stairDescentSpeed
        case .sixMinuteWalkTestDistance: .sixMinuteWalkTestDistance
        default:
            fatalError("\(self) is not a quantity type")
        }
    }

    var hkCategoryIdentifier: HKCategoryTypeIdentifier {
        switch self {
        case .sleepAnalysis: .sleepAnalysis
        case .appleStandHour: .appleStandHour
        case .mindfulSession: .mindfulSession
        case .highHeartRateEvent: .highHeartRateEvent
        case .lowHeartRateEvent: .lowHeartRateEvent
        case .irregularHeartRhythmEvent: .irregularHeartRhythmEvent
        default:
            fatalError("\(self) is not a category type")
        }
    }
}
