import SwiftUI
import SwiftData

struct PlanGenerationView: View {
    var viewModel: OnboardingViewModel
    var existingProfile: UserProfile?
    @Environment(\.modelContext) private var modelContext

    @State private var phase: GenerationPhase = .generating
    @State private var savedProfile: UserProfile?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            switch phase {
            case .generating:
                ProgressView()
                    .controlSize(.large)

                Text("Building your plan...")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Analyzing your goals and preferences")
                    .foregroundStyle(.secondary)

            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))

                Text("You're all set!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your personalized plan is ready.")
                    .foregroundStyle(.secondary)

            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange)
                    .transition(.scale.combined(with: .opacity))

                Text("Something went wrong")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button("Try Again") {
                    withAnimation {
                        phase = .generating
                    }
                    Task {
                        await generatePlan()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .task {
            await generatePlan()
        }
    }

    private func generatePlan() async {
        guard case .generating = phase else { return }

        // Reuse a previously saved profile, accept an existing one, or create new
        let profile: UserProfile
        if let saved = savedProfile {
            profile = saved
        } else if let existing = existingProfile {
            profile = existing
            savedProfile = existing
        } else {
            let newProfile = viewModel.saveProfile(context: modelContext)
            savedProfile = newProfile
            profile = newProfile
        }

        let payload = viewModel.toPromptPayload()

        do {
            let planResponse = try await ClaudeAPIService.shared.generatePlan(from: payload)
            try PlanMapper.mapToPlan(from: planResponse, for: profile, context: modelContext)

            withAnimation {
                phase = .complete
            }
        } catch {
            withAnimation {
                phase = .failed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Generation Phase

extension PlanGenerationView {
    enum GenerationPhase: Equatable {
        case generating
        case complete
        case failed(String)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, Plan.self, WorkoutDay.self, Exercise.self,
        MealPlan.self, Meal.self, WorkoutSession.self, SetLog.self,
        WeightEntry.self, MeasurementEntry.self, StreakRecord.self,
        configurations: config
    )

    PlanGenerationView(viewModel: OnboardingViewModel())
        .modelContainer(container)
}
