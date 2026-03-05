import SwiftUI
import SwiftData

struct LogWeightSheet: View {
    let initialDate: Date
    let unitPreference: UnitPreference
    let initialWeightKg: Double
    let dailySummaries: [DailySummary]
    let profile: UserProfile?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date
    @State private var weightText: String = ""
    @State private var showDatePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        initialDate: Date,
        unitPreference: UnitPreference,
        initialWeightKg: Double,
        dailySummaries: [DailySummary],
        profile: UserProfile?
    ) {
        self.initialDate = initialDate
        self.unitPreference = unitPreference
        self.initialWeightKg = initialWeightKg
        self.dailySummaries = dailySummaries
        self.profile = profile
        _selectedDate = State(initialValue: initialDate)
    }

    private var placeholderText: String {
        if unitPreference == .metric {
            String(format: "%.1f", initialWeightKg)
        } else {
            String(format: "%.1f", UnitConverter.lbsFromKg(initialWeightKg))
        }
    }

    private var unitLabel: String {
        unitPreference == .metric ? "kg" : "lbs"
    }

    private var parsedWeight: Double? {
        guard let w = Double(weightText), w > 0 else { return nil }
        return w
    }

    private var weightInKg: Double? {
        guard let w = parsedWeight else { return nil }
        return unitPreference == .metric ? w : UnitConverter.kgFromLbs(w)
    }

    private var isValid: Bool {
        parsedWeight != nil
    }

    private var validationMessage: String? {
        guard !weightText.isEmpty else { return nil }
        if Double(weightText) == nil {
            return "Enter a valid number"
        }
        if let w = Double(weightText), w <= 0 {
            return "Weight must be greater than zero"
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Date row
                Button {
                    withAnimation { showDatePicker.toggle() }
                } label: {
                    HStack {
                        Text("Date")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                    }
                }

                if showDatePicker {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }

                // Weight input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField(placeholderText, text: $weightText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                        Text(unitLabel)
                            .foregroundStyle(.secondary)
                    }

                    if let msg = validationMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid || isSaving)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func save() {
        guard let kg = weightInKg else { return }
        isSaving = true
        errorMessage = nil

        Task {
            // 1. Write to HealthKit (best-effort)
            do {
                try await HealthKitManager.saveWeight(kg, date: selectedDate)
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't save to Apple Health. You can enable write access in Settings > Health > Reforge."
                }
            }

            // 2. Update UserProfile weight
            await MainActor.run {
                profile?.weight = kg
                profile?.updatedAt = Date()
            }

            // 3. Update or create DailySummary
            await MainActor.run {
                let normalized = DateHelpers.startOfDay(for: selectedDate)
                if let existing = dailySummaries.first(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: normalized)
                }) {
                    existing.bodyMass = kg
                    existing.updatedAt = Date()
                } else {
                    let newSummary = DailySummary(date: normalized, bodyMass: kg)
                    modelContext.insert(newSummary)
                }

                try? modelContext.save()
                isSaving = false

                if errorMessage == nil {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    LogWeightSheet(
        initialDate: Date(),
        unitPreference: .metric,
        initialWeightKg: 70.0,
        dailySummaries: [],
        profile: nil
    )
}
