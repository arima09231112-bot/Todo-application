import SwiftUI
import RPGTodoCore

/// 今日のクエストの1行。チェック円で完了を切り替え、それ以外のタップで編集を開く。
/// ウィジェットと同じく、未完了は「○」、完了はチェックと取り消し線で表す。
struct TodoRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void

    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(todo.isCompleted ? appearance.accent : Color.primary.opacity(0.6))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(todo.isCompleted ? "完了済み。タップで未完了に戻す" : "未完了。タップで完了にする")

            HStack(spacing: 8) {
                Text(todo.title)
                    .font(appearance.font(.body))
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? Color.secondary : Color.primary)
                    .lineLimit(2)
                if todo.isRecurring {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("繰り返し")
                }
                Spacer(minLength: 8)
                if let minutes = todo.timeMinutes {
                    Text(String(format: "%02d:%02d", minutes / 60, minutes % 60))
                        .font(appearance.font(.subheadline))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
        }
        .padding(.vertical, 4)
    }
}
