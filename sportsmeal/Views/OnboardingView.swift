import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = 25
    @State private var heightCm = 170.0
    @State private var weightKg = 70.0
    @State private var sex: Sex = .male
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var goalWeightKg = 65.0
    @State private var skipApiKey = false

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicators
                HStack(spacing: 8) {
                    ForEach(0..<5) { step in
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
                    activityStep.tag(2)
                    goalStep.tag(3)
                    apiKeyStep.tag(4)
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

            // Gold icon
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

                Text("AI-powered calorie tracking\nthat fits your lifestyle")
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

    // MARK: - Step 2: Body Info
    private var bodyInfoStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("About You")
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 16) {
                // Sex picker
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

                onboardingField(label: "Age", value: "\(age)") {
                    Stepper("", value: $age, in: 10...120)
                        .labelsHidden()
                }

                onboardingField(label: "Height", value: "") {
                    HStack {
                        TextField("cm", value: $heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("cm")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                onboardingField(label: "Weight", value: "") {
                    HStack {
                        TextField("kg", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                        Text("kg")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
            .luxuryCard()
            .padding(.horizontal, 16)

            Spacer()
            navigationButtons
        }
        .padding()
    }

    // MARK: - Step 3: Activity Level
    private var activityStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Activity Level")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text("How active are you in a typical week?")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 6) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        activityLevel = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(activityLevel == level ? .black : AppTheme.textPrimary)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(activityLevel == level ? .black.opacity(0.6) : AppTheme.textTertiary)
                            }
                            Spacer()
                            if activityLevel == level {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding(12)
                        .background(activityLevel == level ? AppTheme.gold : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(activityLevel == level ? Color.clear : AppTheme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            Spacer()
            navigationButtons
        }
        .padding()
    }

    // MARK: - Step 4: Goal
    private var goalStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Your Goal")
                .font(.title.bold())
                .foregroundStyle(AppTheme.textPrimary)

            onboardingField(label: "Target Weight", value: "") {
                HStack {
                    TextField("kg", value: $goalWeightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                    Text("kg")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .luxuryCard()
            .padding(.horizontal, 16)

            // Stats preview
            let heightM = heightCm / 100
            let previewBMI = heightM > 0 ? weightKg / (heightM * heightM) : 0
            let previewBMR = sex == .male
                ? 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
                : 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161

            HStack(spacing: 16) {
                previewStat(label: "BMI", value: String(format: "%.1f", previewBMI))
                previewStat(label: "BMR", value: "\(Int(previewBMR))")
                previewStat(label: "TDEE", value: "\(Int(previewBMR * activityLevel.multiplier))")
            }
            .padding(.horizontal, 16)

            Spacer()

            Button { withAnimation { currentStep = 4 } } label: {
                Text("Continue")
                    .luxuryButton()
            }
            .padding(.horizontal, 24)
        }
        .padding()
    }

    // MARK: - Step 5: API Key
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
                Text("SportsMeal uses Claude AI to analyze your meals.\nYou'll need an Anthropic API key to get started.")
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
    private func previewStat(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.gold)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .luxuryCard(padding: 12)
    }

    private func onboardingField<Content: View>(label: String, value: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            trailing()
                .foregroundStyle(AppTheme.textPrimary)
        }
    }

    private var navigationButtons: some View {
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

    private func saveProfile() {
        let profile = UserProfile(
            name: name,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            sex: sex,
            activityLevel: activityLevel,
            goalWeightKg: goalWeightKg
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
