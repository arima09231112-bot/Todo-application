import Foundation

/// 連続達成日数（要件 4.6 H-03）。
public enum Streak {
    /// 「達成率100%の日」が連続した日数。
    ///
    /// - Todo 0 件の日（`percentByDayKey` にない日）は連続を途切れさせず、数えもしない（休日扱い）。
    /// - 今日がまだ100%でなければ、昨日までの連続日数を返す。
    /// - Parameter percentByDayKey: Todo が1件以上あった日の達成率（キーは `LocalDate.dayKey`）。
    public static func current(
        today: LocalDate,
        percentByDayKey: [Int: Int],
        calendar: Calendar = .current
    ) -> Int {
        guard let earliest = percentByDayKey.keys.min() else { return 0 }
        var day = percentByDayKey[today.dayKey] == 100 ? today : today.addingDays(-1, calendar: calendar)
        var count = 0
        while day.dayKey >= earliest {
            if let percent = percentByDayKey[day.dayKey] {
                guard percent == 100 else { break }
                count += 1
            }
            day = day.addingDays(-1, calendar: calendar)
        }
        return count
    }
}

/// 期間の集計（要件 4.6 H-04）。
public enum ProgressStats {
    /// 平均達成率（切り捨て）。Todo がある日が1日もなければ nil。
    public static func average(_ percents: [Int]) -> Int? {
        guard !percents.isEmpty else { return nil }
        return percents.reduce(0, +) / percents.count
    }

    /// `date` を含む週の7日（週の始まりは `calendar.firstWeekday`）。
    public static func week(containing date: LocalDate, calendar: Calendar = .current) -> [LocalDate] {
        let offset = (date.weekday(calendar: calendar).rawValue - calendar.firstWeekday + 7) % 7
        let start = date.addingDays(-offset, calendar: calendar)
        return (0..<7).map { start.addingDays($0, calendar: calendar) }
    }

    /// 月の全日（1日から月末まで）。
    public static func month(year: Int, month: Int, calendar: Calendar = .current) -> [LocalDate] {
        let first = LocalDate(year: year, month: month, day: 1)
        var days: [LocalDate] = []
        var day = first
        while day.month == month && day.year == year {
            days.append(day)
            day = day.addingDays(1, calendar: calendar)
        }
        return days
    }
}

/// 図鑑の発見記録（要件 5.7 CharacterRecord）。日ごとの記録（その日に加わった仲間）から求める。
public struct Discovery: Sendable, Hashable {
    /// 初めて仲間になった日。
    public let firstDate: LocalDate
    /// 仲間になった日数（同じ日に何度加わっても1日）。
    public let days: Int

    /// - Parameter days: 日ごとの「その日に加わった仲間」。順番は問わない。
    public static func compute(days: [(date: LocalDate, members: [CharacterID])]) -> [CharacterID: Discovery] {
        var result: [CharacterID: Discovery] = [:]
        for day in days.sorted(by: { $0.date < $1.date }) {
            for id in Set(day.members) {
                if let found = result[id] {
                    result[id] = Discovery(firstDate: found.firstDate, days: found.days + 1)
                } else {
                    result[id] = Discovery(firstDate: day.date, days: 1)
                }
            }
        }
        return result
    }
}
