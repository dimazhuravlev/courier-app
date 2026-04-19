import SwiftUI
import UIKit

// MARK: - Вкладка

enum Tab: Int, CaseIterable {
    case orders = 0
    case shifts = 1
    case profile = 2

    var title: String {
        switch self {
        case .orders: return "Заказы"
        case .shifts: return "Смены"
        case .profile: return "Профиль"
        }
    }

    var iconName: String {
        switch self {
        case .orders: return "Location"
        case .shifts: return "Calendar"
        case .profile: return "Profile"
        }
    }
}

// MARK: - Состояние паузы

enum PauseState: Equatable {
    case off
    case pending
    case active(since: Date)
}

// MARK: - Clip только когда слева есть таб «Заказы» (иначе календарь не режем — фрейм дня)

private struct ShiftTabHorizontalClip: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content.clipped()
        } else {
            content
        }
    }
}

// MARK: - Главный экран

struct MainView: View {
    @Binding var isShiftOpen: Bool
    @Environment(OrderHistoryStore.self) private var historyStore
    @State private var selectedTab: Tab = .shifts
    @State private var suppressMainTabBar = false
    @State private var pauseState: PauseState = .off
    @State private var tabBeforePause: Tab = .shifts
    @State private var hasNewOrders = false
    @State private var showNewOrderToast = false
    @State private var ordersAreActive = false
    @State private var showShiftClosedToast = false
    @State private var shiftsScrollToTop = false
    /// День, для которого показываем шторку сброса истории (синхронизируется с календарём «Смен»).
    @State private var shakeHistoryTargetDate = Calendar.current.startOfDay(for: Date())
    @State private var showDeleteHistorySheet = false
    private let haptic = UISelectionFeedbackGenerator()

    private var visibleTabs: [Tab] {
        isShiftOpen ? Tab.allCases : Tab.allCases.filter { $0 != .orders }
    }

    var body: some View {
        ZStack {
            Color.surface0
                .ignoresSafeArea()

            ZStack {
                if isShiftOpen {
                    OrdersView(
                        suppressMainTabBar: $suppressMainTabBar,
                        pauseState: $pauseState,
                        ordersAreActive: $ordersAreActive,
                        onNewOrders: handleNewOrders
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(selectedTab == .orders ? 1 : 0)
                }
                ShiftsView(
                    isShiftOpen: $isShiftOpen,
                    pauseState: $pauseState,
                    ordersAreActive: ordersAreActive,
                    onPauseConfirmed: handlePauseConfirmed,
                    scrollToTop: shiftsScrollToTop,
                    shakeHistoryTargetDate: $shakeHistoryTargetDate
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(ShiftTabHorizontalClip(enabled: isShiftOpen))
                    .opacity(selectedTab == .shifts ? 1 : 0)
                ProfileView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(selectedTab == .profile ? 1 : 0)
            }
            .ignoresSafeArea()
            .animation(nil, value: selectedTab)

            VStack {
                Spacer()
                if !suppressMainTabBar {
                    TabBar(
                        selectedTab: $selectedTab,
                        visibleTabs: visibleTabs,
                        hasNewOrders: hasNewOrders,
                        onTap: handleTabTap
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)

        }
        .toast("Новый заказ!", isPresented: $showNewOrderToast)
        .toast("Смена закрыта\n— можно отдыхать", isPresented: $showShiftClosedToast)
        .sheet(isPresented: $showDeleteHistorySheet) {
            DeleteHistorySheetView(
                isPresented: $showDeleteHistorySheet,
                selectedDate: shakeHistoryTargetDate
            ) {
                historyStore.deleteHistory(for: shakeHistoryTargetDate)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            showDeleteHistorySheet = true
        }
        .onChange(of: selectedTab) { _, _ in
            haptic.selectionChanged()
        }
        .onChange(of: isShiftOpen) { old, open in
            if !open {
                suppressMainTabBar = false
                pauseState = .off
                hasNewOrders = false
                ordersAreActive = false
                if selectedTab == .orders {
                    selectedTab = .shifts
                }
                if old {
                    showShiftClosedToast = true
                }
            }
        }
        .onChange(of: pauseState) { old, new in
            if case .active = new, case .active = old {} else if case .active = new {
                var t = Transaction(animation: nil)
                t.disablesAnimations = true
                withTransaction(t) {
                    selectedTab = .orders
                    hasNewOrders = false
                }
            }
            if case .off = new, case .active = old {
                suppressMainTabBar = false
                var t = Transaction(animation: nil)
                t.disablesAnimations = true
                withTransaction(t) {
                    selectedTab = tabBeforePause
                }
            }
        }
    }

    private func handleTabTap(_ newTab: Tab) {
        if newTab == selectedTab {
            if newTab == .shifts {
                shiftsScrollToTop.toggle()
            }
            return
        }
        haptic.selectionChanged()
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedTab = newTab
        }
        if newTab == .orders && hasNewOrders {
            withAnimation(.easeOut(duration: 0.4)) {
                hasNewOrders = false
            }
        }
    }

    private func handleNewOrders() {
        guard selectedTab != .orders else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            hasNewOrders = true
        }
        showNewOrderToast = true
    }

    private func handlePauseConfirmed() {
        tabBeforePause = selectedTab
        withAnimation(.easeInOut(duration: 0.2)) {
            pauseState = .pending
        }
    }
}

// MARK: - Превью

#Preview {
    MainView(isShiftOpen: .constant(false))
        .environment(OrderHistoryStore())
}
