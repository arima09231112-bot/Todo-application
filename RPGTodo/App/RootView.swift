import SwiftUI
import SwiftData
import UIKit
import RPGTodoCore

/// 4タブ（ホーム / カレンダー / 記録 / 設定）と、日付変更の検知。
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var today = LocalDate(.now)

    var body: some View {
        TabView {
            Tab("ホーム", systemImage: "house.fill") {
                HomeView(today: today)
            }
            Tab("カレンダー", systemImage: "calendar") {
                ComingSoonView(title: "カレンダー", message: "予定からTodo候補を作る機能は Phase 4 で追加します。")
            }
            Tab("記録", systemImage: "chart.bar.fill") {
                ComingSoonView(title: "冒険の記録", message: "過去の達成率や図鑑は Phase 5 で追加します。")
            }
            Tab("設定", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        .tint(.blue)
        .task { refreshDay() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshDay() }
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
