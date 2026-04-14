import SwiftUI

// MARK: - Timer Status

enum TimerStatus: Equatable {
    case normal
    case warning
    case late
}

// MARK: - Timer Banner

struct TimerBanner: View {
    let title: String
    let totalSeconds: Int
    var onStatusChange: ((TimerStatus) -> Void)?
    var onBlendChange: ((Double) -> Void)?

    @Environment(DeliveryTimerStore.self) private var timerStore

    // Unique per view instance: preserved across tab switches (same view stays alive),
    // but regenerated when the order stage changes (SwiftUI creates a new TimerBanner).
    @State private var instanceID = UUID()
    @State private var lastReported: TimerStatus = .normal

    // MARK: Computed

    private var key: String { instanceID.uuidString }

    /// Accessing ticks inside body registers this view as an observer in @Observable tracking.
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

    /// Share of total width for the active (green/yellow) timeline fill — shrinks from the right as time runs out.
    private var remainingWidthFraction: CGFloat {
        guard totalSeconds > 0, status != .late else { return 0 }
        return CGFloat(Double(remaining) / Double(totalSeconds))
    }

    private var status: TimerStatus {
        if remaining <= 0 { return .late }
        return progress <= 0.10 ? .warning : .normal
    }

    // 0 = full green, 1 = full orange.
    // Transition window: 25% → 10% remaining.
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

    // MARK: Subviews

    private var ambientGlow: some View {
        ZStack {
            // Green glow (normal)
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

            // Yellow-orange glow (warning) — fades in via fillBlend, matching the fill
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

            // Red glow (late)
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

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {

                // Text on top of fill
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
                    // Track — same translucent gray as section cards (e.g. AddressSectionView)
                    Color.surface3

                    if status != .late {
                        ZStack {
                            // Green (normal)
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.4, green: 0.76, blue: 0.04), location: 0),
                                    Gradient.Stop(color: Color(red: 0.01, green: 0.67, blue: 0), location: 1),
                                ],
                                startPoint: UnitPoint(x: 0, y: 0.5),
                                endPoint: UnitPoint(x: 1, y: 0.5)
                            )

                            // Yellow (warning) — fades in via fillBlend
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
                        // Red (late) — full width once time is up
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

// MARK: - Preview

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
