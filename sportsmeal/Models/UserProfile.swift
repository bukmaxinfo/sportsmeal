import Foundation
import SwiftData

enum Sex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"
    case extraActive = "Extra Active"

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .extraActive: return 1.9
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Exercise 1-3 days/week"
        case .moderate: return "Exercise 3-5 days/week"
        case .active: return "Exercise 6-7 days/week"
        case .extraActive: return "Very intense exercise daily"
        }
    }
}

enum DietType: String, Codable, CaseIterable, Identifiable {
    case none = "No Preference"
    case keto = "Keto"
    case whole30 = "Whole 30"
    case paleo = "Paleo"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case mediterranean = "Mediterranean"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .none: return "No dietary restrictions"
        case .keto: return "High fat, very low carb (<20g/day)"
        case .whole30: return "No sugar, grains, dairy, or legumes for 30 days"
        case .paleo: return "Whole foods, no processed items, grains, or dairy"
        case .vegan: return "No animal products"
        case .vegetarian: return "No meat or fish"
        case .mediterranean: return "Plant-based, healthy fats, whole grains, seafood"
        case .lowCarb: return "Reduced carbohydrate intake"
        case .highProtein: return "Emphasis on protein-rich foods"
        }
    }
}

@Model
final class UserProfile {
    var name: String = ""
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var heightCm: Double = 170
    var weightKg: Double = 70
    var sex: Sex = Sex.male
    var activityLevel: ActivityLevel = ActivityLevel.moderate
    var goalWeightKg: Double?
    var dietType: DietType?
    var dietaryRestrictions: [String]?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 25
    }

    init(
        name: String = "",
        dateOfBirth: Date? = nil,
        heightCm: Double = 170,
        weightKg: Double = 70,
        sex: Sex = .male,
        activityLevel: ActivityLevel = .moderate,
        goalWeightKg: Double? = nil,
        dietType: DietType? = nil,
        dietaryRestrictions: [String]? = nil
    ) {
        self.name = name
        self.dateOfBirth = dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.sex = sex
        self.activityLevel = activityLevel
        self.goalWeightKg = goalWeightKg
        self.dietType = dietType
        self.dietaryRestrictions = dietaryRestrictions
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Summary string for use in AI prompts
    var dietarySummary: String {
        var parts: [String] = []
        if let diet = dietType, diet != .none {
            parts.append(diet.rawValue)
        }
        if let restrictions = dietaryRestrictions, !restrictions.isEmpty {
            parts.append("Avoids: \(restrictions.joined(separator: ", "))")
        }
        return parts.isEmpty ? "No dietary restrictions" : parts.joined(separator: ". ")
    }

    // BMI = weight(kg) / height(m)²
    var bmi: Double {
        let heightM = heightCm / 100.0
        guard heightM > 0 else { return 0 }
        return weightKg / (heightM * heightM)
    }

    var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    // BMR using Mifflin-St Jeor equation
    // Male:   10 × weight(kg) + 6.25 × height(cm) - 5 × age - 5
    // Female: 10 × weight(kg) + 6.25 × height(cm) - 5 × age - 161
    var bmr: Double {
        let base = 10.0 * weightKg + 6.25 * heightCm - 5.0 * Double(age)
        switch sex {
        case .male: return base + 5
        case .female: return base - 161
        }
    }

    // Total Daily Energy Expenditure
    var tdee: Double {
        return bmr * activityLevel.multiplier
    }

    /// Recommended daily macro targets based on diet type
    var macroTargets: (protein: Double, carbs: Double, fat: Double) {
        let cals = bmr // Use BMR as baseline budget
        switch dietType {
        case .keto:
            // 25% protein, 5% carbs, 70% fat
            return (protein: cals * 0.25 / 4, carbs: cals * 0.05 / 4, fat: cals * 0.70 / 9)
        case .lowCarb:
            // 30% protein, 20% carbs, 50% fat
            return (protein: cals * 0.30 / 4, carbs: cals * 0.20 / 4, fat: cals * 0.50 / 9)
        case .highProtein:
            // 40% protein, 35% carbs, 25% fat
            return (protein: cals * 0.40 / 4, carbs: cals * 0.35 / 4, fat: cals * 0.25 / 9)
        default:
            // Balanced: 25% protein, 50% carbs, 25% fat
            return (protein: cals * 0.25 / 4, carbs: cals * 0.50 / 4, fat: cals * 0.25 / 9)
        }
    }
}
