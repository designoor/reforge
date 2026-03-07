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
        case .notificationPermission: "Finish"
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
    @State private var onAdvanceAction: (() -> Void)?
    @State private var isTextFieldFocused = false

    private enum NavigationDirection {
        case forward, backward
    }

    private var step: OnboardingStep {
        OnboardingStep(rawValue: currentStep) ?? .welcome
    }

    var body: some View {
        VStack(spacing: 0) {
            currentStepView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(transition)
                .id(currentStep)

            if step.showsNextButton && !isTextFieldFocused {
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
            if newValue != OnboardingStep.personalInfo.rawValue {
                isTextFieldFocused = false
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var currentStepView: some View {
        switch step {
        case .welcome:
            WelcomeView(canAdvance: $canAdvance)
        case .personalInfo:
            PersonalInfoView(canAdvance: $canAdvance, onAdvanceAction: $onAdvanceAction, isTextFieldFocused: $isTextFieldFocused)
        case .schedule:
            ScheduleView(canAdvance: $canAdvance, onAdvanceAction: $onAdvanceAction)
        case .healthKitPermission:
            HealthKitPermissionView(canAdvance: $canAdvance, onGranted: { goForward() })
        case .apiKey:
            APIKeyView(canAdvance: $canAdvance, onAdvanceAction: $onAdvanceAction)
        case .notificationPermission:
            NotificationPermissionView(canAdvance: $canAdvance)
        case .backfillProgress:
            BackfillProgressView(canAdvance: $canAdvance)
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

    @ViewBuilder
    private var navigationButtons: some View {
        if step == .welcome {
            Button {
                goForward()
            } label: {
                Text(step.nextButtonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            ZStack {
                if step != .welcome && step != .backfillProgress {
                    progressIndicator
                }

                HStack {
                    if step.showsBackButton {
                        Button("Back") {
                            goBack()
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if step == .notificationPermission && !canAdvance {
                        Button("Skip") {
                            canAdvance = true
                            goForward()
                        }
                        .buttonStyle(.bordered)
                    } else if (step != .healthKitPermission && step != .apiKey && step != .notificationPermission) || canAdvance {
                        Button(step.nextButtonTitle) {
                            goForward()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canAdvance)
                    }
                }
            }
        }
    }

    private func goForward() {
        guard canAdvance, currentStep < OnboardingStep.allCases.count - 1 else { return }
        onAdvanceAction?()
        onAdvanceAction = nil
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

// MARK: - Previews

#Preview {
    OnboardingContainerView()
        .environment(AppState())
}
