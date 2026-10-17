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
