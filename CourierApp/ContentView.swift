import SwiftUI

// MARK: - Корневой экран

struct ContentView: View {
    @State private var isShiftOpen = false

    var body: some View {
        MainView(isShiftOpen: $isShiftOpen)
    }
}

// MARK: - Превью

#Preview {
    ContentView()
        .environment(OrderHistoryStore())
}
