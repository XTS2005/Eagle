import SwiftUI

/// Eagle's shared activity treatment. The phase comes from wall-clock time so
/// rebuilding a parent view or receiving a new progress value cannot restart
/// the animation. Both loops end on the same visual state in which they begin.
struct EagleRainbowSpinner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 20

    var body: some View {
        TimelineView(.animation(
            minimumInterval: 1.0 / 45.0,
            paused: reduceMotion
        )) { context in
            let phase = reduceMotion
                ? 0.0
                : eagleRainbowPhase(at: context.date, duration: 1.45)

            ZStack {
                ForEach(0..<12, id: \.self) { index in
                    let hue = Double(index) / 12.0

                    Capsule(style: .continuous)
                        .fill(Color(
                            hue: hue,
                            saturation: 0.88,
                            brightness: 1.0
                        ))
                        .frame(
                            width: max(2.2, size * 0.11),
                            height: size * 0.31
                        )
                        .offset(y: -size * 0.32)
                        .rotationEffect(.degrees(Double(index) * 30.0))
                        .opacity(0.48 + Double(index) / 22.0)
                        .shadow(
                            color: Color(
                                hue: hue,
                                saturation: 0.82,
                                brightness: 1.0
                            ).opacity(0.28),
                            radius: max(0.7, size * 0.045)
                        )
                }
            }
            .frame(width: size, height: size)
            .rotationEffect(.degrees(phase * 360.0))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct EagleRainbowProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let value: Double
    var height: CGFloat = 4

    var body: some View {
        TimelineView(.animation(
            minimumInterval: 1.0 / 45.0,
            paused: reduceMotion
        )) { context in
            let phase = reduceMotion
                ? 0.0
                : eagleRainbowPhase(at: context.date, duration: 2.4)

            GeometryReader { geometry in
                let width = max(geometry.size.width, 1)
                let fillWidth = width * min(max(value, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.secondary.opacity(0.24))

                    HStack(spacing: 0) {
                        movingGradient.frame(width: width)
                        movingGradient.frame(width: width)
                    }
                    .frame(width: width * 2, alignment: .leading)
                    .offset(x: -width * phase)
                    .frame(width: fillWidth, alignment: .leading)
                    .clipped()
                    .mask(Capsule(style: .continuous))
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LaraL10n.text(
            en: "Preparation progress",
            es: "Progreso de preparación"
        ))
        .accessibilityValue(Text(
            min(max(value, 0), 1),
            format: .percent.precision(.fractionLength(0))
        ))
    }

    private var movingGradient: LinearGradient {
        LinearGradient(
            colors: [
                .cyan,
                .blue,
                .purple,
                .pink,
                .red,
                .orange,
                .yellow,
                .green,
                .cyan,
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private func eagleRainbowPhase(at date: Date, duration: TimeInterval) -> Double {
    let cycles = date.timeIntervalSinceReferenceDate / duration
    return cycles - floor(cycles)
}
