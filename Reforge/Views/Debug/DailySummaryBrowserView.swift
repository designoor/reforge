import SwiftUI
import SwiftData

struct DailySummaryBrowserView: View {

    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query(sort: \WorkoutSummary.date) private var allWorkouts: [WorkoutSummary]
    @Query private var profiles: [UserProfile]

    @State private var selectedDate: Date = DateHelpers.yesterday()

    // MARK: - Computed Properties

    private var profile: UserProfile? { profiles.first }

    private var unitPref: UnitPreference {
        UnitPreference(rawValue: profile?.unitPreference ?? "metric") ?? .metric
    }

    private var selectedSummary: DailySummary? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return dailySummaries.first {
            Calendar.current.isDate($0.date, inSameDayAs: normalized)
        }
    }

    private var selectedWorkouts: [WorkoutSummary] {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return allWorkouts.filter {
            Calendar.current.isDate($0.date, inSameDayAs: normalized)
        }
    }

    private var earliestDate: Date? { dailySummaries.first?.date }

    private var canGoBack: Bool {
        guard let earliest = earliestDate else { return false }
        return DateHelpers.startOfDay(for: selectedDate) > DateHelpers.startOfDay(for: earliest)
    }

    private var canGoForward: Bool {
        DateHelpers.startOfDay(for: selectedDate) < DateHelpers.yesterday()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            dateHeader
                .padding(.horizontal, 16)

            if let summary = selectedSummary {
                List {
                    activitySection(summary)
                    runningSection(summary)
                    cyclingSection(summary)
                    heartSection(summary)
                    respiratorySection(summary)
                    bodySection(summary)
                    mobilitySection(summary)
                    sleepSection(summary)
                    eventsSection(summary)
                    workoutsSection
                }
                .listStyle(.insetGrouped)
            } else {
                Spacer()
                noDataView
                Spacer()
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canGoBack ? Color.accentColor : Color(.systemGray3))
            }
            .disabled(!canGoBack)

            Spacer()

            Text(formattedDate)
                .font(.headline)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canGoForward ? Color.accentColor : Color(.systemGray3))
            }
            .disabled(!canGoForward)
        }
        .padding(.vertical, 8)
    }

    // MARK: - No Data

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemGray3))

            Text("No data for this date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sections

    private func activitySection(_ s: DailySummary) -> some View {
        Section("Activity & Fitness") {
            Group {
                metricRow("Steps", intValue: s.steps)
                metricRow("Walking + Running Distance", value: s.distanceWalkingRunning, format: fmtDistance)
                metricRow("Cycling Distance", value: s.distanceCycling, format: fmtDistance)
                metricRow("Swimming Distance", value: s.distanceSwimming, format: fmtDistance)
                metricRow("Resting Energy", value: s.basalEnergyBurned, format: fmtKcal)
                metricRow("Active Energy", value: s.activeEnergyBurned, format: fmtKcal)
                metricRow("Flights Climbed", intValue: s.flightsClimbed)
            }
            Group {
                metricRow("Exercise Time", value: s.appleExerciseTime, format: fmtMin)
                metricRow("Move Time", value: s.appleMoveTime, format: fmtMin)
                metricRow("Stand Time", value: s.appleStandTime, format: fmtMin)
                metricRow("Swimming Strokes", intValue: s.swimmingStrokeCount)
                metricRow("Physical Effort", value: s.physicalEffort, format: { fmt1($0) + " APE" })
                metricRow("VO2 Max", value: s.vo2Max, format: { fmt1($0) + " mL/kg/min" })
            }
        }
    }

    private func runningSection(_ s: DailySummary) -> some View {
        Section("Running") {
            metricRow("Running Speed", value: s.runningSpeed, format: fmtMps)
            metricRow("Running Power", value: s.runningPower, format: fmtWatt)
            metricRow("Stride Length", value: s.runningStrideLength, format: { fmt2($0) + " m" })
            metricRow("Vertical Oscillation", value: s.runningVerticalOscillation, format: { fmt1($0) + " cm" })
            metricRow("Ground Contact Time", value: s.runningGroundContactTime, format: fmtMs)
        }
    }

    private func cyclingSection(_ s: DailySummary) -> some View {
        Section("Cycling") {
            metricRow("Cycling Speed", value: s.cyclingSpeed, format: fmtMps)
            metricRow("Cycling Power", value: s.cyclingPower, format: fmtWatt)
            metricRow("Cycling FTP", value: s.cyclingFTP, format: fmtWatt)
            metricRow("Cycling Cadence", value: s.cyclingCadence, format: { fmtInt($0) + " rpm" })
        }
    }

    private func heartSection(_ s: DailySummary) -> some View {
        Section("Heart") {
            avgMinMaxRow("Heart Rate", avg: s.heartRateAvg, min: s.heartRateMin, max: s.heartRateMax, format: fmtBpm)
            metricRow("Resting Heart Rate", value: s.restingHeartRate, format: fmtBpm)
            metricRow("Walking Heart Rate", value: s.walkingHeartRateAvg, format: fmtBpm)
            metricRow("Heart Rate Variability", value: s.hrv, format: fmtMs)
            metricRow("Heart Rate Recovery", value: s.heartRateRecovery, format: fmtBpm)
            metricRow("AFib Burden", value: s.atrialFibrillationBurden, format: fmtPercent)
            metricRow("Perfusion Index", value: s.peripheralPerfusionIndex, format: fmtPercent)
        }
    }

    private func respiratorySection(_ s: DailySummary) -> some View {
        Section("Respiratory") {
            avgMinMaxRow("Respiratory Rate", avg: s.respiratoryRateAvg, min: s.respiratoryRateMin, max: s.respiratoryRateMax, format: { fmt1($0) + " brpm" })
            avgMinRow("Blood Oxygen", avg: s.oxygenSaturationAvg, min: s.oxygenSaturationMin, format: fmtPercent)
        }
    }

    private func bodySection(_ s: DailySummary) -> some View {
        Section("Body") {
            metricRow("Height", value: s.height, format: fmtHeight)
            metricRow("Weight", value: s.bodyMass, format: fmtWeight)
            metricRow("BMI", value: s.bmi, format: { fmt1($0) })
            avgMinMaxRow("Wrist Temperature", avg: s.sleepingWristTempAvg, min: s.sleepingWristTempMin, max: s.sleepingWristTempMax, format: fmtTemp)
        }
    }

    private func mobilitySection(_ s: DailySummary) -> some View {
        Section("Mobility") {
            metricRow("Walking Speed", value: s.walkingSpeed, format: fmtMps)
            metricRow("Walking Step Length", value: s.walkingStepLength, format: { fmt2($0) + " m" })
            metricRow("Walking Asymmetry", value: s.walkingAsymmetry, format: fmtPercent)
            metricRow("Double Support Time", value: s.walkingDoubleSupport, format: fmtPercent)
            metricRow("Stair Ascent Speed", value: s.stairAscentSpeed, format: fmtMps)
            metricRow("Stair Descent Speed", value: s.stairDescentSpeed, format: fmtMps)
            metricRow("Six-Minute Walk", value: s.sixMinWalkDistance, format: fmtDistance)
        }
    }

    private func sleepSection(_ s: DailySummary) -> some View {
        Section("Sleep") {
            metricRow("Total Sleep", value: s.sleepTotalHours, format: fmtHours)

            if s.sleepTotalHours != nil {
                sleepBreakdownBar(s)
            }

            metricRow("In Bed", value: s.sleepInBedHours, format: fmtHours)
            metricRow("Awake", value: s.sleepAwakeHours, format: fmtHours)
            metricRow("Core", value: s.sleepCoreHours, format: fmtHours)
            metricRow("Deep", value: s.sleepDeepHours, format: fmtHours)
            metricRow("REM", value: s.sleepREMHours, format: fmtHours)
        }
    }

    private func eventsSection(_ s: DailySummary) -> some View {
        Section("Events") {
            metricRow("Stand Hours", intValue: s.standHoursCount)
            metricRow("Mindful Minutes", value: s.mindfulMinutes, format: fmtMin)
            metricRow("High Heart Rate Events", intValue: s.highHeartRateEvents)
            metricRow("Low Heart Rate Events", intValue: s.lowHeartRateEvents)
            metricRow("Irregular Rhythm Events", intValue: s.irregularRhythmEvents)
        }
    }

    private var workoutsSection: some View {
        Section("Workouts") {
            if selectedWorkouts.isEmpty {
                Text("No workouts")
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(selectedWorkouts, id: \.startTime) { workout in
                    workoutRow(workout)
                }
            }
        }
    }

    // MARK: - Sleep Breakdown Bar

    @ViewBuilder
    private func sleepBreakdownBar(_ s: DailySummary) -> some View {
        let stages: [(label: String, hours: Double?, color: Color)] = [
            ("Awake", s.sleepAwakeHours, .orange),
            ("Core", s.sleepCoreHours, .cyan),
            ("Deep", s.sleepDeepHours, .blue),
            ("REM", s.sleepREMHours, .indigo),
        ]
        let total = stages.compactMap(\.hours).reduce(0, +)

        if total > 0 {
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    HStack(spacing: 1) {
                        ForEach(stages.indices, id: \.self) { i in
                            if let hours = stages[i].hours, hours > 0 {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(stages[i].color)
                                    .frame(width: geo.size.width * (hours / total))
                            }
                        }
                    }
                }
                .frame(height: 12)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                HStack(spacing: 12) {
                    ForEach(stages.indices, id: \.self) { i in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(stages[i].color)
                                .frame(width: 8, height: 8)
                            Text(stages[i].label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Workout Row

    private func workoutRow(_ w: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(w.workoutType.capitalized)
                .font(.body.weight(.medium))

            HStack(spacing: 16) {
                Label(fmtMin(w.duration), systemImage: "clock")

                if let energy = w.totalEnergyBurned {
                    Label(fmtKcal(energy), systemImage: "flame")
                }

                if let distance = w.totalDistance {
                    Label(fmtDistance(distance), systemImage: "figure.walk")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(w.startTime.formatted(date: .omitted, time: .shortened))
                Text("–")
                Text(w.endTime.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Row Helpers

    private func metricRow(
        _ label: String,
        value: Double?,
        format: (Double) -> String
    ) -> some View {
        LabeledContent(label) {
            if let value {
                Text(format(value))
                    .monospacedDigit()
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func metricRow(
        _ label: String,
        intValue: Int?,
        unit: String = ""
    ) -> some View {
        LabeledContent(label) {
            if let intValue {
                Text(unit.isEmpty ? "\(intValue)" : "\(intValue) \(unit)")
                    .monospacedDigit()
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func avgMinMaxRow(
        _ label: String,
        avg: Double?,
        min: Double?,
        max: Double?,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)

            HStack(spacing: 16) {
                statItem("Avg", value: avg, format: format)
                statItem("Min", value: min, format: format)
                statItem("Max", value: max, format: format)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func avgMinRow(
        _ label: String,
        avg: Double?,
        min: Double?,
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)

            HStack(spacing: 16) {
                statItem("Avg", value: avg, format: format)
                statItem("Min", value: min, format: format)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }

    private func statItem(
        _ label: String,
        value: Double?,
        format: (Double) -> String
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let value {
                Text(format(value))
                    .monospacedDigit()
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Formatters

    private func fmtInt(_ v: Double) -> String {
        String(format: "%.0f", v)
    }

    private func fmt1(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    private func fmt2(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    private func fmtDistance(_ meters: Double) -> String {
        UnitConverter.displayDistance(meters, unit: unitPref)
    }

    private func fmtWeight(_ kg: Double) -> String {
        UnitConverter.displayWeight(kg, unit: unitPref)
    }

    private func fmtHeight(_ m: Double) -> String {
        UnitConverter.displayHeight(m, unit: unitPref)
    }

    private func fmtTemp(_ celsius: Double) -> String {
        UnitConverter.displayTemperature(celsius, unit: unitPref)
    }

    private func fmtKcal(_ v: Double) -> String {
        fmtInt(v) + " kcal"
    }

    private func fmtMin(_ v: Double) -> String {
        fmtInt(v) + " min"
    }

    private func fmtBpm(_ v: Double) -> String {
        fmtInt(v) + " bpm"
    }

    private func fmtMs(_ v: Double) -> String {
        fmtInt(v) + " ms"
    }

    // HealthKit stores percentages as 0–1 fractions
    private func fmtPercent(_ v: Double) -> String {
        fmt1(v * 100) + "%"
    }

    private func fmtMps(_ v: Double) -> String {
        fmt2(v) + " m/s"
    }

    private func fmtWatt(_ v: Double) -> String {
        fmtInt(v) + " W"
    }

    private func fmtHours(_ v: Double) -> String {
        let h = Int(v)
        let m = Int((v - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}

#Preview {
    NavigationStack {
        DailySummaryBrowserView()
    }
    .modelContainer(for: [
        DailySummary.self,
        WorkoutSummary.self,
        UserProfile.self,
    ], inMemory: true)
}
