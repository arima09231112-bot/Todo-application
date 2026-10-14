/// キャラクターの種別。出現のしやすさ（重み）を決める。
public enum CharacterKind: String, Sendable, Codable, CaseIterable {
    /// 主人公（ユーザー）の見た目。戦士（男）・戦士（女）のどちらかをユーザーが選ぶ。
    /// 常にパーティの先頭で、仲間の抽選の対象外。
    case hero
    /// 通常の職業キャラ（剣士・魔法使い…。男女は別キャラ）。
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

/// ゲームに登場するキャラクター1体の定義（素材の画像名は含まない）。図鑑の文章は `docs/character-profiles.md` が元。
public struct GameCharacter: Sendable, Hashable, Identifiable {
    public let id: CharacterID
    public let kind: CharacterKind
    /// 職業・種族の名前（例: 「剣士（男）」）。
    public let displayName: String
    /// 図鑑に出す名前（例: 「ユウリ」）。
    public let name: String
    /// 二つ名（例: 「蒼の剣士」）。
    public let title: String
    /// 図鑑の紹介文。
    public let profile: String
    /// ひとこと（セリフ）。
    public let quote: String
    /// 未発見のあいだに出すヒント。勇者は最初から図鑑に載るので空。
    public let hint: String

    public init(
        id: CharacterID,
        kind: CharacterKind,
        displayName: String,
        name: String = "",
        title: String = "",
        profile: String = "",
        quote: String = "",
        hint: String = ""
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.name = name
        self.title = title
        self.profile = profile
        self.quote = quote
        self.hint = hint
    }
}

/// 全キャラクターの一覧。キャラを追加するときは `all` に1行足す（素材は `art/sprites/` に置く）。
public enum CharacterCatalog {
    /// 勇者の見た目の既定値（ユーザーが選ぶまではこれを使う）。
    public static let defaultHeroID: CharacterID = "warrior_m"

