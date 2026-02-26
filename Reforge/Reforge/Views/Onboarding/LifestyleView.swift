import SwiftUI

struct LifestyleView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Activity Level
                Text("Activity Level")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        ActivityLevelRow(
                            level: level,
                            isSelected: viewModel.activityLevel == level
                        ) {
                            withAnimation(.snappy) {
                                viewModel.activityLevel = level
                            }
                        }
                    }
                }

                Divider()

                // Training Schedule
                Text("Training Schedule")
                    .font(.title2)
                    .fontWeight(.bold)

                Stepper("Days per week: \(viewModel.availableDays)",
                        value: $viewModel.availableDays, in: 3...6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Length").font(.headline)
                    Picker("Session Length", selection: $viewModel.sessionLength) {
                        Text("20 min").tag(20)
                        Text("30 min").tag(30)
                        Text("45 min").tag(45)
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                // Dietary Preferences
                Text("Dietary Preferences")
                    .font(.title2)
                    .fontWeight(.bold)

                FlowLayout(spacing: 8) {
                    ForEach(DietaryRestriction.allCases.filter { $0 != .none }, id: \.self) { restriction in
                        ChipView(
                            title: displayName(for: restriction),
                            isSelected: viewModel.dietaryRestrictions.contains(restriction)
                        ) {
                            toggleRestriction(restriction)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func toggleRestriction(_ restriction: DietaryRestriction) {
        withAnimation(.snappy) {
            if viewModel.dietaryRestrictions.contains(restriction) {
                viewModel.dietaryRestrictions.remove(restriction)
            } else {
                viewModel.dietaryRestrictions.insert(restriction)
            }
        }
    }

    private func displayName(for restriction: DietaryRestriction) -> String {
        switch restriction {
        case .none: "None"
        case .vegetarian: "Vegetarian"
        case .vegan: "Vegan"
        case .glutenFree: "Gluten Free"
        case .dairyFree: "Dairy Free"
        case .lowCarb: "Low Carb"
        }
    }
}

// MARK: - Activity Level Row

private struct ActivityLevelRow: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var title: String {
        switch level {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly Active"
        case .moderatelyActive: "Moderately Active"
        case .active: "Active"
        }
    }

    private var description: String {
        switch level {
        case .sedentary: "Little to no exercise"
        case .lightlyActive: "Light exercise 1-3 days/week"
        case .moderatelyActive: "Moderate exercise 3-5 days/week"
        case .active: "Hard exercise 6-7 days/week"
        }
    }
}

// MARK: - Chip View

private struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : .clear, in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(Capsule().stroke(isSelected ? Color.accentColor : .secondary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}

#Preview {
    LifestyleView(viewModel: OnboardingViewModel())
}
