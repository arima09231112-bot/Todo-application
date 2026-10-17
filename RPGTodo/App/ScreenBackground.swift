import SwiftUI

extension View {
    /// ホーム以外の画面にも冒険の背景（ライトは昼・ダークは夜）を敷く。
    /// リスト・フォームの標準の背景を消し、上に薄い膜を重ねて、見出しや説明の文字を読みやすくする。
    /// 行やカードは標準の色のまま（文字が読みやすい）。文字を背景の上に直接置く画面は `scrim` を濃くする。
    func adventureScreenBackground(scrim: Double = 0.45) -> some View {
        scrollContentBackground(.hidden)
            .background {
                AdventureBackground()
                    .overlay {
                        Color(.systemGroupedBackground)
                            .opacity(scrim)
                            .ignoresSafeArea()
                    }
            }
    }
}

extension View {
    /// 入力画面向け。冒険の背景をすりガラス越しに見せる（絵はぼかして色だけ残す）。
    /// 背景の細かい模様が文字に重ならないので、見出しやプレースホルダーが読みやすい。
    /// 行にも `frostedRow()` を付けると、全体がガラスの板のような見た目になる。
    func frostedScreenBackground() -> some View {
        scrollContentBackground(.hidden)
            .background {
                AdventureBackground()
                    .overlay {
                        Rectangle()
                            .fill(.regularMaterial)
                            .ignoresSafeArea()
                    }
            }
    }

    /// すりガラスの背景の上に置く行。標準の不透明な行の代わりに、明るめのガラス板にする。
    /// RPG の見た目では、行の文字色（白・こげ茶）が読めるよう、ホームのカードと同じ色をガラスに重ねる。
    func frostedRow(_ appearance: AppearanceStyle = .simple) -> some View {
        listRowBackground(FrostedRowBackground(appearance: appearance))
    }
}

private struct FrostedRowBackground: View {
    let appearance: AppearanceStyle

    var body: some View {
        ZStack {
            Rectangle().fill(.thinMaterial)
            switch appearance {
            case .simple: EmptyView()
            case .rpg: RPGPalette.window.opacity(0.8)
            case .rpgWood: RPGPalette.woodPanel.opacity(0.9)
            }
        }
    }
}
