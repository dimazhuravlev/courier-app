import SwiftUI

// MARK: - В пути к клиенту

struct OnWayView: View {
    let order: Order
    let onArrived: () -> Void
    var onCopy: ((String) -> Void)? = nil
    var onBlurredTap: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    TimerBanner(
                        title: "Следуйте к дому клиента",
                        totalSeconds: 360
                    )
                    .padding(.bottom, 10)

                    AddressSectionView(title: "Адрес", address: order.address, onCopy: onCopy, onBlurredTap: onBlurredTap)
                    ClientSectionView(order: order, onCall: {}, onCopy: onCopy)
                    OrderSectionView(order: order, onDetails: {})
                }
                .padding(.horizontal, 12)
                .padding(.top, 72)
                .padding(.bottom, 172)
            }

            VStack(spacing: 0) {
                Spacer()
                SliderButton(label: "Я около дома клиента", onConfirm: onArrived)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Превью

#Preview {
    OnWayView(order: Order.sampleOrders[0]) {}
}
