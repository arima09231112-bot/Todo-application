import SwiftUI
import RPGTodoCore

/// ドット絵の立ち姿（静止画1枚、80×80ドットのキャンバス）を、にじませずに整数倍で表示する。
///
/// 素材名の対応（キャラID → アセット名）はここで解決し、`RPGTodoCore` には持ち込まない。
struct PixelSprite: View {
    let character: CharacterID
    var scale: Int = 3

    private static let canvas = 80

    var body: some View {
        Image("Characters/\(character.rawValue)")
            .interpolation(.none)
            .resizable()
            .frame(width: CGFloat(Self.canvas * scale), height: CGFloat(Self.canvas * scale))
            .accessibilityLabel(character.rawValue)
    }
}
