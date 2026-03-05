import SwiftUI
import SwiftData

struct BackfillProgressView: View {
    @Binding var canAdvance: Bool
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var phase: BackfillPhase = .idle

    private enum BackfillPhase {
        case idle
        case importing(daysProcessed: Int, totalDays: Int)
        case complete(dayCount: Int)
        case noData
        case error(String)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            iconSection
            titleSection
            progressSection
            infoNote

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            startBackfill()
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Group {
            switch phase {
            case .idle, .importing:
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
            case .complete:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            case .noData:
                Image(systemName: "tray")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 8) {
            switch phase {
            case .idle:
                Text("Preparing Import")
                    .font(.largeTitle.bold())
                Text("Getting ready to import your health history...")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case .importing(let daysProcessed, let totalDays):
                Text("Importing Health Data")
                    .font(.largeTitle.bold())
                Text("Importing your health history…\n\(daysProcessed) of \(totalDays) days processed")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case .complete(let dayCount):
                Text("Import Complete")
                    .font(.largeTitle.bold())
                Text("\(dayCount) days of health data imported successfully.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case .noData:
                Text("No Historical Data")
                    .font(.largeTitle.bold())
                Text("No historical data found. We'll start collecting from today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

            case .error(let message):
                Text("Import Error")
                    .font(.largeTitle.bold())
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Progress

    @ViewBuilder
    private var progressSection: some View {
        switch phase {
        case .idle:
            ProgressView()
                .controlSize(.large)
                .padding(.top, 8)

        case .importing(let daysProcessed, let totalDays):
            VStack(spacing: 12) {
                ProgressView(
                    value: Double(daysProcessed),
                    total: Double(totalDays)
                )
                .tint(Color.accentColor)

                Text("\(Int((Double(daysProcessed) / Double(totalDays)) * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

        case .complete:
            EmptyView()

        case .noData:
            EmptyView()

        case .error:
            Button("Continue Anyway") {
                completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)
        }
    }

    // MARK: - Info Note

    @ViewBuilder
    private var infoNote: some View {
        switch phase {
        case .idle, .importing:
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.accentColor)
                    .font(.footnote)
                Text("This is a one-time import. Daily updates happen automatically.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        default:
            EmptyView()
        }
    }

    // MARK: - Logic

    private func startBackfill() {
        Task {
            do {
                guard HealthKitManager.isAvailable() else {
                    phase = .noData
                    scheduleTransition()
                    return
                }

                guard let earliestDate = try await HealthKitManager.getEarliestSampleDate() else {
                    phase = .noData
                    scheduleTransition()
                    return
                }

                let startDate = DateHelpers.startOfDay(for: earliestDate)
                let endDate = DateHelpers.yesterday()

                guard startDate <= endDate else {
                    phase = .noData
                    scheduleTransition()
                    return
                }

                try await HealthDataAggregator.backfillHistory(
                    from: startDate,
                    to: endDate,
                    context: modelContext
                ) { daysProcessed, totalDays in
                    Task { @MainActor in
                        phase = .importing(
                            daysProcessed: daysProcessed,
                            totalDays: totalDays
                        )
                    }
                }

                let totalDays = Calendar.current.dateComponents(
                    [.day], from: startDate, to: endDate
                ).day.map { $0 + 1 } ?? 0

                phase = .complete(dayCount: totalDays)
                scheduleTransition()

            } catch {
                phase = .error("Something went wrong: \(error.localizedDescription)")
            }
        }
    }

    private func scheduleTransition() {
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        BackgroundTaskManager.scheduleNextCollection()
        appState.isOnboardingComplete = true
    }
}

#Preview {
    BackfillProgressView(canAdvance: .constant(false))
        .environment(AppState())
        .modelContainer(for: DailySummary.self, inMemory: true)
}
