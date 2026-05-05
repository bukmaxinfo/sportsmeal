import Foundation
import WidgetKit

/// Lightweight bridge between the main app and the widget extension.
/// Uses a shared App Group UserDefaults so the widget can read today's
/// calorie/macro summary without importing SwiftData.
///
/// The main app calls `update(…)` after every meal log/delete.
/// The widget's TimelineProvider calls the static read helpers.
final class SharedDataService {
    static let shared = SharedDataService()

    static let appGroupID = "group.com.bukmax.sportsmeal"

    // MARK: - UserDefaults keys
    private enum Key {
        static let consumed = "widget_consumedCalories"
        static let budget = "widget_calorieBudget"
        static let mealCount = "widget_mealCount"
        static let recentMeals = "widget_recentMeals"
        static let protein = "widget_protein"
        static let carbs = "widget_carbs"
        static let fat = "widget_fat"
        static let lastUpdated = "widget_lastUpdated"
    }

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: SharedDataService.appGroupID)
    }

    // MARK: - Write (called from main app)

    /// Push today's summary into the shared container and tell WidgetKit to refresh.
    func update(
        consumed: Double,
        budget: Double,
        mealCount: Int,
        recentMeals: [String],
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        defaults?.set(consumed, forKey: Key.consumed)
        defaults?.set(budget, forKey: Key.budget)
        defaults?.set(mealCount, forKey: Key.mealCount)
        defaults?.set(recentMeals, forKey: Key.recentMeals)
        defaults?.set(protein, forKey: Key.protein)
        defaults?.set(carbs, forKey: Key.carbs)
        defaults?.set(fat, forKey: Key.fat)
        defaults?.set(Date().timeIntervalSince1970, forKey: Key.lastUpdated)

        // Tell all three widget kinds to rebuild their timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "SportsMealCalorieRing")
        WidgetCenter.shared.reloadTimelines(ofKind: "SportsMealDailyOverview")
        WidgetCenter.shared.reloadTimelines(ofKind: "SportsMealLockScreen")
    }

    // MARK: - Read (called from widget TimelineProvider)

    static func readSnapshot() -> WidgetSnapshot {
        let defaults = UserDefaults(suiteName: appGroupID)
        return WidgetSnapshot(
            consumed: defaults?.double(forKey: Key.consumed) ?? 0,
            budget: defaults?.double(forKey: Key.budget) ?? 2000,
            mealCount: defaults?.integer(forKey: Key.mealCount) ?? 0,
            recentMeals: defaults?.stringArray(forKey: Key.recentMeals) ?? [],
            protein: defaults?.double(forKey: Key.protein) ?? 0,
            carbs: defaults?.double(forKey: Key.carbs) ?? 0,
            fat: defaults?.double(forKey: Key.fat) ?? 0,
            lastUpdated: Date(timeIntervalSince1970: defaults?.double(forKey: Key.lastUpdated) ?? 0)
        )
    }
}

/// Plain value type the widget can consume without importing SwiftData.
struct WidgetSnapshot {
    let consumed: Double
    let budget: Double
    let mealCount: Int
    let recentMeals: [String]
    let protein: Double
    let carbs: Double
    let fat: Double
    let lastUpdated: Date

    /// True if the snapshot is from today (i.e. data is fresh).
    var isFromToday: Bool {
        Calendar.current.isDateInToday(lastUpdated)
    }
}
