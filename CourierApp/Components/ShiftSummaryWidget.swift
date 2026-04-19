import SwiftUI

// MARK: - Данные саммари

struct ShiftDaySummary {
    let aheadCount: Int
    let totalOrders: Int
    let totalDistanceKm: Double
    let totalTimeSeconds: Int

    init(entries: [ShiftTimelineEntry]) {
        var ahead = 0
        var total = 0
        var distance = 0.0

        for entry in entries {
            if case .route(_, _, let orders) = entry {
                for order in orders {
                    if case .delivered(let minutes) = order.status {
                        total += 1
                        if minutes > 0 { ahead += 1 }
                    }
                    distance += order.distance ?? 0
                }
            }
        }

        self.aheadCount = ahead
        self.totalOrders = total
        self.totalDistanceKm = distance

        var totalSeconds = 0
        var openTime: Date?
        for entry in entries {
            switch entry {
            case .shiftOpened(_, let time):
                openTime = time
            case .shiftClosed(_, let time):
                if let start = openTime {
                    totalSeconds += Int(time.timeIntervalSince(start))
                    openTime = nil
                }
            default:
                break
            }
        }
        if let start = openTime {
            totalSeconds += Int(Date().timeIntervalSince(start))
        }
        self.totalTimeSeconds = totalSeconds
    }
}

// MARK: - PreferenceKey ширины

private struct ContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Виджет саммари

struct ShiftSummaryWidget: View {
    let summary: ShiftDaySummary

    @State private var containerWidth: CGFloat = 0

    private let cardBg = Color.surface3
    private let cardStroke = Color.stroke2
    private let numberFont = Font.custom("PPNeueBit-Bold", size: 72)
    private let gap: CGFloat = 6

    var body: some View {
        VStack(spacing: gap) {
            topRow
            bottomRow
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContainerWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(ContainerWidthKey.self) { containerWidth = $0 }
    }

    // MARK: - Верхний ряд

    private var topRow: some View {
        let available = containerWidth - gap
        let leftWidth = available * 65.0 / 110.0
        let rightWidth = available * 45.0 / 110.0

        return HStack(spacing: gap) {
            metricCard {
                Text("\(summary.aheadCount)")
                    .font(numberFont)
                    .lineSpacing(0)
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0, green: 0.541, blue: 0.118), location: 0),
                                .init(color: Color(red: 0.459, green: 0.922, blue: 0), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Заказов")
                    Text("с опережением")
                }
            }
            .frame(width: containerWidth > 0 ? leftWidth : nil, alignment: .leading)
            .frame(maxWidth: containerWidth > 0 ? nil : .infinity)

            metricCard {
                Text("\(summary.totalOrders)")
                    .font(numberFont)
                    .lineSpacing(0)
                    .foregroundStyle(Color.text1)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Всего")
                    Text("заказов")
                }
            }
            .frame(width: containerWidth > 0 ? rightWidth : nil, alignment: .leading)
            .frame(maxWidth: containerWidth > 0 ? nil : .infinity)
        }
    }

    // MARK: - Нижний ряд

    private var bottomRow: some View {
        HStack(spacing: gap) {
            metricCard {
                Text(formatDistance(summary.totalDistanceKm))
                    .font(numberFont)
                    .lineSpacing(0)
                    .foregroundStyle(Color.text1)
            } label: {
                Text("Всего в пути")
            }

            metricCard {
                Text(formatTime(summary.totalTimeSeconds))
                    .font(numberFont)
                    .lineSpacing(0)
                    .foregroundStyle(Color.text1)
            } label: {
                Text("Общее время")
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Карточка метрики

    @ViewBuilder
    private func metricCard<Value: View, Label: View>(
        @ViewBuilder value: () -> Value,
        @ViewBuilder label: () -> Label
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            value()
                .fixedSize(horizontal: true, vertical: false)
                .padding(.bottom, -4)

            label()
                .textStyle()
                .foregroundStyle(Color.text2)
                .padding(.bottom, -12)
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(cardStroke, lineWidth: 1)
        )
    }

    // MARK: - Форматирование

    private func formatDistance(_ km: Double) -> String {
        if km >= 1 {
            return "\(Int(km.rounded())) km"
        }
        return "\(Int((km * 1000).rounded())) m"
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}
