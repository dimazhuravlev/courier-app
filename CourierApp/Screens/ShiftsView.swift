import SwiftUI
import UIKit

// MARK: - Ячейка дня

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let dotColor: Color?

    private static let selectionFill = Color.surface3
    private static let selectionStroke = Color.stroke2

    /// Как в месячном календаре: маркер «сегодня» — фиолетовый градиент (не зелёный «есть история»).
    private static let todayMarkerGradient = LinearGradient(
        colors: [
            Color(red: 143 / 255, green: 0, blue: 214 / 255),
            Color(red: 112 / 255, green: 0, blue: 204 / 255)
        ],
        startPoint: UnitPoint(x: 0, y: 0),
        endPoint: UnitPoint(x: 1, y: 0.405696 / 8.36818)
    )

    private var isPast: Bool {
        date < Calendar.current.startOfDay(for: Date())
    }

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: date))
    }

    private var dateOpacity: Double {
        isPast && !isSelected ? 0.4 : 1.0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Self.selectionFill)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Self.selectionStroke, lineWidth: 1))
                .scaleEffect(isSelected ? 1 : 0.95)
                .opacity(isSelected ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: isSelected)
                .allowsHitTesting(false)

            Text(dayNumber)
                .headline1Style()
                .foregroundStyle(.white.opacity(dateOpacity))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)

            ZStack {
                if isToday {
                    Circle()
                        .fill(Self.todayMarkerGradient)
                        .frame(width: 8, height: 8)
                }
                if let dotColor {
                    Circle().fill(dotColor).frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 49)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Экран смен

// MARK: - Состояние виджета смены

private enum ShiftWidgetState: Equatable {
    case closed
    case active(since: Date, totalPause: TimeInterval)
    case paused(shiftStart: Date, totalPauseBefore: TimeInterval, pauseSince: Date)
}

struct ShiftsView: View {
    @Binding var isShiftOpen: Bool
    @Binding var pauseState: PauseState
    var ordersAreActive: Bool = false
    var onPauseConfirmed: () -> Void
    var scrollToTop: Bool = false
    @Binding var shakeHistoryTargetDate: Date
    @Environment(OrderHistoryStore.self) private var historyStore
    @State private var weekDelta: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var shiftState: ShiftWidgetState = .closed
    @State private var showOpenShiftSheet = false
    @State private var showCloseShiftSheet = false
    @State private var showCalendarSheet = false
    @State private var showPauseWarningSheet = false
    @State private var showBlockedCloseToast = false

    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let impactHaptic = UIImpactFeedbackGenerator(style: .light)

    private let bg = Color.surface0
    private let overlayShade = Color(red: 15 / 255, green: 18 / 255, blue: 21 / 255)

    // MARK: - Неделя

    private var mondayBase: Date {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysBack = weekday == 1 ? 6 : weekday - 2
        return cal.date(byAdding: .day, value: -daysBack, to: today) ?? today
    }

    private func weekStart(delta: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: delta, to: mondayBase) ?? mondayBase
    }

    private func weekDays(delta: Int) -> [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart(delta: delta)) }
    }

    private var showStartShiftButton: Bool {
        guard isSelectedDayToday else { return false }
        if case .closed = shiftState { return true }
        return false
    }

    private var isSelectedDayToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    private var isSelectedDayPast: Bool {
        selectedDate < Calendar.current.startOfDay(for: Date())
    }

    private var isSelectedDayFuture: Bool {
        selectedDate > Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Строки заголовка

    private var headerTitleString: String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        if cal.isDate(selectedDate, inSameDayAs: today) {
            return "Смены сегодня"
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  cal.isDate(selectedDate, inSameDayAs: yesterday) {
            return "Смены вчера"
        } else if let tomorrow = cal.date(byAdding: .day, value: 1, to: today),
                  cal.isDate(selectedDate, inSameDayAs: tomorrow) {
            return "Смены завтра"
        }
        return "Смены"
    }

    private var headerSubtitleString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Разметка

    var body: some View {
        GeometryReader { geo in
            // Родитель (`MainView`) игнорирует safe area — у `GeometryReader` иногда top inset = 0.
            let topInset = resolvedTopSafeInset(from: geo)
            let bottomInset = geo.safeAreaInsets.bottom
            let headerTopPadding = topInset + 8
            // Высота блока заголовка (две строки + кнопка календаря); меньше — лишний зазор до недели.
            let headerReservedHeight: CGFloat = 64

            ZStack(alignment: .topLeading) {
                bg.ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Color.clear
                                .frame(height: headerTopPadding + headerReservedHeight)
                                .id("shiftsTop")

                            weekdayNamesRow
                                .padding(.top, 10)

                            weekStripView
                                .padding(.top, 4)

                            contentArea
                        }
                        .padding(.bottom, 196 + bottomInset)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: scrollToTop) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("shiftsTop", anchor: .top)
                        }
                    }
                }

                topHeaderGradient(topInset: topInset)
                headerView
                    .padding(.horizontal, 12)
                    .padding(.top, topInset + 8)
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                bottomGradient(bottomInset: bottomInset)

                sliderButtonBar
                    .opacity(showStartShiftButton ? 1 : 0)
                    .allowsHitTesting(showStartShiftButton)
                    .animation(.easeInOut(duration: 0.3), value: showStartShiftButton)
                if !isSelectedDayToday {
                    todayFloatingButton
                        .transition(.opacity)
                }
            }
        }
        .toast("Сначала закончите все заказы\n— и можно закрыть смену", isPresented: $showBlockedCloseToast)
        .animation(.easeInOut(duration: 0.2), value: isSelectedDayToday)
        .onAppear {
            selectionHaptic.prepare()
            impactHaptic.prepare()
            syncShiftStateFromBinding()
            shakeHistoryTargetDate = selectedDate
        }
        .onChange(of: isShiftOpen) { _, open in
            syncShiftStateFromBinding()
        }
        .sheet(isPresented: $showOpenShiftSheet) {
            OpenShiftSheetView(isPresented: $showOpenShiftSheet) {
                let now = Date()
                withAnimation(.easeInOut(duration: 0.2)) {
                    shiftState = .active(since: now, totalPause: 0)
                    isShiftOpen = true
                }
                historyStore.addEntry(.shiftOpened(id: UUID(), time: now))
            }
        }
        .sheet(isPresented: $showCloseShiftSheet) {
            CloseShiftSheetView(isPresented: $showCloseShiftSheet) {
                let now = Date()
                historyStore.addEntry(.shiftClosed(id: UUID(), time: now))
                withAnimation(.easeInOut(duration: 0.2)) {
                    shiftState = .closed
                    isShiftOpen = false
                }
            }
        }
        .sheet(isPresented: $showCalendarSheet) {
            CalendarBottomSheet(selectedDate: $selectedDate, isPresented: $showCalendarSheet)
        }
        .sheet(isPresented: $showPauseWarningSheet) {
            PauseWarningSheetView(isPresented: $showPauseWarningSheet) {
                onPauseConfirmed()
            }
        }
        .onChange(of: pauseState) { _, new in
            switch new {
            case .active:
                if case .active(let since, let totalPause) = shiftState {
                    let now = Date()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        shiftState = .paused(shiftStart: since, totalPauseBefore: totalPause, pauseSince: now)
                    }
                    historyStore.addEntry(.pause(id: UUID(), time: now))
                }
            case .off:
                if case .paused(let shiftStart, let totalBefore, let pauseSince) = shiftState {
                    let addedPause = Date().timeIntervalSince(pauseSince)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        shiftState = .active(since: shiftStart, totalPause: totalBefore + addedPause)
                    }
                }
            case .pending:
                break
            }
        }
        .onChange(of: selectedDate) { _, new in
            shakeHistoryTargetDate = new
            applyWeekDeltaForCurrentSelection()
        }
        .onChange(of: showCalendarSheet) { _, isOpen in
            // После выбора даты в месячном календаре иногда не срабатывает onChange(selectedDate)
            // до закрытия sheet — догоняем неделю при закрытии шторки.
            if !isOpen {
                normalizeSelectedDateToStartOfDay()
                applyWeekDeltaForCurrentSelection()
            }
        }
    }

    private func normalizeSelectedDateToStartOfDay() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: selectedDate)
        if start != selectedDate {
            selectedDate = start
        }
    }

    private func applyWeekDeltaForCurrentSelection() {
        let newDelta = weekDeltaForDate(selectedDate)
        if newDelta != weekDelta {
            weekDelta = newDelta
        }
    }

    private func syncShiftStateFromBinding() {
        if isShiftOpen {
            if case .closed = shiftState, isSelectedDayToday {
                shiftState = .active(since: Date(), totalPause: 0)
            }
        } else {
            shiftState = .closed
        }
    }

    // MARK: - Заголовок

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitleString)
                    .headline1Style()
                    .foregroundStyle(Color.text1)
                    .id(headerTitleString)
                    .transition(.blurReplace)
                Text(headerSubtitleString)
                    .headline1Style()
                    .foregroundStyle(Color.text2)
                    .id(headerSubtitleString)
                    .transition(.blurReplace)
            }
            Spacer()
            calendarButton
        }
        .animation(.easeInOut(duration: 0.25), value: selectedDate)
    }

    private var calendarButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showCalendarSheet = true
        } label: {
            Image("Calendar small")
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
    }

    // MARK: - Полоса недели

    private var weekdayNamesRow: some View {
        HStack(spacing: 4) {
            ForEach(["пн", "вт", "ср", "чт", "пт", "сб", "вс"], id: \.self) { name in
                Text(name)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 12)
    }

    private var weekStripView: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            HStack(spacing: 0) {
                weekRow(delta: weekDelta - 1).frame(width: width)
                weekRow(delta: weekDelta).frame(width: width)
                weekRow(delta: weekDelta + 1).frame(width: width)
            }
            .frame(width: width * 3, alignment: .leading)
            .offset(x: -width + dragOffset)
            .contentShape(Rectangle())
            // Одновременно с вертикальным ScrollView; горизонталь доминирует — не съедаем вертикальный скролл.
            .simultaneousGesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        let w = value.translation.width
                        let h = value.translation.height
                        guard abs(w) >= abs(h) else { return }
                        dragOffset = w
                    }
                    .onEnded { value in
                        let w = value.translation.width
                        let h = value.translation.height
                        guard abs(w) >= abs(h) else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { dragOffset = 0 }
                            return
                        }
                        let t = w
                        let v = value.predictedEndTranslation.width
                        let threshold = width * 0.2
                        if t < -threshold || v < -width * 0.4 {
                            commitWeekSwipe(direction: 1, width: width)
                        } else if t > threshold || v > width * 0.4 {
                            commitWeekSwipe(direction: -1, width: width)
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { dragOffset = 0 }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 49)
    }

    private func commitWeekSwipe(direction: Int, width: CGFloat) {
        impactHaptic.impactOccurred()
        let targetOffset = direction > 0 ? -width : width
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            dragOffset = targetOffset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            weekDelta += direction
            advanceSelectedDate(by: direction)
            withTransaction(Transaction(animation: nil)) { dragOffset = 0 }
        }
    }

    @ViewBuilder
    private func weekRow(delta: Int) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        HStack(spacing: 4) {
            ForEach(weekDays(delta: delta), id: \.self) { day in
                Button {
                    guard !Calendar.current.isDate(day, inSameDayAs: selectedDate) else { return }
                    selectionHaptic.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.15)) { selectedDate = day }
                } label: {
                    DayCell(
                        date: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDate(day, inSameDayAs: today),
                        dotColor: historyStore.hasHistory(for: day) && !Calendar.current.isDate(day, inSameDayAs: today) ? .success : nil
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .animation(.easeInOut(duration: 0.15), value: selectedDate)
    }

    // MARK: - Контент

    private var timelineEntries: [ShiftTimelineEntry] {
        if Calendar.current.isDateInToday(selectedDate) {
            return historyStore.todayEntries
        }
        return historyStore.entries(for: selectedDate)
    }

    private var isShiftActive: Bool {
        if case .closed = shiftState { return false }
        return true
    }

    private var hasSummaryData: Bool {
        timelineEntries.contains { entry in
            if case .route = entry { return true }
            return false
        }
    }

    /// Отступ таймлайна под блоком саммари или виджета открытой смены (только «сегодня»).
    private var todayTimelineTopPadding: CGFloat {
        guard !timelineEntries.isEmpty else { return 0 }
        return 40
    }

    @ViewBuilder
    private var contentArea: some View {
        if isSelectedDayToday {
            todayContentArea
        } else if !timelineEntries.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if hasSummaryData {
                    ShiftSummaryWidget(summary: ShiftDaySummary(entries: timelineEntries))
                        .padding(.horizontal, 12)
                }
                ShiftTimelineView(entries: timelineEntries)
                    .padding(.horizontal, 12)
                    .padding(.top, hasSummaryData ? 40 : 0)
            }
            .padding(.top, 24)
        } else {
            emptyStateView
        }
    }

    @ViewBuilder
    private var todayShiftWidgetsSlot: some View {
        if isShiftActive {
            openShiftWidget
                .transition(.opacity)
        } else if hasSummaryData {
            ShiftSummaryWidget(summary: ShiftDaySummary(entries: timelineEntries))
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var todayContentArea: some View {
        if timelineEntries.isEmpty, !isShiftActive {
            emptyStateView
        } else {
            VStack(alignment: .leading, spacing: 0) {
                todayShiftWidgetsSlot
                    .padding(.horizontal, 12)
                if !timelineEntries.isEmpty {
                    ShiftTimelineView(entries: timelineEntries)
                        .padding(.horizontal, 12)
                        .padding(.top, todayTimelineTopPadding)
                }
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Пустой день

    private var emptyStatePlaceholderText: String {
        if isSelectedDayPast {
            return "День был,\nработы не было"
        }
        if isSelectedDayToday {
            return "Отличный день,\nчтобы поработать"
        }
        return "Заглянули в будущее\n— тут пока пусто"
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if isSelectedDayToday, case .closed = shiftState {
            VStack(spacing: 8) {
                Image("start shift")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)

                Text(emptyStatePlaceholderText)
                    .textStyle()
                    .foregroundStyle(Color.text2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .animation(.easeInOut(duration: 0.2), value: selectedDate)
        } else {
            Text(emptyStatePlaceholderText)
                .textStyle()
                .foregroundStyle(Color.text2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .animation(.easeInOut(duration: 0.2), value: selectedDate)
        }
    }

    // MARK: - Нижняя область

    /// Верхний inset: из GeometryReader, иначе у активного окна (у родителя с ignoresSafeArea() в geo часто 0).
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

    /// Отдельно от хедера: иначе `ZStack` с градиентом даёт большую область hit-testing и перехватывает тапы/жесты над календарём.
    private func topHeaderGradient(topInset: CGFloat) -> some View {
        LinearGradient(
            colors: [overlayShade, overlayShade.opacity(0.92), overlayShade.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: topInset + 140)
        .frame(maxWidth: .infinity, alignment: .top)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private func bottomGradient(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(
                colors: [overlayShade.opacity(0), overlayShade.opacity(0.88), overlayShade],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: bottomInset + 128)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
        // Иначе Spacer перехватывает жесты по всему экрану поверх ScrollView.
        .allowsHitTesting(false)
    }

    private var openShiftWidget: some View {
        OpenShiftWidget(
            shiftState: shiftState,
            pauseState: pauseState,
            onFinish: {
                if ordersAreActive {
                    showBlockedCloseToast = true
                } else {
                    showCloseShiftSheet = true
                }
            },
            onPause: {
                showPauseWarningSheet = true
            },
            onResume: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pauseState = .off
                }
            },
            onCancelPause: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pauseState = .off
                }
            }
        )
    }

    private var startShiftButton: some View {
        Button {
            showOpenShiftSheet = true
        } label: {
            StartShiftButtonLabel(text: "Выйти на смену")
        }
        .buttonStyle(StartShiftButtonStyle())
        .padding(.horizontal, 24)
    }

    private var sliderButtonBar: some View {
        startShiftButton
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Кнопка «Сегодня»

    private var todayFloatingButton: some View {
        VStack {
            Spacer()
                .allowsHitTesting(false)
            Button {
                impactHaptic.impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedDate = Calendar.current.startOfDay(for: Date())
                    weekDelta = 0
                }
            } label: {
                HStack(spacing: 8) {
                    if isSelectedDayFuture {
                        todayArrowIcon("Back-left")
                    }
                    Text("Сегодня")
                        .textStyle()
                        .foregroundStyle(Color.text1)
                    if isSelectedDayPast {
                        todayArrowIcon("Back-right")
                    }
                }
                .frame(height: 48)
                .padding(.horizontal, 20)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
    }

    private func todayArrowIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.text1)
    }

    // MARK: - Вспомогательное

    private func weekDeltaForDate(_ date: Date) -> Int {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: dayStart)
        let daysBack = weekday == 1 ? 6 : weekday - 2
        let dateMonday = cal.date(byAdding: .day, value: -daysBack, to: dayStart) ?? dayStart
        let days = cal.dateComponents([.day], from: mondayBase, to: dateMonday).day ?? 0
        return days / 7
    }

    private func advanceSelectedDate(by weeks: Int) {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: selectedDate)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        let newStart = weekStart(delta: weekDelta)
        if let newDay = cal.date(byAdding: .day, value: daysFromMonday, to: newStart) {
            selectedDate = newDay
        }
    }
}

// MARK: - Виджет открытой смены

private struct OpenShiftWidget: View {
    let shiftState: ShiftWidgetState
    let pauseState: PauseState
    let onFinish: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancelPause: () -> Void

    private let cardBg = Color.surface3
    private let cardStroke = Color.stroke2

    var body: some View {
        if case .closed = shiftState {
            EmptyView()
        } else {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let now = context.date
                let isPaused: Bool = {
                    if case .paused = shiftState { return true }
                    return false
                }()

                VStack(alignment: .leading, spacing: 16) {
                    if case .active(let since, let totalPause) = shiftState {
                        activeContent(now: now, since: since, totalPause: totalPause)
                    } else if case .paused(_, let totalBefore, let pauseSince) = shiftState {
                        pausedContent(now: now, totalPauseBefore: totalBefore, pauseSince: pauseSince)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            shiftInnerGlow(isPaused: isPaused)
                                .position(x: 128, y: 196)

                            RoundedRectangle(cornerRadius: 24)
                                .fill(cardBg)

                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(cardStroke, lineWidth: 1)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
            }
        }
    }

    /// Размытый овал: зелёный градиент на смене, плавно сменяется на красный при паузе.
    private func shiftInnerGlow(isPaused: Bool) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.01, green: 0.67, blue: 0), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.33, green: 1, blue: 0), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0, y: 0),
                        endPoint: UnitPoint(x: 1, y: 1)
                    )
                )
                .opacity(isPaused ? 0 : 1)

            Ellipse()
                .fill(
                    EllipticalGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.99, green: 0.39, blue: 0), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.9, green: 0, blue: 0.15), location: 1.00),
                        ],
                        center: UnitPoint(x: 0.39, y: 0.34)
                    )
                )
                .opacity(isPaused ? 1 : 0)
        }
        .frame(width: 350, height: 180)
        .rotationEffect(Angle(degrees: 7))
        .blur(radius: 70)
        .opacity(0.5)
        .animation(.easeInOut(duration: 0.6), value: isPaused)
        .allowsHitTesting(false)
    }

    private func activeContent(now: Date, since: Date, totalPause: TimeInterval) -> some View {
        let elapsed = now.timeIntervalSince(since) - totalPause
        let isPausePending = pauseState == .pending
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    RecordBlinkDot()
                    Text("На смене")
                        .headline1Style()
                        .foregroundStyle(Color.text1)
                }
                Text(formatElapsed(elapsed))
                    .headline1Style()
                    .foregroundStyle(Color.text2)
            }

            if isPausePending {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onFinish()
                } label: {
                    HStack(spacing: 8) {
                        FinishIcon()
                        Text("Завершить")
                            .textStyle()
                            .foregroundStyle(Color.textInverted)
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 20)
                }
                .background(Capsule().fill(.white))
                .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)

                Rectangle()
                    .fill(Color.stroke2)
                    .frame(height: 1)

                Text("Пауза начнётся после доставки последнего заказа")
                    .headline1Style()
                    .foregroundStyle(Color.text2)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onCancelPause()
                } label: {
                    Text("Отменить паузу")
                        .textStyle()
                        .foregroundStyle(Color.text1)
                        .frame(height: 48)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(ShiftPauseButtonStyle())
            } else {
                HStack(spacing: 6) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onFinish()
                    } label: {
                        HStack(spacing: 8) {
                            FinishIcon()
                            Text("Завершить")
                                .textStyle()
                                .foregroundStyle(Color.textInverted)
                        }
                        .frame(height: 48)
                        .padding(.horizontal, 20)
                    }
                    .background(Capsule().fill(.white))
                    .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onPause()
                    } label: {
                        HStack(spacing: 6) {
                            PauseIcon()
                            Text("Пауза")
                                .textStyle()
                                .foregroundStyle(Color.text1)
                        }
                        .frame(height: 48)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(ShiftPauseButtonStyle())
                }
            }
        }
    }

    private func pausedContent(now: Date, totalPauseBefore: TimeInterval, pauseSince: Date) -> some View {
        let pauseElapsed = now.timeIntervalSince(pauseSince)
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Смена на паузе")
                    .headline1Style()
                    .foregroundStyle(Color.text1)
                Text(formatElapsed(pauseElapsed))
                    .headline1Style()
                    .foregroundStyle(Color.text2)
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onResume()
            } label: {
                HStack(spacing: 6) {
                    PlayIcon()
                    Text("Вернуться на смену")
                        .textStyle()
                        .foregroundStyle(Color.textInverted)
                }
                .frame(height: 48)
                .padding(.horizontal, 16)
            }
            .buttonStyle(ShiftResumeButtonStyle())
        }
    }

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

