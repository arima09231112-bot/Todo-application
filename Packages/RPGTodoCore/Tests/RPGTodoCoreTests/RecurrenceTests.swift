import Foundation
import Testing
@testable import RPGTodoCore

@Suite("Recurrence")
struct RecurrenceTests {
    // 2026-10-12 は月曜
    private let monday = LocalDate(year: 2026, month: 10, day: 12)
    private func day(_ d: Int) -> LocalDate { LocalDate(year: 2026, month: 10, day: d) }

    @Test("毎日は全日、平日は月〜金のみ")
    func dailyAndWeekdays() {
        let daily = RecurrenceSchedule(rule: .daily, startDate: monday)
        let weekdays = RecurrenceSchedule(rule: .weekdays, startDate: monday)
        // 12(月)〜18(日)
        let week = (12...18).map(day)
        #expect(week.filter { daily.occurs(on: $0, calendar: utcCalendar) }.count == 7)
        #expect(week.filter { weekdays.occurs(on: $0, calendar: utcCalendar) } == (12...16).map(day))
    }

    @Test("曜日指定（複数）")
    func weekly() {
        let schedule = RecurrenceSchedule(rule: .weekly([.monday, .thursday]), startDate: monday)
        let hits = (12...18).map(day).filter { schedule.occurs(on: $0, calendar: utcCalendar) }
        #expect(hits == [day(12), day(15)])
    }

    @Test("開始日より前・終了日より後・一時停止中・スキップした日は作らない")
    func exclusions() {
        let base = RecurrenceSchedule(rule: .daily, startDate: day(12), endDate: day(14), skippedDates: [day(13)])
        #expect(!base.occurs(on: day(11), calendar: utcCalendar))
        #expect(base.occurs(on: day(12), calendar: utcCalendar))
        #expect(!base.occurs(on: day(13), calendar: utcCalendar))
        #expect(base.occurs(on: day(14), calendar: utcCalendar))
        #expect(!base.occurs(on: day(15), calendar: utcCalendar))

        var paused = base
        paused.isPaused = true
        #expect(!paused.occurs(on: day(12), calendar: utcCalendar))
    }

    @Test("初回は開始日から今日まで生成する")
    func firstGeneration() {
        let schedule = RecurrenceSchedule(rule: .daily, startDate: day(12))
        #expect(schedule.datesToGenerate(through: day(14), calendar: utcCalendar) == [day(12), day(13), day(14)])
    }

    @Test("アプリを開かなかった間の日も、前回の翌日から補って生成する")
    func backfillsMissedDays() {
        let schedule = RecurrenceSchedule(rule: .daily, startDate: day(1), lastGeneratedDate: day(10))
        #expect(schedule.datesToGenerate(through: day(13), calendar: utcCalendar) == [day(11), day(12), day(13)])
    }

    @Test("生成済みの日までなら何も作らない（冪等）")
    func idempotent() {
        let schedule = RecurrenceSchedule(rule: .daily, startDate: day(1), lastGeneratedDate: day(14))
        #expect(schedule.datesToGenerate(through: day(14), calendar: utcCalendar).isEmpty)
    }

    @Test("開始日が未来なら何も作らない")
    func futureStart() {
        let schedule = RecurrenceSchedule(rule: .daily, startDate: day(20))
        #expect(schedule.datesToGenerate(through: day(14), calendar: utcCalendar).isEmpty)
    }

    @Test("さかのぼりは上限日数まで")
    func backfillIsCapped() {
        let schedule = RecurrenceSchedule(rule: .daily, startDate: LocalDate(year: 2020, month: 1, day: 1))
        let dates = schedule.datesToGenerate(through: day(14), calendar: utcCalendar)
        #expect(dates.count == RecurrenceSchedule.maxBackfillDays + 1)
        #expect(dates.last == day(14))
    }

    @Test("保存用の表現の往復")
    func storageRoundTrip() {
        let rules: [RecurrenceRule] = [.daily, .weekdays, .weekly([.tuesday, .saturday])]
        for rule in rules {
            #expect(RecurrenceRule(storageKind: rule.storageKind, mask: rule.storageMask) == rule)
        }
        #expect(RecurrenceRule(storageKind: "unknown", mask: 0) == nil)
        #expect(RecurrenceRule.weekly([.sunday, .saturday]).storageMask == 0b1000001)
    }
}
