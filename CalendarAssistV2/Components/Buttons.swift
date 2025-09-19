import SwiftUI
import UIKit

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    init(title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minHeight: 48) // Minimum touch target
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.large)
                .padding(.vertical, AppSpacing.medium)
                .background(
                    isDisabled ? Color.adaptiveButtonDisabled : Color.adaptiveButtonPrimary
                )
                .cornerRadius(AppCornerRadius.button)
                .applyShadow(isDisabled ? AppShadow.none : AppShadow.small)
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint(isDisabled ? "Button is disabled" : "Double tap to \(title.lowercased())")
    }
}

enum ButtonSize {
    case regular
    case compact
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    let size: ButtonSize
    
    init(title: String, isDisabled: Bool = false, size: ButtonSize = .regular, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            let isCompact = (size == .compact)
            Text(title)
                .font(isCompact ? AppTypography.callout : AppTypography.headline)
                .fontWeight(.semibold)
                .foregroundColor(isDisabled ? Color.secondary : Color.primary)
                .lineLimit(1)
                .layoutPriority(1)
                .frame(minWidth: isCompact ? 90 : 120, minHeight: isCompact ? 40 : 48)
                .padding(.horizontal, isCompact ? AppSpacing.medium : AppSpacing.large)
                .padding(.vertical, isCompact ? AppSpacing.small : AppSpacing.medium)
                .background(
                    isDisabled
                    ? Color.lightGray.opacity(0.25)
                    : Color.adaptiveTertiaryBackground
                )
                .cornerRadius(AppCornerRadius.button)
                .applyShadow(isDisabled ? AppShadow.none : AppShadow.subtle)
        }
        .disabled(isDisabled)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint(isDisabled ? "Button is disabled" : "Double tap to \(title.lowercased())")
    }
}

struct FABButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.softRed)
                .cornerRadius(AppCornerRadius.fab)
                .applyShadow(AppShadow.fab)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButton: View {
    let icon: String
    let action: () -> Void
    let isActive: Bool
    
    init(icon: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isActive ? Color.darkGray : Color.lightGray)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}