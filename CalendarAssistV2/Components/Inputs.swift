import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppCornerRadius.input)
                .fill(Color.adaptiveInputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .stroke(Color.adaptiveBorder, lineWidth: 1)
                )
            
            TextField("", text: $text)
                .font(AppTypography.body)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.clear)
            
            if text.isEmpty {
                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.adaptivePlaceholder)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
    }
}

struct AppTextEditor: View {
    let placeholder: String
    @Binding var text: String
    let minHeight: CGFloat
    
    init(placeholder: String, text: Binding<String>, minHeight: CGFloat = 100) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background + border drawn once for consistent appearance
            RoundedRectangle(cornerRadius: AppCornerRadius.input)
                .fill(Color.adaptiveInputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.input)
                        .stroke(Color.adaptiveBorder, lineWidth: 1)
                )
            
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(AppTypography.body)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            if text.isEmpty {
                Text(placeholder)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.adaptivePlaceholder)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
        }
        .frame(minHeight: minHeight)
    }
}