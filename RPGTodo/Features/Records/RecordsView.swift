import SwiftUI
import SwiftData
import RPGTodoCore

/// 記録タブ（冒険の記録。要件 4.6・6.5）: 連続達成日数と平均のサマリー、月カレンダー、日ごとの詳細。
struct RecordsView: View {
    let today: LocalDate

    @Query private var progresses: [DailyProgress]
    @State private var shownMonth: LocalDate
    @State private var selectedDay: SelectedDay?

    /// シートに渡すための入れ物（`LocalDate` は Identifiable ではないため）。
    struct SelectedDay: Identifiable {
        let date: LocalDate
        var id: Int { date.dayKey }
    }

    init(today: LocalDate) {
        self.today = today
        _shownMonth = State(initialValue: LocalDate(year: today.year, month: today.month, day: 1))
    }

    private var progressByKey: [Int: DailyProgress] {
        Dictionary(progresses.map { ($0.dateKey, $0) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        let byKey = progressByKey
        let percents = AdventureLog.percentByDayKey(progresses)
        let monthDays = ProgressStats.month(year: shownMonth.year, month: shownMonth.month)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summary(percents: percents, monthDays: monthDays)
                    calendarCard(days: monthDays, byKey: byKey)
                    legend
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("冒険の記録")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $selectedDay) { day in
            DayDetailView(date: day.date)
        }
    }

    // MARK: サマリー

    private func summary(percents: [Int: Int], monthDays: [LocalDate]) -> some View {
        let streak = Streak.current(today: today, percentByDayKey: percents)
        let week = ProgressStats.average(ProgressStats.week(containing: today).compactMap { percents[$0.dayKey] })
        let month = ProgressStats.average(monthDays.compactMap { percents[$0.dayKey] })

        return HStack(spacing: 10) {
            statTile("連続達成", value: "\(streak)日", systemImage: "flame.fill", tint: .orange)
            statTile("今週の平均", value: week.map { "\($0)%" } ?? "—", systemImage: "calendar", tint: .blue)
            statTile("\(shownMonth.month)月の平均", value: month.map { "\($0)%" } ?? "—", systemImage: "chart.bar.fill", tint: .green)
        }
    }

    private func statTile(_ title: String, value: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: 月カレンダー

    private var isCurrentMonth: Bool { shownMonth.year == today.year && shownMonth.month == today.month }

    private func calendarCard(days: [LocalDate], byKey: [Int: DailyProgress]) -> some View {
        let calendar = Calendar.current
        let leading = days.first.map { ($0.weekday(calendar: calendar).rawValue - calendar.firstWeekday + 7) % 7 } ?? 0
        let symbols = calendar.veryShortWeekdaySymbols
        let orderedSymbols = (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return VStack(spacing: 10) {
            HStack {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("前の月")
                Spacer()
                Text(shownMonth.date().formatted(.dateTime.year().month(.wide)))
                    .font(.headline)
                Spacer()
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(isCurrentMonth)
                    .accessibilityLabel("次の月")
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(orderedSymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(.caption2.bold()).foregroundStyle(.secondary)
                }
                ForEach(0..<leading, id: \.self) { _ in
                    Color.clear.frame(height: 40)
                }
                ForEach(days, id: \.dayKey) { day in
                    dayCell(day, progress: byKey[day.dayKey])
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func dayCell(_ day: LocalDate, progress: DailyProgress?) -> some View {
        let isFuture = day > today
        let percent = progress?.recordedPercent
        let hasSuperstar = progress?.joinedMembers.contains("superstar") ?? false

        return Button { selectedDay = SelectedDay(date: day) } label: {
            Text("\(day.day)")
                .font(.subheadline.weight(day == today ? .heavy : .regular))
                .monospacedDigit()
                .foregroundStyle(Self.textColor(percent: percent))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Self.fillColor(percent: percent), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    if day == today {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.blue, lineWidth: 2)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if hasSuperstar {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.4), radius: 1)
                            .padding(2)
                    }
                }
                .opacity(isFuture ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .accessibilityLabel("\(day.shortText)、\(percent.map { "達成率\($0)%" } ?? "タスクなし")\(hasSuperstar ? "、スーパースター" : "")")
    }

    /// 100% は緑、1〜99% は青の濃淡、0% は淡い青、Todo 0 件はグレー（要件 6.5）。
    static func fillColor(percent: Int?) -> Color {
        guard let percent else { return Color.gray.opacity(0.12) }
        if percent >= 100 { return .green }
        return Color.blue.opacity(0.12 + 0.68 * Double(percent) / 100)
    }

    static func textColor(percent: Int?) -> Color {
        guard let percent else { return .primary }
        return percent >= 50 ? .white : .primary
    }

    private func moveMonth(_ delta: Int) {
        var year = shownMonth.year
        var month = shownMonth.month + delta
        if month < 1 { month = 12; year -= 1 }
        if month > 12 { month = 1; year += 1 }
        shownMonth = LocalDate(year: year, month: month, day: 1)
    }

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(.green, "100%")
            legendItem(Color.blue.opacity(0.5), "1〜99%")
            legendItem(Color.gray.opacity(0.25), "タスクなし")
            Label("スーパースター", systemImage: "star.fill")
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.yellow)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(text)
        }
    }
}

/// 日ごとの詳細: 達成率・完了数・その日のパーティ・タスク（要件 H-02）。閲覧のみ。
struct DayDetailView: View {
    let date: LocalDate

    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [DailyProgress]
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue

    private var progress: DailyProgress? { progresses.first { $0.dateKey == date.dayKey } }
    private var todos: [TodoItem] {
        TodoOrdering.sorted(allTodos.filter { $0.dateKey == date.dayKey }, minutes: { $0.timeMinutes }, createdAt: { $0.createdAt })
    }

    var body: some View {
        let items = todos
        let completed = items.filter(\.isCompleted).count
        let percent = CompletionRate.percent(completed: completed, total: items.count)
        let members = progress?.currentMembers ?? []

        NavigationStack {
            List {
                Section {
                    HStack(alignment: .firstTextBaseline) {
                        Text(percent.map { "\($0)%" } ?? "—")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(percent == 100 ? Color.green : Color.primary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(items.isEmpty ? "タスクなし" : "\(completed) / \(items.count) 完了")
                            Text("仲間 \(members.count)人").foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }

                Section("その日のパーティ") {
                    PartyField(hero: HeroSetting.resolve(heroRaw), companions: members)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    if !members.isEmpty {
                        Text(members.compactMap { CharacterCatalog.character($0)?.name }.joined(separator: "・"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("タスク") {
                    if items.isEmpty {
                        Text("この日のタスクはありません").foregroundStyle(.secondary)
                    }
                    ForEach(items) { todo in
                        HStack(spacing: 10) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todo.isCompleted ? Color.blue : Color.secondary)
                            Text(todo.title)
                                .foregroundStyle(todo.isCompleted ? Color.secondary : Color.primary)
                            Spacer()
                            if let minutes = todo.timeMinutes {
                                Text(String(format: "%d:%02d", minutes / 60, minutes % 60))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle(date.shortText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
