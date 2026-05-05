import Foundation
import WatchConnectivity

/// Manages communication between iPhone and Apple Watch
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    @Published var receivedCalories: Double = 0
    @Published var receivedBudget: Double = 2000
    @Published var receivedTemplates: [[String: Any]] = []

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send to iPhone
    func sendMealLog(templateName: String, calories: Double) {
        guard WCSession.default.isReachable else { return }
        let message: [String: Any] = [
            "action": "logMeal",
            "templateName": templateName,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    func sendExerciseSession(type: String, durationMinutes: Int) {
        guard WCSession.default.isReachable else { return }
        let message: [String: Any] = [
            "action": "logExercise",
            "type": type,
            "durationMinutes": durationMinutes,
            "timestamp": Date().timeIntervalSince1970
        ]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let calories = applicationContext["consumedCalories"] as? Double {
                self.receivedCalories = calories
            }
            if let budget = applicationContext["calorieBudget"] as? Double {
                self.receivedBudget = budget
            }
            if let templates = applicationContext["templates"] as? [[String: Any]] {
                self.receivedTemplates = templates
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
