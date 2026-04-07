import Foundation
import UserNotifications

struct NotificationService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    /// Schedule a weekly progress summary notification every Sunday at 8 PM
    static func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Progress"
        content.body = "Check your weekly nutrition summary and keep your streak going!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 20

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-summary", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    /// Daily reminder to log meals (if no meals logged today)
    static func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "You haven't logged any meals today. Tap to scan your next meal."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
