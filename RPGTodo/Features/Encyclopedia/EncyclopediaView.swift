import SwiftUI
import SwiftData
import RPGTodoCore

/// キャラクター図鑑（要件 6.6）: 今日の目標・発見数・勇者・仲間たちの一覧。
struct EncyclopediaView: View {
    let today: LocalDate

    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [DailyProgress]
    @Query private var allTodos: [TodoItem]
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue
    @State private var selected: GameCharacter?

    private var discoveries: [CharacterID: Discovery] { AdventureLog.discoveries(progresses) }
    private var todayProgress: DailyProgress? { progresses.first { $0.dateKey == today.dayKey } }
    private var todayMembers: Set<CharacterID> { Set(todayProgress?.currentMembers ?? []) }
    private var todayTodos: [TodoItem] { allTodos.filter { $0.dateKey == today.dayKey } }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        let found = discoveries
        let pool = CharacterCatalog.companionPool
        let foundCount = pool.filter { found[$0.id] != nil }.count

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalCard

                    sectionTitle("勇者")
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(CharacterCatalog.heroes) { hero in
                            card(hero, isFound: true, badge: HeroSetting.resolve(heroRaw) == hero.id ? "いま" : nil)
                        }
                    }

                    HStack(alignment: .firstTextBaseline) {
                        sectionTitle("仲間たち")
                        Spacer()
                        if foundCount == pool.count {
                            Label("コンプリート！", systemImage: "crown.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.orange)
                        } else {
                            Text("発見 \(foundCount) / \(pool.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(pool) { character in
                            card(
                                character,
                                isFound: found[character.id] != nil,
                                badge: todayMembers.contains(character.id) ? "今日" : nil
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("キャラクター図鑑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .sheet(item: $selected) { character in
            CharacterDetailView(
                character: character,
                discovery: found[character.id],
                isFound: character.kind == .hero || found[character.id] != nil
            )
        }
    }

    // MARK: 今日の目標

    private var goalCard: some View {
        let total = todayTodos.count
        let completed = todayTodos.filter(\.isCompleted).count
        let count = CompletionRate.companionCount(percent: CompletionRate.percent(completed: completed, total: total))
        let remaining = CompletionRate.tasksUntilNextCompanion(completed: completed, total: total)
        let message: String = if total == 0 {
            "まずは今日のタスクを追加しよう"
        } else if let remaining {
            "あと\(remaining)件で新しい仲間が加わる（誰かはお楽しみ）"
        } else {
            "全員集合！ 今日のパーティは満員です"
        }

        return VStack(alignment: .leading, spacing: 8) {
            Label("今日の目標", systemImage: "flag.checkered").font(.headline)
            Text("達成率 100% で、全員集合！").font(.subheadline)
            ProgressView(value: Double(count), total: Double(CompanionLottery.lineupSize)) {
                Text(message).font(.subheadline.bold())
            } currentValueLabel: {
                Text("仲間 \(count) / \(CompanionLottery.lineupSize)")
            }
            .tint(count == CompanionLottery.lineupSize ? .green : .blue)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: カード

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.title3.bold())
    }

    private func card(_ character: GameCharacter, isFound: Bool, badge: String?) -> some View {
        Button { selected = character } label: {
            VStack(spacing: 4) {
                PixelSprite(character: character.id, size: 76, silhouette: !isFound)
                Text(isFound ? character.name : "？？？")
                    .font(.caption.bold())
                    .lineLimit(1)
                Text(isFound ? character.displayName : character.kind.rarityLabel)
                    .font(.caption2)
                    .foregroundStyle(isFound ? Color.secondary : character.kind.rarityColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Text(badge)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue, in: Capsule())
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFound ? "\(character.name)、\(character.displayName)" : "未発見、\(character.kind.rarityLabel)")
    }
}

/// キャラの詳細: 大きな絵・名前・二つ名・ひとこと・紹介文・出会った記録。未発見ならヒントだけ。
struct CharacterDetailView: View {
    let character: GameCharacter
    let discovery: Discovery?
    let isFound: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    PixelSprite(character: character.id, size: 200, silhouette: !isFound)

                    if isFound {
                        VStack(spacing: 2) {
                            Text(character.title).font(.subheadline).foregroundStyle(.secondary)
                            Text(character.name).font(.title.bold())
                            Text(character.displayName).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Text("「\(character.quote)」")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        Text(character.profile)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        records
                    } else {
                        Text("？？？").font(.title.bold())
                        Text(character.kind.rarityLabel)
                            .font(.subheadline.bold())
                            .foregroundStyle(character.kind.rarityColor)
                        Text(character.hint)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text("仲間は毎日ランダムに集まります。いつか出会えるかも。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var records: some View {
        if character.kind == .hero {
            Label("いつもパーティの先頭にいる", systemImage: "shield.lefthalf.filled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if let discovery {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("初めて仲間になった日").foregroundStyle(.secondary)
                    Text(discovery.firstDate.longText)
                }
                GridRow {
                    Text("仲間になった日数").foregroundStyle(.secondary)
                    Text("\(discovery.days)日")
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
