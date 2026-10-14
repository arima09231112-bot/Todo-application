import SwiftUI

/// 設定タブ。今は動作確認用の情報だけ。Phase 2 で勇者の見た目の選択などを追加する。
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("動作確認") {
                    Label(
                        SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK",
                        systemImage: SharedContainer.url == nil ? "xmark.circle" : "checkmark.circle"
                    )
                    .foregroundStyle(SharedContainer.url == nil ? Color.red : Color.green)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
