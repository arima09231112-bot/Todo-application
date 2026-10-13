/// ゲームに登場するキャラクターの識別子。
///
/// 画像名や描画の情報は持たない（素材との対応はアプリ側で解決する）。
/// 値は `art/sprites/` のフォルダ名・ファイル名と一致させる。
public enum CharacterID: String, CaseIterable, Sendable, Codable {
    case hero
    case swordsman
    case mage
    case priest
    case thief
    case knight
    case superstar

    /// 達成率の節目で加入する仲間を、加入順（1〜5人目）に並べたもの。
    public static let companionsInJoinOrder: [CharacterID] = [
        .swordsman, .mage, .priest, .thief, .knight,
    ]
}
