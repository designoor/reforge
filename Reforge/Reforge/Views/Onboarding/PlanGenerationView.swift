import SwiftUI
import SwiftData

struct PlanGenerationView: View {
    var viewModel: OnboardingViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isGenerating = false
    @State private var isComplete = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))

                Text("You're all set!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Your personalized plan is ready.")
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.large)

                Text("Building your plan...")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("Analyzing your goals and preferences")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .task {
            await generatePlan()
        }
    }

    private func generatePlan() async {
        guard !isGenerating else { return }
        isGenerating = true

        // Save profile to SwiftData
        viewModel.saveProfile(context: modelContext)

        // TODO: Replace with ClaudeAPIService.generatePlan() in Step 1.4
        try? await Task.sleep(for: .seconds(2))

        withAnimation {
            isComplete = true
        }
    }
}

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
