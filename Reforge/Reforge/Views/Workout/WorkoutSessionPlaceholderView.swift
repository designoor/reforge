import SwiftUI

struct WorkoutSessionPlaceholderView: View {
    let workout: WorkoutDay

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text(workout.title)
                .font(.title)
                .fontWeight(.bold)

            HStack(spacing: 24) {
                Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                Label("\(workout.estimatedMinutes) min", systemImage: "clock")
            }
            .foregroundStyle(.secondary)

            Text("Coming in Step 1.6")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
