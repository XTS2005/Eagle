import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var sceneManager = EagleSceneManager.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if sceneManager.hasPendingShortcut {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(
                                LaraL10n.text(en: "Scene waiting", es: "Scene en espera"),
                                systemImage: "bolt.shield.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(.indigo)
                            LaraAccessView(compact: true) {
                                sceneManager.applyPendingShortcutIfNeeded()
                            }
                        }
                    } else {
                        homeAccessCard
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        NavigationLink(destination: CompleteStylesView()) {
                            LaraFeatureCard(
                                title: LaraL10n.text(en: "Styles", es: "Estilos"),
                                subtitle: LaraL10n.text(
                                    en: "A complete look for your wallpaper, passcode, and card.",
                                    es: "Un aspecto completo para el fondo, el código y tu tarjeta."
                                ),
                                systemImage: "sparkles",
                                accent: Color(red: 0.33, green: 0.25, blue: 0.82),
                                artwork: .styles
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: EagleSystemView()) {
                            HStack(spacing: 15) {
                                ZStack {
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.title2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 54, height: 54)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Eagle System")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(LaraL10n.text(
                                        en: "Guardian, Scenes, and safe sharing",
                                        es: "Guardian, Scenes y uso compartido seguro"
                                    ))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(15)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 21, style: .continuous)
                                    .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(LaraL10n.text(en: "Customize one part", es: "Personalizar una parte"))
                                .font(.headline)
                                .padding(.horizontal, 2)

                            VStack(spacing: 0) {
                                NavigationLink(destination: AnimatedWallpapersView()) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Wallpapers", es: "Fondos"),
                                        subtitle: LaraL10n.text(en: "Explore or create", es: "Explora o crea"),
                                        systemImage: "photo.on.rectangle.angled",
                                        accent: Color(red: 0.34, green: 0.31, blue: 0.88)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: CardView()) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Cards", es: "Tarjetas"),
                                        subtitle: LaraL10n.text(en: "Wallet design", es: "Diseño de Wallet"),
                                        systemImage: "creditcard.fill",
                                        accent: Color(red: 0.08, green: 0.48, blue: 0.52)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: PasscodeView(mgr: mgr)) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Passcode", es: "Código"),
                                        subtitle: LaraL10n.text(en: "Unlock key styles", es: "Números de desbloqueo"),
                                        systemImage: "circle.grid.3x3.fill",
                                        accent: Color(red: 0.56, green: 0.28, blue: 0.72)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: DarkBoardView()) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Icons", es: "Iconos"),
                                        subtitle: LaraL10n.text(en: "Themes and Android shapes", es: "Temas y formas Android"),
                                        systemImage: "square.grid.2x2.fill",
                                        accent: Color(red: 0.18, green: 0.60, blue: 0.42)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: DockCustomizerView()) {
                                    LaraToolRow(
                                        title: "Dock",
                                        subtitle: LaraL10n.text(en: "Fit up to six apps", es: "Hasta seis apps"),
                                        systemImage: "dock.rectangle",
                                        accent: Color(red: 0.12, green: 0.46, blue: 0.86)
                                    )
                                }

                                Divider().padding(.leading, 62)

                                NavigationLink(destination: AuraStudioView()) {
                                    LaraToolRow(
                                        title: "Aura Studio",
                                        subtitle: LaraL10n.text(
                                            en: "Every system neon in one place",
                                            es: "Todos los neones en un solo lugar"
                                        ),
                                        systemImage: "sparkles",
                                        accent: Color(red: 0.10, green: 0.78, blue: 1.00)
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
        .alert(item: $sceneManager.notice) { notice in
            Alert(
                title: Text("Eagle Scenes"),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if sceneManager.isApplying {
                EagleBlockingProgress(
                    title: LaraL10n.text(
                        en: "Applying Scene safely",
                        es: "Aplicando Scene de forma segura"
                    ),
                    progress: sceneManager.progress
                )
            }
        }
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
                .accessibilityLabel(LaraL10n.text(en: "Language", es: "Idioma"))

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

            Text(LaraL10n.text(
                en: "Customize what you actually see.",
                es: "Personaliza lo que realmente ves."
            ))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var homeAccessCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: mgr.sbxready ? "checkmark.shield.fill" : "iphone.and.arrow.forward")
                    .foregroundStyle(mgr.sbxready ? .green : .blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mgr.sbxready
                         ? LaraL10n.text(en: "iPhone Prepared", es: "iPhone preparado")
                         : LaraL10n.text(en: "Prepare This iPhone", es: "Preparar este iPhone"))
                        .font(.headline)
                    Text(mgr.sbxready
                         ? LaraL10n.text(
                            en: "System customization access is ready.",
                            es: "El acceso para personalizar el sistema está listo."
                         )
                         : LaraL10n.text(
                            en: "Start secure access here without opening another screen.",
                            es: "Inicia aquí el acceso seguro sin abrir otra pantalla."
                         ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 2)

            LaraAccessView(compact: true)
        }
        .accessibilityElement(children: .contain)
    }

    private var trustNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(LaraL10n.text(en: "You stay in control", es: "Tú mantienes el control"))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Eagle requests access only when you choose to apply a change.",
                    es: "Eagle solicita acceso solo cuando eliges aplicar un cambio."
                ))
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

    let title: String
    let subtitle: String
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
    let title: String
    let subtitle: String
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
