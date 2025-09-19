import SwiftUI

struct ResponsiveContainer<Content: View>: View {
    let content: Content
    @State private var screenSize: CGSize = .zero
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .padding(.horizontal, responsivePadding)
                .onAppear {
                    screenSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    screenSize = newSize
                }
        }
    }
    
    private var responsivePadding: CGFloat {
        AppSpacing.responsive(AppSpacing.containerPadding, for: screenSize.width)
    }
}

struct AdaptiveGrid<Content: View>: View {
    let content: Content
    let minItemWidth: CGFloat
    let spacing: CGFloat
    @State private var screenSize: CGSize = .zero
    
    init(
        minItemWidth: CGFloat = 150,
        spacing: CGFloat = AppSpacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: spacing) {
            content
        }
        .background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    screenSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    screenSize = newSize
                }
            }
        )
    }
    
    private var adaptiveColumns: [GridItem] {
        let availableWidth = screenSize.width
        let itemsPerRow = max(1, Int(availableWidth / minItemWidth))
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: itemsPerRow)
    }
}

struct ResponsiveText: View {
    let text: String
    let baseFont: Font
    @State private var screenSize: CGSize = .zero
    
    init(_ text: String, font: Font = AppTypography.body) {
        self.text = text
        self.baseFont = font
    }
    
    var body: some View {
        Text(text)
            .font(responsiveFont)
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        screenSize = geometry.size
                    }
                }
            )
    }
    
    private var responsiveFont: Font {
        AppTypography.responsiveFont(base: baseFont, for: screenSize.width)
    }
}

// MARK: - Screen Size Categories
enum ScreenSizeCategory {
    case compact    // iPhone SE, iPhone 12 mini
    case standard   // iPhone 12, iPhone 13
    case large      // iPhone 12 Pro Max, iPhone 13 Pro Max
    case extraLarge // iPad mini and above
    
    init(width: CGFloat) {
        switch width {
        case 0..<375:
            self = .compact
        case 375..<414:
            self = .standard
        case 414..<480:
            self = .large
        default:
            self = .extraLarge
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .compact:
            return AppSpacing.medium
        case .standard:
            return AppSpacing.containerPadding
        case .large:
            return AppSpacing.large
        case .extraLarge:
            return AppSpacing.xl
        }
    }
    
    var cardSpacing: CGFloat {
        switch self {
        case .compact:
            return AppSpacing.small
        case .standard:
            return AppSpacing.medium
        case .large:
            return AppSpacing.medium
        case .extraLarge:
            return AppSpacing.large
        }
    }
}

// MARK: - View Extension for Responsive Design
extension View {
    func responsivePadding() -> some View {
        self.modifier(ResponsivePaddingModifier())
    }
    
    func adaptiveLayout() -> some View {
        self.modifier(AdaptiveLayoutModifier())
    }
}

struct ResponsivePaddingModifier: ViewModifier {
    @State private var screenSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            screenSize = geometry.size
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            screenSize = newSize
                        }
                }
            )
    }
    
    private var horizontalPadding: CGFloat {
        let category = ScreenSizeCategory(width: screenSize.width)
        return category.horizontalPadding
    }
}

struct AdaptiveLayoutModifier: ViewModifier {
    @State private var screenSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            screenSize = geometry.size
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            screenSize = newSize
                        }
                }
            )
    }
}