import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthService.self) private var authService
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                logoSection
                Spacer()
                featureList
                    .padding(.horizontal, 24)
                Spacer()
                signInSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
            }
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 112, height: 112)
                Circle()
                    .strokeBorder(AppTheme.gold.opacity(0.25), lineWidth: 1)
                    .frame(width: 112, height: 112)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(AppTheme.goldGradient)
            }

            VStack(spacing: 8) {
                Text("SportsMeal")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("AI-powered nutrition for athletes")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - Feature Highlights

    private var featureList: some View {
        VStack(spacing: 10) {
            featureRow(
                icon: "camera.viewfinder",
                title: "Snap to Track",
                subtitle: "Photograph any meal for instant AI analysis"
            )
            featureRow(
                icon: "chart.bar.xaxis.ascending.badge.clock",
                title: "Smart Macros",
                subtitle: "Personalised targets based on your body & goals"
            )
            featureRow(
                icon: "person.crop.circle.badge.checkmark",
                title: "Private Account Sync",
                subtitle: "Sign in with Apple and keep your account data private"
            )
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.gold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .luxuryCard()
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 14) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.negative)
                    .multilineTextAlignment(.center)
            }

            if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white)
                        .frame(height: 50)
                    ProgressView()
                        .tint(Color(white: 0.2))
                }
            } else {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success:
                        isLoading = true
                        errorMessage = nil
                        Task {
                            await authService.handleAppleSignIn(result)
                            isLoading = false
                        }
                    case .failure(let error):
                        let code = (error as? ASAuthorizationError)?.code
                        if code != .canceled {
                            errorMessage = "Apple Sign-In failed. Please try again."
                        }
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Text("Sign in with Apple keeps your account private. Most data stays on your device, and limited account data may sync through your private iCloud storage.")
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
        .preferredColorScheme(.dark)
}
