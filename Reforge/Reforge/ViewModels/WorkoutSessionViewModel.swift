import Foundation
import SwiftData
import UIKit

// MARK: - Supporting Types

struct SetLogEntry {
    let exerciseId: UUID
    let exerciseName: String
    let setNumber: Int
    let targetReps: String
    let actualReps: Int
    let completedAt: Date
}

struct SessionSummary {
    let duration: TimeInterval
    let exercisesCompleted: Int
    let totalSets: Int
    let totalReps: Int
    let personalBests: [PersonalBest]
}

struct PersonalBest: Identifiable {
    let id = UUID()
    let exerciseName: String
    let reps: Int
    let previousBest: Int?
}

// MARK: - ViewModel

@Observable
@MainActor
class WorkoutSessionViewModel {

    // MARK: - Properties

    let workoutDay: WorkoutDay
    let exercises: [Exercise]

    var currentExerciseIndex: Int = 0
    var currentSetNumber: Int = 1
    var selectedReps: Int = 10

    var isResting: Bool = false
    var restTimeRemaining: Int = 0
    private var restTimer: Timer?

    var sessionStartTime: Date?
    var setLogs: [SetLogEntry] = []
    var isComplete: Bool = false
    var showSummary: Bool = false
    var summary: SessionSummary?

    var showEndWorkoutConfirmation: Bool = false
    var difficultyRating: Int?

    // Persisted session reference for rating update
    private var persistedSessionId: UUID?

    // MARK: - Computed Properties

