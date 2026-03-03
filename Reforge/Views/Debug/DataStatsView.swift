import SwiftUI
import SwiftData

struct DataStatsView: View {

    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query(sort: \WorkoutSummary.date) private var allWorkouts: [WorkoutSummary]
    @Query(sort: \HealthInsight.date) private var healthInsights: [HealthInsight]
    @Environment(\.modelContext) private var modelContext

    @State private var backfillPhase: BackfillPhase = .idle
    @State private var showDeleteConfirmation = false

    // MARK: - Computed Properties

    private var totalDaysStored: Int { dailySummaries.count }

    private var earliestDate: Date? { dailySummaries.first?.date }

    private var latestDate: Date? { dailySummaries.last?.date }

    private var dateRangeSpan: Int? {
        guard let earliest = earliestDate, let latest = latestDate else { return nil }
        return Calendar.current.dateComponents([.day], from: earliest, to: latest).day.map { $0 + 1 }
    }

    private var coveragePercentage: Double? {
        guard let span = dateRangeSpan, span > 0 else { return nil }
        return Double(totalDaysStored) / Double(span) * 100
    }

    private var metricCoverage: [MetricDefinition: Int] {
        var counts: [MetricDefinition: Int] = [:]
        for metric in MetricDefinition.allCases {
            guard let checker = metric.dailySummaryChecker else { continue }
            counts[metric] = dailySummaries.filter(checker).count
        }
        return counts
    }

    private var metricsByCategory: [(category: MetricCategory, metrics: [MetricDefinition])] {
        let grouped = Dictionary(grouping: MetricDefinition.allCases.filter { $0 != .workout }) {
            $0.category
        }
        return MetricCategory.allCases.compactMap { cat in
            guard let metrics = grouped[cat], !metrics.isEmpty else { return nil }
            return (category: cat, metrics: metrics)
        }
    }

    private var estimatedStorageSize: String {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            return estimateFallbackSize()
        }

        let storePath = appSupport.appendingPathComponent("default.store").path
        var totalBytes: Int64 = 0

