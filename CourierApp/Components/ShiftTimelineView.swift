import SwiftUI

// MARK: - Shift Timeline View

struct ShiftTimelineView: View {
    let entries: [ShiftTimelineEntry]

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(entries) { entry in
                timelineRow(for: entry)
            }
        }
    }

    @ViewBuilder
    private func timelineRow(for entry: ShiftTimelineEntry) -> some View {
        switch entry {
        case .shiftOpened(_, let time):
            TimelineDividerView(time: time)
            VStack(spacing: 0) {
                TimelineEventCard(title: "Смена открыта")
            }
            .padding(.leading, 48)

        case .route(_, let time, let orders):
            TimelineDividerView(time: time)
            VStack(spacing: 0) {
                ForEach(Array(orders.enumerated()), id: \.element.id) { index, order in
                    if index > 0 {
                        RouteConnector()
                    }
                    TimelineOrderCard(order: order)
                }
            }
            .padding(.leading, 48)

        case .pause(_, let time):
            TimelineDividerView(time: time)
            VStack(spacing: 0) {
                TimelineEventCard(title: "Пауза")
            }
            .padding(.leading, 48)

        case .shiftClosed(_, let time):
            TimelineDividerView(time: time)
            VStack(spacing: 0) {
                TimelineEventCard(title: "Смена закрыта")
            }
            .padding(.leading, 48)
        }
    }
}

// MARK: - Timeline Divider View

private struct TimelineDividerView: View {
    let time: Date

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: 6) {
            Text(Self.formatter.string(from: time))
                .captionStyle()
                .foregroundStyle(Color.text3)

            Rectangle()
                .fill(Color.stroke2)
                .frame(height: 0.5)
        }
        .frame(height: 16)
    }
}

// MARK: - Timeline Event Card

private struct TimelineEventCard: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .textStyle()
                .foregroundStyle(Color.text1)
            Spacer()
        }
        .padding(12)
        .background(Color.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Timeline Order Card

private struct TimelineOrderCard: View {
    let order: TimelineOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(order.address)
                .textStyle()
                .foregroundStyle(Color.text1)

            HStack(spacing: 4) {
                Text(order.number)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .opacity(0.4)

                Circle()
                    .fill(Color.text2)
                    .frame(width: 3, height: 3)
                    .opacity(0.4)

                Text(order.amount)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .opacity(0.4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Route Connector

private struct RouteConnector: View {
    var body: some View {
        HStack {
            Image("merger")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 6)
                .padding(.leading, 16)
            Spacer()
        }
    }
}
