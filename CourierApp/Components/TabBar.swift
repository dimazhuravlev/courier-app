import SwiftUI

// MARK: - Нижняя панель вкладок

struct TabBar: View {
    @Binding var selectedTab: Tab
    var visibleTabs: [Tab] = Tab.allCases
    var hasNewOrders: Bool = false
    var onTap: ((Tab) -> Void)? = nil

    @State private var blobPulse = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 48) {
                ForEach(visibleTabs, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .frame(height: 24)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: hasNewOrders) { _, active in
            blobPulse = active
        }
    }

    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        let showGlow = tab == .orders && hasNewOrders
        return Button {
            if let onTap {
                onTap(tab)
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTab = tab
                }
            }
        } label: {
            Image(tab.iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(
                    showGlow
                        ? Color.danger.opacity(blobPulse ? 1 : 0.45)
                        : (isSelected ? Color.text1 : Color.text3)
                )
                .animation(.easeInOut(duration: 0.15), value: selectedTab)
                .animation(.easeOut(duration: 0.3), value: hasNewOrders)
                .animation(
                    showGlow ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .default,
                    value: blobPulse
                )
                .contentShape(Rectangle())
                .overlay {
                    if showGlow {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.danger.opacity(0.55),
                                        Color.danger.opacity(0.2),
                                        Color.danger.opacity(0),
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 48
                                )
                            )
                            .frame(width: 96, height: 96)
                            .blur(radius: 10)
                            .scaleEffect(blobPulse ? 1.05 : 0.92)
                            .opacity(blobPulse ? 1 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                                value: blobPulse
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.5)))
                            .allowsHitTesting(false)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Превью

#Preview {
    ZStack(alignment: .bottom) {
        Color.surface0
            .ignoresSafeArea()
        TabBar(selectedTab: .constant(.orders))
    }
}
