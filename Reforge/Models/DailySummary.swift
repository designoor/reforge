import Foundation
import SwiftData

@Model
final class DailySummary {
    #Unique<DailySummary>([\.date])

    // MARK: - Identity

    var date: Date
    var dayOfWeek: Int

    // MARK: - Activity

    var steps: Int?
    var distanceWalkingRunning: Double?
    var distanceCycling: Double?
    var distanceSwimming: Double?
    var basalEnergyBurned: Double?
    var activeEnergyBurned: Double?
    var flightsClimbed: Int?
    var appleExerciseTime: Double?
    var appleMoveTime: Double?
    var appleStandTime: Double?
    var swimmingStrokeCount: Int?
    var physicalEffort: Double?
    var vo2Max: Double?

    // MARK: - Running

    var runningSpeed: Double?
    var runningPower: Double?
    var runningStrideLength: Double?
    var runningVerticalOscillation: Double?
    var runningGroundContactTime: Double?

    // MARK: - Cycling

    var cyclingSpeed: Double?
    var cyclingPower: Double?
    var cyclingFTP: Double?
    var cyclingCadence: Double?

    // MARK: - Heart

    var heartRateAvg: Double?
    var heartRateMin: Double?
    var heartRateMax: Double?
    var restingHeartRate: Double?
    var walkingHeartRateAvg: Double?
    var hrv: Double?
    var heartRateRecovery: Double?
    var atrialFibrillationBurden: Double?
    var peripheralPerfusionIndex: Double?

    // MARK: - Respiratory

    var respiratoryRateAvg: Double?
    var respiratoryRateMin: Double?
    var respiratoryRateMax: Double?
    var oxygenSaturationAvg: Double?
    var oxygenSaturationMin: Double?

    // MARK: - Body

    var height: Double?
    var bodyMass: Double?
    var bmi: Double?
    var sleepingWristTempAvg: Double?
    var sleepingWristTempMin: Double?
    var sleepingWristTempMax: Double?

    // MARK: - Mobility

    var walkingSpeed: Double?
    var walkingStepLength: Double?
    var walkingAsymmetry: Double?
    var walkingDoubleSupport: Double?
    var stairAscentSpeed: Double?
    var stairDescentSpeed: Double?
    var sixMinWalkDistance: Double?

    // MARK: - Sleep

    var sleepTotalHours: Double?
    var sleepInBedHours: Double?
    var sleepAwakeHours: Double?
    var sleepCoreHours: Double?
    var sleepDeepHours: Double?
    var sleepREMHours: Double?

    // MARK: - Events

    var standHoursCount: Int?
    var mindfulMinutes: Double?
    var highHeartRateEvents: Int?
    var lowHeartRateEvents: Int?
    var irregularRhythmEvents: Int?

    // MARK: - Metadata

    var createdAt: Date
    var updatedAt: Date

    // MARK: - Initializer

