import SwiftUI

struct DarkModeTransitionOverlay: View {
    @Binding var isDarkMode: Bool
    @State private var isTransitioning = false
    @State private var transitionProgress: Double = 0.0
    @State private var overlayOpacity: Double = 0.0
    
    private let transitionDuration: Double = 1.2
    private let fadeOutDelay: Double = 0.4
    
    var body: some View {
        ZStack {
            if isTransitioning {
                // Multiple gradient layers for a richer transition
                ZStack {
                    // Base gradient layer with blur
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isDarkMode ? Color.black.opacity(0.98) : Color.white.opacity(0.98),
                            isDarkMode ? Color.black.opacity(0.92) : Color.white.opacity(0.92),
                            isDarkMode ? Color.black.opacity(0.7) : Color.white.opacity(0.7),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: UIScreen.main.bounds.height * 1.4
                    )
                    .opacity(overlayOpacity)
                    .blur(radius: overlayOpacity * 2)
                    
                    // Secondary expanding ring effect
                    Circle()
                        .stroke(
                            isDarkMode ? Color.white.opacity(0.15) : Color.black.opacity(0.15),
                            lineWidth: 2
                        )
                        .scaleEffect(transitionProgress * 6)
                        .opacity(overlayOpacity * 0.8)
                    
                    // Primary ripple effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isDarkMode ? Color.black.opacity(0.8) : Color.white.opacity(0.8),
                                    isDarkMode ? Color.black.opacity(0.4) : Color.white.opacity(0.4),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 400
                            )
                        )
                        .scaleEffect(transitionProgress * 3)
                        .opacity(overlayOpacity * 0.6)
                        .blur(radius: overlayOpacity * 1.5)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onChange(of: isDarkMode) { _, newValue in
            performTransition(toDark: newValue)
        }
    }
    
    private func performTransition(toDark: Bool) {
        guard !isTransitioning else { return }
        
        isTransitioning = true
        transitionProgress = 0.0
        overlayOpacity = 0.0
        
        // Start the transition with a smooth spring animation
        withAnimation(.spring(response: transitionDuration, dampingFraction: 0.8, blendDuration: 0.2)) {
            transitionProgress = 1.0
        }
        
        // Fade in the overlay
        withAnimation(.easeIn(duration: 0.3)) {
            overlayOpacity = 1.0
        }
        
        // Start fading out partway through
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay) {
            withAnimation(.easeOut(duration: transitionDuration - fadeOutDelay)) {
                overlayOpacity = 0.0
            }
        }
        
        // End transition after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            isTransitioning = false
            transitionProgress = 0.0
            overlayOpacity = 0.0
        }
    }
}

struct SmoothColorTransition: ViewModifier {
    let isDarkMode: Bool
    
    func body(content: Content) -> some View {
        content
            .animation(.spring(response: 1.0, dampingFraction: 0.9, blendDuration: 0.3), value: isDarkMode)
    }
}

extension View {
    func smoothDarkModeTransition(isDarkMode: Bool) -> some View {
        self.modifier(SmoothColorTransition(isDarkMode: isDarkMode))
    }
}