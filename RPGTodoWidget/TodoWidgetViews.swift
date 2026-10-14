import SwiftUI
import WidgetKit
import AppIntents
import RPGTodoCore

/// サイズに応じて小・中・大のレイアウトを切り替える（要件 6.7）。
struct TodoWidgetView: View {
    let entry: TodoWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallLayout(entry: entry)
        case .systemMedium:
            ListLayout(entry: entry, limit: 4, partyHeight: 44)
        default:
            ListLayout(entry: entry, limit: 8, partyHeight: 84)
        }
    }
}

private extension View {
    /// 背景のイラストの上でも読めるよう、半透明のカードに載せる。
    func widgetCard() -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// 小: 達成率と完了数、パーティ。
private struct SmallLayout: View {
    let entry: TodoWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 0) {
                Text("今日の冒険")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(entry.percentText)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(entry.total == 0 ? "今日の冒険は準備中" : "\(entry.completed)/\(entry.total) 完了")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .widgetCard()

            Spacer(minLength: 0)
            PartyField(hero: entry.hero, companions: entry.companions, height: 44)
        }
    }
}

/// 中・大: 見出しと進捗バー、Todo の一覧、パーティ。
private struct ListLayout: View {
    let entry: TodoWidgetEntry
    let limit: Int
    let partyHeight: CGFloat

    var body: some View {
        let (shown, hidden) = entry.visibleTodos(limit: limit)
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("今日の冒険").font(.caption.bold())
                    Spacer(minLength: 0)
                    Text(entry.percentText).font(.subheadline.bold())
                    if entry.total > 0 {
                        Text("\(entry.completed)/\(entry.total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ProgressView(value: Double(entry.completed), total: Double(max(entry.total, 1)))
                    .tint(.blue)

                if shown.isEmpty {
                    Text("今日の冒険は準備中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(shown) { TodoLine(todo: $0) }
                    if hidden > 0 {
                        Text("ほか \(hidden) 件")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetCard()

            Spacer(minLength: 0)
            PartyField(hero: entry.hero, companions: entry.companions, height: partyHeight)
        }
    }
}

/// Todo 1行。チェックだけがボタン（アプリを開かずに完了を切り替える）。それ以外をタップするとアプリが開く。
private struct TodoLine: View {
    let todo: WidgetTodo

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.isCompleted ? Color.blue : Color.secondary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(.caption)
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? Color.secondary : Color.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
            if let timeText = todo.timeText {
                Text(timeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
