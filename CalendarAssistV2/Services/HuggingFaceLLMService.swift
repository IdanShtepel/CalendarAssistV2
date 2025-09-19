import Foundation

struct HuggingFaceLLMService {
    static let shared = HuggingFaceLLMService()
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "HuggingFaceAPIKey") ?? ""
    }
    
    private var modelEndpoint: String {
        let selectedModel = UserDefaults.standard.string(forKey: "SelectedLLMModel") ?? "microsoft/DialoGPT-medium"
        return "https://api-inference.huggingface.co/models/\(selectedModel)"
    }
    
    private init() {}
    
    func generateResponse(
        for userMessage: String,
        conversationHistory: [ChatMessage] = [],
        systemPrompt: String = "You are a helpful calendar assistant."
    ) async throws -> String {
        
        // Validate API key is configured
        guard !apiKey.isEmpty else {
            throw LLMError.apiKeyNotConfigured
        }
        
        // Prepare the conversation context
        let conversationContext = buildConversationContext(
            systemPrompt: systemPrompt,
            conversationHistory: conversationHistory,
            userMessage: userMessage
        )
        
        // Create the request payload
        let payload: [String: Any] = [
            "inputs": conversationContext,
            "parameters": [
                "max_length": 200,
                "temperature": 0.7,
                "do_sample": true,
                "top_p": 0.9,
                "return_full_text": false
            ],
            "options": [
                "wait_for_model": true
            ]
        ]
        
        // Create the HTTP request
        guard let url = URL(string: modelEndpoint) else {
            throw LLMError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                    print("HTTP Error: \(httpResponse.statusCode)")
                    throw LLMError.httpError(httpResponse.statusCode)
                }
            }
            
            // Parse the response
            return try parseResponse(data)
            
        } catch {
            if error is LLMError {
                throw error
            } else {
                throw LLMError.networkError(error)
            }
        }
    }
    
    private func buildConversationContext(
        systemPrompt: String,
        conversationHistory: [ChatMessage],
        userMessage: String
    ) -> String {
        var context = systemPrompt + "\n\n"
        
        // Add recent conversation history (last 5 messages for context)
        let recentMessages = Array(conversationHistory.suffix(5))
        
        for message in recentMessages {
            let role = message.isFromUser ? "User" : "Assistant"
            context += "\(role): \(message.text)\n"
        }
        
        context += "User: \(userMessage)\nAssistant:"
        
        return context
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        do {
            // First try to parse as array (standard Hugging Face response)
            if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResponse = jsonArray.first,
               let generatedText = firstResponse["generated_text"] as? String {
                
                // Clean up the response
                return cleanUpResponse(generatedText)
            }
            
            // Fallback: try to parse as object
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let generatedText = jsonObject["generated_text"] as? String {
                
                return cleanUpResponse(generatedText)
            }
            
            // If we get here, check for error in response
            if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = jsonObject["error"] as? String {
                print("API Error: \(error)")
                throw LLMError.apiError(error)
            }
            
            throw LLMError.invalidResponse
            
        } catch {
            if error is LLMError {
                throw error
            } else {
                print("JSON Parsing Error: \(error)")
                throw LLMError.parsingError(error)
            }
        }
    }
    
    private func cleanUpResponse(_ text: String) -> String {
        // Remove any unwanted prefixes that might come from the model
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove "Assistant:" prefix if present
        if cleaned.hasPrefix("Assistant:") {
            cleaned = String(cleaned.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Ensure the response is not empty
        if cleaned.isEmpty {
            return "I'm here to help you with your calendar. What would you like to know?"
        }
        
        return cleaned
    }
}


// MARK: - Alternative Models
extension HuggingFaceLLMService {
    static func createWithModel(_ modelName: String) -> HuggingFaceLLMService {
        var service = HuggingFaceLLMService.shared
        // Note: This would need to be refactored to allow different models
        // For now, we'll use the default model
        return service
    }
    
    // Popular models for chat/conversation:
    // - "microsoft/DialoGPT-medium"
    // - "microsoft/DialoGPT-large" 
    // - "facebook/blenderbot-400M-distill"
    // - "microsoft/blenderbot-3B"
}