import SwiftUI

struct GoalsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Goal")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(GoalType.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: viewModel.goal == goal
                    ) {
                        withAnimation(.snappy) {
                            viewModel.goal = goal
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }
}

private struct GoalCard: View {
    let goal: GoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary), in: Circle())
                    .foregroundStyle(isSelected ? .white : .primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .opacity(isSelected ? 1 : 0)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch goal {
        case .loseFat: "flame.fill"
        case .buildMuscle: "dumbbell.fill"
        case .recomposition: "arrow.triangle.2.circlepath"
        }
    }

    private var title: String {
        switch goal {
        case .loseFat: "Lose Fat"
        case .buildMuscle: "Build Muscle"
        case .recomposition: "Body Recomposition"
        }
    }

    private var description: String {
        switch goal {
        case .loseFat: "Reduce body fat while maintaining lean mass"
        case .buildMuscle: "Gain muscle size and strength"
        case .recomposition: "Simultaneously build muscle and lose fat"
        }
    }
}

#Preview {
    GoalsView(viewModel: OnboardingViewModel())
}
