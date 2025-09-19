import SwiftUI

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmAction: () -> Void
    let cancelAction: () -> Void
    let isDestructive: Bool
    
    init(
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        confirmAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.large) {
            VStack(spacing: AppSpacing.medium) {
                Text(title)
                    .font(AppTypography.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: AppSpacing.small) {
                Button(action: confirmAction) {
                    Text(confirmTitle)
                        .font(AppTypography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.medium)
                        .background(isDestructive ? Color.red : Color.softRed)
                        .cornerRadius(AppCornerRadius.button)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button(action: cancelAction) {
                    Text("Cancel")
                        .font(AppTypography.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.medium)
                        .background(Color.lightGray.opacity(0.2))
                        .cornerRadius(AppCornerRadius.button)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(AppSpacing.xl)
        .background(.ultraThinMaterial)
        .cornerRadius(AppCornerRadius.card)
        .applyShadow(AppShadow.modal)
    }
}

struct ConfirmationOverlay: View {
    @Binding var isPresented: Bool
    let dialog: ConfirmationDialog
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                
                dialog
                    .padding(.horizontal, AppSpacing.xl)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
        }
    }
}

// MARK: - View Extension for Easy Usage
extension View {
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        confirmAction: @escaping () -> Void
    ) -> some View {
        self.overlay(
            ConfirmationOverlay(
                isPresented: isPresented,
                dialog: ConfirmationDialog(
                    title: title,
                    message: message,
                    confirmTitle: confirmTitle,
                    isDestructive: isDestructive,
                    confirmAction: {
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                        confirmAction()
                    },
                    cancelAction: {
                        withAnimation {
                            isPresented.wrappedValue = false
                        }
                    }
                )
            )
        )
    }
}