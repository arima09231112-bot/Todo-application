import SwiftUI
import SwiftData
import RPGTodoCore

/// 今日の完了したクエストの一覧（ホームの「今日のクエスト」からは外れる）。チェックを外すと未完了に戻る。
struct CompletedQuestsSheet: View {
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearance) private var appearance
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]

    private var completed: [TodoItem] {
        let items = allTodos.filter { $0.dateKey == today.dayKey && $0.isCompleted }
        return TodoOrdering.sorted(items, minutes: { $0.timeMinutes }, createdAt: { $0.createdAt })
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    ContentUnavailableView("完了したクエストはまだありません", systemImage: "checkmark.circle")
                } else {
                    List(completed) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: { withAnimation { TodoService.toggle(todo, in: context) } },
                            onEdit: {}
                        )
                        .frostedRow(appearance)
                    }
                }
            }
            .frostedScreenBackground()
            .navigationTitle("完了したクエスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
