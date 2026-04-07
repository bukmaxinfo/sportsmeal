import Foundation
import UIKit

/// Shared client for all Claude API interactions.
/// Handles authentication, request building, response parsing, and image encoding.
actor ClaudeAPIClient {
    static let shared = ClaudeAPIClient()

    enum APIError: LocalizedError {
        case noAPIKey
        case invalidImage
        case networkError(String)
        case parsingError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "API key not configured. Go to Profile → API Key to set it up."
            case .invalidImage: return "Could not process the image"
            case .networkError(let msg): return "Network error: \(msg)"
            case .parsingError(let msg): return "Could not parse response: \(msg)"
            }
        }
    }

    // MARK: - Text-only request

    func sendText(prompt: String, maxTokens: Int = 1024) async throws -> String {
        let requestBody: [String: Any] = [
            "model": APIConfig.model,
            "max_tokens": maxTokens,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        return try await send(body: requestBody)
    }

    // MARK: - Vision request (image + text)

    func sendVision(image: UIImage, prompt: String, maxTokens: Int = 1024) async throws -> String {
        let resized = downscale(image, maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": APIConfig.model,
            "max_tokens": maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        return try await send(body: requestBody)
    }

    // MARK: - JSON decoding helper

    func sendVisionAndDecode<T: Decodable>(_ type: T.Type, image: UIImage, prompt: String, maxTokens: Int = 1024) async throws -> T {
        let text = try await sendVision(image: image, prompt: prompt, maxTokens: maxTokens)
        return try decodeJSON(type, from: text)
    }

    func sendTextAndDecode<T: Decodable>(_ type: T.Type, prompt: String, maxTokens: Int = 2048) async throws -> T {
        let text = try await sendText(prompt: prompt, maxTokens: maxTokens)
        return try decodeJSON(type, from: text)
    }

    // MARK: - Private

    private func send(body: [String: Any]) async throws -> String {
        guard let apiKey = APIConfig.anthropicAPIKey else {
            throw APIError.noAPIKey
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: URL(string: APIConfig.anthropicBaseURL)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid response")
        }

        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw APIError.networkError("HTTP \(http.statusCode): \(body)")
        }

        struct ClaudeResponse: Codable {
            struct Content: Codable {
                let text: String?
                let type: String
            }
            let content: [Content]
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let text = textContent.text else {
            throw APIError.parsingError("No text in response")
        }

        return text
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw APIError.parsingError("Could not encode response text")
        }

        return try JSONDecoder().decode(type, from: data)
    }

    private func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale: CGFloat = size.width > size.height
            ? maxDimension / size.width
            : maxDimension / size.height

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
