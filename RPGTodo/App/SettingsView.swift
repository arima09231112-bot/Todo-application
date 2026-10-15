import SwiftUI
import RPGTodoCore

/// 設定タブ。勇者の見た目の選択（S-07）、アプリの見た目（シンプル／RPG）、ライセンス、動作確認用の情報。
struct SettingsView: View {
    @Environment(CalendarStore.self) private var calendar
    @AppStorage(SettingsKey.hero, store: SharedContainer.defaults) private var heroRaw = CharacterCatalog.defaultHeroID.rawValue
    @AppStorage(SettingsKey.appearance, store: SharedContainer.defaults) private var appearance = AppearanceStyle.simple

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
                    Picker("見た目", selection: $appearance) {
                        ForEach(AppearanceStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appearance) { _, _ in WidgetRefresh.request() }
                } header: {
                    Text("見た目")
                } footer: {
                    Text("RPG にすると、ホームとウィジェットがドット風の文字と RPG のウィンドウ風の画面になります。")
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
                    Text("予定は読み取るだけで、変更はしません。オフにしても、iPhone の「設定」→「Daily Quest」→「カレンダー」の許可は残ります。完全に取り消すにはそちらで変更してください。")
                }
                Section("ライセンス") {
                    NavigationLink("DotGothic16（フォント）") { LicenseView(fileName: "DotGothic16-OFL", title: "DotGothic16") }
                }
                Section("動作確認") {
                    Label(
                        SharedContainer.url == nil ? "App Group: 未設定" : "App Group: OK",
                        systemImage: SharedContainer.url == nil ? "xmark.circle" : "checkmark.circle"
                    )
                    .foregroundStyle(SharedContainer.url == nil ? Color.red : Color.green)
                }
            }
            .adventureScreenBackground()
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 同梱している素材のライセンス本文（OFL などは、本文を一緒に配布する必要がある）。
private struct LicenseView: View {
    let fileName: String
    let title: String

    private var text: String {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "ライセンスを読み込めませんでした。" }
        return text
    }

    var body: some View {
        ScrollView {
            Text(text)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
