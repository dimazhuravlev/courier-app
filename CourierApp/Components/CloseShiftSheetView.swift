import SwiftUI

struct CloseShiftSheetView: View {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    @State private var contentHeight: CGFloat = 0
    private let sheetBg = Color.surface1

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image("exit")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)

                Text("Завершить смену?")
                    .headline2Style()
                    .foregroundStyle(Color.text1)
                    .multilineTextAlignment(.center)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onConfirm()
                }
            } label: {
                Text("Да, завершить")
                    .headline2Style()
                    .foregroundStyle(Color.text1)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 143/255, green: 0, blue: 214/255),
                                        Color(red: 112/255, green: 0, blue: 204/255)
                                    ],
                                    startPoint: UnitPoint(x: 0.06, y: 0.5),
                                    endPoint: UnitPoint(x: 0.94, y: 0.5)
                                )
                            )
                            .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
            }
            .buttonStyle(CloseShiftButtonStyle())
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

private struct CloseShiftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
    }
}

#Preview {
    Color.surface0
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            CloseShiftSheetView(isPresented: .constant(true), onConfirm: {})
        }
}
