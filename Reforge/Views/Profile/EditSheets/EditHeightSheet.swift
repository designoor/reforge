import SwiftUI

struct EditHeightSheet: View {
    let initialHeightMeters: Double
    let unitPreference: UnitPreference
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editHeightCm: String = ""
    @State private var editHeightFeet: Int = 5
    @State private var editHeightInches: Int = 7

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if unitPreference == .metric {
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
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { initEditor() }
    }

    private func initEditor() {
        if unitPreference == .metric {
            editHeightCm = String(format: "%.0f", initialHeightMeters * 100.0)
        } else {
            let (feet, inches) = UnitConverter.feetInchesFromMeters(initialHeightMeters)
            editHeightFeet = feet
            editHeightInches = inches
        }
    }

    private func save() {
        let meters: Double
        if unitPreference == .metric {
            meters = (Double(editHeightCm) ?? 1.70) / 100.0
        } else {
            meters = UnitConverter.metersFromFeetInches(feet: editHeightFeet, inches: editHeightInches)
        }
        onSave(meters)
        dismiss()
    }
}

#Preview {
    EditHeightSheet(initialHeightMeters: 1.75, unitPreference: .metric, onSave: { _ in })
}
