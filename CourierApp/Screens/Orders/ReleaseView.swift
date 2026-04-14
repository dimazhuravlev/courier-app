import SwiftUI

// MARK: - Release View

struct ReleaseView: View {
    let order: Order
    let onDelivered: () -> Void
    var onCopy: ((String) -> Void)? = nil

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            // Scrollable content: timer banner + info sections
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    TimerBanner(
                        title: "Передайте заказ клиенту",
                        totalSeconds: 180
                    )
                    .padding(.bottom, 10)

                    AddressSectionView(title: "Адрес", address: order.address, blurDetails: false, onCopy: onCopy)
                    ClientSectionView(order: order, onCall: {}, onCopy: onCopy)
                    OrderSectionView(order: order, onDetails: {})
                }
                .padding(.horizontal, 12)
                .padding(.top, 72)
                .padding(.bottom, 172)
            }

            // Slider button at the bottom
            VStack(spacing: 0) {
                Spacer()
                SliderButton(label: "Я получил оплату и передал заказ", onConfirm: onDelivered)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReleaseView(order: Order.sampleOrders[0]) {}
}
