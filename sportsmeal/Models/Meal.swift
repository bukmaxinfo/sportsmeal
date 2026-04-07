import Foundation
import SwiftData

@Model
final class Meal {
    @Attribute(.externalStorage) var photoData: Data?
    var foodItems: [FoodItem]
    var totalCalories: Double
    var timestamp: Date
    var notes: String?
    var cuisineType: String?
    var portionMultiplier: Double?

    init(
        photoData: Data? = nil,
        foodItems: [FoodItem] = [],
        totalCalories: Double = 0,
        timestamp: Date = Date(),
        notes: String? = nil,
        cuisineType: String? = nil,
        portionMultiplier: Double? = nil
    ) {
        self.photoData = photoData
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.timestamp = timestamp
        self.notes = notes
        self.cuisineType = cuisineType
        self.portionMultiplier = portionMultiplier
    }

    var totalProtein: Double {
        foodItems.compactMap(\.proteinGrams).reduce(0, +)
    }

    var totalCarbs: Double {
        foodItems.compactMap(\.carbsGrams).reduce(0, +)
    }

    var totalFat: Double {
        foodItems.compactMap(\.fatGrams).reduce(0, +)
    }

    var hasMacros: Bool {
        foodItems.contains { $0.proteinGrams != nil }
    }
}

struct FoodItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var calories: Double
    var portionSize: String
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?

    init(name: String, calories: Double, portionSize: String = "", proteinGrams: Double? = nil, carbsGrams: Double? = nil, fatGrams: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.portionSize = portionSize
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}
