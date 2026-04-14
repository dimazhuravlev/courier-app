import SwiftUI
import UIKit

// MARK: - Preference Key для измерения ширины кнопки

private struct ButtonWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Gesture Flags

final class GestureFlags {
    var bloopFired = false
    var lastHapticStep: Int = 0
}

// MARK: - Slider Button

struct SliderButton: View {
    let label: String
    var onConfirm: (() -> Void)? = nil

    @State private var dragOffset: CGFloat = 0
    @State private var isPressed = false
    @State private var isCompleted = false
    @State private var buttonWidth: CGFloat = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonOpacity: Double = 1.0
    @State private var buttonBlur: CGFloat = 0
    @State private var pressScale: CGFloat = 1.0
    @State private var outsideGestureActive = false
    @State private var gf = GestureFlags()

    private let circleSize: CGFloat = 64
    private let edgeInset: CGFloat = 4
    private let completionThreshold: CGFloat = 0.85

    private var maxDrag: CGFloat {
        max(buttonWidth - circleSize - edgeInset * 2, 1)
    }
    private var progress: CGFloat {
        buttonWidth > 0 ? min(dragOffset / maxDrag, 1.0) : 0
    }
    private var isActive: Bool {
        isPressed || outsideGestureActive || dragOffset > 0 || isCompleted
    }

    // Капсула: при нажатии +16px → короткая капсула; при слайде — растёт вправо
    private var capsuleWidth: CGFloat {
        let pressedExtra: CGFloat = (isPressed || outsideGestureActive) ? 16 : 0
        return circleSize + max(pressedExtra, min(dragOffset, maxDrag))
    }
    private var capsuleHeight: CGFloat { 64 }

    // Бульк: масштаб взлетает до 1.03, возвращается к 1.0
    private func triggerBloop() {
        withAnimation(.snappy(duration: 0.07)) {
            buttonScale = 1.03
        }
        Task {
            try? await Task.sleep(for: .milliseconds(70))
            withAnimation(.snappy(duration: 0.1)) {
                buttonScale = 1.0
            }
        }
    }

    private func triggerHaptic(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }

