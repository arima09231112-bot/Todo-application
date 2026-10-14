import Foundation
import RPGTodoCore

/// 繰り返しの選択肢（追加・編集シート用）。
enum RepeatKind: String, CaseIterable, Identifiable {
    case none, daily, weekdays, weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "なし"
        case .daily: "毎日"
        case .weekdays: "平日（月〜金）"
        case .weekly: "曜日を指定"
        }
    }
}

/// 追加・編集シートで編集中の値。保存するまで `TodoItem` には触らない。
struct TodoDraft {
    var title = ""
    var date = Date()
    var hasTime = false
    var time = Date()
    var category: TodoCategory = .other
    var repeatKind: RepeatKind = .none
    var weekdays: Set<Weekday> = []

    init() {}

    init(todo: TodoItem, recurrence: RecurrenceItem?) {
        title = todo.title
        date = todo.date.date()
        if let minutes = todo.timeMinutes {
            hasTime = true
            time = Self.date(fromMinutes: minutes)
        }
        category = todo.category
        if let recurrence {
            switch recurrence.rule {
            case .daily: repeatKind = .daily
            case .weekdays: repeatKind = .weekdays
            case .weekly(let days):
                repeatKind = .weekly
                weekdays = days
            }
        }
    }

    var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// タイトルは1〜100文字。曜日指定のときは1つ以上の曜日が必要。
    var isValid: Bool {
        let length = trimmedTitle.count
        guard (1...100).contains(length) else { return false }
        return repeatKind != .weekly || !weekdays.isEmpty
    }

    var localDate: LocalDate { LocalDate(date) }

    var timeMinutes: Int? {
        guard hasTime else { return nil }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// 繰り返しなしなら nil。
    var rule: RecurrenceRule? {
        switch repeatKind {
        case .none: nil
        case .daily: .daily
        case .weekdays: .weekdays
        case .weekly: .weekly(weekdays)
        }
    }

    static func date(fromMinutes minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
    }
}
