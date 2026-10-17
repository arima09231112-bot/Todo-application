import SwiftUI

/// 見た目の切り替え（設定タブで選ぶ。アプリとウィジェットで共有）。
///
/// - シンプル: iPhone 標準の見た目（システムのフォント・半透明のカード）。
/// - RPG（青）: ドット風フォントと、紺色に白い二重枠の「ウィンドウ」（昔の RPG のメニュー画面風）。
/// - RPG（木）: ドット風フォントと、木の掲示板。
///
/// 保存する文字列（`rawValue`）は変えないこと。変えると、いま選んでいる見た目が初期値に戻る。
enum AppearanceStyle: String, CaseIterable, Identifiable, Sendable {
    case simple
    case rpg
    case rpgWood

    var id: Self { self }

    var displayName: String {
        switch self {
        case .simple: "シンプル"
        case .rpg: "RPG 青"
        case .rpgWood: "RPG 木"
        }
    }

    /// ドット風フォントと枠付きのカードを使う見た目か（青・木に共通）。
    var isRPG: Bool { self != .simple }

    /// 保存された値から見た目を決める。未設定や不正な値はシンプル。
    static func resolve(_ raw: String?) -> AppearanceStyle {
        raw.flatMap(AppearanceStyle.init(rawValue:)) ?? .simple
    }

    /// 背景のイラストの上（ゲージなど、濃い色の上）で使う強調色。
    var accent: Color {
        switch self {
        case .simple: .blue
        case .rpg, .rpgWood: RPGPalette.gold
        }
    }

    /// カードの中で使う強調色（チェックなど）。木は薄い板の上なので、金色ではなく濃い緑にする。
    var cardAccent: Color {
        switch self {
        case .simple: .blue
        case .rpg: RPGPalette.gold
        case .rpgWood: RPGPalette.leaf
        }
    }

    /// カードの中の文字色。
    /// シンプルは Color ではなく階層スタイル（.primary）にする。Color.secondary に取り消し線を付けると、
    /// 半透明のカードの上で文字が消えることがあるため。
    var ink: AnyShapeStyle {
        switch self {
        case .simple: AnyShapeStyle(.primary)
        case .rpg: AnyShapeStyle(Color.white)
        case .rpgWood: AnyShapeStyle(RPGPalette.ink)
        }
    }

    /// カードの中の、控えめな文字色（補足や完了済みの文字）。
    var inkSecondary: AnyShapeStyle {
        switch self {
        case .simple: AnyShapeStyle(.secondary)
        case .rpg: AnyShapeStyle(Color.white.opacity(0.7))
        case .rpgWood: AnyShapeStyle(RPGPalette.ink.opacity(0.72))
        }
    }

    /// RPG のカードの中の区切り線の色（シンプルはシステムの既定）。
    var separatorTint: Color? {
        switch self {
        case .simple: nil
        case .rpg: Color.white.opacity(0.3)
        case .rpgWood: RPGPalette.ink.opacity(0.3)
        }
    }

    /// 達成率ゲージの、円の中の色。
    var gaugeDisc: Color {
        switch self {
        case .simple: Color.black.opacity(0.35)
        case .rpg: RPGPalette.window.opacity(0.85)
        case .rpgWood: RPGPalette.woodEdge.opacity(0.85)
        }
    }

