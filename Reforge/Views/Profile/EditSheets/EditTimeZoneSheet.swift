import SwiftUI

struct EditTimeZoneSheet: View {
    let currentTimeZone: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filteredTimeZones: [String] {
        let all = TimeZone.knownTimeZoneIdentifiers.sorted()
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredTimeZones, id: \.self) { tz in
                Button {
                    onSave(tz)
                    dismiss()
                } label: {
                    HStack {
                        Text(tz)
                            .foregroundStyle(.primary)
                        Spacer()
                        if tz == currentTimeZone {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search time zones")
            .navigationTitle("Time Zone")
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
    EditTimeZoneSheet(currentTimeZone: TimeZone.current.identifier, onSave: { _ in })
}
