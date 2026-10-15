import SwiftUI
import SwiftData
import RPGTodoCore

/// Todo の追加・編集シート。キーボードの「完了」でそのまま保存できる（＋ → 入力 → 完了）。
struct TodoEditorSheet: View {
    let target: EditorTarget
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft = TodoDraft()
    @State private var didLoad = false
    @State private var askSaveScope = false
    @State private var askDeleteScope = false
    @FocusState private var titleFocused: Bool

    private var editingTodo: TodoItem? {
        if case .edit(let todo) = target { return todo }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("クエスト名", text: $draft.title)
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
                Section {
                    DatePicker("対象日", selection: $draft.date, displayedComponents: .date)
                    Toggle("時刻", isOn: $draft.hasTime)
                    if draft.hasTime {
                        DatePicker("時刻", selection: $draft.time, displayedComponents: .hourAndMinute)
                    }
                    Picker("カテゴリ", selection: $draft.category) {
                        ForEach(TodoCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                Section("繰り返し") {
                    Picker("繰り返し", selection: $draft.repeatKind) {
                        ForEach(RepeatKind.allCases) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                    if draft.repeatKind == .weekly {
                        weekdayPicker
                    }
                }
                if let todo = editingTodo {
                    Section {
                        Button("削除", role: .destructive) { requestDelete(todo) }
                            .confirmationDialog("繰り返しのクエストです", isPresented: $askDeleteScope, titleVisibility: .visible) {
                                Button("この日だけ削除", role: .destructive) { delete(todo, scope: .thisDayOnly) }
                                Button("繰り返しを終了して削除", role: .destructive) { delete(todo, scope: .allFuture) }
                                Button("キャンセル", role: .cancel) {}
                            }
                    }
                }
            }
            .adventureScreenBackground()
            .navigationTitle(editingTodo == nil ? "新しいクエスト" : "クエストを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(!draft.isValid)
                }
            }
            .confirmationDialog("繰り返しのクエストです", isPresented: $askSaveScope, titleVisibility: .visible) {
                Button("この日だけ変更") { commitEdit(scope: .thisDayOnly) }
                Button("今後すべて変更") { commitEdit(scope: .allFuture) }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear(perform: load)
    }

    private var weekdayPicker: some View {
        HStack {
            ForEach(Weekday.allCases, id: \.self) { day in
                let selected = draft.weekdays.contains(day)
                Button {
                    if selected { draft.weekdays.remove(day) } else { draft.weekdays.insert(day) }
                } label: {
                    Text(day.shortName)
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .background(selected ? Color.blue : Color.clear, in: Circle())
                        .overlay(Circle().stroke(Color.blue.opacity(0.4)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(day.shortName)曜日")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: 操作

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        switch target {
        case .new:
            draft.date = today.date()
            titleFocused = true
        case .edit(let todo):
            draft = TodoDraft(todo: todo, recurrence: TodoService.recurrence(for: todo, in: context))
        }
    }

    private func save() {
        guard draft.isValid else { return }
        switch target {
        case .new:
            TodoService.create(from: draft, today: today, in: context)
            dismiss()
        case .edit(let todo):
            if todo.isRecurring {
                askSaveScope = true
            } else {
                commitEdit(scope: .thisDayOnly)
            }
        }
    }

    private func commitEdit(scope: RecurrenceScope) {
        guard let todo = editingTodo else { return }
        TodoService.update(todo, from: draft, scope: scope, in: context)
        dismiss()
    }

    private func requestDelete(_ todo: TodoItem) {
        if todo.isRecurring {
            askDeleteScope = true
        } else {
            delete(todo, scope: .thisDayOnly)
        }
    }

    private func delete(_ todo: TodoItem, scope: RecurrenceScope) {
        TodoService.delete(todo, scope: scope, in: context)
        dismiss()
    }
}
