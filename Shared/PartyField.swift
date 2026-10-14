import SwiftUI
import RPGTodoCore

/// 冒険の背景（草原・湖・森の縦長イラスト）。画面全体に敷き、下端（キャラが立つ道）を画面下にそろえる。
struct AdventureBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// ダークモードで背景を暗くする量（夜の背景ができるまでの代わり。要件 F-08）。
    static let nightDimming = 0.45

    var body: some View {
        GeometryReader { geometry in
            Image("Backgrounds/home_day")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                .clipped()
                .overlay(Color.black.opacity(colorScheme == .dark ? Self.nightDimming : 0))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// 冒険フィールドのパーティ: 勇者を先頭にして横一列に立つ（要件 4.3.5）。背景は `AdventureBackground`。
struct PartyField: View {
    let hero: CharacterID
    let companions: [CharacterID]

    /// 6人並んだときに画面の幅に収まるよう、キャラの大きさと間隔を幅から決める。
    /// 素材のキャンバスには左右に余白があるので、隣と少し重ねて並べる。
    private static func layout(width: CGFloat) -> (size: CGFloat, spacing: CGFloat) {
        let size = min(110, width / 4.2)
        let spacing = (width - 8 - 6 * size) / 5
        return (size, spacing)
    }

    var body: some View {
        GeometryReader { geometry in
            let (size, spacing) = Self.layout(width: geometry.size.width)
            HStack(spacing: spacing) {
                ForEach(Array(([hero] + companions).enumerated()), id: \.offset) { _, character in
                    PixelSprite(character: character, size: size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
        }
        .frame(height: 96)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(companions.isEmpty ? "勇者" : "勇者と仲間\(companions.count)人")
    }
}
