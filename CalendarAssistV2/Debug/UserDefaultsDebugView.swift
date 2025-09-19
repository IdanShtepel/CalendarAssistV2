import SwiftUI

struct UserDefaultsDebugView: View {
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            List {
                Section("LLM Provider Settings") {
                    DebugRow(
                        key: "SelectedLLMProvider",
                        value: UserDefaults.standard.string(forKey: "SelectedLLMProvider") ?? "Not Set"
                    )
                }
                
                Section("API Keys") {
                    DebugRow(
                        key: "HuggingFaceAPIKey",
                        value: apiKeyMasked(UserDefaults.standard.string(forKey: "HuggingFaceAPIKey"))
                    )
                    
                    DebugRow(
                        key: "OpenRouterAPIKey", 
                        value: apiKeyMasked(UserDefaults.standard.string(forKey: "OpenRouterAPIKey"))
                    )
                }
                
                Section("Model Settings") {
                    DebugRow(
                        key: "SelectedLLMModel",
                        value: UserDefaults.standard.string(forKey: "SelectedLLMModel") ?? "Not Set"
                    )
                    
                    DebugRow(
                        key: "OpenRouterModel",
                        value: UserDefaults.standard.string(forKey: "OpenRouterModel") ?? "Not Set"
                    )
                }
                
                Section("LLM Service Status") {
                    let status = LLMService.shared.getProviderStatus()
                    DebugRow(key: "Current Provider", value: status.provider.displayName)
                    DebugRow(key: "Is Configured", value: status.isConfigured ? "Yes" : "No")
                }
                
                Section("Actions") {
                    Button("Refresh") {
                        refreshTrigger.toggle()
                    }
                    
                    Button("Clear All LLM Settings") {
                        clearAllSettings()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Debug Settings")
            .navigationBarTitleDisplayMode(.inline)
            .id(refreshTrigger) // Forces refresh when refreshTrigger changes
        }
    }
    
    private func apiKeyMasked(_ key: String?) -> String {
        guard let key = key, !key.isEmpty else {
            return "Not Set"
        }
        
        if key.count <= 8 {
            return "Set (\(key.count) chars)"
        }
        
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)***\(suffix) (\(key.count) chars)"
    }
    
    private func clearAllSettings() {
        UserDefaults.standard.removeObject(forKey: "SelectedLLMProvider")
        UserDefaults.standard.removeObject(forKey: "HuggingFaceAPIKey")
        UserDefaults.standard.removeObject(forKey: "OpenRouterAPIKey")
        UserDefaults.standard.removeObject(forKey: "SelectedLLMModel")
        UserDefaults.standard.removeObject(forKey: "OpenRouterModel")
        refreshTrigger.toggle()
    }
}

struct DebugRow: View {
    let key: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    UserDefaultsDebugView()
}