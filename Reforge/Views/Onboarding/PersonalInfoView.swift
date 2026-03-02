import SwiftUI
import SwiftData
import HealthKit

// MARK: - PersonalInfoView

struct PersonalInfoView: View {
    @Binding var canAdvance: Bool
    @Binding var onAdvanceAction: (() -> Void)?
    @Environment(\.modelContext) private var modelContext

    @State private var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var biologicalSex: BiologicalSexOption = .other
    @State private var unitPreference: UnitPreference = .metric
    @State private var heightCm: String = "170"
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var weightDisplay: String = "70.0"
    @State private var didPreFillFromHealthKit = false

    private var isFormValid: Bool {
        let hasValidHeight: Bool
        if unitPreference == .metric {
            if let cm = Double(heightCm), cm > 0, cm < 300 {
                hasValidHeight = true
            } else {
                hasValidHeight = false
            }
        } else {
            hasValidHeight = heightFeet > 0 || heightInches > 0
        }

        guard let w = Double(weightDisplay), w > 0 else {
            return false
        }

        return hasValidHeight && w > 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                if didPreFillFromHealthKit {
                    healthKitNote
                }

                dateOfBirthSection
                biologicalSexSection
                unitPreferenceSection
                heightSection
                weightSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            unitPreference = Self.localeUnitPreference
            prefillFromHealthKit()
            updateCanAdvance()
            onAdvanceAction = { saveProfile() }
        }
        .onChange(of: dateOfBirth) { _, _ in updateCanAdvance() }
        .onChange(of: biologicalSex) { _, _ in updateCanAdvance() }
        .onChange(of: heightCm) { _, _ in updateCanAdvance() }
        .onChange(of: heightFeet) { _, _ in updateCanAdvance() }
        .onChange(of: heightInches) { _, _ in updateCanAdvance() }
        .onChange(of: weightDisplay) { _, _ in updateCanAdvance() }
        .onChange(of: unitPreference) { oldValue, newValue in
            convertUnitsOnPreferenceChange(from: oldValue, to: newValue)
            updateCanAdvance()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("About You")
                .font(.largeTitle.bold())

            Text("This helps personalize your health insights.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var healthKitNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
                .font(.footnote)
            Text("Pre-filled from Apple Health. You can change these.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var dateOfBirthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date of Birth")
                .font(.headline)

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var biologicalSexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Biological Sex")
                .font(.headline)

            Picker("Biological Sex", selection: $biologicalSex) {
                ForEach(BiologicalSexOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var unitPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Units")
                .font(.headline)

            Picker("Units", selection: $unitPreference) {
                Text("Metric").tag(UnitPreference.metric)
                Text("Imperial").tag(UnitPreference.imperial)
            }
            .pickerStyle(.segmented)
        }
    }

    private var heightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Height")
                .font(.headline)

            if unitPreference == .metric {
                HStack {
                    TextField("Height", text: $heightCm)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Text("cm")
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 16) {
                    Stepper(value: $heightFeet, in: 1...8) {
                        Text("\(heightFeet) ft")
                    }

                    Stepper(value: $heightInches, in: 0...11) {
                        Text("\(heightInches) in")
                    }
                }
            }
        }
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight")
                .font(.headline)

            HStack {
                TextField("Weight", text: $weightDisplay)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                Text(unitPreference == .metric ? "kg" : "lbs")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Logic

    private static var localeUnitPreference: UnitPreference {
        if Locale.current.measurementSystem == .us {
            return .imperial
        }
        return .metric
    }

    private func prefillFromHealthKit() {
        guard HealthKitManager.isAvailable() else { return }

        var didFill = false

        if let dob = try? HealthKitManager.getDateOfBirth() {
            dateOfBirth = dob
            didFill = true
        }

        if let hkSex = try? HealthKitManager.getBiologicalSex() {
            switch hkSex {
            case .male:
                biologicalSex = .male
            case .female:
                biologicalSex = .female
            default:
                break
            }
            didFill = true
        }

        didPreFillFromHealthKit = didFill
    }

    private func convertUnitsOnPreferenceChange(from oldUnit: UnitPreference, to newUnit: UnitPreference) {
        guard oldUnit != newUnit else { return }

        // Convert height
        if newUnit == .imperial {
            if let cm = Double(heightCm) {
                let meters = cm / 100.0
                let (feet, inches) = UnitConverter.feetInchesFromMeters(meters)
                heightFeet = feet
                heightInches = inches
            }
        } else {
            let meters = UnitConverter.metersFromFeetInches(feet: heightFeet, inches: heightInches)
            let cm = meters * 100.0
            heightCm = String(format: "%.0f", cm)
        }

        // Convert weight
        if let currentWeight = Double(weightDisplay) {
            if newUnit == .imperial {
                let lbs = UnitConverter.lbsFromKg(currentWeight)
                weightDisplay = String(format: "%.1f", lbs)
            } else {
                let kg = UnitConverter.kgFromLbs(currentWeight)
                weightDisplay = String(format: "%.1f", kg)
            }
        }
    }

    private func updateCanAdvance() {
        canAdvance = isFormValid
    }

    private func saveProfile() {
        let heightInMeters: Double
        if unitPreference == .metric {
            heightInMeters = (Double(heightCm) ?? 1.70) / 100.0
        } else {
            heightInMeters = UnitConverter.metersFromFeetInches(feet: heightFeet, inches: heightInches)
        }

        let weightInKg: Double
        if unitPreference == .metric {
            weightInKg = Double(weightDisplay) ?? 70.0
        } else {
            weightInKg = UnitConverter.kgFromLbs(Double(weightDisplay) ?? 154.0)
        }

        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.dateOfBirth = dateOfBirth
            existing.biologicalSex = biologicalSex.rawValue
            existing.height = heightInMeters
            existing.weight = weightInKg
            existing.unitPreference = unitPreference.rawValue
            existing.updatedAt = Date()
        } else {
            let profile = UserProfile(
                dateOfBirth: dateOfBirth,
                biologicalSex: biologicalSex.rawValue,
                height: heightInMeters,
                weight: weightInKg,
                unitPreference: unitPreference.rawValue
            )
            modelContext.insert(profile)
        }

        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    PersonalInfoView(
        canAdvance: .constant(true),
        onAdvanceAction: .constant(nil)
    )
    .modelContainer(for: UserProfile.self, inMemory: true)
}
