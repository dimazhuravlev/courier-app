import SwiftUI
import UIKit

// MARK: - Preference Key

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - View Extension

extension View {
    /// Measures the height of the view and writes it into the binding.
    func measureHeight(_ height: Binding<CGFloat>) -> some View {
        self.background {
            GeometryReader { geo in
                Color.clear
                    .preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        }
        .onPreferenceChange(ContentHeightKey.self) { height.wrappedValue = $0 }
    }
}

// MARK: - Window Safe Area

extension UIApplication {
    /// Bottom safe area inset of the key window (home indicator area).
    static var safeAreaBottom: CGFloat {
        (shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
