import SwiftUI
import RPGTodoCore

/// 冒険の背景（草原・湖・森の縦長イラスト）。画面全体に敷き、下端（キャラが立つ道）を画面下にそろえる。
/// ライトモードは昼、ダークモードは夜の絵（同じ構図。要件 F-08）。
struct AdventureBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// ウィジェットは画像の大きさに上限があるため、縮小版（`widget_*`）を使う。
    var isWidget = false

    private var imageName: String {
        "Backgrounds/\(isWidget ? "widget" : "home")_\(colorScheme == .dark ? "night" : "day")"
    }

    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// 冒険フィールドのパーティ: 勇者を先頭にして横一列に立つ（要件 4.3.5）。背景は `AdventureBackground`。
///
/// 仲間が増える・減るときの動き（加入演出）は、呼び出し側の `withAnimation` で決まる。
/// アニメーションなしで人数を変えれば、演出なしで入れ替わる。
///
/// `isLively` のとき（ホーム画面だけ）は、軽い動きを付ける（要件 F-09）:
/// 待機中にゆっくり上下に揺れる・クエストを完了すると小さく跳ねる・キャラをタップするとジャンプしてひとこと。
/// 「視差効果を減らす」がオンのときと、アプリが前面にないときは動かさない。ウィジェット・記録では動かさない。
struct PartyField: View {
    let hero: CharacterID
    let companions: [CharacterID]
    /// 表示の高さ。ウィジェットの小サイズなど、狭い場所では小さくする。
    var height: CGFloat = 96
    /// 軽い動きを付けるか（ホーム画面だけ）。
    var isLively = false
    /// 値が増えるたびに、パーティが順番に小さく跳ねる（クエストを完了したとき）。
    var hopTrigger = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appearance) private var appearance
    @State private var isVisible = false
    @State private var tapCounts: [CharacterID: Int] = [:]
    @State private var speech: Speech?

    private struct Speech: Equatable {
        let id = UUID()
        let character: CharacterID
        let index: Int
    }

    private var animates: Bool { isLively && !reduceMotion }

    /// 6人並んだときに画面の幅に収まるよう、キャラの大きさと間隔を幅から決める。
    /// 素材のキャンバスには左右に余白があるので、隣と少し重ねて並べる。
    /// 人数が少ないときも、各キャラの位置は変わらない（左から並ぶ）。
    private static func layout(width: CGFloat) -> (size: CGFloat, spacing: CGFloat) {
        let size = min(110, width / 4.2)
        let spacing = (width - 8 - 6 * size) / 5
        return (size, spacing)
    }

    /// 加入: 上からぽんと弾んで現れる（「視差効果を減らす」ではフェードのみ）。減少: フェードアウト。
    private var joinTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity)
    }

    var body: some View {
        GeometryReader { geometry in
            let (size, spacing) = Self.layout(width: geometry.size.width)
            Group {
                if animates {
                    // 1秒に30回だけ描き直す（電池対策）。画面に出ていないとき・前面にないときは止める
                    TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isVisible || scenePhase != .active)) { timeline in
                        row(size: size, spacing: spacing, time: timeline.date.timeIntervalSinceReferenceDate)
                    }
                } else {
                    row(size: size, spacing: spacing, time: nil)
                }
            }
            .padding(.leading, 4)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottomLeading)
            .overlay(alignment: .topLeading) {
                if let speech, let character = CharacterCatalog.character(speech.character) {
                    speechBubble(character, index: speech.index, size: size, spacing: spacing, in: geometry.size)
                }
            }
        }
        .frame(height: height)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(companions.isEmpty ? "勇者" : "勇者と仲間\(companions.count)人")
    }

    private func row(size: CGFloat, spacing: CGFloat, time: TimeInterval?) -> some View {
        HStack(spacing: spacing) {
            member(hero, index: 0, size: size, time: time)
            ForEach(Array(companions.enumerated()), id: \.element) { offset, character in
                member(character, index: offset + 1, size: size, time: time)
                    .transition(joinTransition)
            }
        }
    }

    @ViewBuilder
    private func member(_ character: CharacterID, index: Int, size: CGFloat, time: TimeInterval?) -> some View {
        let sprite = PixelSprite(character: character, size: size)
        if isLively {
            sprite
                // 待機中の揺れ（キャラごとにタイミングをずらす）
                .offset(y: time.map { Self.bob(time: $0, index: index) } ?? 0)
                // 完了したとき: 先頭から順に小さく跳ねる
                .keyframeAnimator(initialValue: 0.0, trigger: animates ? hopTrigger : 0) { content, y in
                    content.offset(y: y)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(0, duration: 0.001 + Double(index) * 0.06)
                        SpringKeyframe(-12, duration: 0.14)
                        SpringKeyframe(0, duration: 0.35, spring: .bouncy)
                    }
                }
                // タップしたとき: 大きくジャンプ
                .keyframeAnimator(initialValue: 0.0, trigger: animates ? tapCounts[character, default: 0] : 0) { content, y in
                    content.offset(y: y)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(-22, duration: 0.18)
                        SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { speak(character, index: index) }
        } else {
            sprite
        }
    }

    /// 呼吸のようなゆっくりした上下の揺れ（0〜-3pt。足元より下には動かさない）。
    private static func bob(time: TimeInterval, index: Int) -> CGFloat {
        let phase = time * 2 * .pi / 2.6 + Double(index) * 0.9
        return CGFloat(-1.5 * (1 + sin(phase)))
    }

    /// 吹き出し: タップしたキャラの頭の上に、図鑑の名前とひとことを出す。画面の端からはみ出さないよう位置を寄せる。
    private func speechBubble(_ character: GameCharacter, index: Int, size: CGFloat, spacing: CGFloat, in field: CGSize) -> some View {
        let width: CGFloat = min(230, field.width - 16)
        let center = 4 + CGFloat(index) * (size + spacing) + size / 2
        let x = min(max(center, width / 2 + 8), field.width - width / 2 - 8)
        return VStack(alignment: .leading, spacing: 2) {
            Text(character.name)
                .font(appearance.font(.caption, weight: .bold))
                .foregroundStyle(appearance == .rpg ? RPGPalette.gold : Color.blue)
            Text(character.quote.isEmpty ? "……" : character.quote)
                .font(appearance.font(.subheadline))
                .foregroundStyle(appearance == .rpg ? Color.white : Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, appearance == .rpg ? 14 : 12)
        .padding(.vertical, appearance == .rpg ? 11 : 8)
        .frame(width: width, alignment: .leading)
        .background {
            if appearance == .rpg {
                RPGWindowBackground(opacity: 0.95)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            }
        }
        .position(x: x, y: field.height - size * 0.95 - 24)
        .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
        .id(character.id)
    }

    private func speak(_ character: CharacterID, index: Int) {
        tapCounts[character, default: 0] += 1
        let next = Speech(character: character, index: index)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { speech = next }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.8))
            if speech == next { withAnimation(.easeOut(duration: 0.2)) { speech = nil } }
        }
    }
}
