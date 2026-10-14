import SwiftUI
import SwiftData
import EventKit
import UIKit
import RPGTodoCore

enum AppTab: Hashable {
    case home, calendar, records, settings
}

/// 4タブ（ホーム / カレンダー / 記録 / 設定）と、日付変更の検知。
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var today = LocalDate(.now)
    @State private var selection = AppTab.home
    @State private var calendar = CalendarStore()

    var body: some View {
        TabView(selection: $selection) {
            Tab("ホーム", systemImage: "house.fill", value: AppTab.home) {
                HomeView(today: today, onOpenCalendar: { selection = .calendar })
            }
            Tab("カレンダー", systemImage: "calendar", value: AppTab.calendar) {
                CalendarView(today: today)
            }
            Tab("記録", systemImage: "chart.bar.fill", value: AppTab.records) {
                ComingSoonView(title: "冒険の記録", message: "過去の達成率や図鑑は Phase 5 で追加します。")
            }
            Tab("設定", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tint(.blue)
        .environment(calendar)
        .task {
            refreshDay()
            calendar.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshDay()
                calendar.refresh()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            calendar.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            refreshDay()
        }
    }

    /// 日付変更の処理（要件 D-02〜D-05）。何度呼んでも結果は同じ（二重に作らない・引き直さない）。
    /// ①前日までの記録を確定 → ②（ストリークは P1）→ ③今日の繰り返し Todo を生成 → ④今日の仲間を抽選
    private func refreshDay() {
        let now = LocalDate(.now)
        today = now
        DailyProgressService.finalizePastDays(before: now, in: context)
        TodoService.generateRecurringTodos(through: now, in: context)
        DailyProgressService.prepareToday(now, in: context)
    }
}
