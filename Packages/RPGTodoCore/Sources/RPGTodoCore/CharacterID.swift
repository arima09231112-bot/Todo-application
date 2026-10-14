/// キャラクターの識別子（例: `"warrior_m"`）。
///
/// 画像名や描画の情報は持たない（素材との対応はアプリ側で解決する）。
/// 値は `art/sprites/{rawValue}.png` のファイル名と一致させる。
/// キャラは今後も増えるため、enum ではなく文字列で持つ（追加は `CharacterCatalog` に1行足すだけ）。
public struct CharacterID: RawRepresentable, Hashable, Sendable, Codable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var description: String { rawValue }
}
