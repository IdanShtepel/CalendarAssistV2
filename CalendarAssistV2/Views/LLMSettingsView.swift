import SwiftUI

struct LLMSettingsView: View {
    @StateObject private var assistantService = AssistantService.shared
    @State private var selectedProvider: LLMProvider = .openRouter
    @State private var huggingFaceAPIKey: String = ""
    @State private var openRouterAPIKey: String = ""
    @State private var selectedHuggingFaceModel: String = "microsoft/DialoGPT-medium"
    @State private var selectedOpenRouterModel: String = "anthropic/claude-3-haiku"
    @State private var showingApiKeyInfo = false
    @State private var testingConnection = false
    @State private var connectionStatus: ConnectionStatus = .unknown
    @State private var showingDebugView = false
    
    enum ConnectionStatus {
        case unknown, testing, success, failed
        
        var color: Color {
            switch self {
            case .unknown: return .secondary
            case .testing: return .blue
            case .success: return .green
            case .failed: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .testing: return "arrow.triangle.2.circlepath"
            case .success: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var message: String {
            switch self {
            case .unknown: return "Not tested"
            case .testing: return "Testing connection..."
            case .success: return "Connection successful"
            case .failed: return "Connection failed"
            }
        }
    }
    
    private let availableHuggingFaceModels = [
        "microsoft/DialoGPT-medium",
        "microsoft/DialoGPT-large",
        "facebook/blenderbot-400M-distill",
        "microsoft/blenderbot-3B"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Provider Selection")) {
                    Picker("AI Provider", selection: $selectedProvider) {
                        ForEach(LLMProvider.allCases, id: \.self) { provider in
                            VStack(alignment: .leading) {
                                Text(provider.displayName)
                                    .font(AppTypography.body)
                                Text(provider.description)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("API Configuration")) {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Text("\(selectedProvider.displayName) API Key")
                                .font(AppTypography.headline)
                            
                            Spacer()
                            
                            Button(action: { showingApiKeyInfo = true }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        SecureField(apiKeyPlaceholder, text: currentAPIKeyBinding)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        HStack {
                            Image(systemName: connectionStatus.icon)
                                .foregroundColor(connectionStatus.color)
                            
                            Text(connectionStatus.message)
                                .font(AppTypography.caption)
                                .foregroundColor(connectionStatus.color)
                            
                            Spacer()
                            
                            if connectionStatus != .testing && !currentAPIKey.isEmpty {
                                Button("Test") {
                                    testConnection()
                                }
                                .font(AppTypography.caption)
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section(header: Text("Model Selection")) {
                    if selectedProvider == .huggingFace {
                        Picker("Model", selection: $selectedHuggingFaceModel) {
                            ForEach(availableHuggingFaceModels, id: \.self) { model in
                                VStack(alignment: .leading) {
                                    Text(model)
                                        .font(AppTypography.body)
                                    Text(huggingFaceModelDescription(for: model))
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }
                                .tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    } else {
                        Picker("Model", selection: $selectedOpenRouterModel) {
                            ForEach(OpenRouterService.availableModels, id: \.id) { model in
                                VStack(alignment: .leading) {
                                    Text(model.name)
                                        .font(AppTypography.body)
                                    HStack {
                                        Text(model.description)
                                            .font(AppTypography.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(model.costPer1MTokens)
                                            .font(AppTypography.caption)
                                            .foregroundColor(.secondary)
                                            .fontWeight(.medium)
                                    }
                                }
                                .tag(model.id)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section(header: Text("Assistant Personality")) {
                    Picker("Tone", selection: $assistantService.config.tone) {
                        ForEach(AssistantTone.allCases, id: \.self) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("System Prompt")
                            .font(AppTypography.headline)
                        
                        TextEditor(text: $assistantService.config.systemPrompt)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Section(header: Text("Behavior")) {
                    Toggle("Auto-schedule events", isOn: $assistantService.config.autoSchedule)
                    Toggle("Confirm before creating events", isOn: $assistantService.config.eventCreationConfirmation)
                }
                
                Section(header: Text("Working Hours")) {
                    DatePicker(
                        "Start Time",
                        selection: $assistantService.config.workingHours.startTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "End Time", 
                        selection: $assistantService.config.workingHours.endTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    Toggle("Hide events outside working hours", isOn: $assistantService.config.workingHours.hideOutsideHours)
                }
                
                Section("Debug") {
                    Button("Debug Settings") {
                        showingDebugView = true
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("AI Assistant Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSettings()
            }
            .onChange(of: selectedProvider) { _, _ in
                saveSettings()
                connectionStatus = .unknown
            }
            .onChange(of: huggingFaceAPIKey) { _, _ in
                saveSettings()
                connectionStatus = .unknown
            }
            .onChange(of: openRouterAPIKey) { _, _ in
                saveSettings()
                connectionStatus = .unknown
            }
            .onChange(of: selectedHuggingFaceModel) { _, _ in
                saveSettings()
                connectionStatus = .unknown
            }
            .onChange(of: selectedOpenRouterModel) { _, _ in
                saveSettings()
                connectionStatus = .unknown
            }
        }
        .sheet(isPresented: $showingApiKeyInfo) {
            APIKeyInfoView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
        .sheet(isPresented: $showingDebugView) {
            UserDefaultsDebugView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
    }
    
    // MARK: - Computed Properties
    private var currentAPIKey: String {
        selectedProvider == .huggingFace ? huggingFaceAPIKey : openRouterAPIKey
    }
    
    private var currentAPIKeyBinding: Binding<String> {
        selectedProvider == .huggingFace ? $huggingFaceAPIKey : $openRouterAPIKey
    }
    
    private var apiKeyPlaceholder: String {
        selectedProvider == .huggingFace ? "hf_your_api_key_here" : "sk-or-v1-your_key_here"
    }
    
    private func huggingFaceModelDescription(for model: String) -> String {
        switch model {
        case "microsoft/DialoGPT-medium":
            return "Balanced performance and speed"
        case "microsoft/DialoGPT-large":
            return "Better quality, slower responses"
        case "facebook/blenderbot-400M-distill":
            return "Fast, good for simple conversations"
        case "microsoft/blenderbot-3B":
            return "High quality, advanced reasoning"
        default:
            return "Custom model"
        }
    }
    
    private func testConnection() {
        guard !currentAPIKey.isEmpty else { return }
        
        connectionStatus = .testing
        testingConnection = true
        
        Task {
            do {
                // Test with the unified LLM service
                _ = try await LLMService.shared.testConnection()
                
                await MainActor.run {
                    connectionStatus = .success
                    testingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .failed
                    testingConnection = false
                }
            }
        }
    }
    
    private func loadSettings() {
        // Load provider selection
        let providerString = UserDefaults.standard.string(forKey: "SelectedLLMProvider") ?? LLMProvider.openRouter.rawValue
        selectedProvider = LLMProvider(rawValue: providerString) ?? .openRouter
        
        // Load API keys
        huggingFaceAPIKey = UserDefaults.standard.string(forKey: "HuggingFaceAPIKey") ?? ""
        openRouterAPIKey = UserDefaults.standard.string(forKey: "OpenRouterAPIKey") ?? ""
        
        // Load model selections
        selectedHuggingFaceModel = UserDefaults.standard.string(forKey: "SelectedLLMModel") ?? "microsoft/DialoGPT-medium"
        selectedOpenRouterModel = UserDefaults.standard.string(forKey: "OpenRouterModel") ?? "anthropic/claude-3-haiku"
    }
    
    private func saveSettings() {
        // Save provider selection
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "SelectedLLMProvider")
        
        // Save API keys
        UserDefaults.standard.set(huggingFaceAPIKey, forKey: "HuggingFaceAPIKey")
        UserDefaults.standard.set(openRouterAPIKey, forKey: "OpenRouterAPIKey")
        
        // Save model selections
        UserDefaults.standard.set(selectedHuggingFaceModel, forKey: "SelectedLLMModel")
        UserDefaults.standard.set(selectedOpenRouterModel, forKey: "OpenRouterModel")
        
        // Force synchronize to ensure settings are written immediately
        UserDefaults.standard.synchronize()
        
        // Debug logging
        print("LLMSettingsView: Saved settings")
        print("  Provider: \(selectedProvider.rawValue)")
        print("  OpenRouter key length: \(openRouterAPIKey.count)")
        print("  HuggingFace key length: \(huggingFaceAPIKey.count)")
    }
}

struct APIKeyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider: LLMProvider = .openRouter
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("Setting Up Your AI API Key")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                    
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(LLMProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("To use the AI assistant with \(selectedProvider.displayName), you need an API key:")
                        .font(AppTypography.body)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        ForEach(selectedProvider.setupInstructions.components(separatedBy: "\n"), id: \.self) { instruction in
                            Text(instruction)
                                .font(AppTypography.body)
                        }
                    }
                    .padding(.leading, AppSpacing.medium)
                    
                    if selectedProvider == .openRouter {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            Text("Why OpenRouter?")
                                .font(AppTypography.headline)
                                .fontWeight(.semibold)
                            
                            Text("• Access to multiple AI models including Claude, GPT-4, and Llama")
                            Text("• Pay-per-use pricing (often cheaper than direct APIs)")
                            Text("• Better performance and reliability")
                            Text("• Advanced models for more intelligent responses")
                        }
                        .font(AppTypography.body)
                        .padding(.top, AppSpacing.medium)
                    }
                    
                    Text("Your API key is stored securely on your device and only used to communicate with \(selectedProvider.displayName)'s servers.")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, AppSpacing.medium)
                    
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.containerPadding)
            }
            .navigationTitle("API Key Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LLMSettingsView()
}