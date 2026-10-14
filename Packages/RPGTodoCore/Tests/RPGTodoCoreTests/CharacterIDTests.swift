import Testing
@testable import RPGTodoCore

@Suite("CharacterID")
struct CharacterIDTests {
    @Test("仲間プールには勇者とスーパースターが含まれない")
    func poolExcludesHeroAndSuperstar() {
        let pool = CharacterID.companionPool
        #expect(!pool.contains(.hero))
        #expect(!pool.contains(.superstar))
    }

    @Test("仲間プールは、ランダムに5体を重複なしで選べる大きさがある")
    func poolIsLargeEnoughForALineup() {
        #expect(CharacterID.companionPool.count >= 5)
    }

    @Test("rawValue は素材のファイル名と一致する")
    func rawValuesMatchAssetNames() {
        #expect(CharacterID.allCases.map(\.rawValue) == [
            "hero", "swordsman", "mage", "priest", "thief", "knight", "superstar",
        ])
    }
}
