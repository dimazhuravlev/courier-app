import SwiftUI
import UIKit

// MARK: - PreferenceKey высоты

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Расширение View

extension View {
    /// Высота вью пишется в binding.
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

// MARK: - Safe area окна

extension UIApplication {
    /// Нижний inset активного окна (зона индикатора «домой»).
    static var safeAreaBottom: CGFloat {
        (shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