    public static let all: [GameCharacter] = [
        // 勇者（ユーザーが男女どちらかを選ぶ。仲間の抽選には出ない）
        GameCharacter(
            id: "warrior_m", kind: .hero, displayName: "戦士（男）",
            name: "アルト", title: "はじまりの勇者",
            profile: "村の朝練を一日も欠かさない若き戦士。大きな仕事も「まずは一歩」と小さく切り分けて片づけるのが得意。赤いハチマキは、やり遂げると決めた日にだけ締める。",
            quote: "今日の一歩目、いこうか！",
            hint: ""
        ),
        GameCharacter(
            id: "warrior_f", kind: .hero, displayName: "戦士（女）",
            name: "カリン", title: "大斧の勇者",
            profile: "大斧をかつぐ快活な戦士。「迷ったら手を動かす」が信条で、山積みの用事も勢いよく切り崩していく。赤いマントはおばあちゃんのお下がり。",
            quote: "まとめて片づけちゃおう！",
            hint: ""
        ),

        GameCharacter(
            id: "swordsman_m", kind: .job, displayName: "剣士（男）",
            name: "ユウリ", title: "蒼の剣士",
            profile: "無駄のない太刀筋が自慢の剣士。予定表も剣と同じで、余計なものを削るほど強くなると信じている。",
            quote: "優先順位、決めたか？",
            hint: "迷いなく進む日に、剣の音が聞こえる…"
        ),
        GameCharacter(
            id: "swordsman_f", kind: .job, displayName: "剣士（女）",
            name: "シエル", title: "銀のティアラ",
            profile: "城を抜け出して修行中の小国の姫。几帳面で、チェックリストを端から埋めていくのが何より好き。",
            quote: "全部チェック、しましょうね。",
            hint: "きちんとした人が好きらしい…"
        ),
        GameCharacter(
            id: "mage_m", kind: .job, displayName: "魔法使い（男）",
            name: "ノア", title: "星読みの魔法使い",
            profile: "夜空の星で明日を占う魔法使い。忘れ物をしないのは魔法ではなく、前の晩に確認しているから。準備が九割、詠唱は一割。",
            quote: "準備ができれば、半分おわり。",
            hint: "星のきれいな夜の翌日に…"
        ),
        GameCharacter(
            id: "mage_f", kind: .job, displayName: "魔法使い（女）",
            name: "ピピ", title: "おてんば見習い魔女",
            profile: "ピンクの髪の見習い魔女。呪文はよく失敗するが、決めた練習は毎日やる。「続けることがいちばんの魔法」が口ぐせ。",
            quote: "失敗しても、明日もやるよ！",
            hint: "毎日がんばる人のところへ箒で…"
        ),
        GameCharacter(
            id: "archer_m", kind: .job, displayName: "弓使い（男）",
            name: "フィン", title: "森の射手",
            profile: "森で育った弓使い。狙いを一つに絞るのが上手で、いま一番大事なタスクを見抜く目を持つ。",
            quote: "狙いは、ひとつ。",
            hint: "森のほうから、矢の音が…"
        ),
        GameCharacter(
            id: "archer_f", kind: .job, displayName: "弓使い（女）",
            name: "エル", title: "風読みの弓使い",
            profile: "風で天気を当てる弓使い。朝のうちに難しい用事を射抜いて、午後はのんびり昼寝するのが理想の一日。",
            quote: "朝イチで片づけよっ。",
            hint: "朝の風に乗ってやってくる…"
        ),
        GameCharacter(
            id: "priest_m", kind: .job, displayName: "僧侶（男）",
            name: "ルカ", title: "陽だまりの僧侶",
            profile: "いつも穏やかな僧侶。がんばりすぎる仲間に休憩をすすめるのが役目。「休むことも予定のうち」と手帳に書いている。",
            quote: "ひと息つくのも大事ですよ。",
            hint: "がんばりすぎた日に、そっと…"
        ),
        GameCharacter(
            id: "priest_f", kind: .job, displayName: "僧侶（女）",
            name: "ハル", title: "癒やしの祈り手",
            profile: "祈りで疲れを癒やす僧侶。寝る前に「今日できたこと」を三つ数える習慣があり、どんな日も少し前向きに終わらせる。",
            quote: "今日もよくがんばりました。",
            hint: "できたことを数える人のもとへ…"
        ),
        GameCharacter(
            id: "thief_m", kind: .job, displayName: "盗賊（男）",
            name: "クロウ", title: "すき間の盗賊",
            profile: "黒いフードの盗賊。盗むのは宝ではなく「すき間時間」。5分あれば用事を一つ片づけるのが流儀。",
            quote: "5分あれば十分さ。",
            hint: "すき間時間に、黒い影が…"
        ),
        GameCharacter(
            id: "thief_f", kind: .job, displayName: "盗賊（女）",
            name: "ネネ", title: "鍵開けの名人",
            profile: "身軽な盗賊。鍵開けと同じで、面倒な用事も「とっかかり」さえ見つければすぐに開くと知っている。",
            quote: "コツはね、最初のひと手間。",
            hint: "手ごわい用事の前に現れるとか…"
        ),
        GameCharacter(
            id: "knight_m", kind: .job, displayName: "騎士（男）",
            name: "ガルド", title: "鉄壁の騎士",
            profile: "大盾で仲間を守る騎士。約束の場所には必ず10分前に着く。守るのは仲間と、締め切り。",
            quote: "締め切りは守るものだ。",
            hint: "約束を守る人を守りにくる…"
        ),
        GameCharacter(
            id: "knight_f", kind: .job, displayName: "騎士（女）",
            name: "アイリス", title: "白銀の騎士団長",
            profile: "白い鎧の騎士団長。朝の身支度は5分、書類仕事は昼まで、と一日の段取りがきっちり決まっている。",
            quote: "段取り八分、ですわ。",
            hint: "段取りのいい日に、白い鎧が…"
        ),
        GameCharacter(
            id: "ninja_m", kind: .job, displayName: "忍者（男）",
            name: "ハヤテ", title: "疾風の忍",
            profile: "音もなく任務をこなす忍者。終わった仕事を誰にも自慢しないが、チェックが付いた瞬間だけ小さくガッツポーズする。",
            quote: "任務、完了。",
            hint: "気づけば、もうそばにいる…"
        ),
        GameCharacter(
            id: "ninja_f", kind: .job, displayName: "忍者（女）",
            name: "カエデ", title: "紅マフラーのくノ一",
            profile: "手裏剣の名手。やることを紙に書き出して、一つずつ打ち抜いていく。マフラーは修行を始めた日に師匠からもらった宝物。",
            quote: "次、いくよ！",
            hint: "赤いマフラーが風に揺れて…"
        ),
        GameCharacter(
            id: "summoner_m", kind: .job, displayName: "召喚士（男）",
            name: "レイ", title: "蒼炎の召喚士",
            profile: "青い炎の精霊と暮らす召喚士。一人で抱えこまず、頼れるものは頼るのが彼の強さ。",
            quote: "手伝ってもらうのも、力のうち。",
            hint: "青い炎が、ゆらりと…"
        ),
        GameCharacter(
            id: "summoner_f", kind: .job, displayName: "召喚士（女）",
            name: "ユエ", title: "月夜の召喚士",
            profile: "小さなゴーストを相棒にする召喚士。夜型で、寝る前に明日のやることを相棒と一緒に確かめるのが日課。",
            quote: "明日の予定、もう決めた？",
            hint: "月の夜に、小さな精霊を連れて…"
        ),

        GameCharacter(
            id: "slime", kind: .monster, displayName: "スライム",
            name: "プルン", title: "ちいさな王さま",
            profile: "王冠をかぶったスライム。本人いわく王様だが、国民は自分ひとり。ぷるぷる跳ねて、朝いちばんに仲間になりがち。",
            quote: "ぷるっ！（がんばろう）",
            hint: "何かがぷるぷる跳ねている…"
        ),
        GameCharacter(
            id: "golem", kind: .monster, displayName: "ゴーレム",
            name: "ゴロン", title: "苔むす巨人",
            profile: "千年動かなかった岩の巨人。のんびり屋だが、一度動き出すと止まらない。「始めるまでが一番重い」を身をもって知っている。",
            quote: "……ウゴク。ナラ、サイゴマデ。",
            hint: "重い腰を上げた日に、地面が揺れる…"
        ),
        GameCharacter(
            id: "dragon", kind: .monster, displayName: "ドラゴン",
            name: "ヒバナ", title: "ちびドラゴン",
            profile: "火の山で生まれた子どものドラゴン。まだ小さな火しか吐けないが、毎日の練習で少しずつ炎が大きくなっている。",
            quote: "ちょっとずつ、でっかくなる！",
            hint: "火の粉が、ぱちっと…"
        ),
        GameCharacter(
            id: "ghost", kind: .monster, displayName: "ゴースト",
            name: "ポルタ", title: "夜ふかしゴースト",
            profile: "古いお城に住むゴースト。夜ふかしが大好きだが、最近は早寝早起きに挑戦中。先延ばしにした用事の前に、ふわっと現れるらしい。",
            quote: "あとで…って、いつ？",
            hint: "先延ばしの気配に、ひんやりと…"
        ),

        GameCharacter(
            id: "demonlord_m", kind: .demonLord, displayName: "魔王（男）",
            name: "ヴァルゼル", title: "黒炎の魔王",
            profile: "かつて世界を震え上がらせた魔王。完璧主義がすぎて、計画を立てるだけで一日が終わるのが最近の悩み。勇者の手際に興味を持ち、ときどき仲間になる。",
            quote: "……我も、まずは一つやってみるか。",
            hint: "強大な気配が、こちらを見ている…"
        ),
        GameCharacter(
            id: "demonlord_f", kind: .demonLord, displayName: "魔王（女）",
            name: "ルシア", title: "紫苑の魔女王",
            profile: "魔法陣を自在に操る魔王。部下に任せるのが上手で、自分は大事な一手だけを打つ。何でも一人で抱える勇者を、少し心配して見ている。",
            quote: "任せるのも、王の仕事よ。",
            hint: "紫の魔法陣が、どこかで光る…"
        ),

        GameCharacter(
            id: "superstar", kind: .superstar, displayName: "スーパースター",
            name: "カンナ", title: "うちは冒険界のスーパースター",
            profile: "世界中をツアーで回るアイドル。どんなに忙しくても、その日の予定を全部やり切った人のところへ、ステージ衣装のまま駆けつけるという。",
            quote: "やり切った君が、今日の主役だよ☆",
            hint: "とてもまれに現れる…"
        ),
    ]

    /// 勇者として選べる見た目（戦士（男）・戦士（女））。
    public static var heroes: [GameCharacter] {
        all.filter { $0.kind == .hero }
    }

    /// IDからキャラを引く。
    public static func character(_ id: CharacterID) -> GameCharacter? {
        all.first { $0.id == id }
    }

    /// 仲間の抽選元（勇者の見た目を除く全キャラ）。重みは `CharacterKind.drawWeight`。
    public static var companionPool: [GameCharacter] {
        all.filter { $0.kind.drawWeight > 0 }
    }
}
