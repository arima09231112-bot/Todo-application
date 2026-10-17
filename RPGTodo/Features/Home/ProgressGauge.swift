import SwiftUI

/// 達成率の円形ゲージ（シンプルは青、RPG は金色）。
struct ProgressGauge: View {
    let percent: Int?

    @Environment(\.appearance) private var appearance

    var body: some View {
        ZStack {
            Circle()
                .fill(appearance.gaugeDisc)
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(percent ?? 0) / 100)
                .stroke(appearance.accent, style: StrokeStyle(lineWidth: 10, lineCap: appearance.isRPG ? .butt : .round))
                .rotationEffect(.degrees(-90))
            Text(percent.map { "\($0)%" } ?? "–")
                .font(appearance.font(.title2, weight: .bold))
                .monospacedDigit()
        }
        .frame(width: 84, height: 84)
        .animation(.easeOut(duration: 0.3), value: percent)
        .accessibilityLabel("達成率")
        .accessibilityValue(percent.map { "\($0)パーセント" } ?? "準備中")
    }
}
