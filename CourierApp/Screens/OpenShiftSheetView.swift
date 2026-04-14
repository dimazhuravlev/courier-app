import SwiftUI
import UIKit

// MARK: - Courier Type

enum CourierType: Int, CaseIterable {
    case walker = 0
    case bike = 1
    case car = 2

    var imageName: String {
        switch self {
        case .walker: return "walker"
        case .bike: return "bike"
        case .car: return "car"
        }
    }

    var label: String {
        switch self {
        case .walker: return "Пешком"
        case .bike: return "На велосипеде\nили мопеде"
        case .car: return "На машине"
        }
    }
}

// MARK: - Sheet Step

private enum ShiftStartStep: Equatable {
    case welcome
    case courierType
}

// MARK: - Open Shift Sheet View

struct OpenShiftSheetView: View {
    @Binding var isPresented: Bool
    let onShiftOpened: () -> Void

    @State private var step: ShiftStartStep = .welcome
    @State private var welcomeOpacity: Double = 1
    @State private var courierTypeOpacity: Double = 0
    @State private var selectedCourierType: CourierType?
    @State private var shakeAmount: CGFloat = 0
    @State private var welcomeHeight: CGFloat = 0
    @State private var courierTypeHeight: CGFloat = 0

    private let sheetBg = Color.surface1

    private var sheetHeight: CGFloat {
        let content: CGFloat
        switch step {
        case .welcome:     content = welcomeHeight
        case .courierType: content = courierTypeHeight
        }
        return content + UIApplication.safeAreaBottom
    }

    var body: some View {
        ZStack {
            welcomeStep
                .measureHeight($welcomeHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(welcomeOpacity)
                .allowsHitTesting(step == .welcome)

            courierTypeStep
                .measureHeight($courierTypeHeight)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .opacity(courierTypeOpacity)
                .allowsHitTesting(step == .courierType)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.stroke2)
                .frame(width: 40, height: 4)
                .padding(.top, 5)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(sheetBg)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: sheetHeight)
    }

    // MARK: - Welcome Step

    private var welcomeStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image("backpack")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)

                Text("Выходите на смену,\nкогда вы уже в ресторане\nи готовы начать доставку")
                    .headline2Style()
                    .foregroundStyle(Color.text1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            shiftActionButton("Я готов начать доставку") {
                advance(to: .courierType)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 24)
        .padding(.bottom, 56)
    }

    // MARK: - Courier Type Step

    private var courierTypeStep: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                Text("Какой вы курьер сегодня?")
                    .headline2Style()
                    .foregroundStyle(Color.text1)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    ForEach(CourierType.allCases, id: \.rawValue) { type in
                        courierTypeCard(type)
                    }
                }
                .modifier(ShakeEffect(animatableData: shakeAmount))
            }
            .padding(.horizontal, 24)

            shiftActionButton("Дальше") {
                if selectedCourierType != nil {
                    isPresented = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onShiftOpened()
                    }
                } else {
                    triggerShake()
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 24)
        .padding(.bottom, 56)
    }

    // MARK: - Courier Type Card

    @ViewBuilder
    private func courierTypeCard(_ type: CourierType) -> some View {
        let isSelected = selectedCourierType == type

        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedCourierType = type
            }
        } label: {
            HStack(spacing: 12) {
                Image(type.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)

                Text(type.label)
                    .headline2Style()
                    .foregroundStyle(isSelected ? Color.textInverted : Color.text1)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(isSelected ? Color.fillInverted : Color.surface3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(isSelected ? Color.clear : Color.stroke2, lineWidth: 1)
            )
        }
        .buttonStyle(ShiftSheetButtonStyle())
    }

    // MARK: - Shake

    private func triggerShake() {
        shakeAmount = 0
        withAnimation(.easeOut(duration: 0.5)) {
            shakeAmount = 1
        }
        // Haptic feedback synchronized with shake peaks
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.prepare()
        let peakTimes: [(Double, CGFloat)] = [
            (0.04, 1.0), (0.125, 0.75), (0.21, 0.55), (0.29, 0.40), (0.375, 0.25)
        ]
        for (delay, intensity) in peakTimes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                haptic.impactOccurred(intensity: intensity)
            }
        }
    }

    // MARK: - Button

    @ViewBuilder
    private func shiftActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .headline2Style()
                .foregroundStyle(Color.text1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 143/255, green: 0, blue: 214/255),
                                    Color(red: 112/255, green: 0, blue: 204/255)
                                ],
                                startPoint: UnitPoint(x: 0.06, y: 0.5),
                                endPoint: UnitPoint(x: 0.94, y: 0.5)
                            )
                        )
                        .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                )
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
        }
        .buttonStyle(ShiftSheetButtonStyle())
    }

    // MARK: - Navigation

    private func advance(to next: ShiftStartStep) {
        withAnimation(.easeOut(duration: 0.2)) {
            welcomeOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            step = next
            withAnimation(.easeIn(duration: 0.25)) {
                courierTypeOpacity = 1
            }
        }
    }
}

// MARK: - Button Style

private struct ShiftSheetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
    }
}

// MARK: - Shake Effect

private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let amplitude: CGFloat = 10
        let decay = max(0, 1 - animatableData)
        let translation = amplitude * sin(animatableData * .pi * 6) * decay
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Preview

#Preview {
    Color.surface0
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            OpenShiftSheetView(isPresented: .constant(true), onShiftOpened: {})
        }
}
