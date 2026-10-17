import Foundation
import SwiftData
import RPGTodoCore

/// 予定からの候補の採用・除外・復帰。重複は `CalendarSuggestionRecord`（予定の識別子＋開始日時）で防ぐ（要件 4.4.2）。
@MainActor
enum CalendarSuggestionService {
    static func record(for key: String, in context: ModelContext) -> CalendarSuggestionRecord? {
        let descriptor = FetchDescriptor<CalendarSuggestionRecord>(predicate: #Predicate { $0.calendarEventKey == key })
        return try? context.fetch(descriptor).first
    }

    /// 候補を Todo にする。すでに採用済みなら何もしない。
    ///
    /// - 今日の予定: 予定の日に「準備」の Todo を、開始の30分前で作る。
    /// - 明日以降の予定（前日に採用したとき）: 今日に「準備」の Todo（時刻なし）を、予定の日に予定そのものの Todo（開始時刻）を作る。
    static func adopt(_ event: CalendarEvent, today: LocalDate = LocalDate(.now), in context: ModelContext) {
        let existing = record(for: event.key, in: context)
        guard existing?.status != .adopted else { return }

        let eventDay = LocalDate(event.start)
        let prepTitle = CalendarSuggestion.title(forEventTitle: event.title)
        if eventDay > today {
            insertTodo(prepTitle, date: today, timeMinutes: nil, key: event.key, in: context)
            insertTodo(
                String(event.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100)),
                date: eventDay,
                timeMinutes: event.isAllDay ? nil : startMinutes(for: event),
                key: event.key,
                in: context
            )
        } else {
            insertTodo(
                prepTitle, date: eventDay,
                timeMinutes: event.isAllDay ? nil : suggestedMinutes(for: event),
                key: event.key, in: context
            )
        }

        if let existing {
            existing.status = .adopted
            existing.lastSyncedAt = .now
        } else {
            context.insert(CalendarSuggestionRecord(
                calendarEventKey: event.key, eventTitle: event.title,
                startAt: event.start, endAt: event.end, status: .adopted
            ))
        }
        commit(context)
    }

    /// 候補を除外する（一覧から隠す。Todo は作らない）。
    static func dismiss(_ event: CalendarEvent, in context: ModelContext) {
        if let existing = record(for: event.key, in: context) {
            guard existing.status != .adopted else { return }
            existing.status = .dismissed
            existing.lastSyncedAt = .now
        } else {
            context.insert(CalendarSuggestionRecord(
                calendarEventKey: event.key, eventTitle: event.title,
                startAt: event.start, endAt: event.end, status: .dismissed
            ))
        }
        commit(context)
    }

    /// 除外した候補を、一覧に戻す。
    static func restore(_ event: CalendarEvent, in context: ModelContext) {
        guard let existing = record(for: event.key, in: context), existing.status == .dismissed else { return }
        context.delete(existing)
        commit(context)
    }

    private static func insertTodo(_ title: String, date: LocalDate, timeMinutes: Int?, key: String, in context: ModelContext) {
        let todo = TodoItem(title: title, date: date, timeMinutes: timeMinutes, category: .work)
        todo.calendarEventKey = key
        context.insert(todo)
    }

    static func startMinutes(for event: CalendarEvent) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: event.start)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    static func suggestedMinutes(for event: CalendarEvent) -> Int {
        CalendarSuggestion.suggestedMinutes(eventStartMinutes: startMinutes(for: event))
    }

    private static func commit(_ context: ModelContext) {
        try? context.save()
        WidgetRefresh.request()
    }
}
