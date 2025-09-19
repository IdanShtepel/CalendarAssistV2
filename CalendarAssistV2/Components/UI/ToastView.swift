import SwiftUI

enum ToastType {
    case success
    case error
    case info
    case warning
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title3)
            
            Text(message)
                .font(AppTypography.callout)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(AppSpacing.containerPadding)
        .background(.ultraThinMaterial)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.medium)
    }
}

struct ToastContainer: View {
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        VStack {
            if let successMessage = appState.successMessage {
                ToastView(
                    message: successMessage,
                    type: .success
                ) {
                    appState.dismissMessages()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: appState.successMessage)
            }
            
            if let errorMessage = appState.errorMessage {
                ToastView(
                    message: errorMessage,
                    type: .error
                ) {
                    appState.dismissMessages()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: appState.errorMessage)
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.containerPadding)
        .padding(.top, AppSpacing.small)
    }
}

struct LoadingOverlay: View {
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.medium) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.softRed)
                    
                    Text("Loading...")
                        .font(AppTypography.callout)
                        .foregroundColor(.primary)
                }
                .padding(AppSpacing.xl)
                .background(.ultraThinMaterial)
                .cornerRadius(AppCornerRadius.card)
                .applyShadow(AppShadow.modal)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
    }
}