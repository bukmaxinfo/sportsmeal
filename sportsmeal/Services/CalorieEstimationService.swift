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

    private var isChineseLocale: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }

    private func isChineseCuisine(_ cuisine: String?) -> Bool {
        guard let c = cuisine?.lowercased() else { return isChineseLocale }
        return c.contains("chinese") || c.contains("中") || c.isEmpty && isChineseLocale
    }

    private func buildPrompt(portionMultiplier: Double, notes: String?, cuisine: String?) -> String {
        var prompt = "Analyze this meal photo and estimate the calories for each food item visible.\n\n"

        if isChineseCuisine(cuisine) {
            prompt += """
            This is Chinese cuisine. You MUST apply these rules for accurate estimation:

            COOKING METHOD CALORIE ADJUSTMENTS — Chinese cooking uses significant oil:
            • Stir-fry (炒): Add 80-150 kcal per dish for cooking oil (2-4 tbsp). Dishes like 回锅肉, 宫保鸡丁, 鱼香肉丝 are oil-heavy.
            • Deep-fried (炸/煎): Add 150-300 kcal. Items like 炸鸡腿, 春卷, 锅贴 absorb oil.
            • Red-braised (红烧): Add 80-120 kcal for sugar + oil. 红烧肉 is ~500-600 kcal per serving due to pork belly fat + sugar glaze.
            • Steamed (蒸): Minimal added calories. 蒸鱼, 蒸蛋 are relatively accurate from base ingredients.
            • Boiled/soup (煮/汤): Low added fat unless it's bone broth (骨汤) — add 50-100 kcal for fat layer.
            • Hot pot (火锅): Estimate per ingredient. Broth base adds 100-300 kcal depending on 清汤 vs 麻辣 (spicy oil).
            • Dry pot (干锅): Very oil-heavy, add 200-300 kcal for oil.

            COMMON PORTION SIZE REFERENCES:
            • 米饭 (steamed rice): One standard bowl (碗) = ~200g cooked = ~230 kcal. Restaurant bowls are larger (~300g = 350 kcal).
            • 面条/粉 (noodles): One bowl = 200-300g cooked noodles = 280-400 kcal (before sauce/toppings).
            • 馒头 (steamed bun): One piece ~100g = 220 kcal.
            • 包子 (filled bun): One piece ~120g = 250-350 kcal depending on filling (肉包 > 菜包).
            • 饺子 (dumplings): Per piece = 40-60 kcal. A typical serving is 10-15 pieces = 400-750 kcal.
            • 小笼包: Per piece = 50-70 kcal. A steamer basket of 8 = 400-560 kcal.

            SHARED PLATES — Chinese meals are often family-style:
            • If you see a large plate meant for sharing (like a whole 水煮鱼 or 回锅肉), estimate the TOTAL dish calories, then note "whole dish" in portionSize. The user will adjust with the portion multiplier.
            • If it looks like an individual portion (盖浇饭, 套餐, single bowl of noodles), estimate as one serving.

            HIGH-CALORIE DISHES PEOPLE UNDERESTIMATE:
            • 水煮鱼/水煮肉片: 800-1200 kcal per dish (massive amount of oil despite "boiled" name)
            • 糖醋排骨/糖醋里脊: 600-800 kcal (deep fried + sugar glaze)
            • 地三鲜: 500-700 kcal (eggplant absorbs enormous oil)
            • 麻婆豆腐: 400-550 kcal (more oil than expected)
            • 蛋炒饭: 500-650 kcal per plate (oil + egg + rice)
            • 炒面/炒河粉: 600-800 kcal (oil-heavy)
            • 烧烤 (BBQ skewers): 80-150 kcal per skewer depending on meat vs vegetable

            LOW-CALORIE OPTIONS:
            • 凉拌黄瓜/凉拌菜: 50-100 kcal
            • 清蒸鱼: 200-300 kcal
            • 白灼虾/白灼菜心: 100-200 kcal
            • 紫菜蛋花汤: 50-80 kcal


            """

            if isChineseLocale {
                prompt += "Return food names in Chinese (e.g., 宫保鸡丁, 米饭, 红烧肉).\n\n"
            }
        } else if let cuisine = cuisine, !cuisine.isEmpty {
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
            {"name": "food name", "calories": 250, "portionSize": "1 serving / 200g / 1 piece", "protein_g": 20.0, "carbs_g": 30.0, "fat_g": 8.0}
          ],
          "totalCalories": 500
        }

        IMPORTANT RULES:
        - Estimate the VISIBLE portion in the photo, not a textbook serving size.
        - Always account for cooking oil, sauces, and hidden fats — these are the #1 source of underestimation.
        - For each food item, estimate protein, carbs, and fat in grams.
        - Use grams or common units (碗/个/片/串) for portionSize.
        - If you can't identify a food, give your best guess based on appearance.
        """

        return prompt
    }
}
