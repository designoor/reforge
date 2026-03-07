import SwiftUI
import SwiftData

// MARK: - ScheduleView

struct ScheduleView: View {
    @Binding var canAdvance: Bool
    @Binding var onAdvanceAction: (() -> Void)?
    @Environment(\.modelContext) private var modelContext

    @State private var wakeTime: Date = {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
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
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Wake Time")
                .font(.largeTitle.bold())

            Text("Set your typical wake time for personalized timing.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var wakeTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker(
                "Wake Time",
                selection: $wakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
        }
    }

    // MARK: - Logic

    private func saveProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.timeZone = TimeZone.current.identifier
            existing.wakeTime = wakeTime
            existing.updatedAt = Date()
        } else {
            let profile = UserProfile(
                timeZone: TimeZone.current.identifier,
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
