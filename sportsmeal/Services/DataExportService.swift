import Foundation

struct DataExportService {
    static func exportMealsAsCSV(meals: [Meal]) -> String {
        var csv = "Date,Time,Food Items,Total Calories,Protein (g),Carbs (g),Fat (g),Cuisine,Notes\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for meal in meals.sorted(by: { $0.timestamp < $1.timestamp }) {
            let date = dateFormatter.string(from: meal.timestamp)
            let time = timeFormatter.string(from: meal.timestamp)
            let foods = meal.foodItems.map(\.name).joined(separator: "; ")
            let calories = Int(meal.totalCalories)
            let protein = meal.hasMacros ? "\(Int(meal.totalProtein))" : ""
            let carbs = meal.hasMacros ? "\(Int(meal.totalCarbs))" : ""
            let fat = meal.hasMacros ? "\(Int(meal.totalFat))" : ""
            let cuisine = meal.cuisineType ?? ""
            let notes = (meal.notes ?? "").replacingOccurrences(of: ",", with: ";")

            csv += "\(date),\(time),\"\(foods)\",\(calories),\(protein),\(carbs),\(fat),\(cuisine),\"\(notes)\"\n"
        }

        return csv
    }

    static func generateWeeklySummary(meals: [Meal], exercises: [ExerciseEntry], profile: UserProfile?) -> WeeklySummary {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let weekMeals = meals.filter { $0.timestamp >= weekAgo }
        let weekExercises = exercises.filter { $0.timestamp >= weekAgo }

        let totalCalories = weekMeals.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = weekMeals.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = weekMeals.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = weekMeals.reduce(0) { $0 + $1.totalFat }
        let mealCount = weekMeals.count
        let exerciseCount = weekExercises.count

        let daysWithMeals = Set(weekMeals.map { calendar.startOfDay(for: $0.timestamp) }).count
        let avgDailyCalories = daysWithMeals > 0 ? totalCalories / Double(daysWithMeals) : 0

        let exerciseCalories = profile.map { p in
            weekExercises.reduce(0) { $0 + $1.caloriesBurned(weightKg: p.weightKg) }
        } ?? 0

        return WeeklySummary(
            totalCalories: totalCalories,
            avgDailyCalories: avgDailyCalories,
            mealCount: mealCount,
            exerciseCount: exerciseCount,
            exerciseCaloriesBurned: exerciseCalories,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFat: totalFat,
            daysTracked: daysWithMeals
        )
    }
}

struct WeeklySummary {
    let totalCalories: Double
    let avgDailyCalories: Double
    let mealCount: Int
    let exerciseCount: Int
    let exerciseCaloriesBurned: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let daysTracked: Int
}
