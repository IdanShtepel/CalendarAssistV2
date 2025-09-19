import SwiftUI

struct ClockWithSparkIcon: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 24, color: Color = .softRed) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Main clock icon
            Image(systemName: "clock")
                .font(.system(size: size, weight: .medium))
                .foregroundColor(color)
            
            // Small spark at top-right
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.yellow)
                .offset(x: size * 0.35, y: -size * 0.35)
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }
}