import Foundation
import SwiftData

/// Convenience that queries today's meals from a ModelContext and pushes
/// the summary to SharedDataService for the widget to read.
///
/// Call `WidgetSyncHelper.sync(context:)` after every meal insert or delete.
enum WidgetSyncHelper {

    static func sync(context: ModelContext) {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        // Fetch today's meals
        let mealDescriptor = FetchDescriptor<Meal>(
            predicate: #Predicate<Meal> { $0.timestamp >= startOfDay },
            sortBy: [SortDescriptor(\Meal.timestamp, order: .reverse)]
        )
        let todayMeals = (try? context.fetch(mealDescriptor)) ?? []

        // Fetch today's exercises (for budget calculation)
        let exerciseDescriptor = FetchDescriptor<ExerciseEntry>(
            predicate: #Predicate<ExerciseEntry> { $0.timestamp >= startOfDay }
        )
        let todayExercises = (try? context.fetch(exerciseDescriptor)) ?? []

        // Fetch profile for budget
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let profile = (try? context.fetch(profileDescriptor))?.first

        let consumed = todayMeals.reduce(0) { $0 + $1.totalCalories }
        let exerciseBurned = todayExercises.reduce(0) { total, entry in
            total + entry.caloriesBurned(weightKg: profile?.weightKg ?? 70)
        }
        let budget = (profile?.bmr ?? 2000) + exerciseBurned

        let protein = todayMeals.reduce(0) { $0 + $1.totalProtein }
        let carbs = todayMeals.reduce(0) { $0 + $1.totalCarbs }
        let fat = todayMeals.reduce(0) { $0 + $1.totalFat }

        let recentNames = todayMeals.prefix(3).map { meal in
            meal.foodItems.first?.name ?? "Meal"
        }

        SharedDataService.shared.update(
            consumed: consumed,
            budget: budget,
            mealCount: todayMeals.count,
            recentMeals: recentNames,
            protein: protein,
            carbs: carbs,
            fat: fat
        )

        // Also push to Watch if paired
        let templateDescriptor = FetchDescriptor<MealTemplate>(
            sortBy: [SortDescriptor(\MealTemplate.useCount, order: .reverse)]
        )
        let templates = (try? context.fetch(templateDescriptor)) ?? []
        let topTemplates = templates.prefix(5).map { ($0.name, $0.totalCalories) }

        WatchSyncService.shared.pushToWatch(
            consumed: consumed,
            budget: budget,
            templates: topTemplates
        )
    }
}
