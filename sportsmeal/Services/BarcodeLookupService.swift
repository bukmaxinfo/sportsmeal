import Foundation

struct BarcodeProduct: Codable {
    let name: String
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let servingSize: String

    /// Parse from OpenFoodFacts API response
    static func from(openFoodFactsData: Data) -> BarcodeProduct? {
        struct OFFResponse: Codable {
            let status: Int
            let product: OFFProduct?
        }
        struct OFFProduct: Codable {
            let product_name: String?
            let nutriments: OFFNutriments?
            let serving_size: String?
        }
        struct OFFNutriments: Codable {
            let energy_kcal_100g: Double?
            let proteins_100g: Double?
            let carbohydrates_100g: Double?
            let fat_100g: Double?
            // Per serving
            let energy_kcal_serving: Double?
            let proteins_serving: Double?
            let carbohydrates_serving: Double?
            let fat_serving: Double?

            enum CodingKeys: String, CodingKey {
                case energy_kcal_100g = "energy-kcal_100g"
                case proteins_100g = "proteins_100g"
                case carbohydrates_100g = "carbohydrates_100g"
                case fat_100g = "fat_100g"
                case energy_kcal_serving = "energy-kcal_serving"
                case proteins_serving = "proteins_serving"
                case carbohydrates_serving = "carbohydrates_serving"
                case fat_serving = "fat_serving"
            }
        }

        guard let response = try? JSONDecoder().decode(OFFResponse.self, from: openFoodFactsData),
              response.status == 1,
              let product = response.product,
              let name = product.product_name,
              let nutriments = product.nutriments else {
            return nil
        }

        // Prefer per-serving values, fall back to per-100g
        let cals = nutriments.energy_kcal_serving ?? nutriments.energy_kcal_100g ?? 0
        let protein = nutriments.proteins_serving ?? nutriments.proteins_100g ?? 0
        let carbs = nutriments.carbohydrates_serving ?? nutriments.carbohydrates_100g ?? 0
        let fat = nutriments.fat_serving ?? nutriments.fat_100g ?? 0
        let serving = product.serving_size ?? "100g"

        return BarcodeProduct(
            name: name,
            calories: cals,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
            servingSize: serving
        )
    }
}

actor BarcodeLookupService {
    func lookup(barcode: String) async throws -> BarcodeProduct? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("SportsMeal iOS App", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        return BarcodeProduct.from(openFoodFactsData: data)
    }
}
