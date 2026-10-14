import Testing
@testable import RPGTodoCore

/// テストで結果を再現できるようにする、種を指定できる乱数（SplitMix64）。
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("CompanionLottery")
struct CompanionLotteryTests {
    @Test("5体を重複なしで抽選し、勇者（戦士）は含まれない")
    func distinctAndNoHero() {
        var generator = SeededGenerator(seed: 1)
        for _ in 0..<500 {
            let lineup = CompanionLottery.draw(using: &generator)
            #expect(lineup.count == 5)
            #expect(Set(lineup).count == 5)
            #expect(!lineup.contains("warrior_m"))
            #expect(!lineup.contains("warrior_f"))
        }
    }

    @Test("同じ種なら同じ結果（顔ぶれも順番も）")
    func reproducible() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        #expect(CompanionLottery.draw(using: &a) == CompanionLottery.draw(using: &b))
    }

    @Test("重みが重い種別ほど出やすい（通常 > モンスター > 魔王 > スーパースター）")
    func weightsOrder() {
        var generator = SeededGenerator(seed: 7)
        var appearances: [CharacterKind: Int] = [:]
        let days = 4000
        for _ in 0..<days {
            let lineup = CompanionLottery.draw(using: &generator)
            let kinds = Set(lineup.compactMap { id in CharacterCatalog.all.first { $0.id == id }?.kind })
            for kind in kinds { appearances[kind, default: 0] += 1 }
        }
        let job = appearances[.job] ?? 0
        let monster = appearances[.monster] ?? 0
        let demonLord = appearances[.demonLord] ?? 0
        let superstar = appearances[.superstar] ?? 0
        #expect(job > monster && monster > demonLord && demonLord > superstar)
        // 目安（要件 4.3.1a）: モンスター約47%、魔王約17%、スーパースター約6%
        #expect((0.40...0.54).contains(Double(monster) / Double(days)))
        #expect((0.12...0.23).contains(Double(demonLord) / Double(days)))
        #expect((0.03...0.10).contains(Double(superstar) / Double(days)))
    }

    @Test("抽選元が足りないときは選べるだけ返す")
    func smallPool() {
        var generator = SeededGenerator(seed: 3)
        let pool = Array(CharacterCatalog.companionPool.prefix(3))
        #expect(CompanionLottery.draw(count: 5, from: pool, using: &generator).count == 3)
    }

    @Test("重みが 0 のキャラ（勇者）だけなら何も選ばない")
    func onlyHeroes() {
        var generator = SeededGenerator(seed: 3)
        #expect(CompanionLottery.draw(from: CharacterCatalog.heroes, using: &generator).isEmpty)
    }
}
