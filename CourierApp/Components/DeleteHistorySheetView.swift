import SwiftUI

struct DeleteHistorySheetView: View {
    @Binding var isPresented: Bool
    let selectedDate: Date
    let onConfirm: () -> Void

    @State private var contentHeight: CGFloat = 0
    private let sheetBg = Color.surface1

    private var dateString: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if cal.isDate(selectedDate, inSameDayAs: today) {
            return "сегодня"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Удалить историю\nзаказов за \(dateString)?")
                .headline2Style()
                .foregroundStyle(Color.text1)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onConfirm()
                }
            } label: {
                Text("Удалить")
                    .headline2Style()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(Color.danger)
                            .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                    )
            }
            .buttonStyle(DeleteHistoryButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        .measureHeight($contentHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color.stroke2)
                .frame(width: 40, height: 4)
                .padding(.top, 5)
        }
        .presentationDetents([.height(contentHeight + UIApplication.safeAreaBottom)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(sheetBg)
    }
}

private struct DeleteHistoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
    }
}
