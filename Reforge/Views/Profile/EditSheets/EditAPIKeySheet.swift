import SwiftUI

struct EditAPIKeySheet: View {
    let initialAPIKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var editAPIKey: String = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?

    private enum ValidationResult {
        case success
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                SecureField("sk-ant-...", text: $editAPIKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

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
                .disabled(editAPIKey.count < 10 || isValidating)

                if let result = validationResult {
                    switch result {
                    case .success:
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title3)
                            Text("API key is valid")
                                .foregroundStyle(.secondary)
                        }
                    case .failure(let message):
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.title3)
                            Text(message)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

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

                Spacer()
            }
            .padding(24)
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editAPIKey)
                        dismiss()
                    }
                    .disabled(editAPIKey.count < 10)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { editAPIKey = initialAPIKey }
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
        request.setValue(editAPIKey, forHTTPHeaderField: "x-api-key")
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
    EditAPIKeySheet(initialAPIKey: "", onSave: { _ in })
}
