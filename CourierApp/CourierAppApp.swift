import SwiftUI
import CoreText

@main
struct CourierAppApp: App {
    private let timerStore = DeliveryTimerStore()
    private let historyStore = OrderHistoryStore()

    init() {
        registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerStore)
                .environment(historyStore)
        }
    }

    private func registerFonts() {
        let fonts: [(name: String, ext: String)] = [
            ("Pretendard-SemiBold", "otf"),
            ("PPNeueBit-Bold", "otf")
        ]
        for font in fonts {
            guard let url = Bundle.main.url(forResource: font.name, withExtension: font.ext) else {
                print("⚠️ Font not found in bundle: \(font.name).\(font.ext)")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