    // Скрытие: масштаб падает до 0.75 + opacity 0 + blur 32
    private func triggerDismiss() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.65)) {
            buttonScale = 0.8
            buttonOpacity = 0
            buttonBlur = 20
        }
    }

    var body: some View {
        buttonContent
            .frame(height: 72)
            .background(buttonGradient)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(white: 1, opacity: 0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isActive)
            .scaleEffect(buttonScale * pressScale, anchor: .center)
            .opacity(buttonOpacity)
            .blur(radius: buttonBlur)
            .sensoryFeedback(.impact(weight: .medium), trigger: isCompleted)
            .onPreferenceChange(ButtonWidthKey.self) { buttonWidth = $0 }
            .simultaneousGesture(outsideGesture)
    }

    private var labelOpacity: Double {
        Double(max(0, 1 - progress * 1.4))
    }

    private var labelView: some View {
        TimelineView(.animation) { timeline in
            let t = CGFloat(
                timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 2.0) / 2.0
            )
            let sweepX = t * 1.6 - 1.3

            Text(label)
                .headline2Style()
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.7), location: 0.35),
                            .init(color: .white.opacity(1.0), location: 0.5),
                            .init(color: .white.opacity(0.7), location: 0.65),
                        ],
                        startPoint: UnitPoint(x: sweepX, y: 0.9),
                        endPoint: UnitPoint(x: sweepX + 2.0, y: 0.1)
                    )
                )
                .multilineTextAlignment(.center)
                .blur(radius: progress * 10)
                .frame(maxWidth: .infinity)
                .padding(.leading, edgeInset + circleSize + 8)
                .padding(.trailing, 40)
                .allowsHitTesting(false)
        }
        .opacity(labelOpacity)
    }

    private var widthReader: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ButtonWidthKey.self, value: geo.size.width)
        }
    }

    private var buttonContent: some View {
        ZStack(alignment: .leading) {
            widthReader
            labelView
            slidingCapsule.padding(.leading, edgeInset)
        }
    }

    private var outsideGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isCompleted else { return }
                if !outsideGestureActive {
                    let sx = value.startLocation.x
                    let sy = value.startLocation.y
                    let capsuleMinY = (72 - capsuleHeight) / 2
                    let isInsideCapsule = sx >= edgeInset
                        && sx <= edgeInset + circleSize
                        && sy >= capsuleMinY
                        && sy <= capsuleMinY + capsuleHeight
                    guard !isInsideCapsule else { return }
                    outsideGestureActive = true
                    triggerHaptic(intensity: 0.6)
                }
            }
            .onEnded { _ in
                guard outsideGestureActive else { return }
                outsideGestureActive = false
            }
    }

    private var slidingCapsule: some View {
        let radius = capsuleHeight / 2
        let iconW: CGFloat = 21
        let iconH: CGFloat = 37
        // Line width fills the space to the left of the centered icon.
        // As capsule grows rightward, icon drifts right (center-anchored) and line stretches.
        let lineW = max(0, (capsuleWidth - iconW) / 2 + 20)

        return ZStack {
            // Horizontal tail — grows from the left as capsule expands
            Rectangle()
                .fill(Color.fillInverted)
                .frame(width: lineW, height: 5)
                .offset(x: -(iconW + lineW) / 2 + 20)

            // Pixel arrowhead, center-anchored so it moves right during slide
            Image("slider arrow")
                .resizable()
                .interpolation(.none)
                .frame(width: iconW, height: iconH)
        }
        .frame(width: capsuleWidth, height: capsuleHeight)
        .background(
            RoundedRectangle(cornerRadius: radius)
                .fill(Color.white.opacity(isPressed ? 0.4 : 0.3))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
        )
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .overlay(
            RoundedRectangle(cornerRadius: radius)
                .stroke(Color(white: 1, opacity: 0.06), lineWidth: 1.125)
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: capsuleHeight)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: isPressed)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: outsideGestureActive)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !isCompleted else { return }
                    if !isPressed {
                        isPressed = true
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { pressScale = 1.03 }
                        triggerHaptic(intensity: 0.6)
                    }
                    let newOffset = max(0, min(value.translation.width, maxDrag))
                    // Бульк при достижении правого края
                    if newOffset >= maxDrag && dragOffset < maxDrag && !gf.bloopFired {
                        gf.bloopFired = true
                        triggerBloop()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    // Сброс флага только при явном отводе назад (мёртвая зона 12pt),
                    // чтобы микродрожание пальца у края не перезапускало бульк
                    if newOffset < maxDrag - 12 {
                        gf.bloopFired = false
                    }
                    dragOffset = newOffset

                    // 20 лёгких хаптиков равномерно по пути (шаги 1–20, но шаг 20 — сильный выше)
                    let newStep = Int(progress * 20)
                    if newStep > gf.lastHapticStep {
                        gf.lastHapticStep = newStep
                        if newStep < 20 {
                            triggerHaptic(intensity: 0.3)
                        }
                    } else if newStep < gf.lastHapticStep {
                        gf.lastHapticStep = newStep
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) { pressScale = 1.0 }
                    gf.lastHapticStep = 0
                    guard !isCompleted else { return }
                    if progress >= completionThreshold {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = maxDrag
                            isCompleted = true
                        }
                        onConfirm?()
                        if gf.bloopFired {
                            // Бульк уже был — сразу скрываем
                            triggerDismiss()
                        } else {
                            // Бульк не был (snap-кейс: отпустил до края) — бульк + скрытие
                            Task {
                                try? await Task.sleep(for: .milliseconds(300))
                                triggerBloop()
                                try? await Task.sleep(for: .milliseconds(170))
                                triggerDismiss()
                            }
                        }
                    } else {
                        gf.bloopFired = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private var buttonGradient: some View {
        ZStack {
            // Default gradient
            LinearGradient(
                colors: [
                    Color(red: 143 / 255, green: 0, blue: 214 / 255),
                    Color(red: 112 / 255, green: 0, blue: 204 / 255)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            // Pressed/active gradient cross-fades in
            LinearGradient(
                colors: [
                    Color(red: 173 / 255, green: 10 / 255, blue: 1.0),
                    Color(red: 140 / 255, green: 0, blue: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(isActive ? 1 : 0)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        SliderButton(label: "Я около дома клиента")
            .padding(.horizontal, 24)
    }
}
