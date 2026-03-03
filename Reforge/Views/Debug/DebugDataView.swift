import SwiftUI
import SwiftData

struct DebugDataView: View {

    enum DebugTab: String, CaseIterable {
        case dailySummary = "Daily Summary"
        case claudeData = "Claude Data"
        case stats = "Stats"
    }

    @State private var selectedTab: DebugTab = .dailySummary

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch selectedTab {
            case .dailySummary:
                DailySummaryBrowserView()
            case .claudeData:
                AggregatedDataView()
            case .stats:
                DataStatsView()
            }
        }
        .navigationTitle("Debug Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DebugDataView()
    }
    .modelContainer(for: [
        DailySummary.self,
        WorkoutSummary.self,
        UserProfile.self,
        HealthInsight.self,
    ], inMemory: true)
}
