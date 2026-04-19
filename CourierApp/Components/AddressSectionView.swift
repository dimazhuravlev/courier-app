import SwiftUI
import UIKit

// MARK: - Секция адреса

struct AddressSectionView: View {
    let title: String
    let address: DeliveryAddress
    var showDetails: Bool = true
    var blurDetails: Bool = true
    var onCopy: ((String) -> Void)? = nil
    var onBlurredTap: (() -> Void)? = nil

    @State private var navigatorIconPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if showDetails {
                divider
                detailsRow
            }
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
                Text(title)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                Text(address.street)
                    .headline1Style()
                    .foregroundStyle(Color.text1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onCopy?(address.street) }

            navigationButton
        }
    }

    // MARK: - Кнопка навигации

    private var navigationButton: some View {
        Button {
            openYandexNavigator(for: address)
        } label: {
            Image("navigation button")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipped()
                .scaleEffect(navigatorIconPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: navigatorIconPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !navigatorIconPressed {
                        navigatorIconPressed = true
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.prepare()
                        haptic.impactOccurred()
                    }
                }
                .onEnded { _ in
                    navigatorIconPressed = false
                }
        )
        .accessibilityLabel("Открыть в Яндекс Навигаторе")
    }

    private func openYandexNavigator(for address: DeliveryAddress) {
        guard let url = yandexNavigatorMapSearchURL(for: address) else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            if !success, let storeURL = URL(string: "https://apps.apple.com/app/id474500851") {
                UIApplication.shared.open(storeURL, options: [:], completionHandler: nil)
            }
        }
    }

    private func yandexNavigatorMapSearchURL(for address: DeliveryAddress) -> URL? {
        var components = URLComponents(string: "yandexnavi://map_search")
        components?.queryItems = [URLQueryItem(name: "text", value: address.navigationSearchQuery)]
        return components?.url
    }

    // MARK: - Разделитель

    private var divider: some View {
        Rectangle()
            .fill(Color.stroke2)
            .frame(height: 1)
    }

    // MARK: - Детали

    private var detailsRow: some View {
        HStack(alignment: .center, spacing: 0) {
            addressDetailItem(label: "Подъезд", value: address.entrance, blurred: false)
            Spacer()
            addressDetailItem(label: "Домофон", value: address.intercom, blurred: blurDetails)
            Spacer()
            addressDetailItem(label: "Этаж", value: address.floor, blurred: blurDetails)
            Spacer()
            addressDetailItem(label: "Квартира", value: address.apartment, blurred: blurDetails)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func addressDetailItem(label: String, value: String, blurred: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .textStyle()
                .foregroundStyle(Color.text2)
            Text(value)
                .headline1Style()
                .foregroundStyle(Color.text1)
                .blur(radius: blurred ? 8 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if blurred {
                onBlurredTap?()
            } else {
                onCopy?(value)
            }
        }
    }
}

// MARK: - Превью

#Preview {
    ZStack {
        Color.surface0.ignoresSafeArea()
        AddressSectionView(
            title: "Адрес",
            address: Order.sampleOrders[0].address
        )
        .padding(.horizontal, 24)
    }
}
