import SwiftUI

// MARK: - Конфигурация экрана успеха

struct SuccessConfig {
    let gradientStops: [Gradient.Stop]
    let stat1Label: String
    let stat1Sequence: [String]
    let stat2Sequence: [String]
    let stat3Sequence: [String]

    init(deliveryResult: DeliveryResult) {
        self.gradientStops = Self.gradientStops(for: deliveryResult.status)
        self.stat1Label = deliveryResult.status == .ahead ? "Опережение" : "Опоздание"
        self.stat1Sequence = Self.timeSequence(from: deliveryResult.timeDelta)
        self.stat2Sequence = Self.timeSequence(from: deliveryResult.deliveryTime)
        self.stat3Sequence = Self.distanceSequence(from: deliveryResult.distance)
    }

    // MARK: - Градиент

    private static func gradientStops(for status: DeliveryStatus) -> [Gradient.Stop] {
        switch status {
        case .ahead:
            return [
                .init(color: Color(red: 0.400, green: 1.000, blue: 0.890), location: 0),
                .init(color: Color(red: 0.000, green: 0.922, blue: 0.231), location: 0.603),
                .init(color: Color(red: 0.314, green: 0.820, blue: 0.000), location: 1)
            ]
        case .slightlyLate:
            return [
                .init(color: Color(red: 1.000, green: 0.961, blue: 0.400), location: 0),
                .init(color: Color(red: 0.945, green: 0.506, blue: 0.000), location: 0.5),
                .init(color: Color(red: 0.945, green: 0.188, blue: 0.000), location: 1)
            ]
        case .veryLate:
            return [
                .init(color: Color(red: 0.588, green: 0.200, blue: 1.000), location: 0),
                .init(color: Color(red: 0.882, green: 0.059, blue: 0.016), location: 0.5),
                .init(color: Color(red: 0.741, green: 0.000, blue: 0.169), location: 1)
            ]
        }
    }

    // MARK: - Последовательности для анимации цифр

    private static func timeSequence(from value: String) -> [String] {
        let prefix: String
        let body: String
        if value.hasPrefix("+") || value.hasPrefix("-") {
            prefix = String(value.prefix(1))
            body = String(value.dropFirst())
        } else {
            prefix = ""
            body = value
        }

        let parts = body.split(separator: ":")
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]) else {
            return [value, value, value]
        }

        let totalSeconds = minutes * 60 + seconds
        return (-2...0).map { offset in
            let s = totalSeconds + offset
            let m = s / 60
            let sec = s % 60
            return "\(prefix)\(m):\(String(format: "%02d", sec))"
        }
    }

    private static func distanceSequence(from value: String) -> [String] {
        if value.hasSuffix(" km") {
            let numStr = value.replacingOccurrences(of: " km", with: "")
                              .replacingOccurrences(of: ",", with: ".")
            if let num = Double(numStr) {
                return (-2...0).map { offset in
                    let v = num + Double(offset) * 0.1
                    let formatted = String(format: "%.1f", v).replacingOccurrences(of: ".", with: ",")
                    return "\(formatted) km"
                }
            }
        } else if value.hasSuffix(" m") {
            let numStr = value.replacingOccurrences(of: " m", with: "")
            if let num = Int(numStr) {
                return (-2...0).map { offset in
                    "\(num + offset * 10) m"
                }
            }
        }
        return [value, value, value]
    }
}

// MARK: - Экран успеха

struct SuccessView: View {
    var ordersDelivered: Int = 1
    var totalOrders: Int = 3
    var config: SuccessConfig
    var buttonLabel: String = "К следующему заказу..."
    let onNext: () -> Void

    @State private var didNavigate = false
    @State private var stat1Visible = false
    @State private var stat2Visible = false
    @State private var stat3Visible = false
    @State private var timerProgress: CGFloat = 1.0
    @State private var currentPackageOpacity: Double = 1.0

    @State private var displayValue1 = ""
    @State private var displayValue2 = ""
    @State private var displayValue3 = ""
    @State private var strokeProgress1: CGFloat = 0
    @State private var strokeProgress2: CGFloat = 0
    @State private var strokeProgress3: CGFloat = 0

    private let timerDuration: Double = 7.0
    private let statColor = Color.surface0

