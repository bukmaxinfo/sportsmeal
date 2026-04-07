import Foundation

struct StreakService {
    /// Calculate the current consecutive-day logging streak
    static func currentStreak(meals: [Meal]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique days with meals, sorted descending
        let daysWithMeals = Set(meals.map { calendar.startOfDay(for: $0.timestamp) })
            .sorted(by: >)

        guard daysWithMeals.contains(today) || daysWithMeals.contains(calendar.date(byAdding: .day, value: -1, to: today)!) else {
            return 0
        }

        var streak = 0
        var checkDate = daysWithMeals.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!

        while daysWithMeals.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    /// Longest streak ever
    static func longestStreak(meals: [Meal]) -> Int {
        let calendar = Calendar.current
        let days = Set(meals.map { calendar.startOfDay(for: $0.timestamp) }).sorted()

        guard !days.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<days.count {
            let diff = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }
}
