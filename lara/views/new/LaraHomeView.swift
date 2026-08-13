import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var mgr = laramgr.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    VStack(alignment: .leading, spacing: 20) {
                        NavigationLink(destination: CompleteStylesView()) {
                            LaraFeatureCard(
                                title: "Estilos",
                                subtitle: "Un aspecto completo para el fondo, el código y tu tarjeta.",
                                systemImage: "sparkles",
                                accent: Color(red: 0.33, green: 0.25, blue: 0.82),
                                artwork: .styles
                            )
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personalizar una parte")
                                .font(.headline)
                                .padding(.horizontal, 2)

                            VStack(spacing: 0) {
                                NavigationLink(destination: AnimatedWallpapersView()) {
                                    LaraToolRow(
                                        title: "Fondos",
                                        subtitle: "Explora o crea",
                                        systemImage: "photo.on.rectangle.angled",
                                        accent: Color(red: 0.34, green: 0.31, blue: 0.88)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: CardView()) {
                                    LaraToolRow(
                                        title: "Tarjetas",
                                        subtitle: "Diseño de Wallet",
                                        systemImage: "creditcard.fill",
                                        accent: Color(red: 0.08, green: 0.48, blue: 0.52)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: PasscodeView(mgr: mgr)) {
                                    LaraToolRow(
                                        title: "Código",
                                        subtitle: "Números de desbloqueo",
                                        systemImage: "circle.grid.3x3.fill",
                                        accent: Color(red: 0.56, green: 0.28, blue: 0.72)
                                    )
                                }
                            }
                            .buttonStyle(.plain)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                            }
                        }
                    }

                    trustNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(.blue)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Eagle")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Spacer()
                Menu {
                    Picker("Language", selection: $language) {
                        ForEach(LaraLanguage.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text(language.shortName)
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background(
                        Color(uiColor: .secondarySystemGroupedBackground),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                    }
                }
                .accessibilityLabel("Language")

                HStack(spacing: 6) {
                    Circle()
                        .fill(mgr.sbxready ? Color.green : Color.secondary.opacity(0.32))
                        .frame(width: 8, height: 8)
                    Text(mgr.sbxready
                        ? LaraL10n.text(en: "Ready", es: "Lista")
                        : LaraL10n.text(en: "Setup", es: "Preparar"))
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .overlay {
                    Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                }
                .accessibilityLabel(
                    mgr.sbxready
                        ? LaraL10n.text(en: "Eagle is ready", es: "Eagle está lista")
                        : LaraL10n.text(en: "Eagle needs preparation", es: "Eagle necesita preparación")
                )
            }

            Text("Personaliza lo que realmente ves.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text("Tú mantienes el control")
                    .font(.subheadline.weight(.semibold))
                Text("Eagle solicita acceso solo cuando eliges aplicar un cambio.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

private struct LaraFeatureCard: View {
    enum Artwork {
        case styles
        case wallpaper
        case card
        case passcode
    }

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let accent: Color
    let artwork: Artwork

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                accent.opacity(0.12)

                switch artwork {
                case .styles:
                    stylesArtwork
                case .wallpaper:
                    wallpaperArtwork
                case .card:
                    cardArtwork
                case .passcode:
                    passcodeArtwork
                }
            }
            .frame(height: 154)
            .clipped()

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 38, height: 38)
                    .background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.055), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var stylesArtwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.72), accent, Color.indigo.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 138)
                .overlay(alignment: .top) {
                    VStack(spacing: 1) {
                        Text("9:41")
                            .font(.system(size: 27, weight: .semibold, design: .rounded))
                        HStack(spacing: 5) {
                            ForEach(1..<4) { number in
                                Circle()
                                    .fill(.white.opacity(0.18))
                                    .frame(width: 18, height: 18)
                                    .overlay {
                                        Text("\(number)")
                                            .font(.system(size: 6, weight: .bold))
                                    }
                            }
                        }
                        .padding(.top, 15)
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 20)
                }
                .rotationEffect(.degrees(-5))

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.9), accent, Color.cyan.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 94)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white)
                        .padding(14)
                }
                .rotationEffect(.degrees(5))
                .offset(x: 72, y: 30)
                .shadow(color: accent.opacity(0.25), radius: 16, y: 8)
        }
        .offset(x: -28)
    }

    private var wallpaperArtwork: some View {
        HStack(spacing: -22) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent.opacity(0.35))
                .frame(width: 92, height: 126)
                .rotationEffect(.degrees(-8))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent)
                .frame(width: 96, height: 132)
                .overlay(alignment: .top) {
                    VStack(spacing: 1) {
                        Text("9:41")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                        Text("jueves, 13 de agosto")
                            .font(.system(size: 6, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 22)
                }
                .shadow(color: accent.opacity(0.25), radius: 18, y: 10)
        }
    }

    private var cardArtwork: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(accent)
            .frame(width: 220, height: 132)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 34) {
                    Image(systemName: "wave.3.right")
                        .font(.title3.weight(.medium))
                    HStack {
                        Text("•••• 4242")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "apple.logo")
                    }
                }
                .foregroundStyle(.white.opacity(0.95))
                .padding(18)
            }
            .rotationEffect(.degrees(-3))
            .shadow(color: accent.opacity(0.25), radius: 18, y: 10)
    }

    private var passcodeArtwork: some View {
        VStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 14) {
                    ForEach(1..<4, id: \.self) { column in
                        let number = row * 3 + column
                        Circle()
                            .fill(accent.opacity(number.isMultiple(of: 2) ? 0.82 : 1))
                            .frame(width: 35, height: 35)
                            .overlay {
                                Text("\(number)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .rotationEffect(.degrees(2))
        .shadow(color: accent.opacity(0.22), radius: 18, y: 10)
    }
}

private struct LaraToolRow: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 38, height: 38)
                .background(accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
