import SwiftUI

// MARK: - Ожидание заказов

struct WaitingView: View {
    let onAssigned: () -> Void

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image("lay back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 210, height: 160)

                Text("Оставайтесь в ресторане\nи ждите новые заказы")
                    .headline2Style()
                    .foregroundStyle(Color.text1)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
        }
        .task {
            do {
                try await Task.sleep(for: .seconds(6))
                onAssigned()
            } catch {}
        }
    }
}

// MARK: - Превью

#Preview {
    WaitingView {}
}
