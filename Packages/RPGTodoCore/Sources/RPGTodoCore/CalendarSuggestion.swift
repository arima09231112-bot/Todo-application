import Foundation

/// カレンダーの予定から Todo 候補を作る（端末内のテンプレート方式。要件 4.4.1）。外部には何も送らない。
public enum CalendarSuggestion {
    /// 予定の開始の何分前を候補の時刻にするか。
    public static let leadMinutes = 30

    /// キーワードと候補の文言。上から順に最初に合ったものを使う。`{}` が予定名に置き換わる。
    private static let templates: [(keywords: [String], format: String)] = [
        (["会議", "定例", "mtg"], "{}の資料を確認する"),
        (["訪問", "商談", "打ち合わせ", "打合せ"], "{}の提案資料を準備する"),
        (["レビュー"], "{}の修正箇所を確認する"),
    ]
    private static let fallbackFormat = "{}の準備をする"

    /// Todo のタイトルは 100 文字までなので、予定名を切り詰める余裕を見ておく。
    private static let maxEventTitleLength = 60

    public static func title(forEventTitle eventTitle: String) -> String {
        let name = String(eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxEventTitleLength))
        let lowered = name.lowercased()
        let format = templates.first { rule in rule.keywords.contains { lowered.contains($0) } }?.format
            ?? fallbackFormat
        return format.replacingOccurrences(of: "{}", with: name)
    }

    /// 候補の時刻（0:00 からの分）。予定開始の30分前。0:00 より前にはしない。
    public static func suggestedMinutes(eventStartMinutes: Int) -> Int {
        max(0, eventStartMinutes - leadMinutes)
    }
}

/// 予定の重複判定キー（要件 4.4.2）。繰り返し予定は識別子を共有するので、その回の開始日時を足して区別する。
public enum CalendarEventKey {
    public static func make(eventID: String, start: Date) -> String {
        "\(eventID)@\(Int(start.timeIntervalSince1970))"
    }
}
