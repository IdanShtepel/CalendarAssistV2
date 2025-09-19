import SwiftUI

struct ColorCustomizationView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingColorPicker = false
    @State private var selectedCategory: EventCategory?
    @State private var showingSignificantOtherSettings = false
    @State private var significantOtherName = ""
    @State private var isDarkModePreview = false
    
    var body: some View {
        ScrollView {
                LazyVStack(spacing: AppSpacing.large) {
                    headerSection
                    
                    aiDetectionSection
                    
                    significantOtherSection
                    
                    categoriesSection
                    
                    previewSection
                    
                    actionsSection
                }
                .padding(.horizontal, AppSpacing.containerPadding)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Event Colors")
            .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingColorPicker) {
            if let category = selectedCategory {
                ColorPickerView(category: category, currentColor: settings.getColor(for: category)) { newColor in
                    settings.setColor(newColor, for: category)
                }
            }
        }
        .sheet(isPresented: $showingSignificantOtherSettings) {
            SignificantOtherSettingsView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.softRed)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Color Customization")
                        .font(AppTypography.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Personalize your event categories")
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
    
    private var aiDetectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "AI Auto-Detection", icon: "brain.head.profile")
            
            VStack(spacing: AppSpacing.small) {
                SettingRow(
                    title: "Smart Category Detection",
                    subtitle: "Automatically categorize new events",
                    icon: "sparkles"
                ) {
                    Toggle("", isOn: $settings.autoDetectEnabled)
                        .labelsHidden()
                }
                
                if settings.autoDetectEnabled {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HStack {
                            Text("Confidence Threshold")
                                .font(AppTypography.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(Int(settings.autoDetectThreshold * 100))%")
                                .font(AppTypography.callout)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(
                            value: $settings.autoDetectThreshold,
                            in: 0.5...0.95,
                            step: 0.05
                        ) {
                            Text("Threshold")
                        }
                        .tint(.softRed)
                        
                        Text("Higher values require more confidence before auto-assigning categories")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, AppSpacing.small)
                }
            }
            .padding(AppSpacing.medium)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(AppCornerRadius.card)
        }
    }
    
    private var significantOtherSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Partner Category", icon: "heart")
            
            VStack(spacing: AppSpacing.small) {
                SettingRow(
                    title: "Enable Partner Category",
                    subtitle: settings.significantOtherEnabled ? "Show events with \(settings.significantOtherName ?? "your partner")" : "Add a special category for your partner",
                    icon: "heart.fill"
                ) {
                    Toggle("", isOn: $settings.significantOtherEnabled)
                        .labelsHidden()
                }
                
                if settings.significantOtherEnabled {
                    Button(action: {
                        significantOtherName = settings.significantOtherName ?? ""
                        showingSignificantOtherSettings = true
                    }) {
                        HStack {
                            Text("Partner Name: \(settings.significantOtherName ?? "Not Set")")
                                .font(AppTypography.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(AppSpacing.small)
                        .background(Color.adaptiveTertiaryBackground)
                        .cornerRadius(AppCornerRadius.input)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(AppSpacing.medium)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(AppCornerRadius.card)
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack {
                SectionHeader(title: "Categories", icon: "tag.fill")
                
                Spacer()
                
                Button(action: {
                    isDarkModePreview.toggle()
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: isDarkModePreview ? "moon.fill" : "sun.max.fill")
                            .font(.caption)
                        Text(isDarkModePreview ? "Dark" : "Light")
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AppSpacing.medium) {
                ForEach(EventCategory.enabledCategories, id: \.self) { category in
                    CategoryColorCard(
                        category: category,
                        color: settings.getColor(for: category),
                        isDarkMode: isDarkModePreview,
                        onEdit: {
                            selectedCategory = category
                            showingColorPicker = true
                        },
                        onReset: {
                            settings.resetColor(for: category)
                        }
                    )
                }
            }
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            SectionHeader(title: "Preview", icon: "eye")
            
            VStack(spacing: AppSpacing.small) {
                ForEach(EventCategory.enabledCategories.prefix(3), id: \.self) { category in
                    EventPreviewRow(
                        category: category,
                        color: settings.getColor(for: category),
                        isDarkMode: isDarkModePreview
                    )
                }
            }
            .padding(AppSpacing.medium)
            .background(isDarkModePreview ? Color.black.opacity(0.9) : Color.adaptiveSecondaryBackground)
            .cornerRadius(AppCornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.card)
                    .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: AppSpacing.small) {
            SecondaryButton(title: "Reset All Colors", isDisabled: false) {
                settings.resetAllColors()
            }
            
            Text("This will restore all categories to their default colors")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.softRed)
            
            Text(title)
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct SettingRow<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.softRed)
                .frame(width: 24, alignment: .center)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            content()
        }
    }
}

struct CategoryColorCard: View {
    let category: EventCategory
    let color: EventColor
    let isDarkMode: Bool
    let onEdit: () -> Void
    let onReset: () -> Void
    
    private var displayColor: Color {
        Color.fromHex(isDarkMode ? color.dark : color.light) ?? .primary
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.small) {
            HStack {
                Circle()
                    .fill(displayColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(AppTypography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(isDarkMode ? color.dark : color.light)
                        .font(AppTypography.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(displayColor)
            }
            
            HStack(spacing: AppSpacing.xs) {
                SecondaryButton(title: "Edit", isDisabled: false, size: .compact) {
                    onEdit()
                }
                
                if AppSettings.shared.customColorPalette[category] != nil {
                    SecondaryButton(title: "Reset", isDisabled: false, size: .compact) {
                        onReset()
                    }
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.subtle)
    }
}

struct EventPreviewRow: View {
    let category: EventCategory
    let color: EventColor
    let isDarkMode: Bool
    
    private var displayColor: Color {
        Color.fromHex(isDarkMode ? color.dark : color.light) ?? .primary
    }
    
    private var textColor: Color {
        // Calculate contrast for accessibility
        let bgColor = displayColor
        // Simplified contrast calculation - in production, use proper WCAG formula
        return .white // For now, assume white text works with our color palette
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Rectangle()
                .fill(displayColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Sample \(category.displayName) Event")
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(isDarkMode ? .white : .primary)
                
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: category.icon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Today at 2:00 PM")
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
        .background(isDarkMode ? Color.gray.opacity(0.2) : Color.adaptiveTertiaryBackground)
        .cornerRadius(AppCornerRadius.input)
    }
}