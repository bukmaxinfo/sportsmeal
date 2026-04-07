import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKey: String = ""
    @State private var isKeyVisible = false
    @State private var showingSaveConfirmation = false
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    @Environment(\.dismiss) private var dismiss

    enum ValidationResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                Text("SportsMeal uses the Claude API to analyze meal photos. You'll need an Anthropic API key to use this feature.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Section("API Key") {
                HStack {
                    if isKeyVisible {
                        TextField("sk-ant-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-ant-...", text: $apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Button {
                        isKeyVisible.toggle()
                    } label: {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                if let result = validationResult {
                    switch result {
                    case .success:
                        Label("API key is valid", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.positive)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.negative)
                    }
                }
            }

            Section {
                Button {
                    Task { await validateAndSave() }
                } label: {
                    HStack {
                        Spacer()
                        if isValidating {
                            ProgressView()
                                .tint(AppTheme.gold)
                                .padding(.trailing, 8)
                            Text("Validating...")
                                .foregroundStyle(AppTheme.gold)
                        } else {
                            Text("Save API Key")
                                .foregroundStyle(AppTheme.gold)
                                .bold()
                        }
                        Spacer()
                    }
                }
                .disabled(apiKey.isEmpty || isValidating)

                if APIConfig.hasAPIKey {
                    Button(role: .destructive) {
                        APIConfig.anthropicAPIKey = nil
                        apiKey = ""
                        validationResult = nil
                    } label: {
                        HStack {
                            Spacer()
                            Text("Remove API Key")
                            Spacer()
                        }
                    }
                }
            }

            Section {
                Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                    Label("Get an API key from Anthropic", systemImage: "arrow.up.right.square")
                        .foregroundStyle(AppTheme.gold)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("API Key")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let existing = APIConfig.anthropicAPIKey {
                apiKey = existing
            }
        }
        .alert("API Key Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your API key has been securely stored in the Keychain.")
        }
    }

    private func validateAndSave() async {
        isValidating = true
        validationResult = nil

        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("sk-ant-") else {
            validationResult = .failure("Key should start with 'sk-ant-'")
            isValidating = false
            return
        }

        do {
            var request = URLRequest(url: URL(string: APIConfig.anthropicBaseURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.setValue(trimmed, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let body: [String: Any] = [
                "model": APIConfig.model,
                "max_tokens": 1,
                "messages": [["role": "user", "content": "hi"]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    APIConfig.anthropicAPIKey = trimmed
                    validationResult = .success
                    showingSaveConfirmation = true
                } else if http.statusCode == 401 {
                    validationResult = .failure("Invalid API key")
                } else {
                    APIConfig.anthropicAPIKey = trimmed
                    validationResult = .success
                    showingSaveConfirmation = true
                }
            }
        } catch {
            validationResult = .failure("Network error: \(error.localizedDescription)")
        }
        isValidating = false
    }
}

#Preview {
    NavigationStack {
        APIKeySettingsView()
    }
    .preferredColorScheme(.dark)
}
