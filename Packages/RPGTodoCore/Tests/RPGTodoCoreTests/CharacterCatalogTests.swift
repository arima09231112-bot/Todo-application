import Foundation
import Testing
@testable import RPGTodoCore

@Suite("CharacterCatalog")
struct CharacterCatalogTests {
    @Test("キャラIDは重複しない")
    func idsAreUnique() {
        let ids = CharacterCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("勇者の見た目は戦士（男）・戦士（女）の2つで、仲間の抽選元に含まれない")
    func heroesAreExcludedFromPool() {
        #expect(CharacterCatalog.heroes.map(\.id) == ["warrior_m", "warrior_f"])
        #expect(CharacterCatalog.heroes.contains { $0.id == CharacterCatalog.defaultHeroID })
        #expect(!CharacterCatalog.companionPool.contains { $0.kind == .hero })
        #expect(CharacterCatalog.companionPool.count == 23)
    }

    @Test("種別ごとの人数")
    func countsPerKind() {
        func count(_ kind: CharacterKind) -> Int {
            CharacterCatalog.all.filter { $0.kind == kind }.count
        }
        #expect(count(.hero) == 2)
        #expect(count(.job) == 16)
        #expect(count(.monster) == 4)
        #expect(count(.demonLord) == 2)
        #expect(count(.superstar) == 1)
    }

    @Test("出やすさの順: 通常 > モンスター > 魔王 > スーパースター > 0")
    func drawWeightOrder() {
        #expect(CharacterKind.job.drawWeight > CharacterKind.monster.drawWeight)
        #expect(CharacterKind.monster.drawWeight > CharacterKind.demonLord.drawWeight)
        #expect(CharacterKind.demonLord.drawWeight > CharacterKind.superstar.drawWeight)
        #expect(CharacterKind.superstar.drawWeight > 0)
        #expect(CharacterKind.hero.drawWeight == 0)
    }

    @Test("抽選元は、5体を重複なしで選べる大きさがある")
    func poolIsLargeEnough() {
        #expect(CharacterCatalog.companionPool.count >= 5)
    }

    @Test("IDは文字列として保存・復元できる")
    func idCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(CharacterID(rawValue: "slime"))
        #expect(String(decoding: data, as: UTF8.self) == "\"slime\"")
        #expect(try JSONDecoder().decode(CharacterID.self, from: data) == "slime")
    }
}
