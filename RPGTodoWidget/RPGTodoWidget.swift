import SwiftUI
import WidgetKit
import AppIntents
import RPGTodoCore

/// 設定項目のないウィジェット用の空の設定（`AppIntentTimelineProvider` を使うために必要）。
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "今日の冒険"
}

struct TodoWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodoWidgetEntry { .sample }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TodoWidgetEntry {
        if context.isPreview { return .sample }
        return await MainActor.run { WidgetDataLoader.load() }
    }

    /// 今の内容を1つ返し、次の 0:00 に作り直す（新しい日の Todo・仲間に切り替わる。要件 W-06）。
    /// アプリや、ウィジェットのチェック操作のあとは、そちらから更新を要求する。
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TodoWidgetEntry> {
        let entry = await MainActor.run { WidgetDataLoader.load() }
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

struct RPGTodoWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RPGTodoWidget", intent: ConfigurationAppIntent.self, provider: TodoWidgetProvider()) { entry in
            TodoWidgetView(entry: entry)
                .containerBackground(for: .widget) { AdventureBackground(imageName: "Backgrounds/widget_day") }
        }
        .configurationDisplayName("今日の冒険")
        .description("今日のTodoの達成率とパーティを表示します。チェックをタップすると完了にできます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct RPGTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        RPGTodoWidget()
    }
}
