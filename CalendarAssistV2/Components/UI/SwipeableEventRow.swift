import SwiftUI

struct SwipeableEventRow: View {
    let event: Event
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isShowingActions = false
    
    private let actionButtonWidth: CGFloat = 80
    private let maxSwipeDistance: CGFloat = 160 // Two buttons
    private let swipeThreshold: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Background action buttons
            HStack(spacing: 0) {
                Spacer()
                
                // Edit button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        resetPosition()
                    }
                    onEdit()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                        Text("Edit")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(width: actionButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.blue)
                }
                
                // Delete button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        resetPosition()
                    }
                    onDelete()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                        Text("Delete")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(width: actionButtonWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                }
            }
            .opacity(isShowingActions ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isShowingActions)
            
            // Main event content
            EventRowContent(event: event)
                .background(Color.adaptiveBackground)
                .cornerRadius(AppCornerRadius.card)
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleDragChanged(value)
                        }
                        .onEnded { value in
                            handleDragEnded(value)
                        }
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1), value: dragOffset)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card))
        .onTapGesture {
            if isShowingActions {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    resetPosition()
                }
            }
        }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // Only allow left swipe (reveal actions on the right)
        let translation = value.translation.width
        if translation < 0 {
            let clampedTranslation = max(translation, -maxSwipeDistance)
            dragOffset = CGSize(width: clampedTranslation, height: 0)
            
            // Show actions when swiping
            if abs(clampedTranslation) > 20 && !isShowingActions {
                isShowingActions = true
            }
        } else if isShowingActions {
            // Allow right swipe to close when actions are showing
            let clampedTranslation = min(translation, maxSwipeDistance)
            dragOffset = CGSize(width: clampedTranslation - maxSwipeDistance, height: 0)
        } else {
            // Minimal resistance for right swipe when actions are closed
            dragOffset = CGSize(width: translation * 0.1, height: 0)
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation.width
        let velocity = value.velocity.width
        
        if isShowingActions {
            // If actions are showing, decide whether to keep them open or close
            if translation > swipeThreshold || velocity > 500 {
                // Close actions
                resetPosition()
            } else {
                // Keep actions open
                snapToOpenPosition()
            }
        } else {
            // If actions are closed, decide whether to open them
            if translation < -swipeThreshold || velocity < -500 {
                // Open actions
                snapToOpenPosition()
            } else {
                // Stay closed
                resetPosition()
            }
        }
    }
    
    private func snapToOpenPosition() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: -maxSwipeDistance, height: 0)
            isShowingActions = true
        }
    }
    
    private func resetPosition() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            isShowingActions = false
        }
    }
}

struct EventRowContent: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Rectangle()
                .fill(event.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(event.title)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatEventTime(event.time))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    
                    if !event.location.isEmpty {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(event.location)
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(Color.adaptiveSecondaryBackground)
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: AppSpacing.small) {
        SwipeableEventRow(
            event: Event(title: "Team Meeting", time: Date(), location: "Conference Room", color: .softRed),
            onDelete: { print("Delete tapped") },
            onEdit: { print("Edit tapped") }
        )
        
        SwipeableEventRow(
            event: Event(title: "Lunch with Client", time: Date().addingTimeInterval(3600), location: "Restaurant", color: .blue),
            onDelete: { print("Delete tapped") },
            onEdit: { print("Edit tapped") }
        )
    }
    .padding()
}