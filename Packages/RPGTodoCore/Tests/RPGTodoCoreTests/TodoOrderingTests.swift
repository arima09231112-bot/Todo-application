import Foundation
import Testing
@testable import RPGTodoCore

@Suite("TodoOrdering")
struct TodoOrderingTests {
    private struct Item: Equatable {
        let name: String
        let minutes: Int?
        let created: TimeInterval
    }

    private func sorted(_ items: [Item]) -> [String] {
        TodoOrdering.sorted(
            items,
            minutes: { $0.minutes },
            createdAt: { Date(timeIntervalSince1970: $0.created) }
        ).map(\.name)
    }

    @Test("時刻の昇順。時刻なしは末尾に作成順")
    func timeThenCreation() {
        let items = [
            Item(name: "夕食", minutes: 19 * 60 + 30, created: 5),
            Item(name: "メモB", minutes: nil, created: 2),
            Item(name: "メール", minutes: 9 * 60, created: 4),
            Item(name: "メモA", minutes: nil, created: 1),
            Item(name: "ジム", minutes: 18 * 60, created: 3),
        ]
        #expect(sorted(items) == ["メール", "ジム", "夕食", "メモA", "メモB"])
    }

    @Test("同じ時刻は作成順")
    func sameTime() {
        let items = [
            Item(name: "後", minutes: 600, created: 2),
            Item(name: "先", minutes: 600, created: 1),
        ]
        #expect(sorted(items) == ["先", "後"])
    }
}
