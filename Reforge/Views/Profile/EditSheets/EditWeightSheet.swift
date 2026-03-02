import SwiftUI

struct EditWeightSheet: View {
    let initialWeightKg: Double
    let unitPreference: UnitPreference
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editWeightDisplay: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    TextField("Weight", text: $editWeightDisplay)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Text(unitPreference == .metric ? "kg" : "lbs")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled({
                            guard let w = Double(editWeightDisplay), w > 0 else { return true }
                            return false
                        }())
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { initEditor() }
    }

    private func initEditor() {
        if unitPreference == .metric {
            editWeightDisplay = String(format: "%.1f", initialWeightKg)
        } else {
            editWeightDisplay = String(format: "%.1f", UnitConverter.lbsFromKg(initialWeightKg))
        }
    }

    private func save() {
        guard let w = Double(editWeightDisplay), w > 0 else { return }
        let kg: Double
        if unitPreference == .metric {
            kg = w
        } else {
            kg = UnitConverter.kgFromLbs(w)
        }
        onSave(kg)
        dismiss()
    }
}

#Preview {
    EditWeightSheet(initialWeightKg: 70.0, unitPreference: .metric, onSave: { _ in })
}
