import SwiftUI

struct AssistantSettingsView: View {
    @StateObject private var assistantService = AssistantService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var workingHoursStart = Date()
    @State private var workingHoursEnd = Date()
    @State private var showingLLMSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Configuration") {
                    Button(action: { showingLLMSettings = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("AI Model Settings")
                                    .font(AppTypography.body)
                                    .foregroundColor(.primary)
                                
                                Text("Configure Hugging Face API and model")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section("Behavior") {
                    HStack {
                        Text("Tone")
                        Spacer()
                        Picker("Tone", selection: $assistantService.config.tone) {
                            ForEach(AssistantTone.allCases, id: \.self) { tone in
                                Text(tone.rawValue).tag(tone)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    
                    Toggle("Auto-schedule", isOn: $assistantService.config.autoSchedule)
                    
                    Toggle("Event creation confirmation", isOn: $assistantService.config.eventCreationConfirmation)
                }
                
                Section("Calendar Integration") {
                    HStack {
                        Text("Default calendar")
                        Spacer()
                        Text(assistantService.config.defaultCalendar)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Working Hours") {
                    DatePicker("Start time", selection: $workingHoursStart, displayedComponents: .hourAndMinute)
                        .onChange(of: workingHoursStart) { _, newValue in
                            assistantService.config.workingHours.startTime = newValue
                        }
                    
                    DatePicker("End time", selection: $workingHoursEnd, displayedComponents: .hourAndMinute)
                        .onChange(of: workingHoursEnd) { _, newValue in
                            assistantService.config.workingHours.endTime = newValue
                        }
                    
                    Toggle("Hide events outside working hours", isOn: $assistantService.config.workingHours.hideOutsideHours)
                }
                
                Section("Custom System Prompt") {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Customize how the assistant behaves and responds")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $assistantService.config.systemPrompt)
                            .frame(minHeight: 100)
                            .font(AppTypography.body)
                    }
                }
                
                Section {
                    Button("Reset to Default") {
                        resetToDefaults()
                    }
                    .foregroundColor(.softRed)
                }
            }
            .navigationTitle("Assistant Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                workingHoursStart = assistantService.config.workingHours.startTime
                workingHoursEnd = assistantService.config.workingHours.endTime
            }
        }
        .sheet(isPresented: $showingLLMSettings) {
            LLMSettingsView()
                .preferredColorScheme(AppState.shared.isDarkMode ? .dark : .light)
        }
    }
    
    private func resetToDefaults() {
        assistantService.config = AssistantConfig()
        workingHoursStart = assistantService.config.workingHours.startTime
        workingHoursEnd = assistantService.config.workingHours.endTime
    }
}