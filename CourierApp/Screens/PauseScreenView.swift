import SwiftUI

struct PauseScreenView: View {
    let pauseSince: Date
    let onResume: () -> Void

    private let darkBg = Color.surface0

    private let backgroundGradient = LinearGradient(
        stops: [
            .init(color: Color(red: 0x96/255, green: 0x33/255, blue: 0xFF/255), location: 0),
            .init(color: Color(red: 0xE1/255, green: 0x0F/255, blue: 0x04/255), location: 0.5),
            .init(color: Color(red: 0xBD/255, green: 0x00/255, blue: 0x2B/255), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let elapsed = Int(max(0, context.date.timeIntervalSince(pauseSince)))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            let timerText = String(format: "%d:%02d", minutes, seconds)

            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Text("Пауза на свои дела")
                            .headline2Style()
                            .foregroundStyle(Color.text1)

                        Text(timerText)
                            .font(.custom("PPNeueBit-Bold", size: 120))
                            .foregroundStyle(Color.text1)
                            .lineSpacing(0)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.3, bounce: 0), value: timerText)
                    }

                    Text("Новые заказы\nне назначаются")
                        .headline2Style()
                        .foregroundStyle(Color.text1)
                        .multilineTextAlignment(.center)
                }

                VStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onResume()
                    } label: {
                        HStack(spacing: 8) {
                            Image("Play")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(darkBg)
                                .frame(width: 24, height: 24)
                            Text("Вернуться на смену")
                                .headline2Style()
                                .foregroundStyle(darkBg)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 72)
                        .background(
                            Capsule()
                                .fill(.white)
                                .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
                    }
                    .buttonStyle(PauseResumeButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

private struct PauseResumeButtonStyle: ButtonStyle {
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
    PauseScreenView(pauseSince: Date()) {}
}
