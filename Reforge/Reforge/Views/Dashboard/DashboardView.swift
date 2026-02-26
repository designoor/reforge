import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Greeting
                greetingSection

                // MARK: - Today's Workout Card
                todayWorkoutCard

                // MARK: - Weekly Progress
                weeklyProgressSection

                // MARK: - Streak Banner
                if let streak = viewModel.streak, streak.currentStreak >= 3 {
                    streakBanner(streak: streak)
                }
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadDashboard(context: modelContext)
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.greeting), \(viewModel.userName).")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Day \(viewModel.dayNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let streak = viewModel.streak, streak.currentStreak >= 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak.currentStreak)")
                        .fontWeight(.semibold)
                }
                .font(.title3)
            }
        }
    }

    // MARK: - Today's Workout Card

    private var todayWorkoutCard: some View {
        Group {
            if let workout = viewModel.todaysWorkout {
                NavigationLink {
                    WorkoutSessionPlaceholderView(workout: workout)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: iconForWorkoutType(workout.type))
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.title)
                                .font(.headline)
                            HStack(spacing: 12) {
                                Label("\(workout.exercises.count) exercises", systemImage: "figure.strengthtraining.functional")
                                Label("\(workout.estimatedMinutes) min", systemImage: "clock")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            } else {
                // Rest day card
                HStack(spacing: 16) {
                    Image(systemName: "bed.double.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.green.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest Day")
                            .font(.headline)
                        Text("Recovery is part of the plan. Take it easy today.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Weekly Progress Dots

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 0) {
                ForEach(viewModel.weeklyDayStatuses) { status in
                    VStack(spacing: 6) {
                        ZStack {
                            if status.isCompleted {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            } else if status.isToday {
                                Circle()
                                    .fill(.tint)
                                    .frame(width: 28, height: 28)
                                    .modifier(PulsingModifier())
                            } else {
                                Circle()
                                    .strokeBorder(.gray.opacity(0.4), lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }
                        }

                        Text(dayAbbreviation(for: status.dayOfWeek))
                            .font(.caption2)
                            .foregroundStyle(status.isToday ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Streak Banner

    private func streakBanner(streak: StreakRecord) -> some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title2)
            Text("\(streak.currentStreak)-day streak!")
                .font(.headline)
            Spacer()
        }
        .foregroundStyle(.white)
        .padding()
        .background(
            LinearGradient(
                colors: [.orange, .red],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func iconForWorkoutType(_ type: String) -> String {
        switch type {
        case ExerciseType.upperPush.rawValue:
            return "figure.arms.open"
        case ExerciseType.upperPull.rawValue:
            return "figure.rowing"
        case ExerciseType.lowerBody.rawValue:
            return "figure.walk"
        case ExerciseType.core.rawValue:
            return "figure.core.training"
        case ExerciseType.cardio.rawValue:
            return "figure.run"
        case ExerciseType.fullBodyHIIT.rawValue:
            return "figure.highintensity.intervaltraining"
        case ExerciseType.warmup.rawValue:
            return "figure.flexibility"
        case ExerciseType.cooldown.rawValue:
            return "figure.cooldown"
        default:
            return "figure.strengthtraining.functional"
        }
    }

    private func dayAbbreviation(for dayOfWeek: Int) -> String {
        switch dayOfWeek {
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        case 7: return "Sun"
        default: return "?"
        }
    }
}

// MARK: - Pulsing Animation Modifier

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
