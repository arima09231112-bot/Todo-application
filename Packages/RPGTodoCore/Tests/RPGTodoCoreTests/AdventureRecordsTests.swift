import Foundation
import Testing
@testable import RPGTodoCore

@Suite("Streak")
struct StreakTests {
    let today = LocalDate(year: 2026, month: 10, day: 14)

    private func key(_ daysAgo: Int) -> Int { today.addingDays(-daysAgo, calendar: utcCalendar).dayKey }

    @Test("今日が100%なら今日も数える")
    func includesToday() {
        let rates = [key(0): 100, key(1): 100, key(2): 50]
        #expect(Streak.current(today: today, percentByDayKey: rates, calendar: utcCalendar) == 2)
    }

    @Test("今日がまだ100%でなければ昨日まで")
    func todayNotDone() {
        let rates = [key(0): 40, key(1): 100, key(2): 100]
        #expect(Streak.current(today: today, percentByDayKey: rates, calendar: utcCalendar) == 2)
    }

    @Test("Todo 0 件の日は途切れず、数えない")
    func skipsEmptyDays() {
        let rates = [key(0): 100, key(2): 100, key(4): 100, key(5): 90]
        #expect(Streak.current(today: today, percentByDayKey: rates, calendar: utcCalendar) == 3)
    }

    @Test("100%でない日で途切れる。記録がなければ 0")
    func breaks() {
        #expect(Streak.current(today: today, percentByDayKey: [key(0): 100, key(1): 99], calendar: utcCalendar) == 1)
        #expect(Streak.current(today: today, percentByDayKey: [:], calendar: utcCalendar) == 0)
    }
}

@Suite("ProgressStats")
struct ProgressStatsTests {
    @Test("平均は切り捨て。日がなければ nil")
    func average() {
        #expect(ProgressStats.average([100, 50, 33]) == 61)
        #expect(ProgressStats.average([]) == nil)
    }

    @Test("週は firstWeekday から7日（日曜始まり）")
    func week() {
        var calendar = utcCalendar
        calendar.firstWeekday = 1
        let days = ProgressStats.week(containing: LocalDate(year: 2026, month: 10, day: 14), calendar: calendar)
        #expect(days.count == 7)
        #expect(days.first == LocalDate(year: 2026, month: 10, day: 11))
        #expect(days.last == LocalDate(year: 2026, month: 10, day: 17))
    }

    @Test("月の日数（うるう年の2月を含む）")
    func month() {
        #expect(ProgressStats.month(year: 2026, month: 10, calendar: utcCalendar).count == 31)
        #expect(ProgressStats.month(year: 2028, month: 2, calendar: utcCalendar).count == 29)
        #expect(ProgressStats.month(year: 2026, month: 2, calendar: utcCalendar).last == LocalDate(year: 2026, month: 2, day: 28))
    }
}

@Suite("Discovery")
struct DiscoveryTests {
    @Test("初めて仲間になった日と、仲間になった日数")
    func compute() {
        let d1 = LocalDate(year: 2026, month: 10, day: 12)
        let d2 = LocalDate(year: 2026, month: 10, day: 13)
        let d3 = LocalDate(year: 2026, month: 10, day: 14)
        let result = Discovery.compute(days: [
            (date: d3, members: ["slime", "mage_f"]),
            (date: d1, members: ["slime"]),
            (date: d2, members: ["slime", "slime"]),
        ])
        #expect(result["slime"] == Discovery(firstDate: d1, days: 3))
        #expect(result["mage_f"] == Discovery(firstDate: d3, days: 1))
        #expect(result["dragon"] == nil)
    }
}

@Suite("NextCompanion")
struct NextCompanionTests {
    @Test("次の仲間まであと何件")
    func remaining() {
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 0, total: 5) == 1)
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 3, total: 5) == 1)
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 0, total: 10) == 2)
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 1, total: 3) == 1)  // 33% → 40% は2件
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 0, total: 1) == 1)
    }

    @Test("0件・全員そろったら nil")
    func none() {
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 0, total: 0) == nil)
        #expect(CompletionRate.tasksUntilNextCompanion(completed: 4, total: 4) == nil)
    }
}

@Suite("CharacterProfiles")
struct CharacterProfileTests {
    @Test("全キャラに名前・紹介文・ひとこと。仲間にはヒントもある")
    func complete() {
        for character in CharacterCatalog.all {
            #expect(!character.name.isEmpty, "\(character.id)")
            #expect(!character.profile.isEmpty, "\(character.id)")
            #expect(!character.quote.isEmpty, "\(character.id)")
        }
        for character in CharacterCatalog.companionPool {
            #expect(!character.hint.isEmpty, "\(character.id)")
        }
        #expect(CharacterCatalog.character("superstar")?.name == "カンナ")
    }
}
