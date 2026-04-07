import Foundation
import UIKit

struct CalorieEstimationResult: Codable {
    let foods: [EstimatedFood]
    let totalCalories: Double
}

struct EstimatedFood: Codable {
    let name: String
    let calories: Double
    let portionSize: String
    let proteinGrams: Double?
    let carbsGrams: Double?
    let fatGrams: Double?

    enum CodingKeys: String, CodingKey {
        case name, calories, portionSize
        case proteinGrams = "protein_g"
        case carbsGrams = "carbs_g"
        case fatGrams = "fat_g"
    }
}

/// Thin service for meal photo analysis — delegates HTTP to ClaudeAPIClient
actor CalorieEstimationService {
    private let client = ClaudeAPIClient.shared

    func estimateCalories(from image: UIImage, portionMultiplier: Double = 1.0, notes: String? = nil, cuisine: String? = nil) async throws -> CalorieEstimationResult {
        let prompt = buildPrompt(portionMultiplier: portionMultiplier, notes: notes, cuisine: cuisine)
        var result = try await client.sendVisionAndDecode(CalorieEstimationResult.self, image: image, prompt: prompt)

        if portionMultiplier != 1.0 {
            result = CalorieEstimationResult(
                foods: result.foods.map { food in
                    EstimatedFood(
                        name: food.name,
                        calories: food.calories * portionMultiplier,
                        portionSize: food.portionSize,
                        proteinGrams: food.proteinGrams.map { $0 * portionMultiplier },
                        carbsGrams: food.carbsGrams.map { $0 * portionMultiplier },
                        fatGrams: food.fatGrams.map { $0 * portionMultiplier }
                    )
                },
                totalCalories: result.totalCalories * portionMultiplier
            )
        }

        return result
    }

    private func buildPrompt(portionMultiplier: Double, notes: String?, cuisine: String?) -> String {
        var prompt = "Analyze this meal photo and estimate the calories for each food item visible.\n\n"

        if let cuisine = cuisine, !cuisine.isEmpty {
            prompt += "This is \(cuisine) cuisine. Consider typical serving sizes, cooking methods (e.g., oil-heavy stir fry vs steamed), and common ingredients for this cuisine when estimating calories.\n\n"
        }

        if let notes = notes, !notes.isEmpty {
            prompt += "Additional context from the user: \"\(notes)\"\n\n"
        }

        if portionMultiplier != 1.0 {
            prompt += "The user indicates this photo represents \(portionMultiplier)x of a standard serving. Estimate calories for what you see in the photo as-is (I will apply the multiplier separately).\n\n"
        }

        prompt += """
        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {
          "foods": [
            {"name": "food name", "calories": 250, "portionSize": "1 cup / 200g / 1 piece", "protein_g": 20.0, "carbs_g": 30.0, "fat_g": 8.0}
          ],
          "totalCalories": 500
        }

        For each food item, estimate protein, carbs, and fat in grams. Be reasonable with portion estimates based on what you see. If you can't identify a food, give your best guess.
        """

        return prompt
    }
}
