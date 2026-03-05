import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query private var healthInsights: [HealthInsight]
    @Query(sort: \WorkoutSummary.date) private var allWorkouts: [WorkoutSummary]
    @Query private var profiles: [UserProfile]

    @State private var selectedDate: Date = DateHelpers.startOfDay(for: Date())
    @State private var showDatePicker = false
    @State private var swipeOffset: CGFloat = 0

    private var selectedSummary: DailySummary? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return dailySummaries.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var selectedInsight: HealthInsight? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return healthInsights.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var selectedWorkouts: [WorkoutSummary] {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return allWorkouts.filter { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var unitPref: UnitPreference {
        UnitPreference(rawValue: profiles.first?.unitPreference ?? "metric") ?? .metric
    }

    private var earliestDate: Date? {
        dailySummaries.first?.date
    }

    private var canGoBack: Bool {
        guard let earliest = earliestDate else { return false }
        return DateHelpers.startOfDay(for: selectedDate) > DateHelpers.startOfDay(for: earliest)
    }

    private var canGoForward: Bool {
        let today = DateHelpers.startOfDay(for: Date())
        return DateHelpers.startOfDay(for: selectedDate) < today
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private var storedDates: Set<Date> {
        Set(dailySummaries.map { DateHelpers.startOfDay(for: $0.date) })
    }

    private var datePickerRange: ClosedRange<Date> {
        let earliest = earliestDate ?? DateHelpers.startOfDay(for: Date())
        return DateHelpers.startOfDay(for: earliest)...DateHelpers.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    dateHeader

                    if selectedSummary == nil {
                        noDataView
                    } else if selectedInsight == nil {
                        emptyStateView
                    }

                    overallScoreSection
                    suggestionsSection
                    dataSummarySection
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .offset(x: swipeOffset)
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onChanged { value in
                        // Only allow horizontal swipe when it makes sense
                        let canSwipeRight = canGoBack // swipe right = go to previous day
                        let canSwipeLeft = canGoForward // swipe left = go to next day

                        if value.translation.width > 0 && canSwipeRight {
                            swipeOffset = value.translation.width * 0.3
                        } else if value.translation.width < 0 && canSwipeLeft {
                            swipeOffset = value.translation.width * 0.3
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold && canGoBack {
                            navigateDay(by: -1)
                        } else if value.translation.width < -threshold && canGoForward {
                            navigateDay(by: 1)
                        }
                        withAnimation(.easeOut(duration: 0.2)) {
                            swipeOffset = 0
                        }
                    }
            )
            .refreshable {
                guard !appState.isSyncing else { return }
                appState.isSyncing = true
                defer { appState.isSyncing = false }
                let context = ModelContext(modelContext.container)
                _ = try? await DailyDataService.collectToday(context: context)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
        }
    }

    private func navigateDay(by offset: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)!
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Button {
                navigateDay(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(canGoBack ? Color.accentColor : Color(.systemGray3))
            }
            .disabled(!canGoBack)

            Spacer()

            VStack(spacing: 4) {
                Button {
                    showDatePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if appState.isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)

                        Text("Syncing health data…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else if selectedSummary != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)

                        Text("Data collected")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button {
                navigateDay(by: 1)
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

            Text("No data recorded for this date.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemGray3))

            Text("No insights yet")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Your first daily analysis will appear here tomorrow morning.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Overall Score

    private var overallScoreSection: some View {
        VStack(spacing: 12) {
            Text("Overall Score")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Text("—")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(spacing: 12) {
            Text("Suggestions")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("AI suggestions will appear here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Data Summary

    @ViewBuilder
    private var dataSummarySection: some View {
        if let summary = selectedSummary {
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
    }

    // MARK: - Category Sections

    @ViewBuilder
    private func activitySection(_ s: DailySummary) -> some View {
        let hasData = s.steps != nil || s.distanceWalkingRunning != nil || s.distanceCycling != nil
            || s.distanceSwimming != nil || s.basalEnergyBurned != nil || s.activeEnergyBurned != nil
            || s.flightsClimbed != nil || s.appleExerciseTime != nil || s.appleMoveTime != nil
            || s.appleStandTime != nil || s.swimmingStrokeCount != nil || s.physicalEffort != nil
            || s.vo2Max != nil
        if hasData {
            categoryCard("Activity & Fitness") {
                metricRow("Steps", intValue: s.steps)
                metricRow("Walking + Running", value: s.distanceWalkingRunning, format: fmtDistance)
                metricRow("Cycling Distance", value: s.distanceCycling, format: fmtDistance)
                metricRow("Swimming Distance", value: s.distanceSwimming, format: fmtDistance)
                metricRow("Resting Energy", value: s.basalEnergyBurned, format: fmtKcal)
                metricRow("Active Energy", value: s.activeEnergyBurned, format: fmtKcal)
                metricRow("Flights Climbed", intValue: s.flightsClimbed)
                metricRow("Exercise Time", value: s.appleExerciseTime, format: fmtMin)
                metricRow("Move Time", value: s.appleMoveTime, format: fmtMin)
                metricRow("Stand Time", value: s.appleStandTime, format: fmtMin)
                metricRow("Swimming Strokes", intValue: s.swimmingStrokeCount)
                metricRow("Physical Effort", value: s.physicalEffort, format: { fmt1($0) + " APE" })
                metricRow("VO2 Max", value: s.vo2Max, format: { fmt1($0) + " mL/kg/min" })
            }
        }
    }

    @ViewBuilder
    private func runningSection(_ s: DailySummary) -> some View {
        let hasData = s.runningSpeed != nil || s.runningPower != nil || s.runningStrideLength != nil
            || s.runningVerticalOscillation != nil || s.runningGroundContactTime != nil
        if hasData {
            categoryCard("Running") {
                metricRow("Speed", value: s.runningSpeed, format: fmtMps)
                metricRow("Power", value: s.runningPower, format: fmtWatt)
                metricRow("Stride Length", value: s.runningStrideLength, format: { fmt2($0) + " m" })
                metricRow("Vertical Oscillation", value: s.runningVerticalOscillation, format: { fmt1($0) + " cm" })
                metricRow("Ground Contact Time", value: s.runningGroundContactTime, format: fmtMs)
            }
        }
    }

    @ViewBuilder
    private func cyclingSection(_ s: DailySummary) -> some View {
        let hasData = s.cyclingSpeed != nil || s.cyclingPower != nil || s.cyclingFTP != nil
            || s.cyclingCadence != nil
        if hasData {
            categoryCard("Cycling") {
                metricRow("Speed", value: s.cyclingSpeed, format: fmtMps)
                metricRow("Power", value: s.cyclingPower, format: fmtWatt)
                metricRow("FTP", value: s.cyclingFTP, format: fmtWatt)
                metricRow("Cadence", value: s.cyclingCadence, format: { fmtInt($0) + " rpm" })
            }
        }
    }

    @ViewBuilder
    private func heartSection(_ s: DailySummary) -> some View {
        let hasData = s.heartRateAvg != nil || s.restingHeartRate != nil || s.walkingHeartRateAvg != nil
            || s.hrv != nil || s.heartRateRecovery != nil || s.atrialFibrillationBurden != nil
            || s.peripheralPerfusionIndex != nil
        if hasData {
            categoryCard("Heart") {
                avgMinMaxRow("Heart Rate", avg: s.heartRateAvg, min: s.heartRateMin, max: s.heartRateMax, format: fmtBpm)
                metricRow("Resting Heart Rate", value: s.restingHeartRate, format: fmtBpm)
                metricRow("Walking Heart Rate", value: s.walkingHeartRateAvg, format: fmtBpm)
                metricRow("HRV", value: s.hrv, format: fmtMs)
                metricRow("Heart Rate Recovery", value: s.heartRateRecovery, format: fmtBpm)
                metricRow("AFib Burden", value: s.atrialFibrillationBurden, format: fmtPercent)
                metricRow("Perfusion Index", value: s.peripheralPerfusionIndex, format: fmtPercent)
            }
        }
    }

    @ViewBuilder
    private func respiratorySection(_ s: DailySummary) -> some View {
        let hasData = s.respiratoryRateAvg != nil || s.oxygenSaturationAvg != nil
        if hasData {
            categoryCard("Respiratory") {
                avgMinMaxRow("Respiratory Rate", avg: s.respiratoryRateAvg, min: s.respiratoryRateMin, max: s.respiratoryRateMax, format: { fmt1($0) + " brpm" })
                avgMinRow("Blood Oxygen", avg: s.oxygenSaturationAvg, min: s.oxygenSaturationMin, format: fmtPercent)
            }
        }
    }

    @ViewBuilder
    private func bodySection(_ s: DailySummary) -> some View {
        let hasData = s.height != nil || s.bodyMass != nil || s.bmi != nil
            || s.sleepingWristTempAvg != nil
        if hasData {
            categoryCard("Body") {
                metricRow("Height", value: s.height, format: fmtHeight)
                metricRow("Weight", value: s.bodyMass, format: fmtWeight)
                metricRow("BMI", value: s.bmi, format: { fmt1($0) })
                avgMinMaxRow("Wrist Temperature", avg: s.sleepingWristTempAvg, min: s.sleepingWristTempMin, max: s.sleepingWristTempMax, format: fmtTemp)
            }
        }
    }

    @ViewBuilder
    private func mobilitySection(_ s: DailySummary) -> some View {
        let hasData = s.walkingSpeed != nil || s.walkingStepLength != nil || s.walkingAsymmetry != nil
            || s.walkingDoubleSupport != nil || s.stairAscentSpeed != nil || s.stairDescentSpeed != nil
            || s.sixMinWalkDistance != nil
        if hasData {
            categoryCard("Mobility") {
                metricRow("Walking Speed", value: s.walkingSpeed, format: fmtMps)
                metricRow("Step Length", value: s.walkingStepLength, format: { fmt2($0) + " m" })
                metricRow("Asymmetry", value: s.walkingAsymmetry, format: fmtPercent)
                metricRow("Double Support", value: s.walkingDoubleSupport, format: fmtPercent)
                metricRow("Stair Ascent Speed", value: s.stairAscentSpeed, format: fmtMps)
                metricRow("Stair Descent Speed", value: s.stairDescentSpeed, format: fmtMps)
                metricRow("Six-Minute Walk", value: s.sixMinWalkDistance, format: fmtDistance)
            }
        }
    }

    @ViewBuilder
    private func sleepSection(_ s: DailySummary) -> some View {
        let hasData = s.sleepTotalHours != nil
        if hasData {
            categoryCard("Sleep") {
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
    }

    @ViewBuilder
    private func eventsSection(_ s: DailySummary) -> some View {
        let hasData = s.standHoursCount != nil || s.mindfulMinutes != nil
            || s.highHeartRateEvents != nil || s.lowHeartRateEvents != nil
            || s.irregularRhythmEvents != nil
        if hasData {
            categoryCard("Events") {
                metricRow("Stand Hours", intValue: s.standHoursCount)
                metricRow("Mindful Minutes", value: s.mindfulMinutes, format: fmtMin)
                metricRow("High Heart Rate Events", intValue: s.highHeartRateEvents)
                metricRow("Low Heart Rate Events", intValue: s.lowHeartRateEvents)
                metricRow("Irregular Rhythm Events", intValue: s.irregularRhythmEvents)
            }
        }
    }

    @ViewBuilder
    private var workoutsSection: some View {
        if !selectedWorkouts.isEmpty {
            categoryCard("Workouts") {
                ForEach(selectedWorkouts, id: \.startTime) { workout in
                    workoutRow(workout)
                }
            }
        }
    }

    // MARK: - Card & Row Helpers

    private func categoryCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                content()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func metricRow(_ label: String, value: Double?, format: (Double) -> String) -> some View {
        if let value {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(format(value))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func metricRow(_ label: String, intValue: Int?, unit: String = "") -> some View {
        if let intValue {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(unit.isEmpty ? "\(intValue)" : "\(intValue) \(unit)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func avgMinMaxRow(_ label: String, avg: Double?, min: Double?, max: Double?, format: @escaping (Double) -> String) -> some View {
        if avg != nil || min != nil || max != nil {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)

                HStack(spacing: 16) {
                    statItem("Avg", value: avg, format: format)
                    statItem("Min", value: min, format: format)
                    statItem("Max", value: max, format: format)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func avgMinRow(_ label: String, avg: Double?, min: Double?, format: @escaping (Double) -> String) -> some View {
        if avg != nil || min != nil {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)

                HStack(spacing: 16) {
                    statItem("Avg", value: avg, format: format)
                    statItem("Min", value: min, format: format)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func statItem(_ label: String, value: Double?, format: (Double) -> String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let value {
                Text(format(value))
                    .font(.subheadline)
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

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

    private func workoutRow(_ w: WorkoutSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(w.workoutType.capitalized)
                .font(.subheadline.weight(.medium))

            HStack(spacing: 16) {
                Label(fmtMin(w.duration / 60), systemImage: "clock")

                if let energy = w.totalEnergyBurned {
                    Label(fmtKcal(energy), systemImage: "flame")
                }

                if let distance = w.totalDistance {
                    Label(fmtDistance(distance), systemImage: "figure.walk")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text(w.startTime.formatted(date: .omitted, time: .shortened))
                Text("–")
                Text(w.endTime.formatted(date: .omitted, time: .shortened))
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Formatters

    private func fmtInt(_ v: Double) -> String { String(format: "%.0f", v) }
    private func fmt1(_ v: Double) -> String { String(format: "%.1f", v) }
    private func fmt2(_ v: Double) -> String { String(format: "%.2f", v) }
    private func fmtDistance(_ m: Double) -> String { UnitConverter.displayDistance(m, unit: unitPref) }
    private func fmtWeight(_ kg: Double) -> String { UnitConverter.displayWeight(kg, unit: unitPref) }
    private func fmtHeight(_ m: Double) -> String { UnitConverter.displayHeight(m, unit: unitPref) }
    private func fmtTemp(_ c: Double) -> String { UnitConverter.displayTemperature(c, unit: unitPref) }
    private func fmtKcal(_ v: Double) -> String { fmtInt(v) + " kcal" }
    private func fmtMin(_ v: Double) -> String { fmtInt(v) + " min" }
    private func fmtBpm(_ v: Double) -> String { fmtInt(v) + " bpm" }
    private func fmtMs(_ v: Double) -> String { fmtInt(v) + " ms" }
    private func fmtPercent(_ v: Double) -> String { fmt1(v * 100) + "%" }
    private func fmtMps(_ v: Double) -> String { fmt2(v) + " m/s" }
    private func fmtWatt(_ v: Double) -> String { fmtInt(v) + " W" }

    private func fmtHours(_ v: Double) -> String {
        let h = Int(v)
        let m = Int((v - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            selectedDate = DateHelpers.startOfDay(for: newDate)
                            showDatePicker = false
                        }
                    ),
                    in: datePickerRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                // Dates with data indicator
                if !storedDates.isEmpty {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("\(storedDates.count) days with data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Go to Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Today") {
                        selectedDate = DateHelpers.startOfDay(for: Date())
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .modelContainer(for: [DailySummary.self, HealthInsight.self, WorkoutSummary.self, UserProfile.self], inMemory: true)
}
