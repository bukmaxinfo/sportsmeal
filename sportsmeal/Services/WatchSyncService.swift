import Foundation
import WatchConnectivity
import SwiftData

/// iPhone-side WatchConnectivity manager.
/// Activated at app launch; pushes today's summary to the Watch
/// and receives meal/exercise log messages from the Watch.
final class WatchSyncService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    /// Stores the modelContext reference so we can handle incoming Watch messages.
    var modelContext: ModelContext?

    private override init() {
        super.init()
    }

    // MARK: - Activation

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Push to Watch

    /// Send today's calorie summary + meal templates to the Watch.
    /// Call this after every meal insert/delete (pairs with WidgetSyncHelper).
    func pushToWatch(
        consumed: Double,
        budget: Double,
        templates: [(name: String, calories: Double)]
    ) {
        guard WCSession.default.activationState == .activated else { return }

        let templateDicts: [[String: Any]] = templates.map {
            ["name": $0.name, "calories": $0.calories]
        }

        let context: [String: Any] = [
            "consumedCalories": consumed,
            "calorieBudget": budget,
            "templates": templateDicts
        ]

        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - WCSessionDelegate (iOS required)

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op; we push data reactively after meal changes
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for multi-watch support
        WCSession.default.activate()
    }

    // MARK: - Receive from Watch

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }

        DispatchQueue.main.async { [weak self] in
            guard let context = self?.modelContext else { return }

            switch action {
            case "logMeal":
                self?.handleWatchMealLog(message: message, context: context)
            case "logExercise":
                self?.handleWatchExerciseLog(message: message, context: context)
            default:
                break
            }
        }
    }

    private func handleWatchMealLog(message: [String: Any], context: ModelContext) {
        guard let templateName = message["templateName"] as? String,
              let calories = message["calories"] as? Double else { return }

        let meal = Meal(
            foodItems: [FoodItem(name: templateName, calories: calories)],
            totalCalories: calories,
            timestamp: Date()
        )
        context.insert(meal)
        WidgetSyncHelper.sync(context: context)
    }

    private func handleWatchExerciseLog(message: [String: Any], context: ModelContext) {
        guard let typeString = message["type"] as? String,
              let durationMinutes = message["durationMinutes"] as? Int else { return }

        // Map Watch exercise type string to ExerciseType enum
        let exerciseType: ExerciseType
        switch typeString.lowercased() {
        case "run", "running": exerciseType = .running
        case "walk", "walking": exerciseType = .walking
        case "cycle", "cycling": exerciseType = .cycling
        default: exerciseType = .walking
        }

        let entry = ExerciseEntry(
            type: exerciseType,
            durationMinutes: durationMinutes,
            timestamp: Date()
        )
        context.insert(entry)
        WidgetSyncHelper.sync(context: context)
    }
}
