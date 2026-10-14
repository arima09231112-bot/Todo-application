/// その日の仲間の顔ぶれを、種別ごとの重みで抽選する（要件 4.3.1a）。
public enum CompanionLottery {
    /// 1日に抽選する仲間の数（達成率 100% で加わる最大人数）。
    public static let lineupSize = 5

    /// `pool` から重み付き・重複なしで `count` 体を、加わる順に抽選する。
    ///
    /// 重みは `GameCharacter.kind.drawWeight`。重みが 0 以下のキャラ（勇者）は選ばれない。
    /// 抽選元が `count` 体に満たないときは、選べるだけ返す。
    public static func draw(
        count: Int = lineupSize,
        from pool: [GameCharacter] = CharacterCatalog.companionPool,
        using generator: inout some RandomNumberGenerator
    ) -> [CharacterID] {
        var candidates = pool.filter { $0.kind.drawWeight > 0 }
        var picked: [CharacterID] = []
        while picked.count < count, !candidates.isEmpty {
            let total = candidates.reduce(0) { $0 + $1.kind.drawWeight }
            var roll = Int.random(in: 0..<total, using: &generator)
            for (index, candidate) in candidates.enumerated() {
                roll -= candidate.kind.drawWeight
                if roll < 0 {
                    picked.append(candidate.id)
                    candidates.remove(at: index)
                    break
                }
            }
        }
        return picked
    }

    /// 端末の乱数で抽選する。
    public static func draw(count: Int = lineupSize, from pool: [GameCharacter] = CharacterCatalog.companionPool) -> [CharacterID] {
        var generator = SystemRandomNumberGenerator()
        return draw(count: count, from: pool, using: &generator)
    }
}
