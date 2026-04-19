import Foundation

// MARK: - Адрес доставки

struct DeliveryAddress {
    let city: String
    let street: String
    let entrance: String
    let intercom: String
    let floor: String
    let apartment: String

    /// Город + улица для внешних карт и навигатора.
    var navigationSearchQuery: String {
        let c = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = street.trimmingCharacters(in: .whitespacesAndNewlines)
        if c.isEmpty { return s }
        if s.isEmpty { return c }
        return "\(c), \(s)"
    }
}

// MARK: - Результат доставки

enum DeliveryStatus {
    case ahead
    case slightlyLate
    case veryLate
}

struct DeliveryResult {
    let status: DeliveryStatus
    let timeDelta: String
    let deliveryTime: String
    let distance: String
}

// MARK: - Оплата

enum PaymentType {
    case cash
    case card

    var label: String {
        switch self {
        case .cash: return "Наличка"
        case .card: return "Картой"
        }
    }
}

// MARK: - Заказ

struct Order: Identifiable {
    let id: UUID
    let sequenceNumber: Int
    let number: String
    let address: DeliveryAddress
    let clientName: String
    let clientComment: String
    let amount: String
    let isPaid: Bool
    let paymentType: PaymentType
    let deliveryResult: DeliveryResult
}

// MARK: - Ресторан

struct Restaurant {
    let name: String
    let address: DeliveryAddress
}

extension Restaurant {
    static let sample = Restaurant(
        name: "Ресторан",
        address: DeliveryAddress(
            city: "Москва",
            street: "ул. Тверская, 12",
            entrance: "",
            intercom: "",
            floor: "",
            apartment: ""
        )
    )
}

// MARK: - Тестовые данные

extension Order {
    static let sampleOrders: [Order] = [
        Order(
            id: UUID(),
            sequenceNumber: 1,
            number: "35012",
            address: DeliveryAddress(
                city: "Москва",
                street: "пер. Покровский, 18",
                entrance: "2",
                intercom: "2801#",
                floor: "4",
                apartment: "13"
            ),
            clientName: "Александр",
            clientComment: "Звоните, как будете у подъезда. Я выйду, так как домофон не работает",
            amount: "2460 ₽",
            isPaid: false,
            paymentType: .card,
            deliveryResult: DeliveryResult(
                status: .ahead,
                timeDelta: "+5:48",
                deliveryTime: "21:57",
                distance: "1,2 km"
            )
        ),
        Order(
            id: UUID(),
            sequenceNumber: 2,
            number: "35013",
            address: DeliveryAddress(
                city: "Москва",
                street: "ул. Ярославская, 21",
                entrance: "1",
                intercom: "45Б",
                floor: "3",
                apartment: "8"
            ),
            clientName: "Мария",
            clientComment: "Оставьте у двери, пожалуйста",
            amount: "1340 ₽",
            isPaid: true,
            paymentType: .card,
            deliveryResult: DeliveryResult(
                status: .slightlyLate,
                timeDelta: "-1:04",
                deliveryTime: "9:11",
                distance: "960 m"
            )
        ),
        Order(
            id: UUID(),
            sequenceNumber: 3,
            number: "35014",
            address: DeliveryAddress(
                city: "Москва",
                street: "ул. Большая Дмитровка, 7",
                entrance: "3",
                intercom: "107#",
                floor: "5",
                apartment: "22"
            ),
            clientName: "Дмитрий",
            clientComment: "Код от подъезда 1234, поднимитесь на лифте",
            amount: "1870 ₽",
            isPaid: false,
            paymentType: .cash,
            deliveryResult: DeliveryResult(
                status: .veryLate,
                timeDelta: "-12:53",
                deliveryTime: "35:07",
                distance: "3,8 km"
            )
        )
    ]
}
