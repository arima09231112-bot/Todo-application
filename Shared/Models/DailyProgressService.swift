import Foundation
import SwiftData
import RPGTodoCore

/// 日ごとの記録（`DailyProgress`）の作成・更新・確定。アプリとウィジェットのどちらから呼んでも二重に抽選しない。
@MainActor
enum DailyProgressService {
    /// その日の記録を返す。なければ作る。
    static func progress(for date: LocalDate, in context: ModelContext) -> DailyProgress {
        let key = date.dayKey
        let descriptor = FetchDescriptor<DailyProgress>(predicate: #Predicate { $0.dateKey == key })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let created = DailyProgress(date: date)
        context.insert(created)
        return created
    }

    /// その日の記録を用意し、仲間の顔ぶれが未抽選なら抽選して保存する（要件 4.3.1a）。
    /// 同じ日には何度呼んでも、最初の抽選結果が変わらない。
    @discardableResult
    static func prepareToday(_ today: LocalDate, in context: ModelContext) -> DailyProgress {
        let progress = progress(for: today, in: context)
        if progress.companionLineup.count < CompanionLottery.lineupSize {
            progress.companionLineup = CompanionLottery.draw().map(\.rawValue)
        }
        recordSnapshot(progress, in: context)
        return progress
    }

    /// Todo から件数・達成率・仲間の人数を再計算して記録する。
    static func recordSnapshot(_ progress: DailyProgress, in context: ModelContext) {
        let key = progress.dateKey
        let todos = (try? context.fetch(FetchDescriptor<TodoItem>(predicate: #Predicate { $0.dateKey == key }))) ?? []
        let completed = todos.filter(\.isCompleted).count
        let percent = CompletionRate.percent(completed: completed, total: todos.count)
        progress.totalTasks = todos.count
        progress.completedTasks = completed
        progress.completionRate = percent
        progress.partyMemberCount = CompletionRate.companionCount(percent: percent)
        try? context.save()
    }

    /// 加入演出を再生した節目を記録する。
    static func unlock(_ milestones: [Int], in progress: DailyProgress, context: ModelContext) {
        progress.unlockedMilestones = Array(Set(progress.unlockedMilestones).union(milestones)).sorted()
        try? context.save()
    }

    /// 今日より前の日の記録を確定する（要件 D-03・D-04）。
    /// 何日ぶりに起動しても、Todo がある日の記録が欠けないようにする。何度呼んでも結果は同じ。
    static func finalizePastDays(before today: LocalDate, in context: ModelContext) {
        let records = (try? context.fetch(FetchDescriptor<DailyProgress>())) ?? []
        for record in records where record.dateKey < today.dayKey && !record.isFinalized {
            recordSnapshot(record, in: context)
            record.isFinalized = true
        }

        let recorded = Set(records.map(\.dateKey))
        let todos = (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
        let missing = Set(todos.map(\.dateKey)).filter { $0 < today.dayKey && !recorded.contains($0) }
        for key in missing {
            guard let date = LocalDate(dayKey: key) else { continue }
            let record = progress(for: date, in: context)
            recordSnapshot(record, in: context)
            record.isFinalized = true
        }
        try? context.save()
    }
}
