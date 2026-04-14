import SwiftUI

// MARK: - Return View

struct ReturnView: View {
    let restaurant: Restaurant
    let onReturned: () -> Void

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            // Scrollable content: timer banner + restaurant address
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    TimerBanner(
                        title: "Вернитесь в ресторан",
                        totalSeconds: 300
                    )
                    .padding(.bottom, 10)

                    AddressSectionView(
                        title: restaurant.name,
                        address: restaurant.address,
                        showDetails: false
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 72)
                .padding(.bottom, 172)
            }

            // Slider button at the bottom
            VStack(spacing: 0) {
                Spacer()
                SliderButton(label: "Я вернулся в ресторан", onConfirm: onReturned)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReturnView(restaurant: .sample) {}
}
