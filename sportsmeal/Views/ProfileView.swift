import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            if let profile = profile {
                ProfileDetailView(profile: profile)
            } else {
                ContentUnavailableView(
                    "No Profile",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Profile not found")
                )
            }
        }
    }
}

struct ProfileDetailView: View {
    @Bindable var profile: UserProfile
    @State private var isEditing = false
    @State private var explanationTitle: String?
    @State private var explanationText: String?
    @State private var showingExercise = false
    @State private var showingPantry = false

    var body: some View {
        Form {
            Section("Personal Info") {
                if isEditing {
                    TextField("Name", text: $profile.name)
                    DatePicker("Date of Birth", selection: $profile.dateOfBirth, in: ...Date(), displayedComponents: .date)
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("cm", value: $profile.heightCm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("cm").foregroundStyle(AppTheme.textTertiary)
                    }
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("kg", value: $profile.weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("kg").foregroundStyle(AppTheme.textTertiary)
                    }
                    Picker("Sex", selection: $profile.sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex.rawValue).tag(sex)
                        }
                    }
                    Picker("Activity Level", selection: $profile.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .tag(level)
                        }
                    }
                } else {
                    LabeledContent("Name", value: profile.name)
                    LabeledContent("Age", value: "\(profile.age) years old")
                    LabeledContent("Height", value: String(format: "%.0f cm", profile.heightCm))
                    LabeledContent("Weight", value: String(format: "%.1f kg", profile.weightKg))
                    LabeledContent("Sex", value: profile.sex.rawValue)
                    LabeledContent("Activity", value: profile.activityLevel.rawValue)
                }
            }

            Section("Health Metrics") {
                healthMetricRow(
                    label: "BMI",
                    explanation: "Body Mass Index — a measure of body fat based on your weight and height. Normal range is 18.5–24.9."
                ) {
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f", profile.bmi))
                            .bold()
                        Text(profile.bmiCategory)
                            .font(.caption)
                            .foregroundStyle(bmiColor(profile.bmiCategory))
                    }
                }
                healthMetricRow(
                    label: "BMR",
                    explanation: "Basal Metabolic Rate — the calories your body burns at complete rest just to keep you alive."
                ) {
                    Text("\(Int(profile.bmr)) kcal/day")
                }
                healthMetricRow(
                    label: "TDEE",
                    explanation: "Total Daily Energy Expenditure — your BMR multiplied by your activity level."
                ) {
                    Text("\(Int(profile.tdee)) kcal/day")
                }
            }

            if isEditing {
                Section("Goal") {
                    HStack {
                        Text("Target Weight")
                        Spacer()
                        TextField("kg", value: Binding(
                            get: { profile.goalWeightKg ?? profile.weightKg },
                            set: { profile.goalWeightKg = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("kg").foregroundStyle(AppTheme.textTertiary)
                    }
                }
            } else if let goal = profile.goalWeightKg {
                Section("Goal") {
                    LabeledContent("Target Weight", value: String(format: "%.1f kg", goal))
                    let diff = profile.weightKg - goal
                    if diff > 0 {
                        LabeledContent("To Lose", value: String(format: "%.1f kg", diff))
                    }
                }
            }

            Section("Dietary Preferences") {
                if isEditing {
                    Picker("Diet", selection: Binding(
                        get: { profile.dietType ?? .none },
                        set: { profile.dietType = $0 == .none ? nil : $0 }
                    )) {
                        ForEach(DietType.allCases) { diet in
                            VStack(alignment: .leading) {
                                Text(diet.rawValue)
                                Text(diet.description)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                            .tag(diet)
                        }
                    }
                } else {
                    LabeledContent("Diet", value: profile.dietType?.rawValue ?? "No Preference")
                }
            }

            Section("Tools") {
                Button {
                    showingExercise = true
                } label: {
                    Label("Exercise", systemImage: "figure.run")
                }
                Button {
                    showingPantry = true
                } label: {
                    Label("Pantry & Recipes", systemImage: "refrigerator.fill")
                }
            }

            Section("Settings") {
                NavigationLink {
                    LanguageSettingsView()
                } label: {
                    HStack {
                        Label("Language", systemImage: "globe")
                        Spacer()
                        Text(LanguageManager.shared.currentLanguageName)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
                NavigationLink {
                    HealthView()
                } label: {
                    Label("Apple Health", systemImage: "heart.fill")
                }
                NavigationLink {
                    APIKeySettingsView()
                } label: {
                    HStack {
                        Label("API Key", systemImage: "key.fill")
                        Spacer()
                        if APIConfig.hasAPIKey {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.positive)
                        } else {
                            Text("Not set")
                                .foregroundStyle(AppTheme.negative)
                        }
                    }
                }
                NavigationLink {
                    APIUsageView()
                } label: {
                    Label("API Usage", systemImage: "chart.bar.fill")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle("Profile")
        .toolbar {
            Button(isEditing ? "Done" : "Edit") {
                if isEditing { profile.updatedAt = Date() }
                isEditing.toggle()
            }
            .foregroundStyle(AppTheme.gold)
        }
        .sheet(isPresented: $showingExercise) {
            ExerciseView()
        }
        .sheet(isPresented: $showingPantry) {
            PantryView()
        }
        .alert(explanationTitle ?? "", isPresented: Binding(
            get: { explanationText != nil },
            set: { if !$0 { explanationText = nil; explanationTitle = nil } }
        )) {
            Button("OK") { explanationText = nil; explanationTitle = nil }
        } message: {
            Text(explanationText ?? "")
        }
    }

    private func healthMetricRow<Content: View>(label: String, explanation: String, @ViewBuilder content: () -> Content) -> some View {
        Button {
            explanationTitle = label
            explanationText = explanation
        } label: {
            LabeledContent {
                content()
            } label: {
                HStack(spacing: 4) {
                    Text(label)
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func bmiColor(_ category: String) -> Color {
        switch category {
        case "Normal": return AppTheme.positive
        case "Underweight": return AppTheme.warning
        case "Overweight": return AppTheme.warning
        case "Obese": return AppTheme.negative
        default: return AppTheme.textPrimary
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: UserProfile.self, inMemory: true)
        .preferredColorScheme(.dark)
}
