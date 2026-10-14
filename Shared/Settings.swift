import Foundation
import RPGTodoCore

/// 設定値（App Group の UserDefaults に保存し、アプリとウィジェットで共有する）。
enum SettingsKey {
    /// 勇者の見た目（`warrior_m` または `warrior_f`）。
    static let hero = "heroCharacterID"
}

enum HeroSetting {
    /// 保存された値から勇者のIDを決める。未設定や不正な値は既定（戦士（男））。
    static func resolve(_ raw: String) -> CharacterID {
        CharacterCatalog.heroes.first { $0.id.rawValue == raw }?.id ?? CharacterCatalog.defaultHeroID
    }
}