    var currentExercise: Exercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }

    var completedSets: Int {
        setLogs.count
    }

    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }

    var isLastSetOfSession: Bool {
        guard let exercise = currentExercise else { return false }
        let isLastExercise = currentExerciseIndex == exercises.count - 1
        let isLastSet = currentSetNumber == exercise.sets
        return isLastExercise && isLastSet
    }

    var isTimeBased: Bool {
        guard let exercise = currentExercise else { return false }
        return Self.isTimeBased(exercise.targetReps)
    }

    // MARK: - Init

    init(workoutDay: WorkoutDay) {
        self.workoutDay = workoutDay
        self.exercises = workoutDay.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    // MARK: - Static Helpers

    static func parseDefaultReps(from target: String) -> Int {
        let trimmed = target.trimmingCharacters(in: .whitespaces).lowercased()

        // Time-based: "30s" → 1
        if isTimeBased(trimmed) {
            return 1
        }

        // "each side" variant: "10 each side" → 10
        if trimmed.contains("each") {
            let parts = trimmed.components(separatedBy: " ")
            if let num = Int(parts[0]) { return num }
        }

        // Range: "8-12" → upper bound
        if trimmed.contains("-") {
            let parts = trimmed.components(separatedBy: "-")
            if let upper = Int(parts.last ?? "") { return upper }
        }

        // Plain number
        if let num = Int(trimmed) { return num }

        return 10
    }

    static func isTimeBased(_ target: String) -> Bool {
        let trimmed = target.trimmingCharacters(in: .whitespaces).lowercased()
        guard trimmed.hasSuffix("s") else { return false }
        let prefix = String(trimmed.dropLast())
        return Int(prefix) != nil
    }

    // MARK: - Session Control

    func startSession() {
        sessionStartTime = Date()
        if let first = exercises.first {
            selectedReps = Self.parseDefaultReps(from: first.targetReps)
        }
    }

    func logSet(context: ModelContext) {
        guard let exercise = currentExercise else { return }

        let entry = SetLogEntry(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            setNumber: currentSetNumber,
            targetReps: exercise.targetReps,
            actualReps: selectedReps,
            completedAt: Date()
        )
        setLogs.append(entry)

        if isLastSetOfSession {
            completeSession(context: context)
        } else if currentSetNumber >= exercise.sets {
            // Last set of this exercise — advance to next
            currentExerciseIndex += 1
            currentSetNumber = 1
            if let next = currentExercise {
                selectedReps = Self.parseDefaultReps(from: next.targetReps)
            }
            startRestTimer(seconds: exercise.restSeconds)
        } else {
            // More sets of same exercise
            currentSetNumber += 1
            startRestTimer(seconds: exercise.restSeconds)
        }
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        restTimeRemaining = seconds
        isResting = true
        restTimer?.invalidate()

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                self.restTimeRemaining -= 1
                if self.restTimeRemaining <= 0 {
                    self.finishRest()
                    // Haptic on finish
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
        }
    }

    func skipRest() {
        finishRest()
    }

    func finishRest() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
        restTimeRemaining = 0
    }

    // MARK: - Session Completion

    func completeSession(context: ModelContext) {
        guard !isComplete else { return }

        let duration = Date().timeIntervalSince(sessionStartTime ?? Date())
        let personalBests = detectPersonalBests(context: context)

        // Unique exercises completed
        let uniqueExercises = Set(setLogs.map { $0.exerciseId }).count
        let totalReps = setLogs.reduce(0) { $0 + $1.actualReps }

        summary = SessionSummary(
            duration: duration,
            exercisesCompleted: uniqueExercises,
            totalSets: setLogs.count,
            totalReps: totalReps,
            personalBests: personalBests
        )

        // Persist WorkoutSession
        let session = WorkoutSession(
            workoutDayId: workoutDay.id,
            durationSeconds: Int(duration),
            completed: true
        )
        context.insert(session)

        // Persist SetLogs
        for entry in setLogs {
            let log = SetLog(
                exerciseName: entry.exerciseName,
                exerciseId: entry.exerciseId,
                setNumber: entry.setNumber,
                targetReps: entry.targetReps,
                actualReps: entry.actualReps,
                completedAt: entry.completedAt
            )
            log.workoutSession = session
            context.insert(log)
        }

        // Update streak
        StreakService.updateStreak(context: context)

        try? context.save()

        persistedSessionId = session.id
        isComplete = true
        showSummary = true

        // Clean up timer
        finishRest()
    }

    func endWorkoutEarly(context: ModelContext) {
        if setLogs.isEmpty {
            // No sets logged — just dismiss
            isComplete = true
        } else {
            completeSession(context: context)
        }
    }

    // MARK: - Difficulty Rating

    func setDifficultyRating(_ rating: Int, context: ModelContext) {
        difficultyRating = rating
        guard let sessionId = persistedSessionId else { return }

        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { $0.id == sessionId }
        )
        if let session = try? context.fetch(descriptor).first {
            session.difficultyRating = rating
            try? context.save()
        }
    }

    // MARK: - Personal Bests

    func detectPersonalBests(context: ModelContext) -> [PersonalBest] {
        // Group current session logs by exercise
        var bestByExercise: [UUID: (name: String, reps: Int)] = [:]
        for entry in setLogs {
            if let existing = bestByExercise[entry.exerciseId] {
                if entry.actualReps > existing.reps {
                    bestByExercise[entry.exerciseId] = (entry.exerciseName, entry.actualReps)
                }
            } else {
                bestByExercise[entry.exerciseId] = (entry.exerciseName, entry.actualReps)
            }
        }

        var personalBests: [PersonalBest] = []

        for (exerciseId, current) in bestByExercise {
            // Query historical max for this exercise
            let descriptor = FetchDescriptor<SetLog>(
                predicate: #Predicate<SetLog> { $0.exerciseId == exerciseId }
            )
            let historicalLogs = (try? context.fetch(descriptor)) ?? []
            let previousMax = historicalLogs.map(\.actualReps).max()

            if let prevMax = previousMax {
                if current.reps > prevMax {
                    personalBests.append(PersonalBest(
                        exerciseName: current.name,
                        reps: current.reps,
                        previousBest: prevMax
                    ))
                }
            } else {
                // First time doing this exercise — it's a PB
                personalBests.append(PersonalBest(
                    exerciseName: current.name,
                    reps: current.reps,
                    previousBest: nil
                ))
            }
        }

        return personalBests.sorted { $0.exerciseName < $1.exerciseName }
    }
}
