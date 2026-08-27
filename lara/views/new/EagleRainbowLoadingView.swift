import SwiftUI

enum EagleSpectrumStyle {
    static let colors: [Color] = [
        .cyan,
        .blue,
        .purple,
        .pink,
        .red,
        .orange,
        .yellow,
        .green,
        .cyan,
    ]

    static var gradient: LinearGradient {
        LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var wordmarkGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.72, blue: 0.90),
                Color(red: 0.19, green: 0.55, blue: 0.96),
                Color(red: 0.33, green: 0.42, blue: 0.94),
                Color(red: 0.52, green: 0.34, blue: 0.91),
                Color(red: 0.74, green: 0.30, blue: 0.85),
                Color(red: 0.93, green: 0.33, blue: 0.63),
                Color(red: 0.98, green: 0.44, blue: 0.42),
                Color(red: 0.99, green: 0.62, blue: 0.30),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static let navigationTintColor: UIColor = {
        let uiColors: [UIColor] = [
            .cyan,
            .systemBlue,
            .systemPurple,
            .systemPink,
            .systemRed,
            .systemOrange,
            .systemYellow,
            .systemGreen,
            .cyan,
        ]
        // Narrow enough that a short label like "Back" spans a full rainbow
        // cycle (matching EagleSpectrumText). The gradient starts and ends on
        // cyan, so the pattern tiles seamlessly across wider items.
        let size = CGSize(width: 44, height: 44)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: uiColors.map(\.cgColor) as CFArray,
                locations: nil
            ) else { return }
            renderer.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: 0),
                options: []
            )
        }
        return UIColor(patternImage: image)
    }()

    static func configureGlobalNavigationAppearance() {
        UINavigationBar.appearance().tintColor = navigationTintColor
        UIBarButtonItem.appearance(
            whenContainedInInstancesOf: [UINavigationBar.self]
        ).tintColor = navigationTintColor
    }
}

struct EagleSpectrumText: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(EagleSpectrumStyle.gradient)
    }
}

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
        EagleSpectrumStyle.gradient
    }
}

private func eagleRainbowPhase(at date: Date, duration: TimeInterval) -> Double {
    let cycles = date.timeIntervalSinceReferenceDate / duration
    return cycles - floor(cycles)
}
