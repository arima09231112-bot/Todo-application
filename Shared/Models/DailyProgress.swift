import Foundation
import SwiftData
import RPGTodoCore

/// 1日ぶんの記録（日次スナップショット）。Todo から再計算できる派生データに、
/// その日の仲間の抽選結果と、加入演出の再生済みの節目を加えたもの。
@Model
final class DailyProgress {
    @Attribute(.unique) var dateKey: Int
    var totalTasks: Int
    var completedTasks: Int
    /// 達成率（%）。Todo が 0 件なら nil。
    var completionRate: Int?
    /// 仲間の人数（勇者を含まない、0〜5）。
    var partyMemberCount: Int
    /// 加入演出を再生した節目（1〜5）。1日1回の演出の管理を兼ねる。
    var unlockedMilestones: [Int]
    /// その日に抽選された仲間5体のID（加わる順）。未抽選なら空。
    var companionLineup: [String]
    /// 日付変更で確定済みか。
    var isFinalized: Bool

    init(date: LocalDate) {
        self.dateKey = date.dayKey
        self.totalTasks = 0
        self.completedTasks = 0
        self.completionRate = nil
        self.partyMemberCount = 0
        self.unlockedMilestones = []
        self.companionLineup = []
        self.isFinalized = false
    }

    var lineup: [CharacterID] { companionLineup.map { CharacterID(rawValue: $0) } }
}
