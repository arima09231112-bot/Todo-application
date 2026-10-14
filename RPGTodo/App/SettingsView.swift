import SwiftUI
import RPGTodoCore

/// 設定タブ。勇者の見た目の選択（S-07）と、動作確認用の情報。
struct SettingsView: View {
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(CharacterCatalog.heroes) { hero in
                        Button { heroRaw = hero.id.rawValue } label: {
                            HStack {
                                PixelSprite(character: hero.id, size: 72)
                                Text(hero.displayName)
                                Spacer()
                                if HeroSetting.resolve(heroRaw) == hero.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(HeroSetting.resolve(heroRaw) == hero.id ? .isSelected : [])
                    }
                } header: {
                    Text("勇者の見た目")
                } footer: {
                    Text("選んだ見た目は、ホームとウィジェットで勇者として表示されます。")
                }
                Section("動作確認") {
                    Label(
                        SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK",
                        systemImage: SharedContainer.url == nil ? "xmark.circle" : "checkmark.circle"
                    )
                    .foregroundStyle(SharedContainer.url == nil ? Color.red : Color.green)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
