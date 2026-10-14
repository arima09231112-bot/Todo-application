import Testing
@testable import RPGTodoCore

@Suite("CompletionRate")
struct CompletionRateTests {
    @Test("端数は切り捨て、100% は全件完了のときだけ")
    func percentFloors() {
        #expect(CompletionRate.percent(completed: 3, total: 5) == 60)
        #expect(CompletionRate.percent(completed: 2, total: 3) == 66)
        #expect(CompletionRate.percent(completed: 199, total: 200) == 99)
        #expect(CompletionRate.percent(completed: 5, total: 5) == 100)
        #expect(CompletionRate.percent(completed: 0, total: 4) == 0)
    }

    @Test("Todo が 0 件なら nil")
    func emptyIsNil() {
        #expect(CompletionRate.percent(completed: 0, total: 0) == nil)
    }

    @Test("範囲外の完了数は丸める")
    func clamps() {
        #expect(CompletionRate.percent(completed: 9, total: 5) == 100)
        #expect(CompletionRate.percent(completed: -1, total: 5) == 0)
    }

    @Test("仲間は 20% ごとに1人、最大5人")
    func companions() {
        #expect(CompletionRate.companionCount(percent: nil) == 0)
        #expect(CompletionRate.companionCount(percent: 0) == 0)
        #expect(CompletionRate.companionCount(percent: 19) == 0)
        #expect(CompletionRate.companionCount(percent: 20) == 1)
        #expect(CompletionRate.companionCount(percent: 40) == 2)
        #expect(CompletionRate.companionCount(percent: 60) == 3)
        #expect(CompletionRate.companionCount(percent: 99) == 4)
        #expect(CompletionRate.companionCount(percent: 100) == 5)
    }
}
