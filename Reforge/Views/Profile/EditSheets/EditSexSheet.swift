import SwiftUI

struct EditSexSheet: View {
    let currentSex: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(BiologicalSexOption.allCases) { option in
                    Button {
                        onSave(option.rawValue)
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if BiologicalSexOption.from(currentSex) == option {
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
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EditSexSheet(currentSex: "male", onSave: { _ in })
}
