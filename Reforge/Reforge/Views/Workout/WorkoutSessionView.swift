import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WorkoutSessionViewModel

    init(workout: WorkoutDay) {
        _viewModel = State(initialValue: WorkoutSessionViewModel(workoutDay: workout))
    }

    var body: some View {
        ZStack {
            // Main content
            mainContent
                .blur(radius: viewModel.isResting ? 6 : 0)
                .allowsHitTesting(!viewModel.isResting)

            // Rest timer overlay
            if viewModel.isResting {
                restTimerOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    viewModel.showEndWorkoutConfirmation = true
                }
                .foregroundStyle(.red)
            }
        }
        .confirmationDialog(
            "End Workout?",
            isPresented: $viewModel.showEndWorkoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Workout", role: .destructive) {
                viewModel.endWorkoutEarly(context: modelContext)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if viewModel.setLogs.isEmpty {
                Text("No sets have been logged. This workout won't be saved.")
            } else {
                Text("Your \(viewModel.setLogs.count) logged sets will be saved.")
            }
        }
        .fullScreenCover(isPresented: $viewModel.showSummary) {
            if let summary = viewModel.summary {
                WorkoutSummaryView(summary: summary, viewModel: viewModel) {
                    viewModel.showSummary = false
                    dismiss()
                }
                .environment(\.modelContext, modelContext)
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            // Early end with no sets — dismiss directly
            if complete && !viewModel.showSummary {
                dismiss()
            }
        }
        .onAppear {
            viewModel.startSession()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer()

            // Exercise info
            exerciseInfoCard
                .padding(.horizontal)

            Spacer()

            // Rep input
            repInput
                .padding(.horizontal)

            // Log set button
            logSetButton
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            if let exercise = viewModel.currentExercise {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.bold)

                Text("Set \(viewModel.currentSetNumber) of \(exercise.sets)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: viewModel.progress)
                .tint(.accentColor)

            HStack {
                Text("\(viewModel.completedSets) of \(viewModel.totalSets) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Exercise Info Card

    private var exerciseInfoCard: some View {
        VStack(spacing: 12) {
            if let exercise = viewModel.currentExercise {
                // 3D model view
                ExerciseModelView(
                    modelId: exercise.modelId,
                    isPlaying: !viewModel.isResting
                )
                .frame(height: UIScreen.main.bounds.height * 0.3)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if !exercise.formCues.isEmpty {
                    Text(exercise.formCues)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("Target: \(exercise.targetReps)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Rep Input

    private var repInput: some View {
        VStack(spacing: 16) {
            if viewModel.isTimeBased {
                // Time-based exercise
                Text("Completed Hold")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                // Rep-based exercise
                Text("Reps Completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 32) {
                    Button {
                        if viewModel.selectedReps > 1 {
                            viewModel.selectedReps -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(viewModel.selectedReps)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .frame(minWidth: 80)

                    Button {
                        viewModel.selectedReps += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }

                // Quick-tap presets
                if let exercise = viewModel.currentExercise {
                    let target = WorkoutSessionViewModel.parseDefaultReps(from: exercise.targetReps)
                    HStack(spacing: 12) {
                        ForEach([target - 1, target, target + 1], id: \.self) { preset in
                            if preset >= 1 {
                                Button {
                                    viewModel.selectedReps = preset
                                } label: {
                                    Text("\(preset)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            viewModel.selectedReps == preset
                                                ? Color.accentColor.opacity(0.2)
                                                : Color.secondary.opacity(0.1)
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Log Set Button

    private var logSetButton: some View {
        Button {
            viewModel.logSet(context: modelContext)
        } label: {
            Text(viewModel.isLastSetOfSession ? "Finish Workout" : "Log Set")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Rest Timer Overlay

    private var restTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Rest")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 160, height: 160)

                    if let exercise = viewModel.currentExercise, exercise.restSeconds > 0 {
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.restTimeRemaining) / CGFloat(exercise.restSeconds))
                            .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: viewModel.restTimeRemaining)
                    }

                    Text("\(viewModel.restTimeRemaining)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Button {
                    viewModel.skipRest()
                } label: {
                    Text("Skip")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
