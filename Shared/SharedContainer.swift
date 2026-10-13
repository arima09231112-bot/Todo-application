import Foundation

/// アプリ本体とウィジェットが共有する App Group の入口。
///
/// グループ名は Info.plist の `AppGroupID`（project.yml の `APP_GROUP_ID`）から読むので、
/// 変更は project.yml の1か所で済む。
enum SharedContainer {
    static var groupID: String? {
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
    }

    /// 共有コンテナのフォルダ。App Group が有効でなければ nil。
    static var url: URL? {
        guard let groupID else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// 共有の UserDefaults（設定値の保存用）。
    static var defaults: UserDefaults? {
        guard let groupID else { return nil }
        return UserDefaults(suiteName: groupID)
    }
}
