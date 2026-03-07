import SwiftUI

struct NotificationPermissionView: View {
    @Binding var canAdvance: Bool

    @State private var isRequesting = false
    @State private var hasRequested = false
    @State private var permissionStatus: PermissionStatus?

    private enum PermissionStatus {
        case granted
        case denied
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                benefitsList
                privacyNote

                if let status = permissionStatus {
                    statusMessage(for: status)
                } else {
                    enableButton
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .onAppear {
            canAdvance = false
            checkCurrentStatus()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("Notifications")
                .font(.largeTitle.bold())

            Text("Reforge sends you a daily notification when your health insights are ready.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You'll be notified when:")
                .font(.headline)

            benefitRow(icon: "chart.bar.doc.horizontal.fill", text: "Your daily health insights are ready")
            benefitRow(icon: "exclamationmark.circle.fill", text: "Notable changes in your health trends")
            benefitRow(icon: "lightbulb.fill", text: "New personalized recommendations")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.raised.fill")
                .foregroundStyle(Color.accentColor)
                .font(.footnote)
            Text("Notifications are fully customizable in the app.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var enableButton: some View {
        Button {
            requestAuthorization()
        } label: {
            if isRequesting {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Enable Notifications")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isRequesting)
        .padding(.top, 8)
    }

    private func statusMessage(for status: PermissionStatus) -> some View {
        HStack(spacing: 8) {
            switch status {
            case .granted:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("Notifications enabled")
                    .font(.body)
                    .foregroundStyle(.secondary)
            case .denied:
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                Text("Notifications denied — you can enable them later in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            Text(text)
                .font(.body)
        }
    }

    private func checkCurrentStatus() {
        Task {
            if await NotificationManager.isPermissionGranted() {
                permissionStatus = .granted
                canAdvance = true
            }
        }
    }

    private func requestAuthorization() {
        isRequesting = true
        Task {
            let granted = await NotificationManager.requestPermission()
            permissionStatus = granted ? .granted : .denied
            isRequesting = false
            canAdvance = true
        }
    }
}

#Preview {
    NotificationPermissionView(canAdvance: .constant(false))
}
