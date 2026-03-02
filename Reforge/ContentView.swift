import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Today", systemImage: "heart.text.square")
                        }

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                }
            } else {
                OnboardingContainerView()
            }
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
