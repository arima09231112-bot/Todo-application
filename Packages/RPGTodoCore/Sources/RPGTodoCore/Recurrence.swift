import Foundation

/// 繰り返しのルール。
public enum RecurrenceRule: Hashable, Sendable {
    case daily
    /// 月〜金。
    case weekdays
    /// 指定した曜日（複数可）。
    case weekly(Set<Weekday>)

    public func occurs(on weekday: Weekday) -> Bool {
        switch self {
        case .daily: true
        case .weekdays: weekday.isWeekday
        case .weekly(let days): days.contains(weekday)
        }
    }

    // MARK: 保存用の表現（種類の文字列＋曜日のビットマスク）

    public var storageKind: String {
        switch self {
        case .daily: "daily"
        case .weekdays: "weekdays"
        case .weekly: "weekly"
        }
    }

    /// 曜日のビットマスク（日曜 = 1 << 0 … 土曜 = 1 << 6）。`weekly` 以外は 0。
    public var storageMask: Int {
        guard case .weekly(let days) = self else { return 0 }
        return days.reduce(0) { $0 | (1 << ($1.rawValue - 1)) }
    }

    public init?(storageKind: String, mask: Int) {
        switch storageKind {
        case "daily":
            self = .daily
        case "weekdays":
            self = .weekdays
        case "weekly":
            let days = Weekday.allCases.filter { mask & (1 << ($0.rawValue - 1)) != 0 }
            self = .weekly(Set(days))
        default:
            return nil
        }
    }
}

/// 繰り返し設定のうち、「どの日に Todo を作るか」を決める部分。
public struct RecurrenceSchedule: Sendable, Hashable {
    public var rule: RecurrenceRule
    public var startDate: LocalDate
    public var endDate: LocalDate?
    public var isPaused: Bool
    /// 「この日だけ削除」した日。ここでは再生成しない。
    public var skippedDates: Set<LocalDate>
    /// 生成処理を済ませた最終日。
    public var lastGeneratedDate: LocalDate?

    public init(
        rule: RecurrenceRule,
        startDate: LocalDate,
        endDate: LocalDate? = nil,
        isPaused: Bool = false,
        skippedDates: Set<LocalDate> = [],
        lastGeneratedDate: LocalDate? = nil
    ) {
        self.rule = rule
        self.startDate = startDate
        self.endDate = endDate
        self.isPaused = isPaused
        self.skippedDates = skippedDates
        self.lastGeneratedDate = lastGeneratedDate
    }

    /// 長期間アプリを開かなかったときに、さかのぼって生成する最大日数。
    public static let maxBackfillDays = 366

    /// `date` に Todo を作る日かどうか。
    public func occurs(on date: LocalDate, calendar: Calendar = .current) -> Bool {
        guard !isPaused, date >= startDate, !skippedDates.contains(date) else { return false }
        if let endDate, date > endDate { return false }
        return rule.occurs(on: date.weekday(calendar: calendar))
    }

    /// 前回の生成の翌日から `today` までで、Todo を作る日（昇順）。
    /// アプリを開かなかった間の日も含む（要件 4.1.1）。
    public func datesToGenerate(through today: LocalDate, calendar: Calendar = .current) -> [LocalDate] {
        var first = lastGeneratedDate.map { $0.addingDays(1, calendar: calendar) } ?? startDate
        first = max(first, startDate, today.addingDays(-Self.maxBackfillDays, calendar: calendar))
        guard first <= today else { return [] }

        var result: [LocalDate] = []
        var day = first
        while day <= today {
            if occurs(on: day, calendar: calendar) { result.append(day) }
            day = day.addingDays(1, calendar: calendar)
        }
        return result
    }
}
