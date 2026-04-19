import SwiftUI

// MARK: - Карточка заказа

struct OrderCard: View {
    let number: Int
    let orderNumber: String
    let address: String
    var isPreparing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    if isPreparing {
                        WaitingIconView(size: 32)
                    } else {
                        Circle()
                            .fill(Color.success)
                            .frame(width: 32, height: 32)
                    }
                    Text("\(number)")
                        .textStyle()
                        .foregroundStyle(Color.text1)
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(orderNumber)
                        .headline1Style()
                        .foregroundStyle(Color.text1)
                    Text(address)
                        .textStyle()
                        .foregroundStyle(Color.text2)
                }

                Spacer()
            }

            if isPreparing {
                Rectangle()
                    .fill(Color.stroke2)
                    .frame(height: 1)

                Text("Готовится")
                    .textStyle()
                    .foregroundStyle(Color.text1)
            }
        }
        .padding(16)
        .background(Color.surface3)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.stroke2, lineWidth: 1)
        )
    }
}

// MARK: - Превью

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        VStack(spacing: 6) {
            OrderCard(number: 1, orderNumber: "35012", address: "ул. Некрасова, 54А", isPreparing: true)
            OrderCard(number: 2, orderNumber: "35013", address: "ул. Ленина, 81")
        }
        .padding(.horizontal, 12)
    }
}
