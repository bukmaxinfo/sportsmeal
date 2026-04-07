import Foundation
import SwiftData

@Model
final class MealTemplate {
    var name: String
    var foodItems: [FoodItem]
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var useCount: Int
    var lastUsed: Date?
    var createdAt: Date

    init(
        name: String,
        foodItems: [FoodItem],
        totalCalories: Double,
        totalProtein: Double = 0,
        totalCarbs: Double = 0,
        totalFat: Double = 0
    ) {
        self.name = name
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.useCount = 0
        self.lastUsed = nil
        self.createdAt = Date()
    }

    /// Suggested meal category based on time of day
    static func suggestedCategory(for date: Date = Date()) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return "Breakfast"
        case 11..<14: return "Lunch"
        case 14..<17: return "Snack"
        default: return "Dinner"
        }
    }
}
