import SwiftUI
import SwiftData

// MARK: - ScheduleView

struct ScheduleView: View {
    @Binding var canAdvance: Bool
    @Binding var onAdvanceAction: (() -> Void)?
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTimeZone: String = TimeZone.current.identifier
    @State private var wakeTime: Date = {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var showTimeZonePicker = false
    @State private var timeZoneSearch = ""

    private var filteredTimeZones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        if timeZoneSearch.isEmpty {
            return all
        }
        return all.filter { $0.localizedCaseInsensitiveContains(timeZoneSearch) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                timeZoneSection
                wakeTimeSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            canAdvance = true
            onAdvanceAction = { saveProfile() }
        }
        .sheet(isPresented: $showTimeZonePicker) {
            timeZonePickerSheet
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Your Schedule")
                .font(.largeTitle.bold())

            Text("Set your timezone and wake time for personalized timing.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var timeZoneSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Zone")
                .font(.headline)

            HStack {
                Text(selectedTimeZone)
                    .foregroundStyle(.primary)

                Spacer()

                Button("Change") {
                    showTimeZonePicker = true
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var wakeTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Typical Wake Time")
                .font(.headline)

            DatePicker(
                "Wake Time",
                selection: $wakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
        }
    }

    // MARK: - Timezone Picker

    private var timeZonePickerSheet: some View {
        NavigationStack {
            List(filteredTimeZones, id: \.self) { tz in
                Button {
                    selectedTimeZone = tz
                    showTimeZonePicker = false
                    timeZoneSearch = ""
                } label: {
                    HStack {
                        Text(tz)
                            .foregroundStyle(.primary)
                        Spacer()
                        if tz == selectedTimeZone {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $timeZoneSearch, prompt: "Search time zones")
            .navigationTitle("Time Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showTimeZonePicker = false
                        timeZoneSearch = ""
                    }
                }
            }
        }
    }

    // MARK: - Logic

    private func saveProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.timeZone = selectedTimeZone
            existing.wakeTime = wakeTime
            existing.updatedAt = Date()
        } else {
            let profile = UserProfile(
                timeZone: selectedTimeZone,
                wakeTime: wakeTime
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    ScheduleView(
        canAdvance: .constant(true),
        onAdvanceAction: .constant(nil)
    )
    .modelContainer(for: UserProfile.self, inMemory: true)
}
