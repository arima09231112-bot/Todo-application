import SwiftUI
import RPGTodoCore

extension DailyProgress {
    /// その日に到達した仲間の人数。あとでチェックを外しても減らない（加入演出を再生した節目も見る）。
    var reachedCompanions: Int { max(partyMemberCount, unlockedMilestones.max() ?? 0) }

    /// その日に一度でも加わった仲間（図鑑の発見に使う）。
    var joinedMembers: [CharacterID] { PartyMilestones.members(lineup: lineup, companionCount: reachedCompanions) }

    /// いま（過去の日は確定時点で）パーティにいる仲間。
    var currentMembers: [CharacterID] { PartyMilestones.members(lineup: lineup, companionCount: partyMemberCount) }

    var localDate: LocalDate? { LocalDate(dayKey: dateKey) }

    /// Todo が1件以上ある日の達成率。
    var recordedPercent: Int? { totalTasks > 0 ? completionRate : nil }
}

/// 日ごとの記録から、図鑑と記録タブの集計を作る。
enum AdventureLog {
    static func discoveries(_ progresses: [DailyProgress]) -> [CharacterID: Discovery] {
        let days = progresses.compactMap { progress -> (date: LocalDate, members: [CharacterID])? in
            guard let date = progress.localDate else { return nil }
            return (date: date, members: progress.joinedMembers)
        }
        return Discovery.compute(days: days)
    }

    /// Todo が1件以上ある日の達成率（キーは dayKey）。
    static func percentByDayKey(_ progresses: [DailyProgress]) -> [Int: Int] {
        var result: [Int: Int] = [:]
        for progress in progresses {
            if let percent = progress.recordedPercent { result[progress.dateKey] = percent }
        }
        return result
    }
}

extension CharacterKind {
    /// 図鑑で見せる「めずらしさ」（要件 6.6）。
    var rarityLabel: String {
        switch self {
        case .hero: "勇者"
        case .job: "なかま"
        case .monster: "めずらしい"
        case .demonLord: "とてもめずらしい"
        case .superstar: "伝説級"
        }
    }

    var rarityColor: Color {
        switch self {
        case .hero: .blue
        case .job: .secondary
        case .monster: .teal
        case .demonLord: .purple
        case .superstar: .pink
        }
    }
}

extension LocalDate {
    /// 「2026年10月14日(水)」のような表示。
    var longText: String { date().formatted(.dateTime.year().month().day().weekday(.abbreviated)) }
    /// 「10月14日(水)」のような表示。
    var shortText: String { date().formatted(.dateTime.month().day().weekday(.abbreviated)) }
}
