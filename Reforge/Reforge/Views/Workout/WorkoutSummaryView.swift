import SwiftUI
import SwiftData

struct WorkoutSummaryView: View {
    @Environment(\.modelContext) private var modelContext

    let summary: SessionSummary
    let viewModel: WorkoutSessionViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration header
                    celebrationHeader

                    // Stats grid
                    statsGrid

                    // Personal bests
                    if !summary.personalBests.isEmpty {
                        personalBestsSection
                    }

                    // Difficulty rating
                    difficultySection

                    // Done button
                    doneButton
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Celebration Header

    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.top, 24)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statCard(
                icon: "clock.fill",
                value: formatDuration(summary.duration),
                label: "Duration"
            )
            statCard(
                icon: "figure.strengthtraining.functional",
                value: "\(summary.exercisesCompleted)",
                label: "Exercises"
            )
            statCard(
                icon: "arrow.up.and.down.circle.fill",
                value: "\(summary.totalSets)",
                label: "Total Sets"
            )
            statCard(
                icon: "repeat.circle.fill",
                value: "\(summary.totalReps)",
                label: "Total Reps"
            )
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Personal Bests

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Personal Bests")
                    .font(.headline)
            }

            ForEach(summary.personalBests) { pb in
                HStack {
                    Text(pb.exerciseName)
                        .font(.subheadline)
                    Spacer()
                    if let prev = pb.previousBest {
                        Text("\(prev)")
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("\(pb.reps) reps")
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Difficulty Rating

    private var difficultySection: some View {
        VStack(spacing: 12) {
            Text("How was it?")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(Array(difficultyOptions.enumerated()), id: \.offset) { index, option in
                    let rating = index + 1
                    Button {
                        viewModel.setDifficultyRating(rating, context: modelContext)
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.icon)
                                .font(.title2)
                            Text(option.label)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.difficultyRating == rating
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Done")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var difficultyOptions: [(icon: String, label: String)] {
        [
            ("😌", "Easy"),
            ("🙂", "Okay"),
            ("💪", "Good"),
            ("😤", "Hard"),
            ("🔥", "Brutal")
        ]
    }
}