    init(
        date: Date,
        steps: Int? = nil,
        distanceWalkingRunning: Double? = nil,
        distanceCycling: Double? = nil,
        distanceSwimming: Double? = nil,
        basalEnergyBurned: Double? = nil,
        activeEnergyBurned: Double? = nil,
        flightsClimbed: Int? = nil,
        appleExerciseTime: Double? = nil,
        appleMoveTime: Double? = nil,
        appleStandTime: Double? = nil,
        swimmingStrokeCount: Int? = nil,
        physicalEffort: Double? = nil,
        vo2Max: Double? = nil,
        runningSpeed: Double? = nil,
        runningPower: Double? = nil,
        runningStrideLength: Double? = nil,
        runningVerticalOscillation: Double? = nil,
        runningGroundContactTime: Double? = nil,
        cyclingSpeed: Double? = nil,
        cyclingPower: Double? = nil,
        cyclingFTP: Double? = nil,
        cyclingCadence: Double? = nil,
        heartRateAvg: Double? = nil,
        heartRateMin: Double? = nil,
        heartRateMax: Double? = nil,
        restingHeartRate: Double? = nil,
        walkingHeartRateAvg: Double? = nil,
        hrv: Double? = nil,
        heartRateRecovery: Double? = nil,
        atrialFibrillationBurden: Double? = nil,
        peripheralPerfusionIndex: Double? = nil,
        respiratoryRateAvg: Double? = nil,
        respiratoryRateMin: Double? = nil,
        respiratoryRateMax: Double? = nil,
        oxygenSaturationAvg: Double? = nil,
        oxygenSaturationMin: Double? = nil,
        height: Double? = nil,
        bodyMass: Double? = nil,
        bmi: Double? = nil,
        sleepingWristTempAvg: Double? = nil,
        sleepingWristTempMin: Double? = nil,
        sleepingWristTempMax: Double? = nil,
        walkingSpeed: Double? = nil,
        walkingStepLength: Double? = nil,
        walkingAsymmetry: Double? = nil,
        walkingDoubleSupport: Double? = nil,
        stairAscentSpeed: Double? = nil,
        stairDescentSpeed: Double? = nil,
        sixMinWalkDistance: Double? = nil,
        sleepTotalHours: Double? = nil,
        sleepInBedHours: Double? = nil,
        sleepAwakeHours: Double? = nil,
        sleepCoreHours: Double? = nil,
        sleepDeepHours: Double? = nil,
        sleepREMHours: Double? = nil,
        standHoursCount: Int? = nil,
        mindfulMinutes: Double? = nil,
        highHeartRateEvents: Int? = nil,
        lowHeartRateEvents: Int? = nil,
        irregularRhythmEvents: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let normalized = Calendar.current.startOfDay(for: date)
        self.date = normalized
        self.dayOfWeek = Calendar.current.component(.weekday, from: normalized)
        self.steps = steps
        self.distanceWalkingRunning = distanceWalkingRunning
        self.distanceCycling = distanceCycling
        self.distanceSwimming = distanceSwimming
        self.basalEnergyBurned = basalEnergyBurned
        self.activeEnergyBurned = activeEnergyBurned
        self.flightsClimbed = flightsClimbed
        self.appleExerciseTime = appleExerciseTime
        self.appleMoveTime = appleMoveTime
        self.appleStandTime = appleStandTime
        self.swimmingStrokeCount = swimmingStrokeCount
        self.physicalEffort = physicalEffort
        self.vo2Max = vo2Max
        self.runningSpeed = runningSpeed
        self.runningPower = runningPower
        self.runningStrideLength = runningStrideLength
        self.runningVerticalOscillation = runningVerticalOscillation
        self.runningGroundContactTime = runningGroundContactTime
        self.cyclingSpeed = cyclingSpeed
        self.cyclingPower = cyclingPower
        self.cyclingFTP = cyclingFTP
        self.cyclingCadence = cyclingCadence
        self.heartRateAvg = heartRateAvg
        self.heartRateMin = heartRateMin
        self.heartRateMax = heartRateMax
        self.restingHeartRate = restingHeartRate
        self.walkingHeartRateAvg = walkingHeartRateAvg
        self.hrv = hrv
        self.heartRateRecovery = heartRateRecovery
        self.atrialFibrillationBurden = atrialFibrillationBurden
        self.peripheralPerfusionIndex = peripheralPerfusionIndex
        self.respiratoryRateAvg = respiratoryRateAvg
        self.respiratoryRateMin = respiratoryRateMin
        self.respiratoryRateMax = respiratoryRateMax
        self.oxygenSaturationAvg = oxygenSaturationAvg
        self.oxygenSaturationMin = oxygenSaturationMin
        self.height = height
        self.bodyMass = bodyMass
        self.bmi = bmi
        self.sleepingWristTempAvg = sleepingWristTempAvg
        self.sleepingWristTempMin = sleepingWristTempMin
        self.sleepingWristTempMax = sleepingWristTempMax
        self.walkingSpeed = walkingSpeed
        self.walkingStepLength = walkingStepLength
        self.walkingAsymmetry = walkingAsymmetry
        self.walkingDoubleSupport = walkingDoubleSupport
        self.stairAscentSpeed = stairAscentSpeed
        self.stairDescentSpeed = stairDescentSpeed
        self.sixMinWalkDistance = sixMinWalkDistance
        self.sleepTotalHours = sleepTotalHours
        self.sleepInBedHours = sleepInBedHours
        self.sleepAwakeHours = sleepAwakeHours
        self.sleepCoreHours = sleepCoreHours
        self.sleepDeepHours = sleepDeepHours
        self.sleepREMHours = sleepREMHours
        self.standHoursCount = standHoursCount
        self.mindfulMinutes = mindfulMinutes
        self.highHeartRateEvents = highHeartRateEvents
        self.lowHeartRateEvents = lowHeartRateEvents
        self.irregularRhythmEvents = irregularRhythmEvents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
