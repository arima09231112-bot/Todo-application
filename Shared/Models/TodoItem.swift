import Foundation
import SwiftData
import RPGTodoCore

/// 1件の Todo。日付は `LocalDate.dayKey`（yyyymmdd）で保存する。
@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var dateKey: Int
    /// 0:00 からの経過分（時刻なしは nil）。
    var timeMinutes: Int?
    var categoryRaw: String
    var isCompleted: Bool
    var completedAt: Date?
    var notificationEnabled: Bool
    /// 繰り返し設定から生成された場合の元ID。
    var recurrenceID: UUID?
    /// カレンダーの予定から作られた場合の、予定の重複判定キー（`CalendarEventKey`）。
    var calendarEventKey: String?
    /// 「今日に移す」で作られた複製先。
    var carriedOverTo: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String,
        date: LocalDate,
        timeMinutes: Int? = nil,
        category: TodoCategory = .other,
        notificationEnabled: Bool = false,
        recurrenceID: UUID? = nil,
        now: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.dateKey = date.dayKey
        self.timeMinutes = timeMinutes
        self.categoryRaw = category.rawValue
        self.isCompleted = false
        self.completedAt = nil
        self.notificationEnabled = notificationEnabled
        self.recurrenceID = recurrenceID
        self.calendarEventKey = nil
        self.carriedOverTo = nil
        self.createdAt = now
        self.updatedAt = now
    }

    var date: LocalDate {
        get { LocalDate(dayKey: dateKey) ?? LocalDate(.now) }
        set { dateKey = newValue.dayKey }
    }

    var category: TodoCategory {
        get { TodoCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var isRecurring: Bool { recurrenceID != nil }

    func setCompleted(_ done: Bool, now: Date = .now) {
        isCompleted = done
        completedAt = done ? now : nil
        updatedAt = now
    }
}
