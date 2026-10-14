import SwiftUI

/// 100% 到達時の「全員集合！」バナー。
struct AllAssembledBanner: View {
    var body: some View {
        Text("全員集合！")
            .font(.title.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(Capsule().fill(Color.blue.gradient))
            .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 2))
            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
            .accessibilityAddTraits(.isStaticText)
    }
}

/// スーパースター登場時に星が降る演出（数秒で降り終わる。常時は動かない）。
struct StarShowerView: View {
    private struct Star {
        let x: CGFloat
        let size: CGFloat
        let delay: Double
        let duration: Double
        let tint: Color
    }

    @State private var falling = false
    private let stars: [Star] = (0..<26).map { _ in
        Star(
            x: .random(in: 0.04...0.96),
            size: .random(in: 14...30),
            delay: .random(in: 0...1.1),
            duration: .random(in: 1.4...2.2),
            tint: [Color.yellow, Color.pink, Color.mint, Color.white].randomElement() ?? .yellow
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(stars.indices, id: \.self) { index in
                let star = stars[index]
                Image(systemName: "star.fill")
                    .font(.system(size: star.size))
                    .foregroundStyle(star.tint)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .position(x: star.x * geometry.size.width, y: falling ? geometry.size.height + 40 : -40)
                    .animation(.easeIn(duration: star.duration).delay(star.delay), value: falling)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { falling = true }
    }
}
