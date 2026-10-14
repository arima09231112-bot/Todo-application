import SwiftUI
import RPGTodoCore

/// 冒険の背景（草原・湖・森の縦長イラスト）。画面全体に敷き、下端（キャラが立つ道）を画面下にそろえる。
/// ライトモードは昼、ダークモードは夜の絵（同じ構図。要件 F-08）。
struct AdventureBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// ウィジェットは画像の大きさに上限があるため、縮小版（`widget_*`）を使う。
    var isWidget = false

    private var imageName: String {
        "Backgrounds/\(isWidget ? "widget" : "home")_\(colorScheme == .dark ? "night" : "day")"
    }

    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// 冒険フィールドのパーティ: 勇者を先頭にして横一列に立つ（要件 4.3.5）。背景は `AdventureBackground`。
///
/// 仲間が増える・減るときの動き（加入演出）は、呼び出し側の `withAnimation` で決まる。
/// アニメーションなしで人数を変えれば、演出なしで入れ替わる。
struct PartyField: View {
    let hero: CharacterID
    let companions: [CharacterID]
    /// 表示の高さ。ウィジェットの小サイズなど、狭い場所では小さくする。
    var height: CGFloat = 96

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 6人並んだときに画面の幅に収まるよう、キャラの大きさと間隔を幅から決める。
    /// 素材のキャンバスには左右に余白があるので、隣と少し重ねて並べる。
    /// 人数が少ないときも、各キャラの位置は変わらない（左から並ぶ）。
    private static func layout(width: CGFloat) -> (size: CGFloat, spacing: CGFloat) {
        let size = min(110, width / 4.2)
        let spacing = (width - 8 - 6 * size) / 5
        return (size, spacing)
    }

    /// 加入: 上からぽんと弾んで現れる（「視差効果を減らす」ではフェードのみ）。減少: フェードアウト。
    private var joinTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity)
    }

    var body: some View {
        GeometryReader { geometry in
            let (size, spacing) = Self.layout(width: geometry.size.width)
            HStack(spacing: spacing) {
                PixelSprite(character: hero, size: size)
                ForEach(companions, id: \.self) { character in
                    PixelSprite(character: character, size: size)
                        .transition(joinTransition)
                }
            }
            .padding(.leading, 4)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(companions.isEmpty ? "勇者" : "勇者と仲間\(companions.count)人")
    }
}
