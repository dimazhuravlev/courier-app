import SwiftUI

struct CalendarBottomSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    @Environment(OrderHistoryStore.self) private var historyStore

    private let sheetBg = Color.surface1
    private let cal = Calendar.current

    private var monthDates: [Date] {
        let y = cal.component(.year, from: Date())
        let m = cal.component(.month, from: Date())
        return (-6...6).compactMap { offset in
            cal.date(from: DateComponents(year: y, month: m + offset, day: 1))
        }
    }

    private var isSelectedToday: Bool {
        cal.isDate(selectedDate, inSameDayAs: Date())
    }

    private var isSelectedPast: Bool {
        selectedDate < cal.startOfDay(for: Date())
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(monthDates, id: \.self) { firstOfMonth in
                            Section {
                                CalendarMonthGrid(
                                    firstOfMonth: firstOfMonth,
                                    selectedDate: $selectedDate,
                                    datesWithHistory: historyStore.datesWithHistory,
                                    onDateSelected: { date in
                                        let day = cal.startOfDay(for: date)
                                        selectedDate = day
                                        // Закрываем на следующем цикле run loop, чтобы @State родителя успел обновиться до dismiss.
                                        DispatchQueue.main.async {
                                            isPresented = false
                                        }
                                    }
                                )
                                .padding(.top, 8)
                                .padding(.bottom, 20)
                            } header: {
                                monthHeader(firstOfMonth)
                                    .id(monthID(firstOfMonth))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    let y = cal.component(.year, from: selectedDate)
                    let m = cal.component(.month, from: selectedDate)
                    if let anchor = cal.date(from: DateComponents(year: y, month: m, day: 1)) {
                        DispatchQueue.main.async {
                            withTransaction(Transaction(animation: nil)) {
                                proxy.scrollTo(monthID(anchor), anchor: .top)
                            }
                        }
                    }
                }
            }

            if !isSelectedToday {
                todayButton
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelectedToday)
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, 12)
                .padding(.trailing, 12)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(40)
        .presentationBackground(sheetBg)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isPresented = false
        } label: {
            Image("Cross")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.text1)
        }
        .frame(width: 48, height: 48)
        .background(
            Circle().fill(
                LinearGradient(
                    colors: [Color.fill1, Color.fill3],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        )
        .overlay(Circle().strokeBorder(Color.stroke2, lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)
    }

    // MARK: - Month Header (sticky)

    private func monthHeader(_ date: Date) -> some View {
        let name: String = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "LLLL"
            return formatter.string(from: date).capitalized
        }()
        let year = String(cal.component(.year, from: date))

        return HStack(spacing: 6) {
            Text(name)
                .headline1Style()
                .foregroundStyle(Color.text1)
            Text(year)
                .headline1Style()
                .foregroundStyle(Color.text3)
            Spacer()
        }
        .padding(.leading, 8)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(sheetBg)
    }

    private func monthID(_ date: Date) -> String {
        "\(cal.component(.year, from: date))-\(cal.component(.month, from: date))"
    }

    // MARK: - Today Button

    private var todayButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selectedDate = cal.startOfDay(for: Date())
            isPresented = false
        } label: {
            HStack(spacing: 8) {
                if !isSelectedPast {
                    arrowIcon("Back-left")
                }
                Text("Сегодня")
                    .textStyle()
                    .foregroundStyle(Color.text1)
                if isSelectedPast {
                    arrowIcon("Back-right")
                }
            }
            .frame(height: 48)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.stroke2, lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 1)
        }
    }

    private func arrowIcon(_ name: String) -> some View {
        Image(name)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .foregroundStyle(Color.text1)
    }
}

// MARK: - Month Grid

private struct CalendarMonthGrid: View {
    let firstOfMonth: Date
    @Binding var selectedDate: Date
    let datesWithHistory: Set<String>
    let onDateSelected: (Date) -> Void

    private let cal = Calendar.current
    private let selectionHaptic = UISelectionFeedbackGenerator()
    private let selectionFill = Color.surface3
    private let selectionStroke = Color.stroke2

    private var year: Int { cal.component(.year, from: firstOfMonth) }
    private var month: Int { cal.component(.month, from: firstOfMonth) }

    private var weeks: [[Date?]] {
        guard let range = cal.range(of: .day, in: .month, for: firstOfMonth) else { return [] }

        let weekday = cal.component(.weekday, from: firstOfMonth)
        let startOffset = weekday == 1 ? 6 : weekday - 2

        var result: [[Date?]] = []
        var currentWeek: [Date?] = Array(repeating: nil, count: startOffset)

        for day in range {
            if let date = cal.date(from: DateComponents(year: year, month: month, day: day)) {
                currentWeek.append(date)
                if currentWeek.count == 7 {
                    result.append(currentWeek)
                    currentWeek = []
                }
            }
        }
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 { currentWeek.append(nil) }
            result.append(currentWeek)
        }

        return result
    }

    var body: some View {
        VStack(spacing: 8) {
            weekdayNamesRow

            VStack(spacing: 4) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    weekRowView(week)
                }
            }
        }
    }

    private var weekdayNamesRow: some View {
        HStack(spacing: 4) {
            ForEach(["пн", "вт", "ср", "чт", "пт", "сб", "вс"], id: \.self) { name in
                Text(name)
                    .font(.custom("Pretendard-SemiBold", size: 14))
                    .foregroundStyle(Color.text2)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func weekRowView(_ days: [Date?]) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                if let date = days[index] {
                    dayCell(date: date)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 47)
                }
            }
        }
    }

    private func dateKey(for date: Date) -> String {
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year!, comps.month!, comps.day!)
    }

    private func dayCell(date: Date) -> some View {
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday = cal.isDate(date, inSameDayAs: Date())
        let hasHistory = datesWithHistory.contains(dateKey(for: date))
        let day = cal.component(.day, from: date)

        return Button {
            selectionHaptic.selectionChanged()
            onDateSelected(date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectionFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(selectionStroke, lineWidth: 1)
                    )
                    .opacity(isSelected ? 1 : 0)

                Text("\(day)")
                    .headline1Style()
                    .foregroundStyle(Color.text1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 6)

                if isToday || hasHistory {
                    Circle()
                        .fill(Color.success)
                        .frame(width: 8, height: 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 5)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 47)
        .buttonStyle(.plain)
    }
}
