import Foundation
import UIKit

struct MenuDish: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let estimatedCalories: Int
    let fitsWithinBudget: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.estimatedCalories = try container.decode(Int.self, forKey: .estimatedCalories)
        self.fitsWithinBudget = try container.decode(Bool.self, forKey: .fitsWithinBudget)
    }

    enum CodingKeys: String, CodingKey {
        case name, description, estimatedCalories, fitsWithinBudget
    }
}

struct MenuScanResult: Codable {
    let restaurantType: String
    let dishes: [MenuDish]
}

/// Scans restaurant menus and estimates dish calories
actor MenuScannerService {
    private let client = ClaudeAPIClient.shared

    func scanMenu(image: UIImage, remainingCalories: Int, dietaryPreference: String) async throws -> MenuScanResult {
        var prompt = """
        Analyze this restaurant menu photo. Identify the dishes and estimate calories for each.
        The user has \(remainingCalories) kcal remaining in their daily budget.
        """

        if !dietaryPreference.isEmpty {
            prompt += "\nDietary preference: \(dietaryPreference)"
        }

        prompt += """

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {
          "restaurantType": "Italian / Chinese / etc",
          "dishes": [
            {
              "name": "Dish name",
              "description": "Brief description",
              "estimatedCalories": 500,
              "fitsWithinBudget": true
            }
          ]
        }

        Set fitsWithinBudget to true if estimatedCalories <= \(remainingCalories). List dishes in order from best fit to least fit for the calorie budget.
        """

        return try await client.sendVisionAndDecode(MenuScanResult.self, image: image, prompt: prompt)
    }
}