    // MARK: - Разметка

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: config.gradientStops,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 120)
                illustrationsBlock
                Spacer()
                statItem(value: displayValue1, label: config.stat1Label, visible: stat1Visible, strokeProgress: strokeProgress1)
                Spacer()
                statItem(value: displayValue2, label: "Время",      visible: stat2Visible, strokeProgress: strokeProgress2)
                Spacer()
                statItem(value: displayValue3, label: "Расстояние", visible: stat3Visible, strokeProgress: strokeProgress3)
                Spacer()
                timerButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 56)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            displayValue1 = config.stat1Sequence.first ?? ""
            displayValue2 = config.stat2Sequence.first ?? ""
            displayValue3 = config.stat3Sequence.first ?? ""
        }
        .task { await runAnimations() }
    }

    // MARK: - Иконки заказов

    private var illustrationsBlock: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<totalOrders, id: \.self) { i in
                    Image("icon-package")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .opacity(opacityForPackage(at: i))
                }
            }

            Text("Доставлен \(ordersDelivered) из \(totalOrders) заказов")
                .headline2Style()
                .foregroundStyle(statColor.opacity(0.5))
        }
    }

    private func opacityForPackage(at index: Int) -> Double {
        if index < ordersDelivered - 1 {
            return 0.3
        } else if index == ordersDelivered - 1 {
            return currentPackageOpacity
        } else {
            return 1.0
        }
    }

    // MARK: - Показатель

    private func statItem(value: String, label: String, visible: Bool, strokeProgress: CGFloat) -> some View {
        let strokeColor = statColor.opacity(strokeProgress)
        return VStack(spacing: -4) {
            Text(value)
                .font(.custom("PPNeueBit-Bold", size: 120))
                .foregroundStyle(statColor)
                .shadow(color: strokeColor, radius: 0, x: 0.5, y: 0)
                .shadow(color: strokeColor, radius: 0, x: -0.5, y: 0)
                .shadow(color: strokeColor, radius: 0, x: 0, y: 0.5)
                .shadow(color: strokeColor, radius: 0, x: 0, y: -0.5)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3, bounce: 0), value: value)

            Text(label)
                .headline2Style()
                .foregroundStyle(statColor.opacity(0.5))
        }
        .padding(.bottom, 8)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : -8)
        .animation(.easeOut(duration: 0.4), value: visible)
    }

    // MARK: - Кнопка с таймером

    private var timerButton: some View {
        Button(action: navigate) {
            ZStack {
                ZStack(alignment: .leading) {
                    Color.fill6
                    Color.white
                        .scaleEffect(x: timerProgress, y: 1, anchor: .leading)
                        .animation(.linear(duration: timerDuration), value: timerProgress)
                }
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))

                Text(buttonLabel)
                    .headline2Style()
                    .foregroundStyle(statColor)
            }
            .frame(height: 72)
        }
        .buttonStyle(ScaleHapticButtonStyle())
    }

    // MARK: - Анимации

    @MainActor
    private func runAnimations() async {
        try? await Task.sleep(for: .milliseconds(50))
        timerProgress = 0

        // Мигание иконки текущего заказа (1.0 ↔ 0.3)
        Task { @MainActor in
            let step: Double = 0.3
            let blinks: [Double] = [0.3, 1.0, 0.3, 1.0, 0.3, 1.0, 0.3, 1.0, 0.3]
            for target in blinks {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { currentPackageOpacity = target }
                try? await Task.sleep(for: .seconds(step))
            }
        }

        try? await Task.sleep(for: .milliseconds(300))
        stat1Visible = true
        Task { @MainActor in
            for v in config.stat1Sequence {
                withAnimation(.spring(duration: 0.3, bounce: 0)) { displayValue1 = v }
                try? await Task.sleep(for: .milliseconds(160))
            }
            withAnimation(.smooth(duration: 0.5)) { strokeProgress1 = 1 }
        }

        try? await Task.sleep(for: .milliseconds(450))
        stat2Visible = true
        Task { @MainActor in
            for v in config.stat2Sequence {
                withAnimation(.spring(duration: 0.3, bounce: 0)) { displayValue2 = v }
                try? await Task.sleep(for: .milliseconds(160))
            }
            withAnimation(.smooth(duration: 0.5)) { strokeProgress2 = 1 }
        }

        try? await Task.sleep(for: .milliseconds(450))
        stat3Visible = true
        Task { @MainActor in
            for v in config.stat3Sequence {
                withAnimation(.spring(duration: 0.3, bounce: 0)) { displayValue3 = v }
                try? await Task.sleep(for: .milliseconds(160))
            }
            withAnimation(.smooth(duration: 0.5)) { strokeProgress3 = 1 }
        }

        try? await Task.sleep(for: .milliseconds(5750))
        navigate()
    }

    private func navigate() {
        guard !didNavigate else { return }
        didNavigate = true
        onNext()
    }
}

// MARK: - Кнопка с хаптиком и масштабом

private struct ScaleHapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.15, bounce: 0), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
    }
}

// MARK: - Превью

#Preview {
    SuccessView(
        ordersDelivered: 1,
        totalOrders: 3,
        config: SuccessConfig(deliveryResult: Order.sampleOrders[0].deliveryResult)
    ) {}
}
