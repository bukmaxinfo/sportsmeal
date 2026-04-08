import SwiftUI
import SwiftData

struct ExerciseView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \ExerciseEntry.timestamp, order: .reverse) private var exercises: [ExerciseEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddSheet = false
    @StateObject private var healthKit = HealthKitService()

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let profile = profile {
                        weightLossProjectionCard(profile: profile)
                    }
                    todayExerciseSection
                    recentExerciseSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Exercise")
            .toolbar {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppTheme.gold)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddExerciseSheet()
            }
        }
    }

    private func weightLossProjectionCard(profile: UserProfile) -> some View {
        let avgDailyExercise = averageDailyExerciseBurn(weightKg: profile.weightKg)
        let avgDailyBurn = profile.bmr + avgDailyExercise
        let avgIntake = averageDailyIntake
        // Positive = losing weight, negative = gaining
        let avgDailyBalance = avgDailyBurn - avgIntake

        let weightToLose = profile.weightKg - (profile.goalWeightKg ?? profile.weightKg)
        let calsToLose = weightToLose * 7700

        return VStack(spacing: 16) {
            Text("Weight Loss Plan")
                .font(.headline)
                .foregroundStyle(AppTheme.gold)

            if let goal = profile.goalWeightKg, goal < profile.weightKg {
                // Current vs goal
                HStack(spacing: 24) {
                    VStack {
                        Text(String(format: "%.1f", profile.weightKg))
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Current kg")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppTheme.gold)
                    VStack {
                        Text(String(format: "%.1f", goal))
                            .font(.title2.bold())
                            .foregroundStyle(AppTheme.positive)
                        Text("Goal kg")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }

                Divider().overlay(AppTheme.border)

                // Daily energy balance
                dailyBalanceSection(balance: avgDailyBalance, intake: avgIntake, burn: avgDailyBurn)

                Divider().overlay(AppTheme.border)

                // Projection (only if in deficit)
                if avgDailyBalance > 0 {
                    projectionSection(dailyDeficit: avgDailyBalance, calsToLose: calsToLose)
                }

                Divider().overlay(AppTheme.border)
                exerciseRecommendation(profile: profile, calsToLose: calsToLose)
            } else {
                Text("Set a goal weight in your Profile to see projections")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .luxuryCard()
    }

    private func dailyBalanceSection(balance: Double, intake: Double, burn: Double) -> some View {
        VStack(spacing: 10) {
            // Status indicator
            if balance > 500 {
                // Aggressive deficit — losing but maybe too fast
                Label("Aggressive deficit", systemImage: "exclamationmark.triangle")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.warning)
                Text("You're burning \(Int(balance)) kcal/day more than you eat. A safe rate is 500 kcal/day deficit (~0.5 kg/week). Going faster risks muscle loss and burnout.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else if balance > 0 {
                // Healthy deficit — on track
                Label("On track", systemImage: "checkmark.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.positive)
                Text("You're in a healthy deficit of \(Int(balance)) kcal/day. You won't gain weight at this pace.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else if balance > -200 {
                // Roughly maintaining
                Label("Maintaining weight", systemImage: "equal.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)
                Text("You're eating about as much as you burn. You won't gain or lose at this pace.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                // Surplus — gaining weight
                Label("Calorie surplus", systemImage: "arrow.up.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.negative)
                Text("You're eating \(Int(abs(balance))) kcal/day more than you burn. This will lead to gradual weight gain.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Breakdown
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(Int(burn))")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.positive)
                    Text("Burn/day")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(Int(intake))")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.gold)
                    Text("Eat/day")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(balance >= 0 ? "-" : "+")\(Int(abs(balance)))")
                        .font(.subheadline.bold())
                        .foregroundStyle(balance >= 0 ? AppTheme.positive : AppTheme.negative)
                    Text("Net/day")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func projectionSection(dailyDeficit: Double, calsToLose: Double) -> some View {
        // Cap projection at a healthy rate: max 500 cal/day deficit for the estimate
        // so the timeline is realistic (not "you'll lose 10kg in 2 weeks")
        let healthyDailyDeficit = min(dailyDeficit, 500)
        let realisticDays = Int(calsToLose / healthyDailyDeficit)
        let weeks = realisticDays / 7
        let months = realisticDays / 30

        return VStack(spacing: 6) {
            Text("Realistic Timeline")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSecondary)

            if months > 1 {
                Text("~\(months) months")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.gold)
            } else {
                Text("~\(weeks) weeks")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.gold)
            }

            Text("Based on a safe rate of ~0.5 kg/week")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)

            if dailyDeficit > 500 {
                Text("Your actual deficit is higher, but faster loss is mostly water and muscle — not sustainable fat loss.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func exerciseRecommendation(profile: UserProfile, calsToLose: Double) -> some View {
        let targetWeeklyDeficit = 3850.0
        let bmrDeficit = max(0, profile.bmr - averageDailyIntake) * 7
        let exerciseDeficitNeeded = max(0, targetWeeklyDeficit - bmrDeficit)

        let runCalPerMin = ExerciseType.running.metValue * profile.weightKg / 60.0
        let walkCalPerMin = ExerciseType.walking.metValue * profile.weightKg / 60.0

        let runMinPerWeek = Int(exerciseDeficitNeeded / runCalPerMin)
        let walkMinPerWeek = Int(exerciseDeficitNeeded / walkCalPerMin)

        return VStack(spacing: 8) {
            Text("Recommended Weekly Exercise")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textSecondary)

            if exerciseDeficitNeeded > 0 {
                HStack(spacing: 16) {
                    VStack {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .foregroundStyle(AppTheme.gold)
                        Text("\(runMinPerWeek) min")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Running")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)

                    Text("or")
                        .foregroundStyle(AppTheme.textTertiary)

                    VStack {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .foregroundStyle(AppTheme.positive)
                        Text("\(walkMinPerWeek) min")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text("Walking")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("Your diet alone creates enough deficit!")
                    .font(.caption)
                    .foregroundStyle(AppTheme.positive)
            }
        }
    }

    private var todayExerciseSection: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let todayExercises = exercises.filter { $0.timestamp >= today }

        return VStack(alignment: .leading, spacing: 8) {
            Text("Today's Exercise")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            // HealthKit imported workouts (Apple Watch, Strava, etc.)
            if !healthKit.todayWorkouts.isEmpty {
                ForEach(healthKit.todayWorkouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workout.icon)
                            .font(.title3)
                            .foregroundStyle(AppTheme.positive)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                            HStack(spacing: 8) {
                                Text("\(workout.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text("via \(workout.source)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        }
                        Spacer()
                        Text("\(Int(workout.caloriesBurned))")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.positive)
                        + Text(" kcal")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                    .luxuryCard()
                }
            }

            // Manually logged exercises
            if todayExercises.isEmpty && healthKit.todayWorkouts.isEmpty {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("No exercise logged today")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .luxuryCard(padding: 24)
            } else {
                ForEach(todayExercises) { entry in
                    exerciseRow(entry)
                }
            }
        }
        .onAppear {
            if healthKit.isAuthorized {
                healthKit.fetchTodayWorkouts()
            }
        }
    }

    private var recentExerciseSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            let recent = Array(exercises.prefix(10))
            if recent.isEmpty {
                Text("Start logging exercises to track progress")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(recent) { entry in
                    exerciseRow(entry)
                }
            }
        }
    }

    private func exerciseRow(_ entry: ExerciseEntry) -> some View {
        let weight = profile?.weightKg ?? 70
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldSubtle)
                    .frame(width: 40, height: 40)
                Image(systemName: entry.type.icon)
                    .font(.body)
                    .foregroundStyle(AppTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("\(entry.durationMinutes) min")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.caloriesBurned(weightKg: weight))) kcal")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.gold)
                Text(entry.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .luxuryCard()
    }

    // MARK: - Helpers
    @Query(sort: \Meal.timestamp, order: .reverse) private var allMeals: [Meal]

    private var todayMealCalories: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return allMeals.filter { $0.timestamp >= today }.reduce(0) { $0 + $1.totalCalories }
    }

    private var averageDailyIntake: Double {
        guard !allMeals.isEmpty else { return 2000 }
        let calendar = Calendar.current
        let dates = Set(allMeals.map { calendar.startOfDay(for: $0.timestamp) })
        return allMeals.reduce(0) { $0 + $1.totalCalories } / Double(max(dates.count, 1))
    }

    private func todayCaloriesBurned(weightKg: Double) -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return exercises.filter { $0.timestamp >= today }.reduce(0) { $0 + $1.caloriesBurned(weightKg: weightKg) }
    }

    private func averageDailyExerciseBurn(weightKg: Double) -> Double {
        guard !exercises.isEmpty else { return 0 }
        let calendar = Calendar.current
        let dates = Set(exercises.map { calendar.startOfDay(for: $0.timestamp) })
        return exercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: weightKg) } / Double(max(dates.count, 1))
    }
}

// MARK: - Add Exercise Sheet
struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: ExerciseType = .running
    @State private var durationMinutes = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Exercise type grid
                VStack(alignment: .leading) {
                    Text("Exercise Type")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(ExerciseType.allCases) { type in
                            Button {
                                selectedType = type
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                    Text(type.rawValue)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(selectedType == type ? AppTheme.gold : AppTheme.surface)
                                .foregroundStyle(selectedType == type ? .black : AppTheme.textSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedType == type ? Color.clear : AppTheme.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack {
                        Text("\(durationMinutes) minutes")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.gold)
                        Spacer()
                        Stepper("", value: $durationMinutes, in: 5...300, step: 5)
                            .labelsHidden()
                    }
                    .luxuryCard()
                }

                Spacer()
            }
            .padding()
            .background(AppTheme.background)
            .navigationTitle("Log Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(ExerciseEntry(type: selectedType, durationMinutes: durationMinutes))
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.gold)
                    .bold()
                }
            }
        }
    }
}

#Preview {
    ExerciseView()
        .modelContainer(for: [UserProfile.self, Meal.self, ExerciseEntry.self], inMemory: true)
        .preferredColorScheme(.dark)
}
