import SwiftUI

// MARK: - Шрифт

extension Font {
    static let display = Font.custom("PPNeueBit-Bold", size: 96)
    static let headline1 = Font.custom("Pretendard-SemiBold", size: 22)
    static let headline2 = Font.custom("Pretendard-SemiBold", size: 18)
    static let text = Font.custom("Pretendard-SemiBold", size: 15)
    static let caption = Font.custom("Pretendard-SemiBold", size: 12)
}

// MARK: - Модификаторы View

private struct DisplayStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.display)
            .lineSpacing(0)
    }
}

private struct Headline1Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline1)
            .lineSpacing(0)
    }
}

private struct Headline2Style: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline2)
            .lineSpacing(2)
    }
}

private struct TextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.text)
            .lineSpacing(2)
    }
}

private struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .lineSpacing(2)
    }
}

extension View {
    func displayStyle() -> some View { modifier(DisplayStyle()) }
    func headline1Style() -> some View { modifier(Headline1Style()) }
    func headline2Style() -> some View { modifier(Headline2Style()) }
    func textStyle() -> some View { modifier(TextStyle()) }
    func captionStyle() -> some View { modifier(CaptionStyle()) }
}
