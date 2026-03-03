import SwiftUI
import SwiftData

struct AggregatedDataView: View {

    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query(sort: \WorkoutSummary.date) private var allWorkouts: [WorkoutSummary]
    @Query private var profiles: [UserProfile]

    @State private var selectedDate: Date = DateHelpers.yesterday()
    @State private var showCopiedToast: Bool = false

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

    private var payload: ClaudeDataPayload? {
        guard let profile, let summary = selectedSummary else { return nil }
        return ClaudeDataPayload.build(
            date: selectedDate,
            profile: profile,
            summary: summary,
            workouts: selectedWorkouts,
            unitPref: unitPref
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            dateHeader
                .padding(.horizontal, 16)

            if let payload {
                List {
                    userProfileSection(payload.userProfile)

                    ForEach(payload.metrics) { category in
                        Section(category.category) {
                            ForEach(category.metrics) { metric in
                                metricWithTrendsRow(metric)
                            }
                        }
                    }

                    workoutsSection(payload.workouts)
                    trendsNoteSection
                    copySection
                }
                .listStyle(.insetGrouped)
            } else if profile == nil {
                Spacer()
                noProfileView
                Spacer()
            } else {
                Spacer()
                noDataView
                Spacer()
            }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text("Copied to clipboard")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCopiedToast)
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

    // MARK: - User Profile Section

    private func userProfileSection(_ profile: UserProfileContext) -> some View {
        Section("User Profile") {
            LabeledContent("Age", value: "\(profile.ageYears) years")
            LabeledContent("Biological Sex", value: profile.biologicalSex)
            LabeledContent("Height", value: profile.heightDisplay)
            LabeledContent("Weight", value: profile.weightDisplay)
        }
    }

    // MARK: - Metric Row with Trends

    private func metricWithTrendsRow(_ metric: MetricData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent(metric.name) {
                Text(metric.displayValue)
                    .monospacedDigit()
            }

            HStack(spacing: 0) {
                trendItem("DoW", value: metric.trends.dayOfWeekMedian)
                Spacer(minLength: 0)
                trendItem("Wk", value: metric.trends.thisWeek)
                Spacer(minLength: 0)
                trendItem("LWk", value: metric.trends.lastWeek)
                Spacer(minLength: 0)
                trendItem("WkM", value: metric.trends.weekMedian)
                Spacer(minLength: 0)
                trendItem("Mo", value: metric.trends.thisMonth)
                Spacer(minLength: 0)
                trendItem("LMo", value: metric.trends.lastMonth)
                Spacer(minLength: 0)
                trendItem("MoM", value: metric.trends.monthMedian)
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func trendItem(_ label: String, value: Double?) -> some View {
        VStack(spacing: 1) {
            Text(label)
            Text(value.map { String(format: "%.1f", $0) } ?? "—")
                .monospacedDigit()
        }
    }

    // MARK: - Workouts Section

    private func workoutsSection(_ workouts: [WorkoutData]) -> some View {
        Section("Workouts") {
            if workouts.isEmpty {
                Text("No workouts")
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.type.capitalized)
                            .font(.body.weight(.medium))

                        HStack(spacing: 16) {
                            Label(String(format: "%.0f min", workout.durationMinutes), systemImage: "clock")

                            if let energy = workout.energyBurnedKcal {
                                Label(String(format: "%.0f kcal", energy), systemImage: "flame")
                            }

                            if let distance = workout.distanceMeters {
                                Label(UnitConverter.displayDistance(distance, unit: unitPref), systemImage: "figure.walk")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Trends Note

    private var trendsNoteSection: some View {
        Section("Trends") {
            Text("Trend comparisons will be available after TrendCalculator is implemented (Phase 10). All trend values currently show \"—\".")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Copy as JSON

    private var copySection: some View {
        Section {
            Button {
                copyPayloadAsJSON()
            } label: {
                Label("Copy as JSON", systemImage: "doc.on.doc")
            }
        }
    }

    private func copyPayloadAsJSON() {
        guard let payload else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(payload),
           let json = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = json
            showCopiedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCopiedToast = false
            }
        }
    }

    // MARK: - Empty States

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

    private var noProfileView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemGray3))

            Text("Complete onboarding to see Claude data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AggregatedDataView()
    }
    .modelContainer(for: [
        DailySummary.self,
        WorkoutSummary.self,
        UserProfile.self,
    ], inMemory: true)
}
