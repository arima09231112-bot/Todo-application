import SwiftUI
import RPGTodoCore

/// 冒険フィールドの配色。ホーム画面の背景のグラデーションも、フィールドの空の色に合わせる。
enum FieldPalette {
    /// フィールド画像の一番上の空の色。
    static let sky = Color(red: 65 / 255, green: 169 / 255, blue: 251 / 255)
    /// フィールド画像の下端より下（タブバーの裏）を埋める草の色。
    static let grass = Color(red: 91 / 255, green: 156 / 255, blue: 88 / 255)
    /// ダークモードで背景を暗くする量（MVP は昼の背景を暗めに補正して使う。要件 F-08）。
    static let nightDimming = 0.4
}

/// 冒険フィールド: 草原と森の背景に、勇者を先頭にしてパーティが横一列に立つ（要件 4.3.5）。
struct PartyField: View {
    let hero: CharacterID
    let companions: [CharacterID]

    @Environment(\.colorScheme) private var colorScheme

    /// 背景画像（331×110 ドット）の縦横比。
    private static let aspect: CGFloat = 331 / 110
    /// キャラ1体の表示サイズ（80ドットのキャンバスを 0.75 倍）。6体並べても幅 375pt の画面に収まる。
    private static let spriteSize: CGFloat = 60

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(([hero] + companions).enumerated()), id: \.offset) { _, character in
                PixelSprite(character: character, size: Self.spriteSize)
            }
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .aspectRatio(Self.aspect, contentMode: .fit)
        .background(alignment: .top) {
            // 画像は幅に合わせて固定し、下（タブバーの裏）は草の色で埋める
            VStack(spacing: 0) {
                Image("Backgrounds/field_day")
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(Self.aspect, contentMode: .fit)
                FieldPalette.grass
            }
            .overlay(Color.black.opacity(colorScheme == .dark ? FieldPalette.nightDimming : 0))
            .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(companions.isEmpty ? "勇者" : "勇者と仲間\(companions.count)人")
    }
}

/// ホーム画面の背景: 上の白（ダーク時は黒）から、フィールドの空の青へのグラデーション。
struct FieldSkyBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                FieldPalette.sky.opacity(colorScheme == .dark ? 1 - FieldPalette.nightDimming : 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}
