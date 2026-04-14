import SwiftUI

// MARK: - Content View

struct ContentView: View {
    @State private var isShiftOpen = false

    var body: some View {
        MainView(isShiftOpen: $isShiftOpen)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
