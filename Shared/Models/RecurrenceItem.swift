import Foundation
import SwiftData
import RPGTodoCore

/// 繰り返し設定。ここから日ごとの `TodoItem` を生成する。
@Model
final class RecurrenceItem {
    @Attribute(.unique) var id: UUID
    // 生成する Todo の雛形
    var title: String
    var timeMinutes: Int?
    var categoryRaw: String
    var notificationEnabled: Bool
    // ルール（`RecurrenceRule` の保存用表現）
    var ruleKind: String
    var weekdayMask: Int
    // 期間・状態
    var startDateKey: Int
    var endDateKey: Int?
    var isPaused: Bool
    var skippedDateKeys: [Int]
    var lastGeneratedDateKey: Int?
    var createdAt: Date

    init(
        title: String,
        timeMinutes: Int?,
        category: TodoCategory,
        notificationEnabled: Bool,
        rule: RecurrenceRule,
        startDate: LocalDate,
        now: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.timeMinutes = timeMinutes
        self.categoryRaw = category.rawValue
        self.notificationEnabled = notificationEnabled
        self.ruleKind = rule.storageKind
        self.weekdayMask = rule.storageMask
        self.startDateKey = startDate.dayKey
        self.endDateKey = nil
        self.isPaused = false
        self.skippedDateKeys = []
        self.lastGeneratedDateKey = nil
        self.createdAt = now
    }

    var category: TodoCategory {
        get { TodoCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var rule: RecurrenceRule {
        get { RecurrenceRule(storageKind: ruleKind, mask: weekdayMask) ?? .daily }
        set {
            ruleKind = newValue.storageKind
            weekdayMask = newValue.storageMask
        }
    }

    /// 「どの日に作るか」を決めるロジック（`RPGTodoCore`）に渡す形。
    var schedule: RecurrenceSchedule {
        RecurrenceSchedule(
            rule: rule,
            startDate: LocalDate(dayKey: startDateKey) ?? LocalDate(.now),
            endDate: endDateKey.flatMap { LocalDate(dayKey: $0) },
            isPaused: isPaused,
            skippedDates: Set(skippedDateKeys.compactMap { LocalDate(dayKey: $0) }),
            lastGeneratedDate: lastGeneratedDateKey.flatMap { LocalDate(dayKey: $0) }
        )
    }
}
