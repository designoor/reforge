import SwiftUI

struct DebugDataView: View {
    var body: some View {
        Text("Debug data coming soon.")
            .foregroundStyle(.secondary)
            .navigationTitle("Debug Data")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DebugDataView()
    }
}
