import SwiftUI
import RPGTodoCore

/// Phase 0 の動作確認用の画面。Phase 1 でホーム画面に置き換える。
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("今日の冒険")
                .font(.largeTitle.bold())
            HStack(spacing: -8) {
                ForEach(CharacterID.allCases, id: \.self) { character in
                    PixelSprite(character: character, scale: 1)
                }
            }
            Text("Phase 0: 準備中")
                .foregroundStyle(.secondary)
            Label(
                SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK",
                systemImage: SharedContainer.url == nil ? "xmark.circle" : "checkmark.circle"
            )
            .foregroundStyle(SharedContainer.url == nil ? Color.red : Color.green)
        }
        .padding()
    }
}

#Preview {
    PlaceholderView()
}
