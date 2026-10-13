import Testing
@testable import RPGTodoCore

@Suite("CharacterID")
struct CharacterIDTests {
    @Test("仲間は5人で、勇者とスーパースターは含まない")
    func companionsExcludeHeroAndSuperstar() {
        let companions = CharacterID.companionsInJoinOrder
        #expect(companions.count == 5)
        #expect(!companions.contains(.hero))
        #expect(!companions.contains(.superstar))
    }

    @Test("加入順は 剣士→魔法使い→僧侶→盗賊→騎士")
    func joinOrder() {
        #expect(CharacterID.companionsInJoinOrder == [.swordsman, .mage, .priest, .thief, .knight])
    }

    @Test("rawValue は素材のフォルダ名と一致する")
    func rawValuesMatchAssetNames() {
        #expect(CharacterID.allCases.map(\.rawValue) == [
            "hero", "swordsman", "mage", "priest", "thief", "knight", "superstar",
        ])
    }
}
