import SwiftUI
import UIKit

// MARK: - Строка настроек

private struct SettingsRow: View {
    let iconName: String
    let title: String
    let subtitle: String?
    let hasCheckBadge: Bool

    init(iconName: String, title: String, subtitle: String? = nil, hasCheckBadge: Bool = false) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.hasCheckBadge = hasCheckBadge
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.text2)

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .textStyle()
                    .foregroundStyle(Color.text1)
                if let subtitle {
                    Text(subtitle)
                        .textStyle()
                        .foregroundStyle(Color.text2)
                }
            }

            Spacer()

            if hasCheckBadge {
                ZStack {
                    Circle()
                        .fill(Color.success)
                        .frame(width: 32, height: 32)

                    Image("Done")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color.text1)
                }
            }

            Image("Arrow-right")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.text2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.surface3)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.stroke2, lineWidth: 1)
                )
        )
    }
}

// MARK: - Экран профиля

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @State private var showSupportSheet = false

    private let bg = Color.surface0
    private static let privacyPolicyURL = URL(string: "https://starterapp.ru/privacy")!
    private static let appSettingsURL = URL(string: UIApplication.openSettingsURLString)!

    var body: some View {
        GeometryReader { geo in
            let topInset = resolvedTopSafeInset(from: geo)
            ZStack {
                bg.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // Профиль и выход (как в «Сменах»: тот же верхний inset и отступы)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Павел Скороходов")
                                .headline1Style()
                                .foregroundStyle(Color.text1)
                            Text("+7 960 348 9812")
                                .headline1Style()
                                .foregroundStyle(Color.text2)
                        }

                        Spacer()

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Image("Exit")
                                .resizable()
                                .renderingMode(.template)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.text1)
                        }
                        .frame(width: 48, height: 48)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(Color.stroke2, lineWidth: 1))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, topInset + 8)
                    .padding(.horizontal, 12)

                    // Настройки и помощь
                    VStack(alignment: .leading, spacing: 6) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            openURL(Self.appSettingsURL)
                        } label: {
                            SettingsRow(iconName: "Location", title: "Геолокация", hasCheckBadge: true)
                        }
                        .buttonStyle(.plain)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            openURL(Self.appSettingsURL)
                        } label: {
                            SettingsRow(iconName: "Push", title: "Пуш-уведомления", hasCheckBadge: true)
                        }
                        .buttonStyle(.plain)

                        Text("Помощь")
                            .headline1Style()
                            .foregroundStyle(Color.text1)
                            .padding(.top, 10)
                            .padding(.bottom, 4)

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showSupportSheet = true
                        } label: {
                            SettingsRow(iconName: "Comment", title: "Связаться с поддержкой", subtitle: "Если что-то случилось")
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showSupportSheet) {
                            SupportSheetView()
                                .presentationBackground(Color.surface1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 28)

                    Spacer()
                }

                // Политика и версия внизу
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 4) {
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            openURL(Self.privacyPolicyURL)
                        } label: {
                            Text("Политика конфиденциальности")
                                .captionStyle()
                                .foregroundStyle(Color.text1)
                        }
                        .buttonStyle(.plain)
                        Text("Версия приложения 1.12")
                            .captionStyle()
                            .foregroundStyle(Color.text2)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Как на экране смен: у родителя с ignoresSafeArea() GeometryReader часто даёт 0 сверху.
    private func resolvedTopSafeInset(from geo: GeometryProxy) -> CGFloat {
        let fromGeo = geo.safeAreaInsets.top
        if fromGeo > 0.5 { return fromGeo }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let fromWindow = scene.windows.first { $0.isKeyWindow }?.safeAreaInsets.top
                ?? scene.windows.first?.safeAreaInsets.top
                ?? 0
            if fromWindow > 0.5 { return fromWindow }
        }
        return 47
    }
}

// MARK: - Превью

#Preview {
    MainView(isShiftOpen: .constant(false))
}
