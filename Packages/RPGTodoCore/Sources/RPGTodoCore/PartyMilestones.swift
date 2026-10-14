/// 仲間の加入（達成率 20% ごとの節目）の判定。
///
/// 節目の番号は「何人目の仲間か」（1〜5）。20% が 1、100% が 5。
public enum PartyMilestones {
    /// 現在の人数に対して、まだ演出を再生していない節目（昇順）。
    ///
    /// 1日1回の演出を守るため、一度到達した節目は `unlocked` に記録して渡す。
    /// 達成率を下げて付け直しても再生されない。Todo が少ない日に節目を一度に超えたときは、複数返る。
    public static func newMilestones(companionCount: Int, unlocked: [Int]) -> [Int] {
        guard companionCount > 0 else { return [] }
        let reached = Set(1...min(companionCount, CompanionLottery.lineupSize))
        return reached.subtracting(unlocked).sorted()
    }

    /// 現在表示する仲間（抽選結果の先頭から人数分）。
    public static func members(lineup: [CharacterID], companionCount: Int) -> [CharacterID] {
        Array(lineup.prefix(max(0, companionCount)))
    }
}
