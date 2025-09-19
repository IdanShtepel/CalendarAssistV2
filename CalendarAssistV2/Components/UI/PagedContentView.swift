import SwiftUI

// MARK: - Main Pager View
struct PagedContentView: View {
    @Binding var selectedTab: TabItem
    @StateObject private var pagerState = PagerState()
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.layoutDirection) var layoutDirection
    
    private let pages: [TabItem] = [.home, .calendar, .chat, .todos]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(for: page)
                        .frame(width: geometry.size.width)
                        .clipped()
                        .allowsHitTesting(abs(Float(index) - pagerState.progress) < 0.5)
                }
            }
            .offset(x: layoutDirection == .rightToLeft ?
                   CGFloat(pagerState.progress) * geometry.size.width :
                   -CGFloat(pagerState.progress) * geometry.size.width)
            .onAppear {
                pagerState.width = geometry.size.width
                pagerState.currentIndex = indexForTab(selectedTab)
                pagerState.progress = Float(pagerState.currentIndex)
            }
            .onChange(of: geometry.size.width) { newWidth in
                pagerState.width = newWidth
            }
            .onChange(of: selectedTab) { newTab in
                let targetIndex = indexForTab(newTab)
                navigateTo(targetIndex: targetIndex, interrupting: false)
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        handlePanGesture(value: value, geometry: geometry)
                    }
                    .onEnded { value in
                        handlePanGestureEnd(value: value, geometry: geometry)
                    }
            )
            .accessibilityLabel("Page navigation")
            .accessibilityHint("Swipe left or right to navigate between pages")
        }
    }
    
    @ViewBuilder
    private func pageView(for page: TabItem) -> some View {
        switch page {
        case .home: HomeView()
        case .calendar: CalendarView()
        case .chat: ChatView()
        case .todos: TodoView()
        case .newEvent: EmptyView()
        }
    }
    
    private func indexForTab(_ tab: TabItem) -> Int {
        pages.firstIndex(of: tab) ?? 0
    }
    
    private func tabForIndex(_ index: Int) -> TabItem {
        guard index >= 0 && index < pages.count else { return .home }
        return pages[index]
    }
    
    private func navigateTo(targetIndex: Int, interrupting: Bool) {
        let clampedTarget = max(0, min(targetIndex, 3))
        let delta = abs(clampedTarget - pagerState.currentIndex)
        if delta == 0 { return }
        
        pagerState.cancelCurrentAnimation()
        
        if interrupting {
            // For gesture-driven navigation, use snap behavior
            snapToPage(clampedTarget)
        } else {
            // For programmatic navigation (tab taps), use original timing
            let duration = AnimationConfig.durations[delta] ?? 0.28
            let easing = AnimationConfig.easing
            
            if reduceMotion {
                withAnimation(.easeInOut(duration: 0.12)) {
                    pagerState.currentIndex = clampedTarget
                    pagerState.progress = Float(clampedTarget)
                    selectedTab = tabForIndex(clampedTarget)
                }
            } else {
                let animation = Animation.timingCurve(
                    easing.0, easing.1, easing.2, easing.3,
                    duration: duration
                )
                withAnimation(animation) {
                    pagerState.progress = Float(clampedTarget)
                    pagerState.currentIndex = clampedTarget
                    selectedTab = tabForIndex(clampedTarget)
                }
            }
        }
    }
    
    private func handlePanGesture(value: DragGesture.Value, geometry: GeometryProxy) {
        let dx = value.translation.width
        let dy = value.translation.height
        
        // Much more restrictive criteria to avoid conflicts with horizontal scrolling
        // Only activate page swipe for strong, clearly page-intended gestures
        // Additionally, require the drag to originate from screen edges
        if !pagerState.isPanning {
            let startX = value.startLocation.x
            let activationMargin = SwipeConfig.edgeActivationMarginPx
            let isFromEdges = startX <= activationMargin || startX >= (geometry.size.width - activationMargin)
            if isFromEdges &&
                abs(dx) >= SwipeConfig.startSlopPx * 3 &&
                abs(dx) >= abs(dy) * SwipeConfig.directionBias * 2 &&
                abs(dx) > 40 &&
                abs(dy) < 20 {
                pagerState.isPanning = true
            }
        }
        
        guard pagerState.isPanning else { return }
        
        let base = Float(pagerState.currentIndex)
        let dragRatio = Float(dx) / Float(geometry.size.width)
        let adjustedDrag = layoutDirection == .rightToLeft ? -dragRatio : dragRatio
        var proposedProgress = base - adjustedDrag
        
        // Apply stronger rubber-band effect at boundaries
        if proposedProgress < 0 {
            // At left boundary (before Home)
            let overscroll = abs(proposedProgress)
            proposedProgress = -overscroll * SwipeConfig.rubberBandFactor * 0.3 // Even more resistance
        } else if proposedProgress > 3 {
            // At right boundary (after Todo)
            let overscroll = proposedProgress - 3
            proposedProgress = 3 + overscroll * SwipeConfig.rubberBandFactor * 0.3 // Even more resistance
        }
        
        pagerState.progress = proposedProgress
    }
    
    private func handlePanGestureEnd(value: DragGesture.Value, geometry: GeometryProxy) {
        guard pagerState.isPanning else { return }
        pagerState.isPanning = false
        
        let dx = value.translation.width
        let predictedDx = value.predictedEndTranslation.width
        
        let adjustedDx = layoutDirection == .rightToLeft ? -dx : dx
        let adjustedPredictedDx = layoutDirection == .rightToLeft ? -predictedDx : predictedDx
        
        // Always ensure we stay within bounds
        let currentIndex = pagerState.currentIndex
        let currentProgress = pagerState.progress
        
        // If we're out of bounds, immediately snap back
        if currentProgress < 0 || currentProgress > 3 {
            snapToPage(currentIndex)
            return
        }
        
        let distanceRatio = abs(adjustedDx) / geometry.size.width
        let shouldAdvance = distanceRatio >= SwipeConfig.distanceThresholdRatio ||
                           abs(adjustedPredictedDx) >= SwipeConfig.velocityThresholdPxPerSec
        
        var targetIndex = currentIndex
        
        if shouldAdvance {
            if adjustedDx < 0 { // Swiping left (next page)
                // Check if we can go to next page
                if currentIndex < 3 {
                    targetIndex = currentIndex + 1
                } else {
                    // At rightmost page, snap back
                    snapToPage(currentIndex)
                    return
                }
            } else if adjustedDx > 0 { // Swiping right (previous page)
                // Check if we can go to previous page
                if currentIndex > 0 {
                    targetIndex = currentIndex - 1
                } else {
                    // At leftmost page, snap back
                    snapToPage(currentIndex)
                    return
                }
            }
        }
        
        snapToPage(targetIndex)
    }
    
    private func snapToPage(_ index: Int) {
        let clampedIndex = max(0, min(index, 3))
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            pagerState.progress = Float(clampedIndex)
            pagerState.currentIndex = clampedIndex
            selectedTab = tabForIndex(clampedIndex)
        }
    }
}

// MARK: - Pager State
@MainActor
class PagerState: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var progress: Float = 0.0
    @Published var width: CGFloat = 0
    @Published var isPanning: Bool = false
    
    private var animationWorkItem: DispatchWorkItem?
    
    func cancelCurrentAnimation() {
        animationWorkItem?.cancel()
        animationWorkItem = nil
    }
}

// MARK: - Animation Config
struct AnimationConfig {
    static let durations: [Int: Double] = [
        1: 0.28,
        2: 0.36,
        3: 0.42
    ]
    static let easing: (Double, Double, Double, Double) = (0.2, 0, 0, 1)
}

// MARK: - Swipe Config
struct SwipeConfig {
    static let startSlopPx: CGFloat = 12  // Increased from 8 to 12
    static let distanceThresholdRatio: CGFloat = 0.45  // Increased from 0.35 to 0.45  
    static let velocityThresholdPxPerSec: CGFloat = 900  // Increased from 750 to 900
    static let rubberBandFactor: Float = 0.55
    static let directionBias: CGFloat = 3.0  // Increased from 2.0 to 3.0
    static let edgeActivationMarginPx: CGFloat = 48  // Widened edge activation area
}
