import SwiftUI

struct HealthKitPermissionView: View {
    @Binding var canAdvance: Bool

    @State private var isRequesting = false
    @State private var hasRequested = false
    @State private var isUnavailable = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                categoriesList
                privacyNote

                if isUnavailable {
                    unavailableMessage
                } else if hasRequested {
                    grantedConfirmation
                } else {
                    grantAccessButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            if HealthKitManager.isAvailable() {
                canAdvance = false
            } else {
                isUnavailable = true
                canAdvance = false
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Health Data Access")
                .font(.largeTitle.bold())

            Text("HealthCoach needs access to your health data to provide personalized insights.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var categoriesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We'll read data from:")
                .font(.headline)

            categoryRow(icon: "figure.run", text: "Activity & Workouts")
            categoryRow(icon: "heart.fill", text: "Heart & Vitals")
            categoryRow(icon: "bed.double.fill", text: "Sleep")
            categoryRow(icon: "lungs.fill", text: "Respiratory")
            categoryRow(icon: "figure.walk", text: "Mobility")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.accentColor)
                .font(.footnote)
            Text("Your data stays on your device. Nothing is shared without your knowledge.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var grantAccessButton: some View {
        Button {
            requestAuthorization()
        } label: {
            if isRequesting {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Grant Access")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isRequesting)
        .padding(.top, 8)
    }

    private var grantedConfirmation: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            Text("Access requested")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }

    private var unavailableMessage: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title3)
            Text("HealthKit is not available on this device.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func categoryRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            Text(text)
                .font(.body)
        }
    }

    private func requestAuthorization() {
        isRequesting = true
        Task {
            try? await HealthKitManager.requestAuthorization()
            isRequesting = false
            hasRequested = true
            canAdvance = true
        }
    }
}

#Preview {
    HealthKitPermissionView(canAdvance: .constant(false))
}
