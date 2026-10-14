import Foundation
import SwiftData

/// SwiftData のコンテナ。保存先は App Group の共有フォルダ（Phase 3 でウィジェットと共有する）。
enum AppStore {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([TodoItem.self, RecurrenceItem.self])
        do {
            let configuration: ModelConfiguration
            if let groupID = SharedContainer.groupID, SharedContainer.url != nil {
                configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(groupID))
            } else {
                // App Group が使えないときは通常の保存先で動かす（Phase 0 の確認画面で気づける）。
                configuration = ModelConfiguration(schema: schema)
            }
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData のコンテナを作れませんでした: \(error)")
        }
    }
}
