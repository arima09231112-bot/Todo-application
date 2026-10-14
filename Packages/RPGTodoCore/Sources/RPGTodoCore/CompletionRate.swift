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
}
