import SwiftUI
import WidgetKit
import AppIntents
import RPGTodoCore

/// サイズに応じて小・中・大のレイアウトを切り替える（要件 6.7。完成イメージ準拠）。
struct TodoWidgetView: View {
    let entry: TodoWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallLayout(entry: entry)
            case .systemMedium:
                WideLayout(entry: entry, limit: 4, ringSize: 44, fullWidthParty: false, partyHeight: 44)
            default:
                WideLayout(entry: entry, limit: 8, ringSize: 76, fullWidthParty: true, partyHeight: 96)
            }
        }
        .environment(\.appearance, entry.appearance)
    }
}

private extension View {
    /// 背景の絵の上に直接置く文字（白＋影）。
    func onArt() -> some View {
        foregroundStyle(.white).shadow(color: .black.opacity(0.7), radius: 2, y: 1)
    }
}

/// 達成率の円ゲージ。
private struct WidgetRing: View {
    let fraction: Double
    let text: String
    let size: CGFloat

    @Environment(\.appearance) private var appearance

    var body: some View {
        let line = max(4, size * 0.12)
        ZStack {
            Circle().fill(appearance.gaugeDisc)
            Circle().stroke(Color.white.opacity(0.25), lineWidth: line)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(appearance.accent, style: StrokeStyle(lineWidth: line, lineCap: appearance.isRPG ? .butt : .round))
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(appearance.font(size: size * 0.27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(line)
        }
        .frame(width: size, height: size)
    }
}

private extension TodoWidgetEntry {
    var fraction: Double { total == 0 ? 0 : Double(completed) / Double(total) }
    var partyText: String { "仲間 \(companionCount)/\(CompanionLottery.lineupSize)" }
}

/// 日付と「今日の冒険」。
private struct TitleBlock: View {
    let entry: TodoWidgetEntry
    let titleSize: CGFloat

    @Environment(\.appearance) private var appearance

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(entry.date, format: .dateTime.month().day().weekday(.abbreviated))
                .font(appearance.font(.caption2, weight: .bold))
            Text("今日の冒険")
                .font(appearance.font(size: titleSize, weight: .heavy))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .onArt()
    }
}

/// 達成率の円ゲージと、完了数・仲間の人数。
private struct StatsBlock: View {
    let entry: TodoWidgetEntry
    let ringSize: CGFloat

    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 6) {
            WidgetRing(fraction: entry.fraction, text: entry.percentText, size: ringSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.countText).font(appearance.font(.caption2, weight: .bold))
                Label(entry.partyText, systemImage: "person.3.fill").font(appearance.font(.caption2, weight: .bold))
            }
            .onArt()
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
    }
}

/// 小: 見出し・円ゲージ・完了数と仲間の人数・パーティ。
private struct SmallLayout: View {
    let entry: TodoWidgetEntry

    @Environment(\.appearance) private var appearance

    var body: some View {
        VStack(spacing: 2) {
            Text("今日の冒険").font(appearance.font(size: 17, weight: .heavy)).onArt()
            WidgetRing(fraction: entry.fraction, text: entry.percentText, size: 50)
            Text("\(entry.total == 0 ? "準備中" : "\(entry.completed)/\(entry.total) 達成") ・ \(entry.partyText)")
                .font(appearance.font(size: 10, weight: .bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .onArt()
            Spacer(minLength: 0)
            PartyField(hero: entry.hero, companions: entry.companions, height: 40)
        }
    }
}

/// 中・大: 左に見出し・ゲージ・パーティ、右に「今日のクエスト」カード（完成イメージ準拠）。
/// 大は、パーティを下いっぱいに広げる。
private struct WideLayout: View {
    let entry: TodoWidgetEntry
    let limit: Int
    let ringSize: CGFloat
    let fullWidthParty: Bool
    let partyHeight: CGFloat

    var body: some View {
        if fullWidthParty {
            VStack(spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        TitleBlock(entry: entry, titleSize: 24)
                        StatsBlock(entry: entry, ringSize: ringSize)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    TaskCard(entry: entry, limit: limit)
                        .frame(maxWidth: .infinity)
                }
                PartyField(hero: entry.hero, companions: entry.companions, height: partyHeight)
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    TitleBlock(entry: entry, titleSize: 19)
                    StatsBlock(entry: entry, ringSize: ringSize)
                    Spacer(minLength: 0)
                    PartyField(hero: entry.hero, companions: entry.companions, height: partyHeight)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TaskCard(entry: entry, limit: limit)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

/// 「今日のクエスト」のカード。シンプルは半透明、RPG はウィンドウ。
private struct TaskCard: View {
    let entry: TodoWidgetEntry
    let limit: Int

    @Environment(\.appearance) private var appearance

    var body: some View {
        let (shown, hidden) = entry.visibleTodos(limit: limit)
        VStack(alignment: .leading, spacing: 4) {
            Text("今日のクエスト").font(appearance.font(.caption, weight: .bold))
            if let message = entry.errorMessage {
                Text(message).font(.system(size: 9)).foregroundStyle(.secondary)
            } else if shown.isEmpty {
                Text("今日の冒険は準備中").font(appearance.font(.caption)).foregroundStyle(.secondary)
            } else {
                ForEach(shown) { TodoLine(todo: $0) }
                if hidden > 0 {
                    Text("ほか \(hidden) 件").font(appearance.font(.caption2)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(appearance.isRPG ? 11 : 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .themedCard(appearance, cornerRadius: 14)
    }
}

/// Todo 1行。チェックだけがボタン（アプリを開かずに完了を切り替える）。それ以外をタップするとアプリが開く。
private struct TodoLine: View {
    let todo: WidgetTodo

    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(spacing: 5) {
            Button(intent: ToggleTodoIntent(todoID: todo.id.uuidString)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(todo.isCompleted ? AnyShapeStyle(appearance.cardAccent) : appearance.inkSecondary)
            }
            .buttonStyle(.plain)

            Text(todo.title)
                .font(appearance.font(.caption))
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? appearance.inkSecondary : appearance.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}
