import AppIntents
import SwiftData
import RPGTodoCore

/// ウィジェットのチェックをタップしたときの処理。アプリを開かずに完了を切り替える（要件 W-04）。
struct ToggleTodoIntent: AppIntent {
    static let title: LocalizedStringResource = "Todoの完了を切り替える"

    @Parameter(title: "Todo ID")
    var todoID: String

    init() {}

    init(todoID: String) {
        self.todoID = todoID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: todoID) else { return .result() }
        let context = AppStore.makeContainer().mainContext
        let descriptor = FetchDescriptor<TodoItem>(predicate: #Predicate { $0.id == id })
        guard let todo = try? context.fetch(descriptor).first else { return .result() }

        TodoService.toggle(todo, in: context)
        // 達成率と仲間の人数の記録も、アプリと同じ計算で更新する。
        let progress = DailyProgressService.progress(for: todo.date, in: context)
        DailyProgressService.recordSnapshot(progress, in: context)
        return .result()
    }
}
