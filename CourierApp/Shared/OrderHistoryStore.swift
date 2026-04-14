import Foundation
import SwiftUI

// MARK: - Order History Store

@Observable
final class OrderHistoryStore {

    // MARK: - State

    private(set) var todayEntries: [ShiftTimelineEntry] = []
    private(set) var datesWithHistory: Set<String> = []

    // MARK: - Private

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var historyDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("order_history", isDirectory: true)
    }

    // MARK: - Init

    init() {
        ensureDirectoryExists()
        loadDatesWithHistory()
        todayEntries = loadEntries(for: Date())
    }

    // MARK: - Public API

    func addEntry(_ entry: ShiftTimelineEntry) {
        todayEntries.append(entry)
        let key = dateKey(for: Date())
        datesWithHistory.insert(key)
        saveEntries(todayEntries, for: Date())
    }

    func entries(for date: Date) -> [ShiftTimelineEntry] {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return todayEntries
        }
        return loadEntries(for: date)
    }

    func hasHistory(for date: Date) -> Bool {
        datesWithHistory.contains(dateKey(for: date))
    }

    func deleteHistory(for date: Date) {
        let key = dateKey(for: date)
        let url = fileURL(for: date)
        try? fileManager.removeItem(at: url)
        datesWithHistory.remove(key)
        if Calendar.current.isDateInToday(date) {
            todayEntries = []
        }
    }

    // MARK: - Private Helpers

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: historyDirectory.path) {
            try? fileManager.createDirectory(at: historyDirectory, withIntermediateDirectories: true)
        }
    }

    private func dateKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year!, comps.month!, comps.day!)
    }

    private func fileURL(for date: Date) -> URL {
        historyDirectory.appendingPathComponent("\(dateKey(for: date)).json")
    }

    private func loadEntries(for date: Date) -> [ShiftTimelineEntry] {
        let url = fileURL(for: date)
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([ShiftTimelineEntry].self, from: data)) ?? []
    }

    private func saveEntries(_ entries: [ShiftTimelineEntry], for date: Date) {
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL(for: date), options: .atomic)
    }

    private func loadDatesWithHistory() {
        guard let files = try? fileManager.contentsOfDirectory(atPath: historyDirectory.path) else { return }
        for file in files where file.hasSuffix(".json") {
            let key = String(file.dropLast(5)) // remove .json
            datesWithHistory.insert(key)
        }
    }
}
