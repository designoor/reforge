import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query private var healthInsights: [HealthInsight]

    @State private var selectedDate: Date = DateHelpers.yesterday()
    @State private var isDataSummaryExpanded = false

    private var selectedSummary: DailySummary? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return dailySummaries.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var selectedInsight: HealthInsight? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return healthInsights.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
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
            .refreshable {
                guard !appState.isSyncing else { return }
                appState.isSyncing = true
                defer { appState.isSyncing = false }
                let context = ModelContext(modelContext.container)
                _ = try? await DailyDataService.collectToday(context: context)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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

            VStack(spacing: 4) {
                Text(formattedDate)
                    .font(.headline)

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

    private var dataSummarySection: some View {
        DisclosureGroup(isExpanded: $isDataSummaryExpanded) {
            Text("Health metrics will appear here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        } label: {
            Text("Health Data")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
        .modelContainer(for: [DailySummary.self, HealthInsight.self], inMemory: true)
}
