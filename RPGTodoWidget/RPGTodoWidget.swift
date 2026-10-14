import SwiftUI
import WidgetKit
import RPGTodoCore

/// Phase 0 の動作確認用ウィジェット。Phase 3 で本実装に置き換える。
struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { PlaceholderEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}

struct RPGTodoWidgetView: View {
    var entry: PlaceholderEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("今日の冒険").font(.headline)
            PixelSprite(character: CharacterCatalog.defaultHeroID, scale: 1)
            Text(SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct RPGTodoWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RPGTodoWidget", provider: PlaceholderProvider()) { entry in
            RPGTodoWidgetView(entry: entry)
        }
        .configurationDisplayName("今日の冒険")
        .description("今日のTodoの達成率とパーティを表示します。")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct RPGTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        RPGTodoWidget()
    }
}
