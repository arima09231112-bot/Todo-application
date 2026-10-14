/// 曜日。値は `Calendar` の weekday と同じ（日曜 = 1 … 土曜 = 7）。
public enum Weekday: Int, CaseIterable, Sendable, Codable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    /// 「日」「月」…の1文字表記。
    public var shortName: String {
        switch self {
        case .sunday: "日"
        case .monday: "月"
        case .tuesday: "火"
        case .wednesday: "水"
        case .thursday: "木"
        case .friday: "金"
        case .saturday: "土"
        }
    }

    public var isWeekday: Bool { self != .sunday && self != .saturday }
}
