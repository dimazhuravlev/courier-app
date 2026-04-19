import SwiftUI
import UIKit

// MARK: - Тост

private struct ToastView: View {
    let text: String
    @Binding var isPresented: Bool

    @State private var offset: CGFloat = -40
    @State private var dragOffset: CGFloat = 0
    @State private var dismissTask: Task<Void, Never>?
    private let haptic = UINotificationFeedbackGenerator()

    private var topInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.text)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textInverted)
                .frame(width: 295, height: 56)
                .background(.white)
                .clipShape(Capsule())
                .position(x: geo.size.width / 2, y: offset + min(dragOffset, 0))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            if value.translation.height < -30 {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .onChange(of: isPresented) { _, show in
                    if show { appear() }
                }
                .onAppear {
                    if isPresented { appear() }
                }
        }
        .ignoresSafeArea()
    }

    private func appear() {
        offset = -40
        dragOffset = 0
        dismissTask?.cancel()

        haptic.notificationOccurred(.success)

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            offset = topInset + 30
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    private func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.25)) {
            offset = -40
            dragOffset = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            isPresented = false
        }
    }
}

// MARK: - Модификатор тоста

private struct ToastModifier: ViewModifier {
    let text: String
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ToastView(text: text, isPresented: $isPresented)
            }
        }
    }
}

// MARK: - Расширение View

extension View {
    func toast(_ text: String, isPresented: Binding<Bool>) -> some View {
        modifier(ToastModifier(text: text, isPresented: isPresented))
    }
}
