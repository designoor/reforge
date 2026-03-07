import SwiftUI

struct APIKeyView: View {
    @Binding var canAdvance: Bool
    @Binding var onAdvanceAction: (() -> Void)?

    @Environment(\.openURL) private var openURL

    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?

    private enum ValidationResult {
        case success
        case failure(String)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                linkSection
                inputSection
                validateSection
                privacyNote
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if let existing = try? KeychainService.getAPIKey() {
                apiKey = existing
            }
            updateCanAdvance()
            onAdvanceAction = { saveKey() }
        }
        .onChange(of: apiKey) {
            updateCanAdvance()
            validationResult = nil
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)

            Text("API Key")
                .font(.largeTitle.bold())

            Text("Reforge uses Claude AI to analyze your health data. You'll need an Anthropic API key.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var linkSection: some View {
        Button {
            openURL(URL(string: "https://console.anthropic.com/")!)
        } label: {
            HStack(spacing: 4) {
                Text("Get your API key")
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
            }
        }
    }

    private var inputSection: some View {
        SecureField("sk-ant-...", text: $apiKey)
            .textContentType(.password)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var validateSection: some View {
        Button {
            validateKey()
        } label: {
            if isValidating {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("Validate Key")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(apiKey.count < 10 || isValidating)

        if let result = validationResult {
            switch result {
            case .success:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    Text("API key is valid")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            case .failure(let message):
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.accentColor)
                .font(.footnote)
            Text("Your API key is stored securely in the device Keychain.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func updateCanAdvance() {
        canAdvance = apiKey.count >= 10
    }

    private func saveKey() {
        try? KeychainService.saveAPIKey(apiKey)
    }

    private func validateKey() {
        isValidating = true
        validationResult = nil

        Task {
            let result = await performValidation()
            isValidating = false
            validationResult = result
        }
    }

    private func performValidation() async -> ValidationResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            return .failure("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1,
            "messages": [["role": "user", "content": "hi"]],
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return .failure("Failed to build request")
        }

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure("Unexpected response")
            }

            switch httpResponse.statusCode {
            case 200:
                return .success
            case 401:
                return .failure("Invalid API key")
            default:
                return .failure("Error (HTTP \(httpResponse.statusCode))")
            }
        } catch {
            return .failure("Network error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    APIKeyView(canAdvance: .constant(false), onAdvanceAction: .constant(nil))
}
