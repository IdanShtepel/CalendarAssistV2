import SwiftUI

struct SignificantOtherSettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var partnerName: String = ""
    @State private var showingDisableConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.large) {
                    headerSection
                    
                    nameSection
                    
                    featureExplanationSection
                    
                    if settings.significantOtherEnabled {
                        previewSection
                        
                        dangerSection
                    }
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Partner Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(settings.significantOtherEnabled ? "Save" : "Enable") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.softRed)
                    .disabled(partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            partnerName = settings.significantOtherName ?? ""
        }
        .alert("Disable Partner Category", isPresented: $showingDisableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                settings.disableSignificantOther()
                dismiss()
            }
        } message: {
            Text("This will remove the partner category and revert all related events to \"Personal\". This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.softRed)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Partner Category")
                        .font(AppTypography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Create a special category for events with your partner")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Partner Name")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                TextField("Enter your partner's name", text: $partnerName)
                    .font(AppTypography.body)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                
                Text("This name will be displayed on events in this category")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private var featureExplanationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("How It Works")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: AppSpacing.small) {
                FeatureExplanationRow(
                    icon: "brain.head.profile",
                    title: "Smart Detection",
                    description: "AI automatically detects events with your partner"
                )
                
                FeatureExplanationRow(
                    icon: "tag.fill",
                    title: "Custom Labels",
                    description: "Events show \"\(partnerName.isEmpty ? "Partner" : partnerName) — Event Title\""
                )
                
                FeatureExplanationRow(
                    icon: "paintbrush.fill",
                    title: "Special Color",
                    description: "Dedicated color theme for partner events"
                )
                
                FeatureExplanationRow(
                    icon: "heart.fill",
                    title: "Privacy Friendly",
                    description: "Name is stored locally on your device"
                )
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Preview")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: AppSpacing.small) {
                EventPreviewWithPartner(
                    originalTitle: "Dinner",
                    partnerName: partnerName.isEmpty ? "Partner" : partnerName,
                    color: settings.getColor(for: .significantOther)
                )
                
                EventPreviewWithPartner(
                    originalTitle: "Movie Night",
                    partnerName: partnerName.isEmpty ? "Partner" : partnerName,
                    color: settings.getColor(for: .significantOther)
                )
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Disable Feature")
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("No longer need this feature? You can disable it anytime.")
                    .font(AppTypography.body)
                    .foregroundColor(.primary)
                
                Text("All events in this category will be moved to \"Personal\"")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                
                Button("Disable Partner Category") {
                    showingDisableConfirmation = true
                }
                .foregroundColor(.red)
                .padding(.top, AppSpacing.small)
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
    }
    
    private func saveSettings() {
        let trimmedName = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if settings.significantOtherEnabled {
            settings.updateSignificantOtherName(trimmedName)
        } else {
            settings.enableSignificantOther(name: trimmedName)
        }
        
        dismiss()
    }
}

struct FeatureExplanationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.softRed)
                .frame(width: 24, alignment: .center)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct EventPreviewWithPartner: View {
    let originalTitle: String
    let partnerName: String
    let color: EventColor
    
    private var displayColor: Color {
        color.swiftUIColor
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Rectangle()
                .fill(displayColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("\(partnerName) — \(originalTitle)")
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Tonight at 7:00 PM")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(displayColor)
                .frame(width: 12, height: 12)
        }
        .padding(AppSpacing.small)
        .background(Color.adaptiveTertiaryBackground)
        .cornerRadius(AppCornerRadius.input)
    }
}

#Preview {
    SignificantOtherSettingsView()
}