import Foundation
import SwiftData
import WidgetKit
import RPGTodoCore

/// ウィジェットに表示する Todo 1件。
struct WidgetTodo: Sendable, Identifiable {
    let id: UUID
    let title: String
    /// 「9:30」形式。時刻なしは nil。
    let timeText: String?
    let isCompleted: Bool
}

/// ウィジェットの1回ぶんの表示内容。
struct TodoWidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let hero: CharacterID
    /// 達成率から決まる仲間（勇者を含まない、0〜5人）。
    let companions: [CharacterID]
    let percent: Int?
    let completed: Int
    let total: Int
    /// 今日の Todo（時刻順）。
    let todos: [WidgetTodo]
    /// 読み込みに失敗したときの内容（画面に出して原因を調べられるようにする）。
    var errorMessage: String? = nil

    /// 表示する件数を超えるときは、未完了を優先して残し、並びは時刻順のまま（要件 6.7）。
    func visibleTodos(limit: Int) -> (shown: [WidgetTodo], hidden: Int) {
        guard todos.count > limit else { return (todos, 0) }
        var keep = Set<UUID>()
        for todo in todos where !todo.isCompleted && keep.count < limit { keep.insert(todo.id) }
        for todo in todos where todo.isCompleted && keep.count < limit { keep.insert(todo.id) }
        return (todos.filter { keep.contains($0.id) }, todos.count - limit)
    }

    /// 達成した仲間の人数（勇者を含まない、0〜5）。
    var companionCount: Int { companions.count }

    var countText: String { total == 0 ? "今日の冒険は準備中" : "\(completed)/\(total) タスク完了" }

    var percentText: String { percent.map { "\($0)%" } ?? "--" }

    /// 画面確認用の見本（ギャラリー・読み込み中）。
    static let sample = TodoWidgetEntry(
        date: .now,
        hero: CharacterCatalog.defaultHeroID,
        companions: ["mage_f", "slime", "knight_m"],
        percent: 60,
        completed: 3,
        total: 5,
        todos: [
            WidgetTodo(id: UUID(), title: "朝のランニング", timeText: "7:00", isCompleted: true),
            WidgetTodo(id: UUID(), title: "企画書を書く", timeText: "10:00", isCompleted: true),
            WidgetTodo(id: UUID(), title: "ミーティング", timeText: "14:00", isCompleted: false),
            WidgetTodo(id: UUID(), title: "買い物", timeText: nil, isCompleted: false),
        ]
    )
}

/// ウィジェットの表示内容を、保存データから作る。
@MainActor
enum WidgetDataLoader {
    static func load(now: Date = .now) -> TodoWidgetEntry {
        do {
            return try loadEntry(now: now)
        } catch {
            return TodoWidgetEntry(
                date: now, hero: CharacterCatalog.defaultHeroID, companions: [], percent: nil,
                completed: 0, total: 0, todos: [], errorMessage: "読み込みエラー: \(error)"
            )
        }
    }

    private static func loadEntry(now: Date) throws -> TodoWidgetEntry {
        let context = try AppStore.make().mainContext
        let today = LocalDate(now)

        // アプリを開かなくても正しい日になるよう、日付変更の処理をここでも行う（要件 D-02・D-05。何度走っても結果は同じ）。
        DailyProgressService.finalizePastDays(before: today, in: context)
        TodoService.generateRecurringTodos(through: today, in: context)
        let progress = DailyProgressService.prepareToday(today, in: context)

        let key = today.dayKey
        let items = (try? context.fetch(FetchDescriptor<TodoItem>(predicate: #Predicate { $0.dateKey == key }))) ?? []
        let sorted = TodoOrdering.sorted(items, minutes: \.timeMinutes, createdAt: \.createdAt)

        let hero = HeroSetting.resolve(SharedContainer.defaults?.string(forKey: SettingsKey.hero) ?? "")
        return TodoWidgetEntry(
            date: now,
            hero: hero,
            companions: PartyMilestones.members(lineup: progress.lineup, companionCount: progress.partyMemberCount),
            percent: progress.completionRate,
            completed: progress.completedTasks,
            total: progress.totalTasks,
            todos: sorted.map {
                WidgetTodo(
                    id: $0.id,
                    title: $0.title,
                    timeText: $0.timeMinutes.map { String(format: "%d:%02d", $0 / 60, $0 % 60) },
                    isCompleted: $0.isCompleted
                )
            }
        )
    }
}
