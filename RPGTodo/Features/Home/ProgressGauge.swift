import SwiftUI

/// 達成率の円形ゲージ（青）。
struct ProgressGauge: View {
    let percent: Int?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 10)
            Circle()
                .trim(from: 0, to: CGFloat(percent ?? 0) / 100)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(percent.map { "\($0)%" } ?? "–")
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(width: 84, height: 84)
        .animation(.easeOut(duration: 0.3), value: percent)
        .accessibilityLabel("達成率")
        .accessibilityValue(percent.map { "\($0)パーセント" } ?? "準備中")
    }
}
