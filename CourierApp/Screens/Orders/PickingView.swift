import SwiftUI

// MARK: - Сбор заказов

struct PickingView: View {
    let orders: [Order]
    let onPickedUp: () -> Void

    /// Какие заказы ещё готовятся (по id).
    @State private var preparingOrderIDs: Set<UUID> = []
    @State private var readyTimer: Timer?

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if hasPreparing {
                    VStack {
                        Text("Подождите, пока все\nзаказы будут готовы")
                            .headline1Style()
                            .foregroundStyle(Color.text1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Color.surface3)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.stroke2, lineWidth: 1)
                    )
                    .padding(.horizontal, 12)
                } else {
                    TimerBanner(
                        title: "Заберите заказы",
                        totalSeconds: 60
                    )
                    .padding(.horizontal, 12)
                }

                VStack(spacing: 6) {
                    ForEach(orders) { order in
                        OrderCard(
                            number: order.sequenceNumber,
                            orderNumber: order.number,
                            address: order.address.street,
                            isPreparing: preparingOrderIDs.contains(order.id)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)

                Spacer()
            }
            .padding(.top, 72)

            VStack(spacing: 0) {
                Spacer()
                SliderButton(label: "Я забрал все заказы", onConfirm: onPickedUp)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
        .onAppear { setupPreparingState() }
        .onDisappear { readyTimer?.invalidate() }
    }

    private var hasPreparing: Bool {
        !preparingOrderIDs.isEmpty
    }

    private func setupPreparingState() {
        // Демо: заказ 35014 сначала «готовится»
        if let order = orders.first(where: { $0.number == "35014" }) {
            preparingOrderIDs.insert(order.id)

            readyTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.35)) {
                    _ = preparingOrderIDs.remove(order.id)
                }
            }
        }
    }
}

// MARK: - Превью

#Preview {
    PickingView(orders: Order.sampleOrders) {}
}