private struct RecordBlinkDot: View {
    private let period: TimeInterval = 0.6

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let phase = Int(t / period) % 2
            Circle()
                .fill(Color.success)
                .frame(width: 16, height: 16)
                .opacity(phase == 0 ? 1 : 0)
                .animation(nil, value: phase)
        }
    }
}

private struct FinishIcon: View {
    var body: some View {
        Image("Hand bye")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.textInverted)
            .frame(width: 20, height: 20)
    }
}

private struct PauseIcon: View {
    var body: some View {
        Image("Pause")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
    }
}

private struct PlayIcon: View {
    var body: some View {
        Image("Play")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.textInverted)
            .frame(width: 16, height: 16)
    }
}

private struct ShiftPauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.fill1, Color.fill3],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)
    }
}

private struct ShiftResumeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Capsule().fill(.white))
            .overlay(Capsule().strokeBorder(Color.stroke1, lineWidth: 1))
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 1)
    }
}

// MARK: - Подпись кнопки «Выйти на смену»

private struct StartShiftButtonLabel: View {
    let text: String

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = CGFloat(
                timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 2.0) / 2.0
            )
            let sweepX = t * 1.6 - 1.3
            Text(text)
                .headline2Style()
                .foregroundStyle(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.7), location: 0.35),
                            .init(color: .white.opacity(1.0), location: 0.5),
                            .init(color: .white.opacity(0.7), location: 0.65),
                        ],
                        startPoint: UnitPoint(x: sweepX, y: 0.9),
                        endPoint: UnitPoint(x: sweepX + 2.0, y: 0.1)
                    )
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
        }
    }
}

// MARK: - Стиль кнопки «Выйти на смену»

private struct StartShiftButtonStyle: ButtonStyle {
    private let gradient = LinearGradient(
        colors: [
            Color(red: 143/255, green: 0, blue: 214/255),
            Color(red: 112/255, green: 0, blue: 204/255)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Capsule().fill(gradient))
            .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
            }
    }
}

// MARK: - Превью

#Preview {
    MainView(isShiftOpen: .constant(false))
}
