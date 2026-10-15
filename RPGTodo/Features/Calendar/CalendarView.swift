import SwiftUI
import SwiftData
import UIKit
import RPGTodoCore

/// カレンダータブ: 今日・明日の予定と、予定ごとのTodo候補（要件 6.4）。
struct CalendarView: View {
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Environment(CalendarStore.self) private var calendar
    @Query private var records: [CalendarSuggestionRecord]
    @State private var showDismissed = false

    private var statusByKey: [String: CalendarSuggestionRecord.Status] {
        Dictionary(records.map { ($0.calendarEventKey, $0.status) }, uniquingKeysWith: { first, _ in first })
    }

    var body: some View {
        NavigationStack {
            Group {
                if !calendar.isEnabled {
                    notice(
                        "カレンダーと連携する",
                        "今日・明日の予定からクエスト候補を作ります。予定は読み取るだけで、変更はしません。",
                        button: "連携をオンにする"
                    ) { Task { await calendar.enable() } }
                } else if calendar.status == .notDetermined {
                    notice(
                        "カレンダーへのアクセスを許可",
                        "予定を読み取るために、カレンダーへのアクセスを許可してください。",
                        button: "アクセスを許可"
                    ) { Task { await calendar.enable() } }
                } else if calendar.isDenied {
                    notice(
                        "カレンダーにアクセスできません",
                        "iPhone の「設定」→「Daily Quest」→「カレンダー」で、フルアクセスを許可してください。",
                        button: "設定アプリを開く"
                    ) {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                } else {
                    list
                }
            }
            .adventureScreenBackground()
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if calendar.isEnabled && calendar.hasAccess {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Toggle("除外した予定を表示", isOn: $showDismissed)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear { calendar.refresh() }
    }

    // MARK: 一覧

    private var list: some View {
        List {
            daySection("今日", day: today)
            daySection("明日", day: today.addingDays(1))
        }
    }

    private func daySection(_ name: String, day: LocalDate) -> some View {
        let events = calendar.events(on: day)
        let pending = events.filter { statusByKey[$0.key] == nil }
        return Section {
            if events.isEmpty {
                Text("予定はありません").foregroundStyle(.secondary)
            }
            ForEach(events.filter { visible($0) }) { event in
                EventRow(event: event, status: statusByKey[event.key])
            }
        } header: {
            HStack {
                Text("\(name)  \(day.date().formatted(.dateTime.month().day().weekday(.abbreviated)))")
                Spacer()
                if pending.count > 1 {
                    Button("すべて追加") {
                        for event in pending { CalendarSuggestionService.adopt(event, in: context) }
                    }
                    .font(.caption.bold())
                    .textCase(nil)
                }
            }
        }
    }

    /// 採用済みは「追加済み」として残し、除外済みは設定したときだけ表示する。
    private func visible(_ event: CalendarEvent) -> Bool {
        statusByKey[event.key] != .dismissed || showDismissed
    }

    private func notice(_ title: String, _ message: String, button: String, action: @escaping () -> Void) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "calendar.badge.clock")
        } description: {
            Text(message)
        } actions: {
            Button(button, action: action).buttonStyle(.borderedProminent)
        }
    }
}

/// 予定1件と、その候補（追加・除外ボタン）。
private struct EventRow: View {
    let event: CalendarEvent
    let status: CalendarSuggestionRecord.Status?

    @Environment(\.modelContext) private var context

    private var timeText: String {
        event.isAllDay
            ? "終日"
            : "\(event.start.formatted(date: .omitted, time: .shortened))〜\(event.end.formatted(date: .omitted, time: .shortened))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(timeText).font(.caption).foregroundStyle(.secondary)
                Text(event.title).font(.subheadline.bold()).lineLimit(1)
            }
            HStack {
                Image(systemName: "arrow.turn.down.right").font(.caption).foregroundStyle(.secondary)
                Text(CalendarSuggestion.title(forEventTitle: event.title))
                    .font(.subheadline)
                    .foregroundStyle(status == nil ? Color.primary : Color.secondary)
                    .lineLimit(2)
                Spacer(minLength: 8)
                actions
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var actions: some View {
        switch status {
        case .none:
            HStack(spacing: 8) {
                Button("追加") { CalendarSuggestionService.adopt(event, in: context) }
                    .buttonStyle(.borderedProminent)
                Button("除外") { CalendarSuggestionService.dismiss(event, in: context) }
                    .buttonStyle(.bordered)
            }
            .controlSize(.small)
        case .adopted:
            Label("追加済み", systemImage: "checkmark.circle.fill")
                .font(.caption.bold())
                .foregroundStyle(.blue)
        case .dismissed:
            Button("戻す") { CalendarSuggestionService.restore(event, in: context) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}
