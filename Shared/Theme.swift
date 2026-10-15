import SwiftUI

/// 見た目の切り替え（設定タブで選ぶ。アプリとウィジェットで共有）。
///
/// - シンプル: iPhone 標準の見た目（システムのフォント・半透明のカード）。
/// - RPG: ドット風フォントと、紺色の背景に白い二重枠の「ウィンドウ」（昔の RPG のメニュー画面風）。
enum AppearanceStyle: String, CaseIterable, Identifiable, Sendable {
    case simple
    case rpg

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simple: "シンプル"
        case .rpg: "RPG"
        }
    }

    /// 保存された値から見た目を決める。未設定や不正な値はシンプル。
    static func resolve(_ raw: String?) -> AppearanceStyle {
        raw.flatMap(AppearanceStyle.init(rawValue:)) ?? .simple
    }

    /// チェック・ゲージなどの強調色。
    var accent: Color {
        switch self {
        case .simple: .blue
        case .rpg: RPGPalette.gold
        }
    }

    /// 文字の種類に合わせた書体。RPG はドット風フォントで、文字の大きさの設定（ダイナミックタイプ）に追従する。
    /// ドット風フォントは太さが1種類なので、`weight` はシンプルのときだけ効く。
    func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .simple: .system(style, weight: weight)
        case .rpg: .custom(PixelFont.name, size: PixelFont.baseSize(style), relativeTo: style)
        }
    }

    /// 大きさを直接指定する書体（ウィジェットなど、場所が限られるところ用）。
    func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        switch self {
        case .simple: .system(size: size, weight: weight, design: design)
        case .rpg: .custom(PixelFont.name, fixedSize: size)
        }
    }
}

extension EnvironmentValues {
    /// 今の見た目。アプリは `RootView`、ウィジェットは `TodoWidgetView` で設定する。
    @Entry var appearance: AppearanceStyle = .simple
}

/// ドット風フォント（DotGothic16。SIL Open Font License 1.1）。
/// 両方のターゲットの Info.plist の `UIAppFonts` で登録している（project.yml）。
enum PixelFont {
    static let name = "DotGothic16-Regular"

    /// 標準の文字の大きさ（設定が「標準」のときの、システムの各スタイルの大きさ）。
    static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        default: 17
        }
    }
}

/// RPG の見た目の色。
enum RPGPalette {
    /// ウィンドウの紺色。
    static let window = Color(red: 0.06, green: 0.09, blue: 0.29)
    /// ボタンの青（ウィンドウより少し明るい）。
    static let button = Color(red: 0.15, green: 0.27, blue: 0.64)
    /// 強調の金色。
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.29)
}

/// RPG のウィンドウ: 紺色の背景に、白い二重の枠。
struct RPGWindowBackground: View {
    var fill: Color = RPGPalette.window
    var cornerRadius: CGFloat = 10
    var opacity: Double = 0.9

    var body: some View {
        let outer = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let inner = RoundedRectangle(cornerRadius: max(cornerRadius - 4, 2), style: .continuous)
        outer
            .fill(fill.opacity(opacity))
            .overlay(outer.strokeBorder(Color.white, lineWidth: 3))
            .overlay(inner.strokeBorder(Color.white.opacity(0.8), lineWidth: 1).padding(5))
    }
}

private struct ThemedCard: ViewModifier {
    let style: AppearanceStyle
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .simple:
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .rpg:
            // ウィンドウの中は、ライト／ダークに関係なく白い文字にする
            content
                .background(RPGWindowBackground(cornerRadius: min(cornerRadius, 12)))
                .environment(\.colorScheme, .dark)
        }
    }
}

extension View {
    /// 背景のイラストの上に置くカード。シンプルは半透明、RPG はウィンドウ。
    func themedCard(_ style: AppearanceStyle, cornerRadius: CGFloat = 20) -> some View {
        modifier(ThemedCard(style: style, cornerRadius: cornerRadius))
    }
}
