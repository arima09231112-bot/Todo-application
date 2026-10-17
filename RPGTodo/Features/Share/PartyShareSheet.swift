import SwiftUI
import SwiftData
import RPGTodoCore

/// シェア画像の形。
enum ShareImageFormat: String, CaseIterable, Identifiable {
    /// 投稿向け（1:1）。
    case square
    /// ストーリー向け（9:16）。
    case story

    var id: String { rawValue }

    var label: String {
        switch self {
        case .square: "正方形"
        case .story: "縦長"
        }
    }

    /// 画像の大きさ（pt）。3倍で書き出すので 1080px 幅になる。
    var size: CGSize {
        switch self {
        case .square: CGSize(width: 360, height: 360)
        case .story: CGSize(width: 360, height: 640)
        }
    }
}

/// その日のパーティを1枚の画像にして、共有シートで X・Instagram・LINE などに送る（docs/ideas.md 9）。
/// クエストの中身は、初期設定では画像に載せない（個人的な予定が写らないように）。
struct PartyShareSheet: View {
    let date: LocalDate

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearance) private var appearance
    @Query private var progresses: [DailyProgress]
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue
    @AppStorage("share.format") private var format = ShareImageFormat.square
    @AppStorage("share.includeQuests") private var includeQuests = false
    @State private var rendered: Image?

    private var card: PartyShareCard {
        let todos = TodoOrdering.sorted(
            allTodos.filter { $0.dateKey == date.dayKey }, minutes: { $0.timeMinutes }, createdAt: { $0.createdAt }
        )
        let completed = todos.filter(\.isCompleted)
        return PartyShareCard(
            date: date,
            percent: CompletionRate.percent(completed: completed.count, total: todos.count),
            completedCount: completed.count,
            totalCount: todos.count,
            hero: HeroSetting.resolve(heroRaw),
            companions: progresses.first { $0.dateKey == date.dayKey }?.currentMembers ?? [],
            questTitles: includeQuests ? completed.map(\.title) : [],
            format: format
        )
    }

    private var shareMessage: String {
        card.percent == 100 ? "冒険のパーティ、全員集合！ #DailyQuest" : "冒険の記録 #DailyQuest"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("形", selection: $format) {
                    ForEach(ShareImageFormat.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Toggle("達成したクエスト名を載せる", isOn: $includeQuests)

                card
                    .environment(\.appearance, appearance)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                    .scaleEffect(format == .story ? 0.62 : 0.85)
                    // 見本はタップしない。背景の絵は枠の外まで（切り取られて見えない部分も）タップを受けてしまい、
                    // 上の「形」や「クエスト名を載せる」が押せなくなるため、タップを素通りさせる。
                    .allowsHitTesting(false)
                    .frame(
                        width: format.size.width * (format == .story ? 0.62 : 0.85),
                        height: format.size.height * (format == .story ? 0.62 : 0.85)
                    )
                    .frame(maxHeight: .infinity)

                if let rendered {
                    ShareLink(item: rendered, message: Text(shareMessage), preview: SharePreview("今日のパーティ", image: rendered)) {
                        Label("シェアする", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("パーティをシェア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .task(id: RenderKey(format: format, includeQuests: includeQuests, total: card.totalCount, completed: card.completedCount)) {
            render()
        }
    }

    private struct RenderKey: Equatable {
        var format: ShareImageFormat
        var includeQuests: Bool
        var total: Int
        var completed: Int
    }

    private func render() {
        let renderer = ImageRenderer(content: card.environment(\.appearance, appearance))
        renderer.scale = 3
        rendered = renderer.uiImage.map { Image(uiImage: $0) }
    }
}

/// シェア画像の中身: 冒険の背景に、日付・達成率・パーティ・アプリ名。
struct PartyShareCard: View {
    let date: LocalDate
    let percent: Int?
    let completedCount: Int
    let totalCount: Int
    let hero: CharacterID
    let companions: [CharacterID]
    /// 載せるクエスト名（載せないときは空）。
    let questTitles: [String]
    let format: ShareImageFormat

    @Environment(\.appearance) private var appearance

    private var isAllAssembled: Bool { percent == 100 }
    private var hasSuperstar: Bool { companions.contains { CharacterCatalog.character($0)?.kind == .superstar } }
    private var maxQuests: Int { format == .story ? 8 : 3 }

    var body: some View {
        ZStack {
            AdventureBackground()

            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text(Self.dateText(date))
                        .font(appearance.font(size: 15, weight: .semibold))
                    Text(percent.map { "\($0)%" } ?? "—")
                        .font(appearance.font(size: 52, weight: .heavy, design: .rounded))
                    Text(totalCount == 0 ? "今日の冒険は準備中" : "\(completedCount) / \(totalCount) クエスト達成")
                        .font(appearance.font(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 3, y: 1)

                if isAllAssembled {
                    AllAssembledBanner()
                        .scaleEffect(0.8)
                }

                if !questTitles.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(questTitles.prefix(maxQuests).enumerated()), id: \.offset) { _, title in
                            Label(title, systemImage: "checkmark.circle.fill")
                                .lineLimit(1)
                        }
                        if questTitles.count > maxQuests {
                            Text("ほか \(questTitles.count - maxQuests) 件")
                        }
                    }
                    .font(appearance.font(size: 13))
                    .foregroundStyle(appearance.ink)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .themedCard(appearance, cornerRadius: 10)
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 0)

                if !companions.isEmpty {
                    Text(companions.compactMap { CharacterCatalog.character($0)?.name }.joined(separator: "・"))
                        .font(appearance.font(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 12)
                }
                PartyField(hero: hero, companions: companions, height: 90)
                    .frame(height: 90)

                Text("Daily Quest")
                    .font(appearance.font(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                    .padding(.bottom, 8)
            }
            .padding(.top, format == .story ? 48 : 16)

            if hasSuperstar {
                // スーパースターがいる日は星の飾り
                ForEach(Self.starPositions.indices, id: \.self) { i in
                    let point = Self.starPositions[i]
                    Image(systemName: "sparkle")
                        .font(.system(size: i.isMultiple(of: 2) ? 18 : 12))
                        .foregroundStyle(.yellow)
                        .shadow(color: .orange.opacity(0.7), radius: 3)
                        .position(x: point.x * format.size.width, y: point.y * format.size.height)
                }
            }
        }
        .frame(width: format.size.width, height: format.size.height)
    }

    private static let starPositions: [CGPoint] = [
        CGPoint(x: 0.1, y: 0.08), CGPoint(x: 0.88, y: 0.1), CGPoint(x: 0.18, y: 0.3),
        CGPoint(x: 0.82, y: 0.34), CGPoint(x: 0.06, y: 0.55), CGPoint(x: 0.94, y: 0.6),
    ]

    private static func dateText(_ date: LocalDate) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.setLocalizedDateFormatFromTemplate("yMMMMdEEE")
        return formatter.string(from: date.date())
    }
}
