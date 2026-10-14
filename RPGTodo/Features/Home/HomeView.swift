import SwiftUI
import SwiftData
import RPGTodoCore

/// 追加・編集シートの対象。
enum EditorTarget: Identifiable {
    case new
    case edit(TodoItem)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let todo): todo.id.uuidString
        }
    }
}

/// ホーム画面（今日の冒険）。Phase 1 では日付・達成率・タスク一覧まで。パーティの表示は Phase 2。
struct HomeView: View {
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @AppStorage("home.hideCompleted") private var hideCompleted = false
    @State private var categoryFilter: TodoCategory?
    @State private var editor: EditorTarget?
    @State private var showCarryOver = false
    @State private var pendingDelete: TodoItem?

    // MARK: 集計

    private var todayTodos: [TodoItem] { allTodos.filter { $0.dateKey == today.dayKey } }
    private var completedCount: Int { todayTodos.filter(\.isCompleted).count }
    private var percent: Int? { CompletionRate.percent(completed: completedCount, total: todayTodos.count) }
    private var companionCount: Int { CompletionRate.companionCount(percent: percent) }

    /// 表示する行。絞り込みは表示だけに効かせ、達成率の計算には影響させない。
    private var visibleTodos: [TodoItem] {
        let filtered = todayTodos.filter { todo in
            (!hideCompleted || !todo.isCompleted) && (categoryFilter == nil || todo.category == categoryFilter)
        }
        return TodoOrdering.sorted(filtered, minutes: { $0.timeMinutes }, createdAt: { $0.createdAt })
    }

    // MARK: 画面

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                taskCard
                partyField
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editor = .new } label: { Image(systemName: "plus") }
                        .accessibilityLabel("タスクを追加")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $editor) { target in
            TodoEditorSheet(target: target, today: today)
        }
        .sheet(isPresented: $showCarryOver) {
            CarryOverSheet(today: today)
        }
        .sensoryFeedback(.selection, trigger: completedCount)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.dateText(today))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("今日の冒険")
                    .font(.largeTitle.bold())
                Text("やることをこなして、仲間と一緒に進もう。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                ProgressGauge(percent: percent)
                Text(percent == nil ? "今日の冒険は準備中" : "\(completedCount) / \(todayTodos.count) タスク完了")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var taskCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("今日のタスク").font(.headline)
                Spacer()
                listMenu
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if visibleTodos.isEmpty {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                List {
                    ForEach(visibleTodos) { todo in
                        TodoRow(
                            todo: todo,
                            onToggle: { TodoService.toggle(todo, in: context) },
                            onEdit: { editor = .edit(todo) }
                        )
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: !todo.isRecurring) {
                            Button(role: .destructive) { requestDelete(todo) } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }

            Button { editor = .new } label: {
                Label("新しいタスクを追加", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(16)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .frame(maxHeight: .infinity)
        .confirmationDialog(
            "繰り返しのタスクです",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { todo in
            Button("この日だけ削除", role: .destructive) {
                TodoService.delete(todo, scope: .thisDayOnly, in: context)
            }
            Button("繰り返しを終了して削除", role: .destructive) {
                TodoService.delete(todo, scope: .allFuture, in: context)
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private var listMenu: some View {
        Menu {
            Toggle("完了済みを隠す", isOn: $hideCompleted)
            Button { showCarryOver = true } label: {
                Label("未完了のタスクを見る", systemImage: "arrow.uturn.forward")
            }
            Picker("カテゴリで絞り込み", selection: $categoryFilter) {
                Text("すべて").tag(TodoCategory?.none)
                ForEach(TodoCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(TodoCategory?.some(category))
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .padding(8)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("リストメニュー")
    }

    /// 冒険フィールド。Phase 2 で、日替わりの仲間を並べる。
    private var partyField: some View {
        HStack(spacing: 8) {
            PixelSprite(character: CharacterCatalog.defaultHeroID, scale: 1)
            Text(companionCount == 0 ? "勇者" : "勇者 ＋ 仲間\(companionCount)人")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
    }

    // MARK: 操作

    private var emptyMessage: String {
        if todayTodos.isEmpty { return "タスクを追加して、冒険をはじめよう。" }
        return "条件に合うタスクはありません。"
    }

    private func requestDelete(_ todo: TodoItem) {
        if todo.isRecurring {
            pendingDelete = todo
        } else {
            TodoService.delete(todo, scope: .thisDayOnly, in: context)
        }
    }

    private static func dateText(_ date: LocalDate) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("MMMMdEEE")
        return formatter.string(from: date.date())
    }
}
