import SwiftUI

// MARK: - Состояние таймера

enum TimerStatus: Equatable {
    case normal
    case warning
    case late
}

// MARK: - Баннер таймера

struct TimerBanner: View {
    let title: String
    let totalSeconds: Int
    var onStatusChange: ((TimerStatus) -> Void)?
    var onBlendChange: ((Double) -> Void)?

    @Environment(DeliveryTimerStore.self) private var timerStore

    // Свой UUID на экземпляр; при смене этапа заказа вью пересоздаётся — новый ключ таймера.
    @State private var instanceID = UUID()
    @State private var lastReported: TimerStatus = .normal

    // MARK: Вычисляемое

    private var key: String { instanceID.uuidString }

    /// Чтение ticks в body подписывает вью на @Observable.
    private var elapsed: Int {
        let _ = timerStore.ticks[key, default: 0]
        return timerStore.elapsed(for: key)
    }

    private var remaining: Int { max(0, totalSeconds - elapsed) }
    private var overtime: Int { max(0, elapsed - totalSeconds) }

    private var progress: Double {
        guard totalSeconds > 0, remaining > 0 else { return 0 }
        return Double(remaining) / Double(totalSeconds)
    }

    /// Доля ширины зелёной/жёлтой заливки; убывает справа по мере истечения времени.
    private var remainingWidthFraction: CGFloat {
        guard totalSeconds > 0, status != .late else { return 0 }
        return CGFloat(Double(remaining) / Double(totalSeconds))
    }

    private var status: TimerStatus {
        if remaining <= 0 { return .late }
        return progress <= 0.10 ? .warning : .normal
    }

    // 0 — зелёный, 1 — оранжевый; переход между 25% и 10% оставшегося времени.
    private var fillBlend: Double {
        guard status != .late, totalSeconds > 0 else { return 1 }
        return max(0, min(1, (0.25 - progress) / 0.15))
    }

    private var subtitleText: String {
        remaining > 0
            ? "Успейте за \(formatTime(remaining))"
            : "Опаздываем на \(formatTime(overtime))"
    }

    private func formatTime(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    // MARK: Подвью

    private var ambientGlow: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.01, green: 0.67, blue: 0), location: 0),
                            Gradient.Stop(color: Color(red: 0.33, green: 1, blue: 0), location: 1),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
                .opacity(status != .late ? 1 - fillBlend : 0)

            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.95, green: 0.52, blue: 0), location: 0),
                            Gradient.Stop(color: Color(red: 0.95, green: 0.43, blue: 0), location: 1),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
                .opacity(status != .late ? fillBlend : 0)

            Ellipse()
                .fill(
                    EllipticalGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.99, green: 0.39, blue: 0), location: 0),
                            Gradient.Stop(color: Color(red: 0.9, green: 0, blue: 0.15), location: 1),
                        ],
                        center: UnitPoint(x: 0.39, y: 0.34)
                    )
                )
                .opacity(status == .late ? 1 : 0)
        }
        .blur(radius: 90)
        .offset(x: -28, y: -22)
        .animation(.easeInOut(duration: 0.6), value: status)
        .animation(.linear(duration: 0.95), value: fillBlend)
    }

    // MARK: Разметка

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .headline1Style()
                        .foregroundStyle(Color.text1)
                    Text(subtitleText)
                        .headline1Style()
                        .foregroundStyle(Color.text2)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack(alignment: .leading) {
                    Color.surface3

                    if status != .late {
                        ZStack {
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.4, green: 0.76, blue: 0.04), location: 0),
                                    Gradient.Stop(color: Color(red: 0.01, green: 0.67, blue: 0), location: 1),
                                ],
                                startPoint: UnitPoint(x: 0, y: 0.5),
                                endPoint: UnitPoint(x: 1, y: 0.5)
                            )

                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.95, green: 0.52, blue: 0), location: 0),
                                    Gradient.Stop(color: Color(red: 0.95, green: 0.43, blue: 0), location: 1),
                                ],
                                startPoint: UnitPoint(x: 0, y: 0.5),
                                endPoint: UnitPoint(x: 1, y: 0.5)
                            )
                            .opacity(fillBlend)
                        }
                        .frame(width: max(0, geo.size.width * remainingWidthFraction))
                        .clipped()
                    } else {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color(red: 0.59, green: 0.07, blue: 0.19), location: 0),
                                Gradient.Stop(color: Color(red: 0.41, green: 0.06, blue: 0.18), location: 1),
                            ],
                            startPoint: UnitPoint(x: 0, y: 0),
                            endPoint: UnitPoint(x: 1, y: 1)
                        )
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.stroke2, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.4), value: status)
            .animation(.linear(duration: 0.95), value: remaining)
        }
        .frame(height: 76)
        .background { ambientGlow }
        .onAppear {
            timerStore.register(key: key)
            notifyIfNeeded()
            onBlendChange?(fillBlend)
        }
        .onChange(of: timerStore.ticks[key, default: 0]) { _, _ in
            notifyIfNeeded()
            onBlendChange?(fillBlend)
        }
    }

    private func notifyIfNeeded() {
        let current = status
        guard current != lastReported else { return }
        lastReported = current
        onStatusChange?(current)
    }
}

// MARK: - Превью

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        VStack(spacing: 12) {
            TimerBanner(title: "Следуйте к дому клиента", totalSeconds: 360)
            TimerBanner(title: "Передайте заказ клиенту", totalSeconds: 20)
            TimerBanner(title: "Заберите 3 заказа", totalSeconds: 0)
        }
        .padding(.horizontal, 24)
    }
    .environment(DeliveryTimerStore())
}
