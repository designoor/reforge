import SwiftUI

// MARK: - OnboardingStep

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case personalInfo = 1
    case schedule = 2
    case healthKitPermission = 3
    case apiKey = 4
    case notificationPermission = 5
    case backfillProgress = 6

    var title: String {
        switch self {
        case .welcome: "Welcome"
        case .personalInfo: "Personal Info"
        case .schedule: "Schedule"
        case .healthKitPermission: "HealthKit Access"
        case .apiKey: "API Key"
        case .notificationPermission: "Notifications"
        case .backfillProgress: "Setup"
        }
    }

    var showsBackButton: Bool {
        self != .welcome && self != .backfillProgress
    }

    var showsNextButton: Bool {
        self != .backfillProgress
    }

    var nextButtonTitle: String {
        switch self {
        case .welcome: "Get Started"
        default: "Next"
        }
    }
}

// MARK: - OnboardingContainerView

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState

    @State private var currentStep = 0
    @State private var canAdvance = true
    @State private var navigationDirection: NavigationDirection = .forward

    private enum NavigationDirection {
        case forward, backward
    }

    private var step: OnboardingStep {
        OnboardingStep(rawValue: currentStep) ?? .welcome
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome && step != .backfillProgress {
                progressIndicator
                    .padding(.top, 8)
            }

            currentStepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(transition)
                .id(currentStep)

            if step.showsNextButton {
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            currentStep = appState.currentOnboardingStep
        }
        .onChange(of: currentStep) { _, newValue in
            appState.currentOnboardingStep = newValue
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .welcome:
            WelcomeView(canAdvance: $canAdvance)
        case .personalInfo:
            OnboardingStepPlaceholder(step: .personalInfo, canAdvance: $canAdvance)
        case .schedule:
            OnboardingStepPlaceholder(step: .schedule, canAdvance: $canAdvance)
        case .healthKitPermission:
            OnboardingStepPlaceholder(step: .healthKitPermission, canAdvance: $canAdvance)
        case .apiKey:
            OnboardingStepPlaceholder(step: .apiKey, canAdvance: $canAdvance)
        case .notificationPermission:
            OnboardingStepPlaceholder(step: .notificationPermission, canAdvance: $canAdvance)
        case .backfillProgress:
            OnboardingStepPlaceholder(step: .backfillProgress, canAdvance: $canAdvance)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1..<6, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            if step.showsBackButton {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(step.nextButtonTitle) {
                goForward()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdvance)
        }
    }

    private func goForward() {
        guard canAdvance, currentStep < OnboardingStep.allCases.count - 1 else { return }
        navigationDirection = .forward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
        canAdvance = true
    }

    private func goBack() {
        guard currentStep > 0 else { return }
        navigationDirection = .backward
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
        canAdvance = true
    }

    private var transition: AnyTransition {
        switch navigationDirection {
        case .forward:
            .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }
}

// MARK: - Placeholder (replaced by Steps 5.2–5.8)

struct OnboardingStepPlaceholder: View {
    @Environment(AppState.self) private var appState

    let step: OnboardingStep
    @Binding var canAdvance: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(step.title)
                .font(.largeTitle.bold())

            Text("Screen \(step.rawValue + 1) of 7")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(description)
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if step == .backfillProgress {
                Button("Complete Onboarding") {
                    appState.isOnboardingComplete = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 16)
            }
        }
        .onAppear {
            canAdvance = true
        }
    }

    private var iconName: String {
        switch step {
        case .welcome: "hand.wave"
        case .personalInfo: "person.fill"
        case .schedule: "clock"
        case .healthKitPermission: "heart.fill"
        case .apiKey: "key.fill"
        case .notificationPermission: "bell.fill"
        case .backfillProgress: "arrow.down.circle"
        }
    }

    private var description: String {
        switch step {
        case .welcome: "Welcome screen with value proposition"
        case .personalInfo: "DOB, sex, units, height, weight"
        case .schedule: "Timezone and wake time"
        case .healthKitPermission: "Grant HealthKit access"
        case .apiKey: "Enter Anthropic API key"
        case .notificationPermission: "Enable notifications"
        case .backfillProgress: "Import historical health data"
        }
    }
}

// MARK: - Previews

#Preview {
    OnboardingContainerView()
        .environment(AppState())
}