        for suffix in ["", "-wal", "-shm"] {
            let path = storePath + suffix
            if let attrs = try? fileManager.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                totalBytes += size
            }
        }

        if totalBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        }
        return estimateFallbackSize()
    }

    // MARK: - Body

    var body: some View {
        if dailySummaries.isEmpty && allWorkouts.isEmpty {
            emptyStateView
        } else {
            List {
                overviewSection
                ForEach(metricsByCategory, id: \.category) { group in
                    coverageSection(category: group.category, metrics: group.metrics)
                }
                storageSection
                actionsSection
            }
            .listStyle(.insetGrouped)
            .confirmationDialog(
                "Delete All Health Data?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Data", role: .destructive) {
                    deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all daily summaries, workouts, and health insights. Your profile will be preserved. This cannot be undone.")
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemGray3))

            Text("No data stored yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                startBackfill()
            } label: {
                Label("Run Backfill", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 4)

            if case .running(let processed, let total) = backfillPhase {
                VStack(spacing: 8) {
                    ProgressView(value: Double(processed), total: Double(max(total, 1)))
                        .tint(Color.accentColor)
                    Text("\(processed) of \(total) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 48)
            }

            if case .error(let message) = backfillPhase {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        Section("Overview") {
            LabeledContent("Total Days Stored") {
                Text("\(totalDaysStored)")
                    .monospacedDigit()
            }

            LabeledContent("Date Range") {
                Text(formattedDateRange)
            }

            if let span = dateRangeSpan, let pct = coveragePercentage {
                LabeledContent("Coverage") {
                    Text("\(totalDaysStored)/\(span) days (\(formatPercentage(pct)))")
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Coverage Section

    private func coverageSection(
        category: MetricCategory,
        metrics: [MetricDefinition]
    ) -> some View {
        Section(category.displayName) {
            ForEach(metrics, id: \.self) { metric in
                LabeledContent(metric.displayName) {
                    Text(coverageText(for: metric))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Storage Section

    private var storageSection: some View {
        Section("Storage") {
            LabeledContent("Total Workouts") {
                Text("\(allWorkouts.count)")
                    .monospacedDigit()
            }
            LabeledContent("Health Insights") {
                Text("\(healthInsights.count)")
                    .monospacedDigit()
            }
            LabeledContent("Estimated Size") {
                Text(estimatedStorageSize)
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section("Actions") {
            backfillRow
            deleteRow
        }
    }

    @ViewBuilder
    private var backfillRow: some View {
        switch backfillPhase {
        case .idle:
            Button {
                startBackfill()
            } label: {
                Label("Re-run Backfill", systemImage: "arrow.clockwise")
            }

        case .running(let processed, let total):
            VStack(alignment: .leading, spacing: 8) {
                Label("Backfilling\u{2026}", systemImage: "arrow.clockwise")
                ProgressView(value: Double(processed), total: Double(max(total, 1)))
                    .tint(Color.accentColor)
                Text("\(processed) of \(total) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 4)

        case .complete(let count):
            Label("Backfill complete (\(count) days checked)", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)

        case .error(let message):
            VStack(alignment: .leading, spacing: 6) {
                Label("Backfill failed", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Retry") { startBackfill() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.vertical, 4)
        }
    }

    private var deleteRow: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Label("Delete All Data", systemImage: "trash")
        }
    }

    // MARK: - Formatters

    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        guard let earliest = earliestDate, let latest = latestDate else {
            return "No data"
        }
        return "\(formatter.string(from: earliest)) \u{2192} \(formatter.string(from: latest))"
    }

    private func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    private func coverageText(for metric: MetricDefinition) -> String {
        let count = metricCoverage[metric] ?? 0
        let total = totalDaysStored
        guard total > 0 else { return "0/0 days" }
        let pct = Double(count) / Double(total) * 100
        return "\(count)/\(total) (\(formatPercentage(pct)))"
    }

    private func estimateFallbackSize() -> String {
        let estimated = dailySummaries.count * 500 + allWorkouts.count * 200 + healthInsights.count * 300
        if estimated == 0 { return "0 bytes" }
        return ByteCountFormatter.string(fromByteCount: Int64(estimated), countStyle: .file)
    }

    // MARK: - Logic

    private func startBackfill() {
        backfillPhase = .running(daysProcessed: 0, totalDays: 0)

        Task {
            do {
                let startDate: Date
                if let earliest = dailySummaries.first?.date {
                    startDate = earliest
                } else if let hkEarliest = try await HealthKitManager.getEarliestSampleDate() {
                    startDate = DateHelpers.startOfDay(for: hkEarliest)
                } else {
                    backfillPhase = .complete(daysProcessed: 0)
                    return
                }

                let endDate = DateHelpers.yesterday()
                guard startDate <= endDate else {
                    backfillPhase = .complete(daysProcessed: 0)
                    return
                }

                let totalDays = Calendar.current.dateComponents(
                    [.day], from: startDate, to: endDate
                ).day.map { $0 + 1 } ?? 0

                try await HealthDataAggregator.backfillHistory(
                    from: startDate,
                    to: endDate,
                    context: modelContext
                ) { daysProcessed, total in
                    Task { @MainActor in
                        backfillPhase = .running(daysProcessed: daysProcessed, totalDays: total)
                    }
                }

                backfillPhase = .complete(daysProcessed: totalDays)
            } catch {
                backfillPhase = .error(error.localizedDescription)
            }
        }
    }

    private func deleteAllData() {
        for summary in dailySummaries {
            modelContext.delete(summary)
        }
        for workout in allWorkouts {
            modelContext.delete(workout)
        }
        for insight in healthInsights {
            modelContext.delete(insight)
        }

        try? modelContext.save()
        backfillPhase = .idle
    }

    // MARK: - Types

    private enum BackfillPhase {
        case idle
        case running(daysProcessed: Int, totalDays: Int)
        case complete(daysProcessed: Int)
        case error(String)
    }
}

// MARK: - MetricDefinition Coverage Checker

private extension MetricDefinition {

    /// Returns a closure that checks whether a DailySummary has non-nil data for this metric.
    /// Returns nil for `.workout` since workouts are stored separately.
    var dailySummaryChecker: ((DailySummary) -> Bool)? {
        switch self {
        // Activity
        case .stepCount:                        return { $0.steps != nil }
        case .distanceWalkingRunning:           return { $0.distanceWalkingRunning != nil }
        case .distanceCycling:                  return { $0.distanceCycling != nil }
        case .distanceSwimming:                 return { $0.distanceSwimming != nil }
        case .basalEnergyBurned:                return { $0.basalEnergyBurned != nil }
        case .activeEnergyBurned:               return { $0.activeEnergyBurned != nil }
        case .flightsClimbed:                   return { $0.flightsClimbed != nil }
        case .appleExerciseTime:                return { $0.appleExerciseTime != nil }
        case .appleMoveTime:                    return { $0.appleMoveTime != nil }
        case .appleStandTime:                   return { $0.appleStandTime != nil }
        case .swimmingStrokeCount:              return { $0.swimmingStrokeCount != nil }
        case .physicalEffort:                   return { $0.physicalEffort != nil }
        case .vo2Max:                           return { $0.vo2Max != nil }

        // Running
        case .runningSpeed:                     return { $0.runningSpeed != nil }
        case .runningPower:                     return { $0.runningPower != nil }
        case .runningStrideLength:              return { $0.runningStrideLength != nil }
        case .runningVerticalOscillation:       return { $0.runningVerticalOscillation != nil }
        case .runningGroundContactTime:         return { $0.runningGroundContactTime != nil }

        // Cycling
        case .cyclingSpeed:                     return { $0.cyclingSpeed != nil }
        case .cyclingPower:                     return { $0.cyclingPower != nil }
        case .cyclingFunctionalThresholdPower:  return { $0.cyclingFTP != nil }
        case .cyclingCadence:                   return { $0.cyclingCadence != nil }

        // Heart
        case .heartRate:                        return { $0.heartRateAvg != nil }
        case .restingHeartRate:                 return { $0.restingHeartRate != nil }
        case .walkingHeartRateAverage:          return { $0.walkingHeartRateAvg != nil }
        case .heartRateVariabilitySDNN:         return { $0.hrv != nil }
        case .heartRateRecoveryOneMinute:       return { $0.heartRateRecovery != nil }
        case .atrialFibrillationBurden:         return { $0.atrialFibrillationBurden != nil }
        case .peripheralPerfusionIndex:         return { $0.peripheralPerfusionIndex != nil }

        // Respiratory
        case .respiratoryRate:                  return { $0.respiratoryRateAvg != nil }
        case .oxygenSaturation:                 return { $0.oxygenSaturationAvg != nil }

        // Body
        case .height:                           return { $0.height != nil }
        case .bodyMass:                         return { $0.bodyMass != nil }
        case .bodyMassIndex:                    return { $0.bmi != nil }
        case .appleSleepingWristTemperature:    return { $0.sleepingWristTempAvg != nil }

        // Mobility
        case .walkingSpeed:                     return { $0.walkingSpeed != nil }
        case .walkingStepLength:                return { $0.walkingStepLength != nil }
        case .walkingAsymmetryPercentage:       return { $0.walkingAsymmetry != nil }
        case .walkingDoubleSupportPercentage:   return { $0.walkingDoubleSupport != nil }
        case .stairAscentSpeed:                 return { $0.stairAscentSpeed != nil }
        case .stairDescentSpeed:                return { $0.stairDescentSpeed != nil }
        case .sixMinuteWalkTestDistance:         return { $0.sixMinWalkDistance != nil }

        // Sleep & Events
        case .sleepAnalysis:                    return { $0.sleepTotalHours != nil }
        case .appleStandHour:                   return { $0.standHoursCount != nil }
        case .mindfulSession:                   return { $0.mindfulMinutes != nil }
        case .highHeartRateEvent:               return { $0.highHeartRateEvents != nil }
        case .lowHeartRateEvent:                return { $0.lowHeartRateEvents != nil }
        case .irregularHeartRhythmEvent:        return { $0.irregularRhythmEvents != nil }

        // Workout — not in DailySummary
        case .workout:                          return nil
        }
    }
}

#Preview {
    NavigationStack {
        DataStatsView()
    }
    .modelContainer(for: [
        DailySummary.self,
        WorkoutSummary.self,
        HealthInsight.self,
    ], inMemory: true)
}
