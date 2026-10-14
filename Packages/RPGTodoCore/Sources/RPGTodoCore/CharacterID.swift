/// ゲームに登場するキャラクターの識別子。
///
/// 画像名や描画の情報は持たない（素材との対応はアプリ側で解決する）。
/// 値は `art/sprites/` のファイル名（`{rawValue}.png`）と一致させる。
///
/// 注意: キャラは今後も増える予定のため、Phase 2 でデータ駆動のカタログ
/// （キャラID・表示名・種別をデータで持つ）に置き換える。
public enum CharacterID: String, CaseIterable, Sendable, Codable {
    case hero
    case swordsman
    case mage
    case priest
    case thief
    case knight
    case superstar

    /// 達成率の節目で加わる「仲間」の抽選元（勇者とレアキャラのスーパースターは含まない）。
    /// 誰がどの順で加わるかは日ごとのランダム抽選で決まる（要件定義書 4.3.1a）。
    public static var companionPool: [CharacterID] {
        allCases.filter { $0 != .hero && $0 != .superstar }
    }
}
