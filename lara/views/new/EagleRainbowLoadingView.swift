import SwiftUI

enum EagleAppearanceMode: String, CaseIterable, Identifiable {
    case dark
    case light
    case system

    static let storageKey = "eagle.appearance.mode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return LaraL10n.text(en: "Dark", es: "Oscuro")
        case .light: return LaraL10n.text(en: "Light", es: "Claro")
        case .system: return LaraL10n.text(en: "System", es: "Sistema")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

enum EagleVisualTheme {
    static let accent = Color(red: 0.34, green: 0.29, blue: 0.88)

    static let accentUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.50, blue: 1.0, alpha: 1)
            : UIColor(red: 0.29, green: 0.24, blue: 0.78, alpha: 1)
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.74)
            : Color.black.opacity(0.68)
    }

    static func surfaceBorder(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.09)
            : Color.black.opacity(0.11)
    }

    static func surfaceShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.clear
            : Color.black.opacity(0.06)
    }
}

struct EagleBrandMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 42
    /// When true the mark carries its own rainbow sweep. The header turns this
    /// off so a single sweep can travel across the whole lockup instead.
    var shimmer: Bool = true

    var body: some View {
        Group {
            if shimmer && !reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    glyph(sweep: eagleBrandSweepProgress(at: context.date))
                }
            } else {
                glyph(sweep: nil)
            }
        }
        .shadow(color: EagleVisualTheme.accent.opacity(0.16), radius: size * 0.10)
        .accessibilityHidden(true)
    }

    private func glyph(sweep: Double?) -> some View {
        ZStack {
            brandGlyph
                .foregroundStyle(.primary.opacity(0.92))

            if let sweep {
                brandShine(progress: sweep)
            }
        }
        .frame(width: size, height: size)
    }

    /// A glossy rainbow reflection that glides across the mark: a feathered
    /// spectrum band carries the colour while a bright specular core gives the
    /// gleam, both clipped to the silhouette so only the bird catches the light.
    private func brandShine(progress: Double) -> some View {
        let x = size * (-1.2 + 2.4 * progress)

        return ZStack {
            EagleSpectrumStyle.gradient
                .frame(width: size * 0.6, height: size * 1.7)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white.opacity(0.65), location: 0.33),
                            .init(color: .white, location: 0.5),
                            .init(color: .white.opacity(0.65), location: 0.67),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(.degrees(-16))
                .offset(x: x)
                .opacity(0.92)

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .white, location: 0.5),
                            .init(color: .clear, location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.17, height: size * 1.7)
                .rotationEffect(.degrees(-16))
                .offset(x: x)
                .blendMode(.plusLighter)
                .opacity(0.75)
        }
        .frame(width: size, height: size)
        .mask(brandGlyph)
        .allowsHitTesting(false)
    }

    private var brandGlyph: some View {
        Image("EagleBrandMark")
            .resizable()
            .renderingMode(.template)
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

/// A reusable rainbow "reflection" that periodically sweeps across whatever it
/// is attached to, then parks off-screen until the next pass. The band carries
/// a vivid full-spectrum colour plus a bright white specular core for the gleam,
/// and is clipped to the content's own shapes so only the glyphs catch the
/// light — it reads on the solid eagle mark and on thin serif letters alike.
struct EagleRainbowSweep: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { ctx in
                            ZStack {
                                if let progress = eagleBrandSweepProgress(at: ctx.date) {
                                    band(in: geo.size, progress: progress)
                                }
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
    }

    private func band(in size: CGSize, progress: Double) -> some View {
        let h = max(size.height, 1)
        let bandWidth = h * 1.0
        let reach = size.width / 2 + bandWidth
        let x = -reach + progress * (reach * 2)
        let tall = max(h, size.width) * 2.2

        return ZStack {
            // Vivid full-spectrum colour, feathered at the edges.
            Rectangle()
                .fill(EagleSpectrumStyle.gradient)
                .frame(width: bandWidth, height: tall)
                .mask(feather(soft: 0.7))
                .saturation(1.5)
                .rotationEffect(.degrees(-18))
                .offset(x: x)

            // Bright white specular core — the crisp "shine" streak.
            Rectangle()
                .fill(Color.white)
                .frame(width: bandWidth * 0.22, height: tall)
                .mask(feather(soft: 0.0))
                .blendMode(.plusLighter)
                .opacity(0.9)
                .rotationEffect(.degrees(-18))
                .offset(x: x)
        }
        .frame(width: size.width, height: size.height)
        .blur(radius: 0.5)
    }

    private func feather(soft: Double) -> some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .white.opacity(soft), location: 0.30),
                .init(color: .white, location: 0.5),
                .init(color: .white.opacity(soft), location: 0.70),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension View {
    /// Adds Eagle's periodic rainbow reflection, clipped to the view's shapes.
    func eagleRainbowSweep() -> some View {
        modifier(EagleRainbowSweep())
    }
}

/// The header lockup: the eagle mark followed by the serif wordmark, sharing a
/// single rainbow reflection that sweeps across both at once.
struct EagleWordmark: View {
    var logoSize: CGFloat = 54
    var nameSize: CGFloat = 32
    var spacing: CGFloat = 12

    var body: some View {
        HStack(spacing: spacing) {
            EagleBrandMark(size: logoSize, shimmer: false)

            Text("Eagle")
                .font(.system(size: nameSize, weight: .semibold, design: .serif).lowercaseSmallCaps())
                .tracking(1.5)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
        }
        .eagleRainbowSweep()
    }
}

/// Shared top header for both the Customize and Access screens: the Eagle
/// wordmark on the left, the language and settings controls together on the
/// right at the same level, and the device-identity pill fixed on the line
/// directly below the wordmark.
struct EagleHeaderBar: View {
    @Binding var language: LaraLanguage
    var onSettings: () -> Void

    @ObservedObject private var mgr = laramgr.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                EagleWordmark()
                Spacer(minLength: 8)
                languageBadge
                settingsButton
            }
            readinessBadge
        }
    }

    private var languageBadge: some View {
        Menu {
            Picker(
                LaraL10n.text(en: "Language", es: "Idioma"),
                selection: $language
            ) {
                ForEach(LaraLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .foregroundStyle(.primary)
                Text(language.shortName)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 11)
            .frame(minHeight: 34)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: Capsule()
            )
            .overlay {
                Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            }
        }
        .tint(.primary)
        .accessibilityLabel(LaraL10n.text(en: "Language", es: "Idioma"))
        .accessibilityValue(language.displayName)
    }

    private var settingsButton: some View {
        Button {
            onSettings()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: Circle()
                )
                .overlay {
                    Circle().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(LaraL10n.text(en: "Settings", es: "Ajustes"))
    }

    private var deviceModelName: String {
        let full = EagleDynamicIslandCompatibility.current.displayModel
        if let cut = full.range(of: " (") {
            return String(full[..<cut.lowerBound])
        }
        return full
    }

    private var iosVersionString: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return v.patchVersion == 0
            ? "\(v.majorVersion).\(v.minorVersion)"
            : "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    private var readinessBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(mgr.sbxready ? Color.green : Color.secondary.opacity(0.32))
                .frame(width: 8, height: 8)
            Text(mgr.sbxready
                ? "\(deviceModelName) · iOS \(iosVersionString)"
                : LaraL10n.text(en: "Not identified", es: "No identificado"))
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 34)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: Capsule()
        )
        .overlay {
            Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            mgr.sbxready
                ? LaraL10n.text(
                    en: "Identified: \(deviceModelName), iOS \(iosVersionString)",
                    es: "Identificado: \(deviceModelName), iOS \(iosVersionString)"
                )
                : LaraL10n.text(en: "Not identified", es: "No identificado")
        )
    }
}

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

    // Monochrome, adaptive navigation tint (black in light, white in dark) so
    // Back/Close match the rest of the neutral chrome.
    static let navigationTintColor = UIColor.label

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
            .foregroundStyle(EagleVisualTheme.accent)
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

/// A short, restrained sheen followed by a long pause. Returning `nil` keeps
/// the overlay out of the render tree while the mark is resting.
private func eagleBrandSweepProgress(at date: Date) -> Double? {
    let cycleDuration = 7.2
    let sweepDuration = 1.2
    let elapsed = date.timeIntervalSinceReferenceDate
        .truncatingRemainder(dividingBy: cycleDuration)

    guard elapsed < sweepDuration else { return nil }
    let progress = max(0, min(elapsed / sweepDuration, 1))
    return progress * progress * (3 - (2 * progress))
}
