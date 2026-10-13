import SwiftUI
import RPGTodoCore

/// ドット絵スプライトを、にじませずに整数倍で表示する。
///
/// 素材名の対応（キャラID → アセット名）はここで解決し、`RPGTodoCore` には持ち込まない。
struct PixelSprite: View {
    let character: CharacterID
    var frame: Int = 0
    var scale: Int = 3

    private static let canvas = 48

    var body: some View {
        Image("Characters/\(character.rawValue)_right_\(frame % 4)")
            .interpolation(.none)
            .resizable()
            .frame(width: CGFloat(Self.canvas * scale), height: CGFloat(Self.canvas * scale))
            .accessibilityLabel(character.rawValue)
    }
}
