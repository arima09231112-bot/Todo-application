/// 達成率とパーティ人数の計算。アプリ・ウィジェット・履歴はすべてここを通す（要件 P-01）。
public enum CompletionRate {
    /// 達成率（%）。完了数 ÷ 総数 × 100 の切り捨て。Todo が 0 件なら nil（「今日の冒険は準備中」）。
    public static func percent(completed: Int, total: Int) -> Int? {
        guard total > 0 else { return nil }
        let done = min(max(completed, 0), total)
        return done * 100 / total
    }

    /// 仲間の人数（勇者は含まない）。20% ごとに1人、最大5人。
    public static func companionCount(percent: Int?) -> Int {
        guard let percent else { return 0 }
        return min(max(percent, 0) / 20, 5)
    }

    /// 次の仲間が加わるまで、あと何件完了すればよいか（図鑑の「今日の目標」）。
    /// Todo が 0 件、またはすでに5人そろっているときは nil。
    public static func tasksUntilNextCompanion(completed: Int, total: Int) -> Int? {
        guard total > 0 else { return nil }
        let done = min(max(completed, 0), total)
        let current = companionCount(percent: percent(completed: done, total: total))
        guard current < CompanionLottery.lineupSize else { return nil }
        // 達成率が次の節目（20% 刻み）以上になる最小の完了数（切り上げ）。
        let target = (current + 1) * 20
        let needed = (target * total + 99) / 100
        return needed - done
    }
}
