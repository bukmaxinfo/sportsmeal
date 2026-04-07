import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var allExercises: [ExerciseEntry]

    private var todayMeals: [Meal] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allMeals.filter { $0.timestamp >= startOfDay }
    }

    private var todayExercises: [ExerciseEntry] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allExercises.filter { $0.timestamp >= startOfDay }
    }

    private var profile: UserProfile? { profiles.first }

    @State private var selectedStat: String?
    @State private var mealSuggestions: [MealSuggestion] = []
    @State private var isLoadingSuggestions = false
    private let recommendationService = MealRecommendationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calorie ring
                    calorieRingCard

                    // Macro rings
                    if let profile = profile {
                        macroRingsCard(profile: profile)
                    }

                    // Streak
                    streakCard

                    // Calories remaining breakdown
                    if let profile = profile {
                        caloriesRemainingCard(profile: profile)
                        exerciseCoachingCard(profile: profile)
                        healthStatsCard(profile: profile)
                    }

                    // Meal suggestions
                    if let profile = profile {
                        mealSuggestionsSection(profile: profile)
                    }

                    todayMealsSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("SportsMeal")
        }
    }

    // MARK: - Calorie Ring
    private var calorieRingCard: some View {
        let totalCalories = todayMeals.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = profile.map { p in
            todayExercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: p.weightKg) }
        } ?? 0
        // Use BMR + exercise as budget (consistent with remaining card)
        let target = (profile?.bmr ?? 2000) + exerciseBurned
        let progress = min(totalCalories / target, 1.0)
        let isOver = totalCalories > target

        return VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppTheme.surfaceLight, lineWidth: 12)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isOver
                            ? AnyShapeStyle(AppTheme.negative)
                            : AnyShapeStyle(AppTheme.goldGradient),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("of \(Int(target))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Text("Today's Intake")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .luxuryCard(padding: 24)
    }

    // MARK: - Macro Rings
    private func macroRingsCard(profile: UserProfile) -> some View {
        let todayProtein = todayMeals.reduce(0) { $0 + $1.totalProtein }
        let todayCarbs = todayMeals.reduce(0) { $0 + $1.totalCarbs }
        let todayFat = todayMeals.reduce(0) { $0 + $1.totalFat }
        let targets = profile.macroTargets
        let hasMacroData = todayMeals.contains { $0.hasMacros }

        return VStack(spacing: 12) {
            Text("Macros")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            if hasMacroData {
                HStack(spacing: 24) {
                    macroRing(label: "Protein", current: todayProtein, target: targets.protein, color: AppTheme.positive)
                    macroRing(label: "Carbs", current: todayCarbs, target: targets.carbs, color: AppTheme.gold)
                    macroRing(label: "Fat", current: todayFat, target: targets.fat, color: AppTheme.warning)
                }
            } else {
                Text("Scan a meal to see macro breakdown")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .luxuryCard()
    }

    private func macroRing(label: String, current: Double, target: Double, color: Color) -> some View {
        let progress = target > 0 ? min(current / target, 1.0) : 0

        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(AppTheme.surfaceLight, lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
                Text("\(Int(current))g")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            VStack(spacing: 1) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
                Text("\(Int(target))g goal")
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
    }

    // MARK: - Streak
    @ViewBuilder
    private var streakCard: some View {
        let streak = StreakService.currentStreak(meals: allMeals)
        if streak > 0 {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(streak >= 7 ? AppTheme.gold : AppTheme.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak) day streak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(streak >= 7 ? "You're on fire! Keep it going." : "Keep logging to build your streak!")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                Spacer()
            }
            .luxuryCard()
        }
    }

    // MARK: - Calories Remaining
    private func caloriesRemainingCard(profile: UserProfile) -> some View {
        let consumed = todayMeals.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = todayExercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: profile.weightKg) }
        let budget = profile.bmr + exerciseBurned
        let remaining = budget - consumed

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Remaining")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
                Text("\(Int(max(0, remaining)))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(remaining > 0 ? AppTheme.gold : AppTheme.negative)
                Text("kcal")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Label("\(Int(profile.bmr)) BMR", systemImage: "flame")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Label("+\(Int(exerciseBurned)) exercise", systemImage: "figure.run")
                    .font(.caption)
                    .foregroundStyle(AppTheme.positive)
                Label("-\(Int(consumed)) food", systemImage: "fork.knife")
                    .font(.caption)
                    .foregroundStyle(AppTheme.gold)
            }
        }
        .luxuryCard()
    }

    // MARK: - Exercise Coaching
    @ViewBuilder
    private func exerciseCoachingCard(profile: UserProfile) -> some View {
        let consumed = todayMeals.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = todayExercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: profile.weightKg) }
        let budget = profile.bmr + exerciseBurned
        let surplus = consumed - budget

        if surplus > 0, profile.weightKg > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(AppTheme.negative)
                    Text("You're \(Int(surplus)) kcal over — here's how to burn it off")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                let exercises: [(ExerciseType, String)] = [
                    (.running, "Run"),
                    (.walking, "Walk"),
                    (.cycling, "Cycle"),
                    (.swimming, "Swim"),
                ]

                HStack(spacing: 10) {
                    ForEach(exercises, id: \.0) { exercise, label in
                        let minutes = Int(ceil(surplus / (exercise.metValue * profile.weightKg / 60)))
                        VStack(spacing: 6) {
                            Image(systemName: exercise.icon)
                                .font(.title3)
                                .foregroundStyle(AppTheme.gold)
                            Text("\(minutes) min")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .luxuryCard()
        }
    }

    // MARK: - Health Stats
    private func healthStatsCard(profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            statBubble(
                title: "BMI",
                value: String(format: "%.1f", profile.bmi),
                subtitle: profile.bmiCategory,
                explanation: "Body Mass Index — a measure of body fat based on your weight and height. Normal range is 18.5–24.9."
            )
            statBubble(
                title: "BMR",
                value: "\(Int(profile.bmr))",
                subtitle: "kcal/day",
                explanation: "Basal Metabolic Rate — the calories your body burns at complete rest just to keep you alive."
            )
            statBubble(
                title: "TDEE",
                value: "\(Int(profile.tdee))",
                subtitle: "kcal/day",
                explanation: "Total Daily Energy Expenditure — your BMR multiplied by your activity level."
            )
        }
    }

    private func statBubble(title: String, value: String, subtitle: String, explanation: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
                Image(systemName: "info.circle")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .luxuryCard(padding: 12)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStat = selectedStat == title ? nil : title
            }
        }
        .popover(isPresented: Binding(
            get: { selectedStat == title },
            set: { if !$0 { selectedStat = nil } }
        )) {
            Text(explanation)
                .font(.subheadline)
                .padding()
                .frame(width: 260)
                .presentationCompactAdaptation(.popover)
        }
    }

    // MARK: - Today's Meals
    // MARK: - Meal Suggestions
    private func mealSuggestionsSection(profile: UserProfile) -> some View {
        let consumed = todayMeals.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = todayExercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: profile.weightKg) }
        let remaining = Int(profile.bmr + exerciseBurned - consumed)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal Ideas")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                if remaining > 100 {
                    Button {
                        Task { await loadSuggestions(remaining: remaining, profile: profile) }
                    } label: {
                        if isLoadingSuggestions {
                            ProgressView().tint(AppTheme.gold)
                        } else {
                            Label(mealSuggestions.isEmpty ? "Get Ideas" : "Refresh", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundStyle(AppTheme.gold)
                        }
                    }
                    .disabled(isLoadingSuggestions)
                }
            }

            if remaining <= 100 {
                Text("You've used most of your calorie budget today")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            } else if mealSuggestions.isEmpty && !isLoadingSuggestions {
                Text("Tap 'Get Ideas' for AI meal suggestions within your \(remaining) kcal budget")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            } else {
                ForEach(mealSuggestions) { suggestion in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(suggestion.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(suggestion.description)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(suggestion.estimatedCalories)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.gold)
                            Text("kcal")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    }
                    .luxuryCard()
                }
            }
        }
    }

    private func loadSuggestions(remaining: Int, profile: UserProfile) async {
        isLoadingSuggestions = true
        let recentNames = todayMeals.flatMap { $0.foodItems.map(\.name) }

        // Build macro guidance if we have data
        var macroGuidance: String?
        let targets = profile.macroTargets
        let todayP = todayMeals.reduce(0) { $0 + $1.totalProtein }
        let todayC = todayMeals.reduce(0) { $0 + $1.totalCarbs }
        let todayF = todayMeals.reduce(0) { $0 + $1.totalFat }
        if todayMeals.contains(where: { $0.hasMacros }) {
            var parts: [String] = []
            if todayP < targets.protein * 0.7 { parts.append("low on protein (need \(Int(targets.protein - todayP))g more)") }
            if todayC < targets.carbs * 0.7 { parts.append("low on carbs (need \(Int(targets.carbs - todayC))g more)") }
            if todayF > targets.fat * 0.9 { parts.append("already near fat target") }
            if !parts.isEmpty { macroGuidance = "Macro note: user is \(parts.joined(separator: ", "))" }
        }

        do {
            mealSuggestions = try await recommendationService.suggestMeals(
                remainingCalories: remaining,
                dietaryPreference: profile.dietarySummary,
                recentMealNames: recentNames,
                macroGuidance: macroGuidance
            )
        } catch {
            // Silently fail — suggestions are optional
        }
        isLoadingSuggestions = false
    }

    // MARK: - Today's Meals
    private var todayMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            if todayMeals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("No meals logged")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Tap 'Scan' to photograph your first meal")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .luxuryCard(padding: 32)
            } else {
                ForEach(todayMeals) { meal in
                    MealRowView(meal: meal, onDelete: {
                        withAnimation { modelContext.delete(meal) }
                    })
                }
            }
        }
    }
}

// MARK: - Meal Row
struct MealRowView: View {
    let meal: Meal
    var onDelete: (() -> Void)?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            if let photoData = meal.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surfaceLight)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(AppTheme.textTertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(meal.foodItems.map(\.name).joined(separator: ", "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(meal.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            Text("\(Int(meal.totalCalories))")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.gold)
            + Text(" kcal")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
        .luxuryCard()
        .contextMenu {
            if onDelete != nil {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete Meal", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Delete this meal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(Int(meal.totalCalories)) kcal from your daily total.")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Meal.self, ExerciseEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}
