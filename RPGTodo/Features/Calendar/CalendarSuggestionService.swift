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

    /// 候補を Todo にする。すでに採用済みなら何もしない。予定の開始日の Todo として作る。
    static func adopt(_ event: CalendarEvent, in context: ModelContext) {
        let existing = record(for: event.key, in: context)
        guard existing?.status != .adopted else { return }

        let todo = TodoItem(
            title: CalendarSuggestion.title(forEventTitle: event.title),
            date: LocalDate(event.start),
            timeMinutes: event.isAllDay ? nil : suggestedMinutes(for: event),
            category: .work
        )
        todo.calendarEventKey = event.key
        context.insert(todo)

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

    static func suggestedMinutes(for event: CalendarEvent) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: event.start)
        return CalendarSuggestion.suggestedMinutes(eventStartMinutes: (parts.hour ?? 0) * 60 + (parts.minute ?? 0))
    }

    private static func commit(_ context: ModelContext) {
        try? context.save()
        WidgetRefresh.request()
    }
}