    /// 文字の種類に合わせた書体。RPG はドット風フォントで、文字の大きさの設定（ダイナミックタイプ）に追従する。
    /// ドット風フォントは太さが1種類なので、`weight` はシンプルのときだけ効く。
    func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .simple: .system(style, weight: weight)
        case .rpg, .rpgWood: .custom(PixelFont.name, size: PixelFont.baseSize(style), relativeTo: style)
        }
    }

    /// 大きさを直接指定する書体（ウィジェットなど、場所が限られるところ用）。
    func font(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        switch self {
        case .simple: .system(size: size, weight: weight, design: design)
        case .rpg, .rpgWood: .custom(PixelFont.name, fixedSize: size)
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
    // MARK: 青（RPG のメニュー画面風）
    /// ウィンドウの紺色。
    static let window = Color(red: 0.06, green: 0.09, blue: 0.29)
    /// ボタンの青（ウィンドウより少し明るい）。
    static let button = Color(red: 0.15, green: 0.27, blue: 0.64)

    // MARK: 木（掲示板）
    /// 枠の木（濃い茶）。
    static let woodFrame = Color(red: 0.44, green: 0.27, blue: 0.13)
    /// 枠のふち（いちばん濃い輪郭）。
    static let woodEdge = Color(red: 0.24, green: 0.13, blue: 0.05)
    /// 中の板の木（上側）。
    static let woodPanel = Color(red: 0.93, green: 0.83, blue: 0.64)
    /// 中の板の木（下側。少しだけ濃くして板の厚みを出す）。
    static let woodPanelShade = Color(red: 0.87, green: 0.74, blue: 0.54)
    /// 板に書いた文字の色（濃い茶）。
    static let ink = Color(red: 0.25, green: 0.14, blue: 0.06)
    /// 木の板の上で使うチェックの色（濃い緑）。
    static let leaf = Color(red: 0.16, green: 0.40, blue: 0.18)

    // MARK: 共通
    /// 強調の金色。
    static let gold = Color(red: 1.0, green: 0.82, blue: 0.29)
}

/// RPG（青）のウィンドウ: 紺色の背景に、白い二重の枠。背景のイラストが少し透ける。
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

/// RPG（木）の掲示板: 濃い茶の木枠の中に、薄い木の板。青と同じく背景のイラストが少し透ける。
struct RPGWoodBoardBackground: View {
    var cornerRadius: CGFloat = 10
    /// 板の透け具合（1 で透けない）。青のウィンドウと同じくらい背景が見えるようにする。
    var opacity: Double = 0.64

    var body: some View {
        let outer = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let frameWidth = max(cornerRadius * 0.45, 6)
        let inner = RoundedRectangle(cornerRadius: max(cornerRadius - frameWidth * 0.6, 3), style: .continuous)
        outer
            // 枠の木（上が明るく下が暗い＝木の厚みに見える）
            .fill(
                LinearGradient(
                    colors: [RPGPalette.woodFrame, RPGPalette.woodEdge],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(min(opacity + 0.16, 1))
            )
            .overlay(outer.strokeBorder(RPGPalette.woodEdge.opacity(0.9), lineWidth: 2))
            .overlay {
                inner
                    .fill(
                        LinearGradient(
                            colors: [RPGPalette.woodPanel, RPGPalette.woodPanelShade],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(opacity)
                    )
                    .overlay(inner.strokeBorder(RPGPalette.woodEdge.opacity(0.4), lineWidth: 1))
                    .padding(frameWidth)
            }
    }
}

/// RPG（木）のボタン: 濃い木の札（薄い板の上で目立つように、文字は生成り色）。
struct RPGWoodButtonBackground: View {
    var cornerRadius: CGFloat = 10

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(
                LinearGradient(
                    colors: [RPGPalette.woodFrame, RPGPalette.woodEdge],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(shape.strokeBorder(RPGPalette.woodEdge, lineWidth: 2))
            .overlay(
                shape
                    .inset(by: 3)
                    .strokeBorder(RPGPalette.woodPanel.opacity(0.35), lineWidth: 1)
            )
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
        case .rpgWood:
            // 木の板の上は、ライト／ダークに関係なく濃い茶の文字にする
            content
                .background(RPGWoodBoardBackground(cornerRadius: min(cornerRadius, 12)))
                .environment(\.colorScheme, .light)
                .foregroundStyle(RPGPalette.ink)
        }
    }
}

extension View {
    /// 背景のイラストの上に置くカード。シンプルは半透明、RPG はウィンドウ（青）か掲示板（木）。
    func themedCard(_ style: AppearanceStyle, cornerRadius: CGFloat = 20) -> some View {
        modifier(ThemedCard(style: style, cornerRadius: cornerRadius))
    }
}
