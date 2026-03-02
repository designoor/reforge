import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("Debug") {
                    Button("Reset Onboarding") {
                        appState.isOnboardingComplete = false
                        appState.currentOnboardingStep = 0
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
}
