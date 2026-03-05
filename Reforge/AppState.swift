import SwiftUI

@Observable
final class AppState {
    private static let onboardingKey = "isOnboardingComplete"
    private static let onboardingStepKey = "currentOnboardingStep"

    var isOnboardingComplete: Bool {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: Self.onboardingKey) }
    }

    var currentOnboardingStep: Int {
        didSet { UserDefaults.standard.set(currentOnboardingStep, forKey: Self.onboardingStepKey) }
    }

    var isSyncing: Bool = false

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.currentOnboardingStep = UserDefaults.standard.integer(forKey: Self.onboardingStepKey)
    }
}
