import SwiftUI

struct EditWakeTimeSheet: View {
    @Binding var wakeTime: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "Wake Time",
                selection: $wakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding()
            .navigationTitle("Wake Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    EditWakeTimeSheet(wakeTime: .constant(Date()))
}
