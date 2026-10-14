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

/// ホーム画面（今日の冒険）: 日付・達成率・タスク一覧・冒険フィールド（勇者と、日替わりの仲間）。
struct HomeView: View {
    let today: LocalDate

    @Environment(\.modelContext) private var context
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @Query private var progresses: [DailyProgress]
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue
    @AppStorage("home.hideCompleted") private var hideCompleted = false
    @State private var categoryFilter: TodoCategory?
    @State private var editor: EditorTarget?
    @State private var showCarryOver = false
    @State private var pendingDelete: TodoItem?
    // 加入演出（4.3.2）。表示中の仲間の人数は、達成率の人数とは別に持ち、演出の順番で増やす。
    @State private var shownCount = 0
    @State private var celebrationTask: Task<Void, Never>?
    @State private var celebrationCount = 0
    @State private var starShowerID: UUID?
    @State private var showAssembledBanner = false

    // MARK: 集計

    private var todayTodos: [TodoItem] { allTodos.filter { $0.dateKey == today.dayKey } }
    private var completedCount: Int { todayTodos.filter(\.isCompleted).count }
    private var percent: Int? { CompletionRate.percent(completed: completedCount, total: todayTodos.count) }
    private var companionCount: Int { CompletionRate.companionCount(percent: percent) }

    private var todayProgress: DailyProgress? { progresses.first { $0.dateKey == today.dayKey } }
    private var hero: CharacterID { HeroSetting.resolve(heroRaw) }
    private var shownCompanions: [CharacterID] {
        PartyMilestones.members(lineup: todayProgress?.lineup ?? [], companionCount: shownCount)
    }

    private struct StatsKey: Equatable {
        var total: Int
        var completed: Int
    }

    private struct PartyState: Equatable {
        var companionCount: Int
        var hasLineup: Bool
    }

    private var statsKey: StatsKey { StatsKey(total: todayTodos.count, completed: completedCount) }
    private var partyState: PartyState {
        PartyState(
            companionCount: companionCount,
            hasLineup: (todayProgress?.companionLineup.count ?? 0) >= CompanionLottery.lineupSize
        )
    }

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
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    header
                    taskCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                PartyField(hero: hero, companions: shownCompanions)
                    .padding(.bottom, 4)
            }
            .overlay { effects }
            .background(AdventureBackground())
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
        .sensoryFeedback(.success, trigger: celebrationCount)
        .onChange(of: statsKey, initial: true) { _, _ in
            if let progress = todayProgress { DailyProgressService.recordSnapshot(progress, in: context) }
        }
        .onChange(of: partyState, initial: true) { _, _ in syncParty() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.dateText(today))
                    .font(.subheadline.weight(.semibold))
                Text("今日の冒険")
                    .font(.largeTitle.bold())
                Text("やることをこなして、仲間と一緒に進もう。")
                    .font(.footnote.weight(.medium))
            }
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                ProgressGauge(percent: percent)
                Text(percent == nil ? "今日の冒険は準備中" : "\(completedCount) / \(todayTodos.count) タスク完了")
                    .font(.caption.weight(.semibold))
            }
        }
        // 背景のイラストの上でも読めるよう、白い文字に影を付ける
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
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
                .scrollContentBackground(.hidden)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
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

    /// 加入演出・バナー・星の演出。操作の邪魔にならないよう、タップは通す。
    private var effects: some View {
        ZStack(alignment: .bottom) {
            if let id = starShowerID {
                StarShowerView()
                    .id(id)
                    .transition(.opacity)
            }
            if showAssembledBanner {
                AllAssembledBanner()
                    .padding(.bottom, 140)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: 加入演出

    /// 達成率に合わせて、表示する仲間の人数を更新する。
    ///
    /// - 節目（20%ごと）に初めて届いたときだけ、1人ずつ順番に加入演出を再生する（1日1回）。
    /// - 一度届いた節目は記録しておき、付け外しを繰り返しても再生しない。減るときも演出なし。
    private func syncParty() {
        celebrationTask?.cancel()
        guard let progress = todayProgress, partyState.hasLineup else {
            showImmediately(companionCount)
            return
        }
        let target = companionCount
        let fresh = PartyMilestones.newMilestones(companionCount: target, unlocked: progress.unlockedMilestones)
        guard let first = fresh.first else {
            showImmediately(target)
            return
        }
        DailyProgressService.unlock(fresh, in: progress, context: context)
        let lineup = progress.lineup
        showImmediately(min(shownCount, first - 1))

        celebrationTask = Task { @MainActor in
            for milestone in fresh {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { shownCount = milestone }
                celebrationCount += 1
                if lineup[milestone - 1] == "superstar" { playStarShower() }
                try? await Task.sleep(for: .milliseconds(550))
                if Task.isCancelled { return }
            }
            if fresh.contains(CompanionLottery.lineupSize) { await playAssembledBanner() }
        }
    }

    private func showImmediately(_ count: Int) {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) { shownCount = count }
    }

    private func playStarShower() {
        withAnimation { starShowerID = UUID() }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation { starShowerID = nil }
        }
    }

    private func playAssembledBanner() async {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showAssembledBanner = true }
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation { showAssembledBanner = false }
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
