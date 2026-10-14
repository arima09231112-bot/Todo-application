import SwiftUI
import RPGTodoCore

/// ドット絵の立ち姿（静止画1枚、80×80ドットのキャンバス）を、にじませずに表示する。
///
/// 素材名の対応（キャラID → アセット名）はここで解決し、`RPGTodoCore` には持ち込まない。
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
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityLabel(character.rawValue)
    }
}
