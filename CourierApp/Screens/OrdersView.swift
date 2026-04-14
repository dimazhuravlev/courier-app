import SwiftUI
import UIKit

// MARK: - Order Stage

enum OrderStage: Equatable {
    case waiting
    case picking
    case onWay(orderIndex: Int)
    case release(orderIndex: Int)
    case success(orderIndex: Int)
    case returning
}

// MARK: - Orders View

struct OrdersView: View {
    @Binding var suppressMainTabBar: Bool
    @Binding var pauseState: PauseState
    @Binding var ordersAreActive: Bool
    var onNewOrders: (() -> Void)? = nil
    @Environment(OrderHistoryStore.self) private var historyStore

    private let orders = Order.sampleOrders
    private let restaurant = Restaurant.sample

    @State private var stage: OrderStage = .waiting
    @State private var overlayOpacity: Double = 0
    @State private var isTransitioning = false
    @State private var showCopiedToast = false
    @State private var showBlurredToast = false
    @State private var currentRouteID: UUID?

    var body: some View {
        ZStack {
            if case .active(let since) = pauseState {
                PauseScreenView(pauseSince: since) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pauseState = .off
                    }
                }
            } else {
                stageContent(for: stage)
                Color.surface0
                    .ignoresSafeArea()
                    .opacity(overlayOpacity)
                    .allowsHitTesting(false)
            }

        }
        .toast("Скопировано", isPresented: $showCopiedToast)
        .toast("Сначала подойдите к дому\n— тогда откроем детали", isPresented: $showBlurredToast)
        .onAppear {
            updateMainTabBarSuppression(for: stage)
            syncOrdersActive(for: stage)
        }
        .onChange(of: stage) { _, new in
            updateMainTabBarSuppression(for: new)
            syncOrdersActive(for: new)
        }
        .onChange(of: pauseState) { _, new in
            if case .pending = new, canStartPauseImmediately {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pauseState = .active(since: Date())
                }
            }
            updateMainTabBarSuppression(for: stage)
        }
    }

    private var canStartPauseImmediately: Bool {
        stage == .waiting || stage == .returning
    }

    private func updateMainTabBarSuppression(for s: OrderStage) {
        if case .active = pauseState {
            suppressMainTabBar = false
            return
        }
        if case .success = s {
            suppressMainTabBar = true
        } else {
            suppressMainTabBar = false
        }
    }

    @ViewBuilder
    private func stageContent(for s: OrderStage) -> some View {
        switch s {
        case .waiting:
            WaitingView { advance(to: .picking) }

        case .picking:
            PickingView(orders: orders) { advance(to: .onWay(orderIndex: 0)) }

        case .onWay(let i):
            OnWayView(order: orders[i], onArrived: { advance(to: .release(orderIndex: i)) }, onCopy: handleCopy, onBlurredTap: handleBlurredTap)
                .id("onWay-\(i)")

        case .release(let i):
            ReleaseView(order: orders[i], onDelivered: { advance(to: .success(orderIndex: i)) }, onCopy: handleCopy)
                .id("release-\(i)")

        case .success(let i):
            let isLast = i == orders.count - 1
            SuccessView(
                ordersDelivered: i + 1,
                totalOrders: orders.count,
                config: successConfig(for: i),
                buttonLabel: isLast ? "Вернуться в ресторан..." : "К следующему заказу..."
            ) {
                if isLast, case .pending = pauseState {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pauseState = .active(since: Date())
                    }
                } else {
                    advance(to: isLast ? .returning : .onWay(orderIndex: i + 1))
                }
            }
            .id("success-\(i)")

        case .returning:
            ReturnView(restaurant: restaurant) {
                if case .pending = pauseState {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pauseState = .active(since: Date())
                    }
                } else {
                    advance(to: .waiting)
                }
            }
        }
    }

    private func successConfig(for orderIndex: Int) -> SuccessConfig {
        SuccessConfig(deliveryResult: orders[orderIndex].deliveryResult)
    }

    private func handleCopy(_ text: String) {
        UIPasteboard.general.string = text
        showCopiedToast = true
    }

    private func handleBlurredTap() {
        showBlurredToast = true
    }

    private func syncOrdersActive(for s: OrderStage) {
        ordersAreActive = s != .waiting && s != .returning
    }

    private static func parseTimeDeltaMinutes(_ delta: String) -> Int {
        let sign: Int
        let body: String
        if delta.hasPrefix("+") {
            sign = 1
            body = String(delta.dropFirst())
        } else if delta.hasPrefix("-") {
            sign = -1
            body = String(delta.dropFirst())
        } else {
            sign = 1
            body = delta
        }
        let parts = body.split(separator: ":")
        guard parts.count == 2, let m = Int(parts[0]) else { return 0 }
        return sign * m
    }

    private static func parseDeliveryTimeMinutes(_ time: String) -> Int {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let m = Int(parts[0]) else { return 0 }
        return m
    }

    private static func parseDistanceKm(_ distance: String) -> Double {
        if distance.hasSuffix(" km") {
            let num = distance.replacingOccurrences(of: " km", with: "")
                              .replacingOccurrences(of: ",", with: ".")
            return Double(num) ?? 0
        } else if distance.hasSuffix(" m") {
            let num = distance.replacingOccurrences(of: " m", with: "")
            return (Double(num) ?? 0) / 1000.0
        }
        return 0
    }

    private func advance(to next: OrderStage) {
        guard !isTransitioning else { return }
        isTransitioning = true

        Task { @MainActor in
            // Fade in black overlay — hides current screen completely
            withAnimation(.easeInOut(duration: 0.25)) {
                overlayOpacity = 1
            }

            try? await Task.sleep(for: .milliseconds(250))
            try? await Task.sleep(for: .milliseconds(300))

            // Switch stage while hidden behind overlay — no flash possible
            withTransaction(Transaction(animation: nil)) {
                stage = next
            }

            if case .picking = next {
                onNewOrders?()
                let routeID = UUID()
                currentRouteID = routeID
                let timelineOrders = orders.map { order in
                    TimelineOrder(
                        number: order.number,
                        address: order.address.street,
                        amount: order.amount,
                        status: .pending,
                        distance: Self.parseDistanceKm(order.deliveryResult.distance)
                    )
                }
                historyStore.addEntry(.route(id: routeID, time: Date(), orders: timelineOrders))
            }

            if case .success(let i) = next, let routeID = currentRouteID {
                let order = orders[i]
                historyStore.updateOrderStatus(
                    routeID: routeID,
                    orderIndex: i,
                    status: .delivered(minutes: Self.parseTimeDeltaMinutes(order.deliveryResult.timeDelta)),
                    deliveryMinutes: Self.parseDeliveryTimeMinutes(order.deliveryResult.deliveryTime)
                )
            }

            try? await Task.sleep(for: .milliseconds(50))

            // Fade out overlay — reveals new screen
            withAnimation(.easeInOut(duration: 0.35)) {
                overlayOpacity = 0
            }

            isTransitioning = false
        }
    }
}

// MARK: - Preview

#Preview {
    MainView(isShiftOpen: .constant(false))
}
