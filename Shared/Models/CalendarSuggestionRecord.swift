import Foundation
import SwiftData

/// 採用・除外した予定の記録。同じ予定から候補を重複して出さないために使う（要件 5.4）。
@Model
final class CalendarSuggestionRecord {
    @Attribute(.unique) var calendarEventKey: String
    var eventTitle: String
    var startAt: Date
    var endAt: Date
    var statusRaw: String
    var lastSyncedAt: Date

    enum Status: String {
        case adopted
        case dismissed
    }

    init(calendarEventKey: String, eventTitle: String, startAt: Date, endAt: Date, status: Status, now: Date = .now) {
        self.calendarEventKey = calendarEventKey
        self.eventTitle = eventTitle
        self.startAt = startAt
        self.endAt = endAt
        self.statusRaw = status.rawValue
        self.lastSyncedAt = now
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .dismissed }
        set { statusRaw = newValue.rawValue }
    }
}
