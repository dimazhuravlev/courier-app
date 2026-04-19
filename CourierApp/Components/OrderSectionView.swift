import SwiftUI

// MARK: - Секция заказа

struct OrderSectionView: View {
    let order: Order
    let onDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            divider
            paymentRow
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.stroke2, lineWidth: 1))
    }

    // MARK: - Верхняя строка

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Заказ")
                    .textStyle()
                    .foregroundStyle(Color.text2)
                Text(order.number)
                    .headline1Style()
                    .foregroundStyle(Color.text1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onDetails()
            } label: {
                detailsButton
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Детали

    private var detailsButton: some View {
        Text("Детали заказа")
            .textStyle()
            .foregroundStyle(Color.text1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 48)
            .background(
                LinearGradient(
                    colors: [
                        Color.fill1,
                        Color.fill3
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.stroke2, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
    }

    // MARK: - Разделитель

    private var divider: some View {
        Rectangle()
            .fill(Color.stroke2)
            .frame(height: 1)
    }

    // MARK: - Оплата

    private var paymentRow: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 6) {
                Image(order.isPaid ? "Hand ok" : "Attention")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(
                        order.isPaid
                            ? Color(red: 3 / 255, green: 171 / 255, blue: 0 / 255)
                            : Color(red: 241 / 255, green: 109 / 255, blue: 0 / 255)
                    )
                Text(order.isPaid ? "Оплачен" : "Не оплачен")
                    .textStyle()
                    .foregroundStyle(
                        order.isPaid
                            ? Color(red: 3 / 255, green: 171 / 255, blue: 0 / 255)
                            : Color(red: 241 / 255, green: 109 / 255, blue: 0 / 255)
                    )
            }

            Spacer()

            HStack(spacing: 6) {
                Text(order.amount)
                    .textStyle()
                    .foregroundStyle(Color.text1)

                Circle()
                    .fill(Color.fill4)
                    .frame(width: 4, height: 4)
                Text(order.paymentType.label)
                    .textStyle()
                    .foregroundStyle(Color.text2)
            }
        }
    }
}

// MARK: - Превью

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        OrderSectionView(order: Order.sampleOrders[0], onDetails: {})
            .padding(.horizontal, 24)
    }
}
