/// Todo のカテゴリ。保存には `rawValue` を使う。
public enum TodoCategory: String, CaseIterable, Sendable, Codable, Hashable {
    case work
    case `private`
    case health
    case other

    public var displayName: String {
        switch self {
        case .work: "仕事"
        case .private: "プライベート"
        case .health: "健康"
        case .other: "その他"
        }
    }
}
