import Foundation

// MARK: - API Error Types

enum APIError: LocalizedError, Sendable {
    case missingAPIKey
    case invalidURL
    case httpError(statusCode: Int, body: String)
    case decodingError(description: String)
    case networkError(description: String)
    case emptyResponse
    case rateLimited
    case responseTruncated
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is not configured. Please add your key to Secrets.swift."
        case .invalidURL:
            return "Invalid API URL."
        case .httpError(let code, _):
            return "Server error (HTTP \(code)). Please try again."
        case .decodingError:
            return "Failed to parse the plan response. Please try again."
        case .networkError(let description):
            return "Network error: \(description)"
        case .emptyResponse:
            return "Received an empty response. Please try again."
        case .rateLimited:
            return "Rate limited. Please wait a moment and try again."
        case .responseTruncated:
            return "The response was truncated. Please try again."
        case .notImplemented:
            return "This feature is not yet available."
        }
    }
}

// MARK: - Request/Response Envelopes

private struct ClaudeRequestBody: Encodable, Sendable {
    let model: String
    let maxTokens: Int
    let system: String
    let messages: [ClaudeMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

private struct ClaudeMessage: Encodable, Sendable {
    let role: String
    let content: String
}

private struct ClaudeAPIResponse: Decodable, Sendable {
    let content: [ContentBlock]
    let stopReason: String?

    struct ContentBlock: Decodable, Sendable {
        let type: String
        let text: String?
    }

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }
}

// MARK: - Claude API Service

actor ClaudeAPIService {
    static let shared = ClaudeAPIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generate Plan

    func generatePlan(from payload: OnboardingPayload) async throws -> PlanResponse {
        let apiKey = Secrets.claudeAPIKey
        guard apiKey != "YOUR_API_KEY_HERE", !apiKey.isEmpty else {
            throw APIError.missingAPIKey
        }

        guard let url = URL(string: AppConstants.claudeAPIBaseURL) else {
            throw APIError.invalidURL
        }

        let userMessage: String
        do {
            userMessage = try buildUserMessage(from: payload)
        } catch {
            throw APIError.decodingError(description: "Failed to encode payload: \(error.localizedDescription)")
        }

        let requestBody = ClaudeRequestBody(
            model: AppConstants.claudeModel,
            maxTokens: AppConstants.maxTokens,
            system: systemPrompt(for: payload),
            messages: [ClaudeMessage(role: "user", content: userMessage)]
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(description: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(description: "Invalid server response")
        }

        if httpResponse.statusCode == 429 {
            throw APIError.rateLimited
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(statusCode: httpResponse.statusCode, body: body)
        }

        let apiResponse: ClaudeAPIResponse
        do {
            apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)
        } catch {
            throw APIError.decodingError(description: error.localizedDescription)
        }

        if apiResponse.stopReason == "max_tokens" {
            throw APIError.responseTruncated
        }

        guard let text = apiResponse.content.first(where: { $0.type == "text" })?.text,
              !text.isEmpty else {
            throw APIError.emptyResponse
        }

        let cleanedJSON = stripMarkdownFences(from: text)

        do {
            return try JSONDecoder().decode(PlanResponse.self, from: Data(cleanedJSON.utf8))
        } catch {
            throw APIError.decodingError(description: error.localizedDescription)
        }
    }

    // MARK: - Phase 3 Stubs

    func adaptPlan(currentPlan: PlanResponse, feedback: String) async throws -> PlanResponse {
        throw APIError.notImplemented
    }

    func generateWeeklyRecap(sessions: [String]) async throws -> String {
        throw APIError.notImplemented
    }

    func swapMeal(current: MealData, preferences: String) async throws -> MealData {
        throw APIError.notImplemented
    }

    // MARK: - Private Helpers

    private func buildUserMessage(from payload: OnboardingPayload) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(payload)
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return "Generate a personalized fitness and nutrition plan based on this user profile:\n\n\(json)"
    }

    private func stripMarkdownFences(from text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```json") {
            result = String(result.dropFirst(7))
        } else if result.hasPrefix("```") {
            result = String(result.dropFirst(3))
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func systemPrompt(for payload: OnboardingPayload) -> String {
        """
        You are a certified personal trainer and sports nutritionist AI. Generate a personalized \
        workout and meal plan based on the user's profile data.

        IMPORTANT CONSTRAINTS:
        - All exercises must be BODYWEIGHT ONLY (no equipment required)
        - The workout plan must have exactly \(payload.availableDaysPerWeek) training days per week
        - Each session should target approximately \(payload.sessionLengthMinutes) minutes
        - Tailor difficulty and volume to the user's activity level and goals
        - Respect all dietary restrictions listed in the profile
        - Provide 2-3 meal options per meal slot for variety

        You must respond with ONLY valid JSON (no markdown, no explanation) matching this exact schema:

        {
          "exercisePlan": {
            "weekCount": <integer, typically 4>,
            "difficulty": <integer 1-4, where 1=beginner 2=intermediate 3=advanced 4=elite>,
            "workoutDays": [
              {
                "dayOfWeek": <integer 1-7, Monday=1>,
                "title": "<string, e.g. 'Upper Push Day'>",
                "type": "<string, e.g. 'upperPush', 'upperPull', 'lowerBody', 'core', 'fullBodyHIIT'>",
                "estimatedMinutes": <integer>,
                "exercises": [
                  {
                    "name": "<string>",
                    "sets": <integer>,
                    "targetReps": "<string, e.g. '8-12' or '30s'>",
                    "restSeconds": <integer>,
                    "formCues": "<string with key form tips>",
                    "muscleGroups": ["<string>"]
                  }
                ]
              }
            ]
          },
          "mealPlan": {
            "dailyCalories": <integer>,
            "dailyProteinG": <integer>,
            "dailyCarbsG": <integer>,
            "dailyFatG": <integer>,
            "meals": [
              {
                "name": "<string, e.g. 'Breakfast'>",
                "timeSlot": "<string: 'Breakfast', 'Lunch', 'Dinner', or 'Snack'>",
                "options": [
                  {
                    "title": "<string>",
                    "ingredients": ["<string>"],
                    "calories": <integer>,
                    "proteinG": <integer>,
                    "carbsG": <integer>,
                    "fatG": <integer>,
                    "preparationNotes": "<string>"
                  }
                ]
              }
            ]
          },
          "metadata": {
            "estimatedWeeklyMinutes": <integer>,
            "focusAreas": ["<string>"],
            "notes": "<string with brief overview of the plan rationale>"
          }
        }

        Respond with ONLY the JSON object. No other text.
        """
    }
}
