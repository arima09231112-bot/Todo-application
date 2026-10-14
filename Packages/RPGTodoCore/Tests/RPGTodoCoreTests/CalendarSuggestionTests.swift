import Foundation
import Testing
@testable import RPGTodoCore

@Suite("CalendarSuggestion")
struct CalendarSuggestionTests {
    @Test("キーワードごとのテンプレート")
    func templates() {
        #expect(CalendarSuggestion.title(forEventTitle: "定例会議") == "定例会議の資料を確認する")
        #expect(CalendarSuggestion.title(forEventTitle: "週次MTG") == "週次MTGの資料を確認する")
        #expect(CalendarSuggestion.title(forEventTitle: "A社 商談") == "A社 商談の提案資料を準備する")
        #expect(CalendarSuggestion.title(forEventTitle: "設計レビュー") == "設計レビューの修正箇所を確認する")
        #expect(CalendarSuggestion.title(forEventTitle: "歯医者") == "歯医者の準備をする")
    }

    @Test("前後の空白は除き、長い予定名は切り詰める")
    func trimsAndTruncates() {
        #expect(CalendarSuggestion.title(forEventTitle: "  歯医者  ") == "歯医者の準備をする")
        let long = String(repeating: "あ", count: 200)
        #expect(CalendarSuggestion.title(forEventTitle: long).count <= 100)
    }

    @Test("候補の時刻は開始の30分前、0:00 より前にはしない")
    func suggestedTime() {
        #expect(CalendarSuggestion.suggestedMinutes(eventStartMinutes: 10 * 60) == 9 * 60 + 30)
        #expect(CalendarSuggestion.suggestedMinutes(eventStartMinutes: 10) == 0)
    }

    @Test("同じ回は同じキー、別の回は別のキー")
    func eventKey() {
        let a = Date(timeIntervalSince1970: 1_800_000_000)
        let b = a.addingTimeInterval(7 * 24 * 3600)
        #expect(CalendarEventKey.make(eventID: "E1", start: a) == CalendarEventKey.make(eventID: "E1", start: a))
        #expect(CalendarEventKey.make(eventID: "E1", start: a) != CalendarEventKey.make(eventID: "E1", start: b))
        #expect(CalendarEventKey.make(eventID: "E1", start: a) != CalendarEventKey.make(eventID: "E2", start: a))
    }
}
