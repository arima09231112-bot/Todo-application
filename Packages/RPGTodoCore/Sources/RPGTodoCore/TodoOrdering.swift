import Foundation

/// 今日のタスクの並び順（要件 T-07）。
public enum TodoOrdering {
    /// 時刻の昇順。時刻なしは末尾に、作成順で並べる。
    /// 完了しても順序は変わらない（完了状態を並び順に使わない）。
    public static func sorted<T>(
        _ items: [T],
        minutes: (T) -> Int?,
        createdAt: (T) -> Date
    ) -> [T] {
        items.enumerated().sorted { lhs, rhs in
            let (a, b) = (lhs.element, rhs.element)
            switch (minutes(a), minutes(b)) {
            case let (x?, y?) where x != y:
                return x < y
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                let (ca, cb) = (createdAt(a), createdAt(b))
                return ca != cb ? ca < cb : lhs.offset < rhs.offset
            }
        }.map(\.element)
    }
}
