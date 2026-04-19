import SwiftUI

// MARK: - Шторка поддержки

struct SupportSheetView: View {
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                sheetButton(icon: "Phone", title: "Позвонить", action: {})
                sheetButton(icon: "Comment", title: "Написать в чат", action: {})
            }

            VStack(spacing: 16) {
                Text("Служба спасения\nв экстренных ситуациях")
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image("Alarm")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(Color.danger)
                        Text("112")
                            .headline2Style()
                            .foregroundStyle(Color.danger)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color.danger.opacity(0.06), Color.danger.opacity(0.10)],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            .overlay(
                                Capsule()
                                    .stroke(Color.stroke2, lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
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
        .presentationBackground(Color.surface1)
    }

    @ViewBuilder
    private func sheetButton(icon: String?, title: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                Text(title)
                    .headline2Style()
                    .foregroundStyle(Color.text1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.fill1, Color.fill3],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        Capsule()
                            .stroke(Color.stroke2, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Превью

#Preview {
    Color.surface0
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SupportSheetView()
        }
}
