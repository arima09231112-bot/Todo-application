import SwiftUI
import RPGTodoCore

/// 設定タブ。勇者の見た目の選択（S-07）と、動作確認用の情報。
struct SettingsView: View {
    @Environment(CalendarStore.self) private var calendar
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(CharacterCatalog.heroes) { hero in
                        Button { heroRaw = hero.id.rawValue; WidgetRefresh.request() } label: {
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
                Section {
                    Toggle("カレンダーと連携する", isOn: Binding(
                        get: { calendar.isEnabled },
                        set: { isOn in
                            if isOn { Task { await calendar.enable() } } else { calendar.disable() }
                        }
                    ))
                } header: {
                    Text("カレンダー")
                } footer: {
                    Text("予定は読み取るだけで、変更はしません。オフにしても、iPhone の「設定」→「RPG Todo」→「カレンダー」の許可は残ります。完全に取り消すにはそちらで変更してください。")
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
