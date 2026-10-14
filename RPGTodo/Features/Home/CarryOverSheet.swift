import SwiftUI
import SwiftData
import RPGTodoCore

/// 過去日の未完了タスクの一覧。手動で「今日に移す」（要件 T-08・4.1.2）。
/// 自動では繰り越さない。繰り返しタスクは翌日分が自動で作られるので対象外。
struct CarryOverSheet: View {
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TodoItem.dateKey, order: .reverse) private var allTodos: [TodoItem]

    private var pending: [TodoItem] {
        allTodos.filter { $0.dateKey < today.dayKey && !$0.isCompleted && $0.carriedOverTo == nil && !$0.isRecurring }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pending.isEmpty {
                    ContentUnavailableView("未完了のタスクはありません", systemImage: "checkmark.seal")
                } else {
                    List(pending) { todo in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todo.title)
                                Text(Self.dateText(todo.date))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("今日に移す") {
                                TodoService.carryOver(todo, to: today, in: context)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("未完了のタスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private static func dateText(_ date: LocalDate) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("yMMMMdEEE")
        return formatter.string(from: date.date())
    }
}
