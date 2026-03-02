import SwiftUI
import SwiftData
import UserNotifications

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

    // MARK: - Edit State

    @State private var editHeightCm: String = ""
    @State private var editHeightFeet: Int = 5
    @State private var editHeightInches: Int = 7
    @State private var editWeightDisplay: String = ""
    @State private var editAPIKey: String = ""
    @State private var isValidatingAPIKey = false
    @State private var apiValidationResult: APIValidationResult?
    @State private var timeZoneSearch = ""

    // MARK: - Display State

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var fullAPIKey: String?
    @State private var maskedAPIKey: String = "Not set"
    @State private var isAPIKeyRevealed = false

    // MARK: - Types

    private enum APIValidationResult {
        case success
        case failure(String)
    }

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

    private var filteredTimeZones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        guard !timeZoneSearch.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(timeZoneSearch) }
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
            .sheet(isPresented: $showDOBPicker) { dobSheet }
            .sheet(isPresented: $showSexPicker) { sexSheet }
            .sheet(isPresented: $showHeightEditor, onDismiss: nil) {
                heightSheet
                    .onAppear { initHeightEditor() }
            }
            .sheet(isPresented: $showWeightEditor, onDismiss: nil) {
                weightSheet
                    .onAppear { initWeightEditor() }
            }
            .sheet(isPresented: $showTimeZonePicker) { timeZoneSheet }
            .sheet(isPresented: $showWakeTimePicker) { wakeTimeSheet }
            .sheet(isPresented: $showAPIKeyEditor, onDismiss: {
                isAPIKeyRevealed = false
                apiValidationResult = nil
            }) {
                apiKeySheet
                    .onAppear { editAPIKey = fullAPIKey ?? "" }
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
        Section("Notifications") {
            HStack {
                Text("Notifications")
                Spacer()
                switch notificationStatus {
                case .authorized, .provisional:
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Enabled")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                default:
                    HStack(spacing: 8) {
                        Text("Disabled")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Button("Enable") {
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

    // MARK: - Edit Sheets

    private var dobSheet: some View {
        NavigationStack {
            DatePicker(
                "Date of Birth",
                selection: dobBinding,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDOBPicker = false }
                }
            }
        }
    }

    private var sexSheet: some View {
        NavigationStack {
            List {
                ForEach(BiologicalSexOption.allCases) { option in
                    Button {
                        updateProfile { $0.biologicalSex = option.rawValue }
                        showSexPicker = false
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if BiologicalSexOption.from(profile?.biologicalSex ?? "other") == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Biological Sex")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSexPicker = false }
                }
            }
        }
    }

    private var heightSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if unitPref == .metric {
                    HStack {
                        TextField("Height", text: $editHeightCm)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        Stepper(value: $editHeightFeet, in: 1...8) {
                            Text("\(editHeightFeet) ft")
                        }
                        Stepper(value: $editHeightInches, in: 0...11) {
                            Text("\(editHeightInches) in")
                        }
                    }
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showHeightEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveHeight() }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var weightSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    TextField("Weight", text: $editWeightDisplay)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Text(unitPref == .metric ? "kg" : "lbs")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showWeightEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWeight() }
                        .disabled({
                            guard let w = Double(editWeightDisplay), w > 0 else { return true }
                            return false
                        }())
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var timeZoneSheet: some View {
        NavigationStack {
            List(filteredTimeZones, id: \.self) { tz in
                Button {
                    updateProfile { $0.timeZone = tz }
                    showTimeZonePicker = false
                    timeZoneSearch = ""
                } label: {
                    HStack {
                        Text(tz)
                            .foregroundStyle(.primary)
                        Spacer()
                        if tz == profile?.timeZone {
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

    private var wakeTimeSheet: some View {
        NavigationStack {
            DatePicker(
                "Wake Time",
                selection: wakeTimeBinding,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Wake Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showWakeTimePicker = false }
                }
            }
        }
    }

    private var apiKeySheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SecureField("sk-ant-...", text: $editAPIKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    validateAPIKey()
                } label: {
                    if isValidatingAPIKey {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Validate Key")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(editAPIKey.count < 10 || isValidatingAPIKey)

                if let result = apiValidationResult {
                    switch result {
                    case .success:
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                            Text("API key is valid")
                                .foregroundStyle(.secondary)
                        }
                    case .failure(let message):
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title3)
                            Text(message)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.footnote)
                    Text("Your API key is stored securely in the device Keychain.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()
            }
            .padding(24)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAPIKeyEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAPIKey() }
                        .disabled(editAPIKey.count < 10)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
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
            set: { newValue in updateProfile { $0.wakeTime = newValue } }
        )
    }

    // MARK: - Actions

    private func updateProfile(_ mutation: (UserProfile) -> Void) {
        guard let profile else { return }
        mutation(profile)
        profile.updatedAt = Date()
        try? modelContext.save()
    }

    private func initHeightEditor() {
        guard let profile else { return }
        if unitPref == .metric {
            editHeightCm = String(format: "%.0f", profile.height * 100.0)
        } else {
            let (feet, inches) = UnitConverter.feetInchesFromMeters(profile.height)
            editHeightFeet = feet
            editHeightInches = inches
        }
    }

    private func saveHeight() {
        let meters: Double
        if unitPref == .metric {
            meters = (Double(editHeightCm) ?? 1.70) / 100.0
        } else {
            meters = UnitConverter.metersFromFeetInches(feet: editHeightFeet, inches: editHeightInches)
        }
        updateProfile { $0.height = meters }
        showHeightEditor = false
    }

    private func initWeightEditor() {
        guard let profile else { return }
        if unitPref == .metric {
            editWeightDisplay = String(format: "%.1f", profile.weight)
        } else {
            editWeightDisplay = String(format: "%.1f", UnitConverter.lbsFromKg(profile.weight))
        }
    }

    private func saveWeight() {
        guard let w = Double(editWeightDisplay), w > 0 else { return }
        let kg: Double
        if unitPref == .metric {
            kg = w
        } else {
            kg = UnitConverter.kgFromLbs(w)
        }
        updateProfile { $0.weight = kg }
        showWeightEditor = false
    }

    private func loadNotificationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
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

    private func saveAPIKey() {
        try? KeychainService.saveAPIKey(editAPIKey)
        loadAPIKey()
        showAPIKeyEditor = false
    }

    private func validateAPIKey() {
        isValidatingAPIKey = true
        apiValidationResult = nil

        Task {
            let result = await performAPIValidation()
            isValidatingAPIKey = false
            apiValidationResult = result
        }
    }

    private func performAPIValidation() async -> APIValidationResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return .failure("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(editAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]],
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure("Failed to build request")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Unexpected response")
            }

            switch httpResponse.statusCode {
            case 200:
                return .success
            case 401:
                return .failure("Invalid API key")
            default:
                return .failure("Error (HTTP \(httpResponse.statusCode))")
            }
        } catch {
            return .failure("Network error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(AppState())
        .modelContainer(for: UserProfile.self, inMemory: true)
}
