import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots (hidden on Welcome)
            if viewModel.currentStep > 0 {
                ProgressDotsView(
                    currentStep: viewModel.currentStep,
                    totalSteps: OnboardingViewModel.totalSteps
                )
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            // Step content
            Group {
                switch viewModel.currentStep {
                case 0:
                    WelcomeView { advanceStep() }
                case 1:
                    BodyStatsView(viewModel: viewModel)
                case 2:
                    GoalsView(viewModel: viewModel)
                case 3:
                    LifestyleView(viewModel: viewModel)
                case 4:
                    PlanGenerationView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
            .id(viewModel.currentStep)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation buttons (hidden on Welcome and PlanGeneration)
            if viewModel.currentStep > 0 && viewModel.currentStep < 4 {
                HStack {
                    Button("Back") { retreatStep() }
                        .buttonStyle(.bordered)

                    Spacer()

                    Button("Next") { advanceStep() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canProceed)
                }
                .padding()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    private func advanceStep() {
        guard viewModel.currentStep < OnboardingViewModel.totalSteps - 1 else { return }
        withAnimation {
            viewModel.currentStep += 1
        }
    }

    private func retreatStep() {
        guard viewModel.currentStep > 0 else { return }
        withAnimation {
            viewModel.currentStep -= 1
        }
    }
}

// MARK: - Progress Dots

private struct ProgressDotsView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == currentStep ? 10 : 8,
                           height: index == currentStep ? 10 : 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }
}

#Preview {
    OnboardingContainerView()
}
