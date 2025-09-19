import SwiftUI

struct BaseCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let shadow: AppShadow.Shadow
    
    init(
        padding: CGFloat = AppSpacing.containerPadding,
        shadow: AppShadow.Shadow = AppShadow.card,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.shadow = shadow
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.adaptiveBackground)
            .cornerRadius(AppCornerRadius.card)
            .applyShadow(shadow)
    }
}

struct InfoCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let backgroundColor: Color
    let action: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        backgroundColor: Color = .adaptiveSecondaryBackground,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: AppSpacing.medium) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.softRed)
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTypography.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(AppSpacing.containerPadding)
        .background(backgroundColor)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.card)
    }
}