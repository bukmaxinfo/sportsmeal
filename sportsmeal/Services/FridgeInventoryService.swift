import Foundation
import UIKit

struct FridgeScanResult: Codable {
    let items: [ScannedIngredient]
}

struct ScannedIngredient: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let estimatedQuantity: String
    let estimatedDaysUntilExpiry: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(String.self, forKey: .category)
        self.estimatedQuantity = try container.decode(String.self, forKey: .estimatedQuantity)
        self.estimatedDaysUntilExpiry = try container.decodeIfPresent(Int.self, forKey: .estimatedDaysUntilExpiry)
    }

    enum CodingKeys: String, CodingKey {
        case name, category, estimatedQuantity, estimatedDaysUntilExpiry
    }
}

/// Scans fridge photos to identify ingredients using Claude Vision
actor FridgeInventoryService {
    private let client = ClaudeAPIClient.shared

    func scanFridge(image: UIImage) async throws -> FridgeScanResult {
        let prompt = """
        Identify all visible food ingredients in this fridge/pantry photo.

        Respond ONLY with valid JSON in this exact format (no markdown, no explanation):
        {
          "items": [
            {
              "name": "ingredient name",
              "category": "Produce|Protein|Dairy|Grains|Condiments|Frozen|Beverages|Snacks|Other",
              "estimatedQuantity": "2 lbs / 1 carton / 3 pieces",
              "estimatedDaysUntilExpiry": 5
            }
          ]
        }

        Only list raw ingredients, not prepared meals. If items are partially hidden, list what's reasonably identifiable. For estimatedDaysUntilExpiry, use null if you can't estimate.
        """

        return try await client.sendVisionAndDecode(FridgeScanResult.self, image: image, prompt: prompt)
    }
}
