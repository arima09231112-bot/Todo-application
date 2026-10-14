import SwiftUI
import RPGTodoCore

/// Phase 0 の動作確認用の画面。Phase 1 でホーム画面に置き換える。
struct PlaceholderView: View {
    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 0)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("今日の冒険")
                    .font(.largeTitle.bold())
                Text("Phase 0: 準備中（全\(CharacterCatalog.all.count)キャラの表示確認）")
                    .foregroundStyle(.secondary)
                Label(
                    SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK",
                    systemImage: SharedContainer.url == nil ? "xmark.circle" : "checkmark.circle"
                )
                .foregroundStyle(SharedContainer.url == nil ? Color.red : Color.green)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(CharacterCatalog.all) { character in
                        PixelSprite(character: character.id, scale: 1)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    PlaceholderView()
}
