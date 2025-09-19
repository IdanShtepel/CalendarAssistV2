import Foundation

struct OpenRouterService {
    static let shared = OpenRouterService()
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "OpenRouterAPIKey") ?? ""
    }
    
    private var selectedModel: String {
        UserDefaults.standard.string(forKey: "OpenRouterModel") ?? "anthropic/claude-3-haiku"
    }
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    private init() {}
    
    func generateResponse(
        for userMessage: String,
        conversationHistory: [ChatMessage] = [],
        systemPrompt: String = "You are a helpful calendar assistant."
    ) async throws -> String {
        
        // Validate API key is configured
        guard !apiKey.isEmpty else {
            throw LLMError.openRouterKeyNotConfigured
        }
        
        // Build messages array for OpenRouter API
        let messages = buildMessages(
            systemPrompt: systemPrompt,
            conversationHistory: conversationHistory,
            userMessage: userMessage
        )
        
        // Create the request payload
        let payload: [String: Any] = [
            "model": selectedModel,
            "messages": messages,
            "max_tokens": 300,
            "temperature": 0.7,
            "top_p": 0.9,
            "stream": false
        ]
        
        // Create the HTTP request
        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CalendarAssistant/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("CalendarAssistant", forHTTPHeaderField: "X-Title")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw LLMError.invalidPayload
        }
        
        // Perform the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    print("OpenRouter HTTP Error: \(httpResponse.statusCode)")
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("Error response: \(errorData)")
                    }
                    throw LLMError.httpError(httpResponse.statusCode)
                }
            }
            
            // Parse the response
            return try parseOpenRouterResponse(data)
            
        } catch {
            if error is LLMError {
                throw error
            } else {
                throw LLMError.networkError(error)
            }
        }
    }
    
    private func buildMessages(
        systemPrompt: String,
        conversationHistory: [ChatMessage],
        userMessage: String
    ) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        
        // Add system message
        messages.append([
            "role": "system",
            "content": systemPrompt
        ])
        
        // Add recent conversation history (last 10 messages for context)
        let recentMessages = Array(conversationHistory.suffix(10))
        
        for message in recentMessages {
            messages.append([
                "role": message.isFromUser ? "user" : "assistant",
                "content": message.text
            ])
        }
        
        // Add current user message
        messages.append([
            "role": "user",
            "content": userMessage
        ])
        
        return messages
    }
    
    private func parseOpenRouterResponse(_ data: Data) throws -> String {
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // Check for error first
                if let error = jsonObject["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("OpenRouter API Error: \(message)")
                    throw LLMError.apiError(message)
                }
                
                // Parse successful response
                if let choices = jsonObject["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    return cleanUpResponse(content)
                }
                
                throw LLMError.invalidResponse
            }
            
            throw LLMError.invalidResponse
            
        } catch {
            if error is LLMError {
                throw error
            } else {
                print("OpenRouter JSON Parsing Error: \(error)")
                throw LLMError.parsingError(error)
            }
        }
    }
    
    private func cleanUpResponse(_ text: String) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure the response is not empty
        if cleaned.isEmpty {
            return "I'm here to help you with your calendar. What would you like to know?"
        }
        
        return cleaned
    }
    
    // Test connection with a simple message
    func testConnection() async throws -> Bool {
        _ = try await generateResponse(
            for: "Hello",
            systemPrompt: "You are a test assistant. Just respond with 'Hello' back."
        )
        return true
    }
}

// MARK: - Available Models
extension OpenRouterService {
    static let availableModels: [LLMModel] = [
        // Claude models (most recommended for calendar tasks)
        LLMModel(
            id: "anthropic/claude-3-haiku",
            name: "Claude 3 Haiku",
            description: "Fast, efficient, great for calendar tasks",
            provider: "Anthropic",
            costPer1MTokens: "$0.25"
        ),
        LLMModel(
            id: "anthropic/claude-3-sonnet",
            name: "Claude 3 Sonnet",
            description: "Balanced performance and intelligence",
            provider: "Anthropic",
            costPer1MTokens: "$3.00"
        ),
        
        // GPT models
        LLMModel(
            id: "openai/gpt-3.5-turbo",
            name: "GPT-3.5 Turbo",
            description: "Popular, well-balanced model",
            provider: "OpenAI",
            costPer1MTokens: "$0.50"
        ),
        LLMModel(
            id: "openai/gpt-4-turbo",
            name: "GPT-4 Turbo",
            description: "Highly capable, more expensive",
            provider: "OpenAI", 
            costPer1MTokens: "$10.00"
        ),
        
        // Llama models (open source)
        LLMModel(
            id: "meta-llama/llama-3-8b-instruct",
            name: "Llama 3 8B",
            description: "Fast, open source model",
            provider: "Meta",
            costPer1MTokens: "$0.07"
        ),
        LLMModel(
            id: "meta-llama/llama-3-70b-instruct",
            name: "Llama 3 70B",
            description: "Powerful open source model",
            provider: "Meta",
            costPer1MTokens: "$0.59"
        ),
        
        // Gemini models
        LLMModel(
            id: "google/gemini-flash-1.5",
            name: "Gemini Flash 1.5",
            description: "Fast Google model",
            provider: "Google",
            costPer1MTokens: "$0.075"
        ),
        
        // Other efficient models
        LLMModel(
            id: "mistralai/mistral-7b-instruct",
            name: "Mistral 7B",
            description: "Efficient European model",
            provider: "Mistral AI",
            costPer1MTokens: "$0.07"
        )
    ]
}

struct LLMModel {
    let id: String
    let name: String
    let description: String
    let provider: String
    let costPer1MTokens: String
}