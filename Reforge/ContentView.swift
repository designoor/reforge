import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                DashboardPlaceholderView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}

// MARK: - Placeholder Views (replaced in later steps)

private struct DashboardPlaceholderView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Text("Dashboard")
                .font(.largeTitle.bold())

            Text("Welcome to Reforge")
                .font(.title2)
                .foregroundStyle(.secondary)

            Button("Reset Onboarding") {
                appState.isOnboardingComplete = false
                appState.currentOnboardingStep = 0
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview("Onboarding") {
    ContentView()
        .environment(AppState())
}

#Preview("Dashboard") {
    let state = AppState()
    state.isOnboardingComplete = true
    return ContentView()
        .environment(state)
}
