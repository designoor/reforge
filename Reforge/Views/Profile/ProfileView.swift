import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    // MARK: - Sheet Presentation

    @State private var showDOBPicker = false
    @State private var showSexPicker = false
    @State private var showHeightEditor = false
    @State private var showWeightEditor = false
    @State private var showTimeZonePicker = false
    @State private var showWakeTimePicker = false
    @State private var showAPIKeyEditor = false

    // MARK: - Display State

    @State private var isNotificationsEnabled = false
    @State private var fullAPIKey: String?
    @State private var maskedAPIKey: String = "Not set"
    @State private var isAPIKeyRevealed = false

    // MARK: - Computed

    private var profile: UserProfile? { profiles.first }

    private var unitPref: UnitPreference {
        UnitPreference(rawValue: profile?.unitPreference ?? "metric") ?? .metric
    }

    private var formattedDOB: String {
        guard let profile else { return "—" }
        return profile.dateOfBirth.formatted(date: .abbreviated, time: .omitted)
    }

    private var formattedWakeTime: String {
        guard let profile else { return "—" }
        return profile.wakeTime.formatted(date: .omitted, time: .shortened)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                personalInfoSection
                preferencesSection
                apiSection
                notificationsSection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .onAppear {
                loadNotificationStatus()
                loadAPIKey()
            }
            .sheet(isPresented: $showDOBPicker) {
                EditDOBSheet(dateOfBirth: dobBinding)
            }
            .sheet(isPresented: $showSexPicker) {
                EditSexSheet(
                    currentSex: profile?.biologicalSex ?? "other",
                    onSave: { newValue in updateProfile { $0.biologicalSex = newValue } }
                )
            }
            .sheet(isPresented: $showHeightEditor) {
                EditHeightSheet(
                    initialHeightMeters: profile?.height ?? 1.70,
                    unitPreference: unitPref,
                    onSave: { meters in updateProfile { $0.height = meters } }
                )
            }
            .sheet(isPresented: $showWeightEditor) {
                EditWeightSheet(
                    initialWeightKg: profile?.weight ?? 70.0,
                    unitPreference: unitPref,
                    onSave: { kg in updateProfile { $0.weight = kg } }
                )
            }
            .sheet(isPresented: $showTimeZonePicker) {
                EditTimeZoneSheet(
                    currentTimeZone: profile?.timeZone ?? TimeZone.current.identifier,
                    onSave: { tz in
                        updateProfile { $0.timeZone = tz }
                        triggerRescheduleAll()
                    }
                )
            }
            .sheet(isPresented: $showWakeTimePicker) {
                EditWakeTimeSheet(wakeTime: wakeTimeBinding)
            }
            .sheet(isPresented: $showAPIKeyEditor, onDismiss: {
                isAPIKeyRevealed = false
            }) {
                EditAPIKeySheet(
                    initialAPIKey: fullAPIKey ?? "",
                    onSave: { newKey in
                        try? KeychainService.saveAPIKey(newKey)
                        loadAPIKey()
                    }
                )
            }
        }
    }

    // MARK: - Sections

    private var personalInfoSection: some View {
        Section("Personal Info") {
            Button { showDOBPicker = true } label: {
                LabeledContent("Date of Birth") {
                    Text(formattedDOB)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button { showSexPicker = true } label: {
                LabeledContent("Biological Sex") {
                    Text(BiologicalSexOption.from(profile?.biologicalSex ?? "other").displayName)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button { showHeightEditor = true } label: {
                LabeledContent("Height") {
                    Text(UnitConverter.displayHeight(profile?.height ?? 1.70, unit: unitPref))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button { showWeightEditor = true } label: {
                LabeledContent("Weight") {
                    Text(UnitConverter.displayWeight(profile?.weight ?? 70.0, unit: unitPref))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Picker("Units", selection: unitPreferenceBinding) {
                Text("Metric").tag("metric")
                Text("Imperial").tag("imperial")
            }

            Button { showTimeZonePicker = true } label: {
                LabeledContent("Time Zone") {
                    Text(profile?.timeZone ?? TimeZone.current.identifier)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Button { showWakeTimePicker = true } label: {
                LabeledContent("Wake Time") {
                    Text(formattedWakeTime)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private var apiSection: some View {
        Section("API") {
            Button { showAPIKeyEditor = true } label: {
                HStack {
                    Text("API Key")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(isAPIKeyRevealed ? (fullAPIKey ?? "Not set") : maskedAPIKey)
                        .foregroundStyle(.secondary)
                        .font(.footnote.monospaced())
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.primary)
            .swipeActions(edge: .trailing) {
                Button {
                    isAPIKeyRevealed.toggle()
                } label: {
                    Image(systemName: isAPIKeyRevealed ? "eye.slash" : "eye")
                }
            }

            LabeledContent("API Usage") {
                Text("Coming soon")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var notificationsSection: some View {
        Group {
            Section("Notifications — System") {
                HStack {
                    Text("Permission")
                    Spacer()
                    if isNotificationsEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Enabled")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    } else {
                        HStack(spacing: 8) {
                            Text("Disabled")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            Button("Enable in Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }

            Section("Notifications — Reminders") {
                Toggle("Weight Reminder", isOn: weightReminderBinding)

                if profile?.weightReminderEnabled == true {
                    DatePicker(
                        "Reminder Time",
                        selection: weightReminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section("Notifications — Debug") {
                Toggle("Data Collection Success", isOn: dailyCollectionNotificationBinding)
            }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            NavigationLink(destination: DebugDataView()) {
                Label("Debug", systemImage: "ladybug")
            }

            Button(role: .destructive) {
                appState.isOnboardingComplete = false
                appState.currentOnboardingStep = 0
            } label: {
                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version") {
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            Button {
                if let url = URL(string: "https://anthropic.com") {
                    openURL(url)
                }
            } label: {
                HStack {
                    Text("Built with Claude by Anthropic")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Bindings

    private var unitPreferenceBinding: Binding<String> {
        Binding(
            get: { profile?.unitPreference ?? "metric" },
            set: { newValue in updateProfile { $0.unitPreference = newValue } }
        )
    }

    private var dobBinding: Binding<Date> {
        Binding(
            get: { profile?.dateOfBirth ?? Date() },
            set: { newValue in updateProfile { $0.dateOfBirth = newValue } }
        )
    }

    private var wakeTimeBinding: Binding<Date> {
        Binding(
            get: { profile?.wakeTime ?? Date() },
            set: { newValue in
                updateProfile { $0.wakeTime = newValue }
                triggerRescheduleAll()
            }
        )
    }

    private var weightReminderBinding: Binding<Bool> {
        Binding(
            get: { profile?.weightReminderEnabled ?? false },
            set: { newValue in
                updateProfile { $0.weightReminderEnabled = newValue }
                triggerRescheduleAll()
            }
        )
    }

    private var weightReminderTimeBinding: Binding<Date> {
        Binding(
            get: { profile?.weightReminderTime ?? Date() },
            set: { newValue in
                updateProfile { $0.weightReminderTime = newValue }
                triggerRescheduleAll()
            }
        )
    }

    private var dailyCollectionNotificationBinding: Binding<Bool> {
        Binding(
            get: { profile?.dailyCollectionNotification ?? false },
            set: { newValue in updateProfile { $0.dailyCollectionNotification = newValue } }
        )
    }

    // MARK: - Actions

    private func updateProfile(_ mutation: (UserProfile) -> Void) {
        guard let profile else { return }
        mutation(profile)
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func triggerRescheduleAll() {
        guard let profile else { return }
        let timeZone = TimeZone(identifier: profile.timeZone) ?? .current
        Task {
            await NotificationManager.rescheduleAll(
                weightReminderEnabled: profile.weightReminderEnabled,
                weightReminderTime: profile.weightReminderTime,
                wakeTime: profile.wakeTime,
                timeZone: timeZone
            )
        }
    }

    private func loadNotificationStatus() {
        Task {
            isNotificationsEnabled = await NotificationManager.isPermissionGranted()
        }
    }

    private func loadAPIKey() {
        fullAPIKey = try? KeychainService.getAPIKey()
        guard let key = fullAPIKey, key.count > 10 else {
            maskedAPIKey = fullAPIKey != nil ? fullAPIKey! : "Not set"
            return
        }
        let prefix = String(key.prefix(6))
        let suffix = String(key.suffix(4))
        maskedAPIKey = "\(prefix)...\(suffix)"
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AppState())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
