import Foundation

// MARK: - Статус заказа в таймлайне

enum TimelineOrderStatus: Codable, Equatable {
    case pending
    case delivered(minutes: Int)
    case cancelled
}

// MARK: - Заказ в таймлайне

struct TimelineOrder: Codable, Identifiable, Equatable {
    let id: UUID
    let number: String
    let address: String
    let amount: String
    var status: TimelineOrderStatus
    var distance: Double?
    var deliveryMinutes: Int?

    init(id: UUID = UUID(), number: String, address: String, amount: String, status: TimelineOrderStatus, distance: Double? = nil, deliveryMinutes: Int? = nil) {
        self.id = id
        self.number = number
        self.address = address
        self.amount = amount
        self.status = status
        self.distance = distance
        self.deliveryMinutes = deliveryMinutes
    }
}

// MARK: - Запись таймлайна смены

enum ShiftTimelineEntry: Codable, Identifiable, Equatable {
    case shiftOpened(id: UUID, time: Date)
    case route(id: UUID, time: Date, orders: [TimelineOrder])
    case pause(id: UUID, time: Date)
    case shiftClosed(id: UUID, time: Date)

    var id: UUID {
        switch self {
        case .shiftOpened(let id, _): return id
        case .route(let id, _, _): return id
        case .pause(let id, _): return id
        case .shiftClosed(let id, _): return id
        }
    }

    var time: Date {
        switch self {
        case .shiftOpened(_, let time): return time
        case .route(_, let time, _): return time
        case .pause(_, let time): return time
        case .shiftClosed(_, let time): return time
        }
    }
}
