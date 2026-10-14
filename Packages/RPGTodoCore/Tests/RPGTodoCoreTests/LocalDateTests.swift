import Foundation
import Testing
@testable import RPGTodoCore

/// テストは端末の設定に左右されないよう、UTC のグレゴリオ暦で行う。
let utcCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

@Suite("LocalDate")
struct LocalDateTests {
    @Test("dayKey の往復")
    func dayKeyRoundTrip() {
        let date = LocalDate(year: 2026, month: 10, day: 14)
        #expect(date.dayKey == 20261014)
        #expect(LocalDate(dayKey: 20261014) == date)
        #expect(LocalDate(dayKey: 0) == nil)
        #expect(LocalDate(dayKey: 20261314) == nil)
    }

    @Test("曜日は Calendar と同じ（2026-10-14 は水曜）")
    func weekday() {
        #expect(LocalDate(year: 2026, month: 10, day: 14).weekday(calendar: utcCalendar) == .wednesday)
        #expect(LocalDate(year: 2026, month: 10, day: 18).weekday(calendar: utcCalendar) == .sunday)
    }

    @Test("日数の加減は月・年をまたぐ")
    func addingDays() {
        let endOfYear = LocalDate(year: 2026, month: 12, day: 31)
        #expect(endOfYear.addingDays(1, calendar: utcCalendar) == LocalDate(year: 2027, month: 1, day: 1))
        #expect(endOfYear.addingDays(-31, calendar: utcCalendar) == LocalDate(year: 2026, month: 11, day: 30))
    }

    @Test("Date からの変換と大小比較")
    func fromDate() {
        let noon = LocalDate(year: 2026, month: 3, day: 1).date(calendar: utcCalendar)
        #expect(LocalDate(noon, calendar: utcCalendar) == LocalDate(year: 2026, month: 3, day: 1))
        #expect(LocalDate(year: 2026, month: 2, day: 28) < LocalDate(year: 2026, month: 3, day: 1))
    }
}
