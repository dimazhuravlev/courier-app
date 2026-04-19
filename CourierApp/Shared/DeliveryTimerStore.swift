import Foundation
import Observation

// MARK: - Таймеры доставки

/// На уровне приложения; тики не зависят от жизненного цикла экранов.
/// Ключ — строка; повторный register для того же ключа не перезапускает таймер.
@Observable
final class DeliveryTimerStore {

    // Подписка @Observable: чтение ticks[key] даёт обновление раз в секунду.
    var ticks: [String: Int] = [:]

    // Чтение startDates не подписывает вью на обновления.
    @ObservationIgnored
    private var startDates: [String: Date] = [:]

    @ObservationIgnored
    private var tasks: [String: Task<Void, Never>] = [:]

    // MARK: API

    /// Регистрирует таймер по ключу, если ещё не запущен.
    func register(key: String) {
        if startDates[key] == nil {
            startDates[key] = Date()
        }
        guard tasks[key] == nil else { return }
        tasks[key] = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.ticks[key, default: 0] += 1
            }
        }
    }

    /// Сброс таймера по ключу.
    func reset(key: String) {
        startDates[key] = Date()
        ticks[key] = 0
    }

    /// Секунд с момента регистрации таймера.
    func elapsed(for key: String) -> Int {
        guard let date = startDates[key] else { return 0 }
        return max(0, Int(Date().timeIntervalSince(date)))
    }
}
