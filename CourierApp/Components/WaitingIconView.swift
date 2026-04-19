import SwiftUI

// MARK: - Иконка ожидания

/// 12 точек по кругу; по очереди гаснут по часовой стрелке.
struct WaitingIconView: View {
    let size: CGFloat
    @State private var hiddenIndex = 0
    @State private var timer: Timer?

    private let totalDots = 12

    var body: some View {
        ZStack {
            ForEach(0..<totalDots, id: \.self) { index in
                Circle()
                    .fill(Color.fillInverted)
                    .frame(width: dotSize, height: dotSize)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(totalDots)))
                    .opacity(index == hiddenIndex ? 0 : 0.4)
            }
        }
        .frame(width: size, height: size)
        .onAppear { startAnimation() }
        .onDisappear { stopAnimation() }
    }

    private var radius: CGFloat { size / 2 - dotSize / 2 - 1 }
    private var dotSize: CGFloat { size * 0.15 }

    private func startAnimation() {
        hiddenIndex = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            hiddenIndex = (hiddenIndex + 1) % totalDots
        }
    }

    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Превью

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        WaitingIconView(size: 32)
    }
}
