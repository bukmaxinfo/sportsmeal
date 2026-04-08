import Foundation
import SwiftData

enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case produce = "Produce"
    case protein = "Protein"
    case dairy = "Dairy"
    case grains = "Grains"
    case condiments = "Condiments"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .protein: return "fish.fill"
        case .dairy: return "cup.and.saucer.fill"
        case .grains: return "basket.fill"
        case .condiments: return "drop.fill"
        case .frozen: return "snowflake"
        case .beverages: return "waterbottle.fill"
        case .snacks: return "birthday.cake.fill"
        case .other: return "bag.fill"
        }
    }
}

@Model
final class PantryItem {
    var name: String = ""
    var category: IngredientCategory = IngredientCategory.other
    var quantity: String = ""
    var addedDate: Date = Date()
    var expirationDate: Date?
    var isAvailable: Bool = true

    init(
        name: String,
        category: IngredientCategory = .other,
        quantity: String = "",
        addedDate: Date = Date(),
        expirationDate: Date? = nil,
        isAvailable: Bool = true
    ) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.addedDate = addedDate
        self.expirationDate = expirationDate
        self.isAvailable = isAvailable
    }

    var isExpiringSoon: Bool {
        guard let exp = expirationDate else { return false }
        return exp.timeIntervalSinceNow < 3 * 86400 && exp.timeIntervalSinceNow > 0
    }

    var isExpired: Bool {
        guard let exp = expirationDate else { return false }
        return exp < Date()
    }
}
