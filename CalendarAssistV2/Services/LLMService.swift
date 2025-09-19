import Foundation

enum LLMProvider: String, CaseIterable {
    case huggingFace = "HuggingFace"
    case openRouter = "OpenRouter"
    
    var displayName: String {
        switch self {
        case .huggingFace:
            return "Hugging Face"
        case .openRouter:
            return "OpenRouter"
        }
    }
    
    var description: String {
        switch self {
        case .huggingFace:
            return "Free models, good for basic conversations"
        case .openRouter:
            return "Premium models, advanced capabilities"
        }
    }
    
    var setupInstructions: String {
        switch self {
        case .huggingFace:
            return "1. Visit huggingface.co\n2. Create account\n3. Go to Settings → Access Tokens\n4. Create 'Read' token"
        case .openRouter:
            return "1. Visit openrouter.ai\n2. Create account\n3. Go to Keys\n4. Create new API key"
        }
    }
}

struct LLMService {
    static let shared = LLMService()
    
    private var currentProvider: LLMProvider {
        let providerString = UserDefaults.standard.string(forKey: "SelectedLLMProvider") ?? LLMProvider.openRouter.rawValue
        return LLMProvider(rawValue: providerString) ?? .openRouter
    }
    
    private init() {}
    
    func generateResponse(
        for userMessage: String,
        conversationHistory: [ChatMessage] = [],
        systemPrompt: String = "You are a helpful calendar assistant."
    ) async throws -> String {
        
        switch currentProvider {
        case .huggingFace:
            return try await HuggingFaceLLMService.shared.generateResponse(
                for: userMessage,
                conversationHistory: conversationHistory,
                systemPrompt: systemPrompt
            )
        case .openRouter:
            return try await OpenRouterService.shared.generateResponse(
                for: userMessage,
                conversationHistory: conversationHistory,
                systemPrompt: systemPrompt
            )
        }
    }
    
    func testConnection() async throws -> Bool {
        switch currentProvider {
        case .huggingFace:
            _ = try await HuggingFaceLLMService.shared.generateResponse(
                for: "Hello",
                systemPrompt: "Just say 'Hello' back."
            )
            return true
        case .openRouter:
            return try await OpenRouterService.shared.testConnection()
        }
    }
    
    func isConfigured() -> Bool {
        switch currentProvider {
        case .huggingFace:
            return !(UserDefaults.standard.string(forKey: "HuggingFaceAPIKey") ?? "").isEmpty
        case .openRouter:
            return !(UserDefaults.standard.string(forKey: "OpenRouterAPIKey") ?? "").isEmpty
        }
    }
    
    func getProviderStatus() -> (isConfigured: Bool, provider: LLMProvider) {
        return (isConfigured(), currentProvider)
    }
}

// MARK: - Error Types
enum LLMError: Error, LocalizedError {
    case apiKeyNotConfigured
    case openRouterKeyNotConfigured
    case invalidURL
    case invalidPayload
    case networkError(Error)
    case httpError(Int)
    case invalidResponse
    case parsingError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Hugging Face API key not configured. Please add your API key in Settings."
        case .openRouterKeyNotConfigured:
            return "OpenRouter API key not configured. Please add your API key in Settings."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidPayload:
            return "Failed to create request payload"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .invalidResponse:
            return "Invalid response from API"
        case .parsingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
    
    static func apiKeyNotConfigured(for provider: LLMProvider) -> LLMError {
        switch provider {
        case .huggingFace:
            return .apiKeyNotConfigured
        case .openRouter:
            return .openRouterKeyNotConfigured
        }
    }
}