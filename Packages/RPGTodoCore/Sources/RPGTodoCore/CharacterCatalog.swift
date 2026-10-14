/// キャラクターの種別。出現のしやすさ（重み）を決める。
public enum CharacterKind: String, Sendable, Codable, CaseIterable {
    /// 主人公（ユーザー）。常にパーティの先頭で、抽選の対象外。
    case hero
    /// 通常の職業キャラ（戦士・剣士・魔法使い…。男女は別キャラ）。
    case job
    /// モンスター系（スライム・ゴーレム…）。
    case monster
    /// 魔王。
    case demonLord
    /// スーパースター（最もレア）。
    case superstar

    /// 抽選の重み（大きいほど出やすい）。値は仮で、運用しながら調整する。
    /// 重みは「キャラ1体あたり」。通常キャラは数が多いので、種別全体でも最も出やすい。
    public var drawWeight: Int {
        switch self {
        case .hero: 0
        case .job: 10
        case .monster: 5
        case .demonLord: 3
        case .superstar: 2
        }
    }
}

/// ゲームに登場するキャラクター1体の定義（素材の画像名は含まない）。
public struct GameCharacter: Sendable, Hashable, Identifiable {
    public let id: CharacterID
    public let kind: CharacterKind
    public let displayName: String

    public init(id: CharacterID, kind: CharacterKind, displayName: String) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
    }
}

/// 全キャラクターの一覧。キャラを追加するときは `all` に1行足す（素材は `art/sprites/` に置く）。
public enum CharacterCatalog {
    public static let heroID: CharacterID = "hero"

    public static let all: [GameCharacter] = [
        GameCharacter(id: "hero", kind: .hero, displayName: "勇者"),

        GameCharacter(id: "warrior_m", kind: .job, displayName: "戦士（男）"),
        GameCharacter(id: "warrior_f", kind: .job, displayName: "戦士（女）"),
        GameCharacter(id: "swordsman_m", kind: .job, displayName: "剣士（男）"),
        GameCharacter(id: "swordsman_f", kind: .job, displayName: "剣士（女）"),
        GameCharacter(id: "mage_m", kind: .job, displayName: "魔法使い（男）"),
        GameCharacter(id: "mage_f", kind: .job, displayName: "魔法使い（女）"),
        GameCharacter(id: "archer_m", kind: .job, displayName: "弓使い（男）"),
        GameCharacter(id: "archer_f", kind: .job, displayName: "弓使い（女）"),
        GameCharacter(id: "priest_m", kind: .job, displayName: "僧侶（男）"),
        GameCharacter(id: "priest_f", kind: .job, displayName: "僧侶（女）"),
        GameCharacter(id: "thief_m", kind: .job, displayName: "盗賊（男）"),
        GameCharacter(id: "thief_f", kind: .job, displayName: "盗賊（女）"),
        GameCharacter(id: "knight_m", kind: .job, displayName: "騎士（男）"),
        GameCharacter(id: "knight_f", kind: .job, displayName: "騎士（女）"),
        GameCharacter(id: "ninja_m", kind: .job, displayName: "忍者（男）"),
        GameCharacter(id: "ninja_f", kind: .job, displayName: "忍者（女）"),
        GameCharacter(id: "summoner_m", kind: .job, displayName: "召喚士（男）"),
        GameCharacter(id: "summoner_f", kind: .job, displayName: "召喚士（女）"),

        GameCharacter(id: "slime", kind: .monster, displayName: "スライム"),
        GameCharacter(id: "golem", kind: .monster, displayName: "ゴーレム"),
        GameCharacter(id: "dragon", kind: .monster, displayName: "ドラゴン"),
        GameCharacter(id: "ghost", kind: .monster, displayName: "ゴースト"),

        GameCharacter(id: "demonlord_m", kind: .demonLord, displayName: "魔王（男）"),
        GameCharacter(id: "demonlord_f", kind: .demonLord, displayName: "魔王（女）"),

        GameCharacter(id: "superstar", kind: .superstar, displayName: "スーパースター"),
    ]

    /// 仲間の抽選元（勇者を除く全キャラ）。重みは `CharacterKind.drawWeight`。
    public static var companionPool: [GameCharacter] {
        all.filter { $0.kind.drawWeight > 0 }
    }
}
