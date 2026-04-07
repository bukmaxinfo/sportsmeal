import Foundation

struct MealSuggestion: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let estimatedCalories: Int
    let category: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.estimatedCalories = try container.decode(Int.self, forKey: .estimatedCalories)
        self.category = try container.decode(String.self, forKey: .category)
    }

    enum CodingKeys: String, CodingKey {
        case name, description, estimatedCalories, category
    }
}

struct MealSuggestionResponse: Codable {
    let suggestions: [MealSuggestion]
}

/// Suggests meals based on remaining calorie budget and dietary preferences
actor MealRecommendationService {
    private let client = ClaudeAPIClient.shared

    func suggestMeals(
        remainingCalories: Int,
        dietaryPreference: String,
        recentMealNames: [String],
        mealType: String? = nil,
        macroGuidance: String? = nil
    ) async throws -> [MealSuggestion] {
        var prompt = """
        Suggest 3 meal ideas that fit within \(remainingCalories) kcal.
        Dietary preference: \(dietaryPreference.isEmpty ? "None" : dietaryPreference)
        """

        if let macroGuidance = macroGuidance {
            prompt += "\n\(macroGuidance)"
        }

        if !recentMealNames.isEmpty {
            prompt += "\nRecent meals (avoid repetition): \(recentMealNames.prefix(5).joined(separator: ", "))"
        }

        if let mealType = mealType {
            prompt += "\nMeal type: \(mealType)"
        }

        prompt += """

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {
          "suggestions": [
            {
              "name": "Meal name",
              "description": "Brief description with key ingredients",
              "estimatedCalories": 400,
              "category": "Breakfast|Lunch|Dinner|Snack"
            }
          ]
        }

        Make suggestions practical, easy to prepare, and varied.
        """

        let response = try await client.sendTextAndDecode(MealSuggestionResponse.self, prompt: prompt)
        return response.suggestions
    }
}
