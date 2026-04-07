import Foundation

struct RecipeSuggestion: Codable, Identifiable {
    let id: UUID
    let name: String
    let ingredients: [String]
    let instructions: [String]
    let estimatedCalories: Int
    let prepTimeMinutes: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.ingredients = try container.decode([String].self, forKey: .ingredients)
        self.instructions = try container.decode([String].self, forKey: .instructions)
        self.estimatedCalories = try container.decode(Int.self, forKey: .estimatedCalories)
        self.prepTimeMinutes = try container.decode(Int.self, forKey: .prepTimeMinutes)
    }

    enum CodingKeys: String, CodingKey {
        case name, ingredients, instructions, estimatedCalories, prepTimeMinutes
    }
}

struct RecipeResponse: Codable {
    let recipes: [RecipeSuggestion]
}

/// Generates recipes from pantry ingredients using Claude
actor RecipeService {
    private let client = ClaudeAPIClient.shared

    func generateRecipes(
        ingredients: [String],
        calorieTarget: Int,
        dietaryPreference: String,
        count: Int = 3
    ) async throws -> [RecipeSuggestion] {
        let ingredientList = ingredients.joined(separator: ", ")

        let prompt = """
        I have these ingredients available: \(ingredientList)

        My calorie target for this meal is approximately \(calorieTarget) kcal.
        Dietary preference: \(dietaryPreference.isEmpty ? "None" : dietaryPreference)

        Suggest \(count) recipes I can make with these ingredients (it's OK to assume basic pantry staples like salt, pepper, oil, garlic are available).

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {
          "recipes": [
            {
              "name": "Recipe Name",
              "ingredients": ["ingredient 1 - amount", "ingredient 2 - amount"],
              "instructions": ["Step 1", "Step 2", "Step 3"],
              "estimatedCalories": 450,
              "prepTimeMinutes": 20
            }
          ]
        }

        Prioritize recipes that use ingredients that might expire soon. Keep instructions concise.
        """

        let response = try await client.sendTextAndDecode(RecipeResponse.self, prompt: prompt)
        return response.recipes
    }
}
