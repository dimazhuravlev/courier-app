import SwiftUI

// MARK: - Settings Row

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

// MARK: - Profile View

struct ProfileView: View {
    @State private var showSupportSheet = false

    private let bg = Color.surface0

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // User info + logout
                HStack(alignment: .top, spacing: 12) {
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
                .padding(.top, 72)
                .padding(.horizontal, 12)

                // Settings + Help sections
                VStack(alignment: .leading, spacing: 6) {
                    SettingsRow(iconName: "Location", title: "Геолокация", hasCheckBadge: true)
                    SettingsRow(iconName: "Push", title: "Пуш-уведомления", hasCheckBadge: true)

                    // Section title
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

            // Bottom section: privacy policy + version label
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 4) {
                    Text("Политика конфиденциальности")
                        .captionStyle()
                        .foregroundStyle(Color.text1)
                    Text("Версия приложения 1.12")
                        .captionStyle()
                        .foregroundStyle(Color.text2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView(isShiftOpen: .constant(false))
}
