import Testing
@testable import RPGTodoCore

@Suite("PartyMilestones")
struct PartyMilestonesTests {
    @Test("節目に届くと、その人数ぶんの加入演出が出る")
    func reachesMilestone() {
        #expect(PartyMilestones.newMilestones(companionCount: 0, unlocked: []).isEmpty)
        #expect(PartyMilestones.newMilestones(companionCount: 1, unlocked: []) == [1])
        #expect(PartyMilestones.newMilestones(companionCount: 3, unlocked: [1, 2]) == [3])
    }

    @Test("Todo が少なく、節目を一度に複数超えたときは順番に返す（2件中1件で 50% → 2人）")
    func skipsSeveral() {
        let percent = CompletionRate.percent(completed: 1, total: 2)
        let count = CompletionRate.companionCount(percent: percent)
        #expect(count == 2)
        #expect(PartyMilestones.newMilestones(companionCount: count, unlocked: []) == [1, 2])
    }

    @Test("一度到達した節目は、付け外ししても再生しない")
    func playsOncePerDay() {
        #expect(PartyMilestones.newMilestones(companionCount: 3, unlocked: [1, 2, 3]).isEmpty)
        // 人数が減っても（チェックを外しても）記録は残る
        #expect(PartyMilestones.newMilestones(companionCount: 2, unlocked: [1, 2, 3]).isEmpty)
    }

    @Test("100% で5人目まで")
    func upToFive() {
        #expect(PartyMilestones.newMilestones(companionCount: 5, unlocked: [1, 2, 3, 4]) == [5])
        #expect(PartyMilestones.newMilestones(companionCount: 9, unlocked: []) == [1, 2, 3, 4, 5])
    }

    @Test("表示する仲間は抽選結果の先頭から人数分")
    func members() {
        let lineup: [CharacterID] = ["a", "b", "c", "d", "e"]
        #expect(PartyMilestones.members(lineup: lineup, companionCount: 0).isEmpty)
        #expect(PartyMilestones.members(lineup: lineup, companionCount: 3) == ["a", "b", "c"])
        #expect(PartyMilestones.members(lineup: lineup, companionCount: 5) == lineup)
    }
}
