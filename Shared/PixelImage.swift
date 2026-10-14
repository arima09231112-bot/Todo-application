import SwiftUI
import RPGTodoCore

/// キャラの立ち姿（静止画1枚）。素材はドット絵風のイラストを元の解像度のまま切り出したもの（256×256px）。
///
/// キャンバスの大きさの基準は 80pt（素材のドット 80 個分）。素材名の対応（キャラID → アセット名）は
/// ここで解決し、`RPGTodoCore` には持ち込まない。
struct PixelSprite: View {
    let character: CharacterID
    /// キャンバス1辺の表示サイズ（pt）。
    var size: CGFloat

    static let canvas: CGFloat = 80

    init(character: CharacterID, scale: Int = 3) {
        self.character = character
        self.size = Self.canvas * CGFloat(scale)
    }

    init(character: CharacterID, size: CGFloat) {
        self.character = character
        self.size = size
    }

    var body: some View {
        Image("Characters/\(character.rawValue)")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityLabel(character.rawValue)
    }
}
