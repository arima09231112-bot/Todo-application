import Foundation

/// 時刻を持たない「日付だけ」の値。Todo の対象日や履歴の日付に使う。
///
/// `Date` はタイムゾーンや夏時間で日付がずれやすいので、年月日の3つ組で持つ。
/// 保存には `dayKey`（例: 20261014）を使う。
public struct LocalDate: Hashable, Comparable, Sendable, Codable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// `date` が属する日（指定カレンダーのタイムゾーンで判定）。
    public init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// 保存用の整数（yyyymmdd）から復元する。形式が不正なら nil。
    public init?(dayKey: Int) {
        let year = dayKey / 10000
        let month = dayKey / 100 % 100
        let day = dayKey % 100
        guard year > 0, (1...12).contains(month), (1...31).contains(day) else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// 保存用の整数（yyyymmdd）。日付の大小と整数の大小が一致する。
    public var dayKey: Int { year * 10_000 + month * 100 + day }

    /// その日の正午の `Date`（夏時間などで日付がずれないよう正午を使う）。
    public func date(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
            ?? Date(timeIntervalSince1970: 0)
    }

    public func weekday(calendar: Calendar = .current) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date(calendar: calendar))) ?? .sunday
    }

    public func addingDays(_ days: Int, calendar: Calendar = .current) -> LocalDate {
        let shifted = calendar.date(byAdding: .day, value: days, to: date(calendar: calendar))
            ?? date(calendar: calendar)
        return LocalDate(shifted, calendar: calendar)
    }

    public static func < (lhs: LocalDate, rhs: LocalDate) -> Bool { lhs.dayKey < rhs.dayKey }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}
