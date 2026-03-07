import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailySummary.date) private var dailySummaries: [DailySummary]
    @Query private var healthInsights: [HealthInsight]
    @Query private var profiles: [UserProfile]
    @State private var selectedDate: Date = DateHelpers.startOfDay(for: Date())
    @State private var showDatePicker = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showManualInputSheet = false
    @State private var showWeightEntrySheet = false

    private var selectedInsight: HealthInsight? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return healthInsights.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var selectedSummary: DailySummary? {
        let normalized = DateHelpers.startOfDay(for: selectedDate)
        return dailySummaries.first { Calendar.current.isDate($0.date, inSameDayAs: normalized) }
    }

    private var unitPref: UnitPreference {
        UnitPreference(rawValue: profiles.first?.unitPreference ?? "metric") ?? .metric
    }

    private var mostRecentWeightKg: Double {
        if let w = selectedSummary?.bodyMass { return w }
        if let w = dailySummaries.last(where: { $0.bodyMass != nil })?.bodyMass { return w }
        return profiles.first?.weight ?? 70.0
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
            Group {
                if selectedInsight != nil {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Future sections go here
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                } else {
                    emptyStateView
                }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        showDatePicker = true
                    } label: {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManualInputSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .confirmationDialog("Log Data", isPresented: $showManualInputSheet) {
                Button {
                    showWeightEntrySheet = true
                } label: {
                    Label("Log Weight", systemImage: "scalemass")
                }
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showWeightEntrySheet) {
                LogWeightSheet(
                    initialDate: selectedDate,
                    unitPreference: unitPref,
                    initialWeightKg: mostRecentWeightKg,
                    dailySummaries: dailySummaries,
                    profile: profiles.first
                )
            }
            .onAppear {
                handlePendingAction()
            }
            .onChange(of: appState.pendingAction) {
                handlePendingAction()
            }
        }
    }

    private func handlePendingAction() {
        guard appState.pendingAction == .logWeight else { return }
        appState.pendingAction = nil
        showWeightEntrySheet = true
    }

    private func navigateDay(by offset: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate)!
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .modelContainer(for: [DailySummary.self, HealthInsight.self, UserProfile.self], inMemory: true)
}
