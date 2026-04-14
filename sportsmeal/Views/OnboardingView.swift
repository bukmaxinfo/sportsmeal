import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var name = ""
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var heightCm = 170.0
    @State private var weightKg = 70.0
    @State private var sex: Sex = .male
    @State private var activityLevel: ActivityLevel = .moderate

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { step in
                        Capsule()
                            .fill(step <= currentStep ? AppTheme.gold : AppTheme.surfaceLight)
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    bodyInfoStep.tag(1)
                    apiKeyStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
        }
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 100, height: 100)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(spacing: 10) {
                Text("SportsMeal")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Photo your meal.\nGet calories & macros instantly.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Text("What should we call you?")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textTertiary)

                TextField("Your name", text: $name)
                    .padding()
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button { withAnimation { currentStep += 1 } } label: {
                Text("Continue")
                    .luxuryButton()
            }
            .padding(.horizontal, 24)
        }
        .padding()
    }

    // MARK: - Step 2: Body Info + Activity
    private var bodyInfoStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("About You")
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach(Sex.allCases, id: \.self) { s in
                        Button {
                            sex = s
                        } label: {
                            Text(s.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(sex == s ? AppTheme.gold : AppTheme.surfaceLight)
                                .foregroundStyle(sex == s ? .black : AppTheme.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Date of Birth")
                        .foregroundStyle(AppTheme.textSecondary)
                    DatePicker("", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.gold)
                }

                onboardingField(label: "Height") {
                    HStack {
                        TextField("cm", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("cm")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                onboardingField(label: "Weight") {
                    HStack {
                        TextField("kg", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("kg")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Activity Level")
                        .foregroundStyle(AppTheme.textSecondary)
                    Picker("Activity", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .luxuryCard()
            .padding(.horizontal, 16)

            // Live calorie budget preview
            if heightCm > 0 && weightKg > 0 {
                let computedBMR = computeBMR()
                VStack(spacing: 4) {
                    Text("Your daily calorie budget")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                    HStack(spacing: 4) {
                        Text("~\(Int(computedBMR))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.gold)
                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Text("Based on your BMR — we'll track against this")
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .luxuryCard(padding: 12)
                .padding(.horizontal, 16)
                .animation(.easeInOut, value: computedBMR)
            }

            Spacer()

            HStack {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
                .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button { withAnimation { currentStep += 1 } } label: {
                    Text("Continue")
                        .font(.headline)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(AppTheme.goldGradient)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
        }
        .padding()
    }

    // MARK: - Step 3: API Key
    private var apiKeyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 100, height: 100)
                Image(systemName: "key.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(spacing: 10) {
                Text("Almost There!")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("SportsMeal uses Claude AI to analyze your meals.\nBring your own Anthropic API key to enable AI features and control your own usage costs.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                NavigationLink {
                    APIKeySettingsView()
                } label: {
                    Label("Set Up API Key", systemImage: "key.fill")
                        .luxuryButton()
                }

                Button {
                    saveProfile()
                } label: {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .padding(.horizontal, 24)

            if APIConfig.hasAPIKey {
                Label("API key configured!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.positive)
                    .font(.subheadline.weight(.semibold))

                Button { saveProfile() } label: {
                    Text("Get Started")
                        .luxuryButton()
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers
    private func onboardingField<Content: View>(label: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            trailing()
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private func computeBMR() -> Double {
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }

    private func saveProfile() {
        let profile = UserProfile(
            name: name,
            dateOfBirth: dateOfBirth,
            heightCm: heightCm,
            weightKg: weightKg,
            sex: sex,
            activityLevel: activityLevel
        )
        modelContext.insert(profile)
        onComplete()
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
        .preferredColorScheme(.dark)
}
