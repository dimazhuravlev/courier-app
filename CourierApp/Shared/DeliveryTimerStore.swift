import Foundation
import Observation

// MARK: - Delivery Timer Store

/// Lives at the app level and keeps timers running regardless of view lifecycle.
/// Each timer is identified by a string key. Calling register(key:) is idempotent —
/// the start date and background Task are created once and survive tab switches.
@Observable
final class DeliveryTimerStore {

    // Observed: views that read ticks[key] re-render every second.
    var ticks: [String: Int] = [:]

    // Not observed: reading startDates doesn't subscribe the view to future changes.
    @ObservationIgnored
    private var startDates: [String: Date] = [:]

    @ObservationIgnored
    private var tasks: [String: Task<Void, Never>] = [:]

    // MARK: Public API

    /// Registers a timer for `key` if not already running. Safe to call multiple times.
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

    /// Restarts the timer for `key` from zero.
    func reset(key: String) {
        startDates[key] = Date()
        ticks[key] = 0
    }

    /// Wall-clock seconds elapsed since the timer for `key` was registered.
    func elapsed(for key: String) -> Int {
        guard let date = startDates[key] else { return 0 }
        return max(0, Int(Date().timeIntervalSince(date)))
    }
}
