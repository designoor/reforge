import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query private var healthInsights: [HealthInsight]

    @State private var selectedDate: Date = DateHelpers.startOfDay(for: Date())
    @State private var isDataSummaryExpanded = false
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
        .modelContainer(for: [DailySummary.self, HealthInsight.self], inMemory: true)
}
