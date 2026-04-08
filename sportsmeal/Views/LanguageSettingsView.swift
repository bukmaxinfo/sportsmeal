import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showRestartAlert = false
    @State private var pendingLanguage: AppLanguage?

    var body: some View {
        List {
            Section {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        if language.rawValue != languageManager.selectedLanguage {
                            pendingLanguage = language
                            showRestartAlert = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: language.icon)
                                .font(.title3)
                                .foregroundStyle(AppTheme.gold)
                                .frame(width: 28)
                            Text(language.displayName)
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            if language.rawValue == languageManager.selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.gold)
                            }
                        }
                    }
                }
            } footer: {
                Text("Changing language requires restarting the app to take full effect.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Change Language", isPresented: $showRestartAlert) {
            Button("Change & Restart") {
                if let language = pendingLanguage {
                    languageManager.setLanguage(language)
                    // Force quit so the app relaunches with new language
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        exit(0)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                pendingLanguage = nil
            }
        } message: {
            if let language = pendingLanguage {
                Text("The app will restart to apply \(language.displayName).")
            }
        }
    }
}
