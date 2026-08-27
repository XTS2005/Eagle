import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var mgr = laramgr.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @AppStorage("eagle.home.auraStudio.beta10Seen")
    private var hasSeenAuraStudioBeta10 = false
    @AppStorage("eagle.home.homeLabelColor.beta10Seen")
    private var hasSeenHomeLabelColorBeta10 = false
    @State private var toolSearchQuery = ""
    @FocusState private var isToolSearchFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    toolSearchField

                    if normalizedToolQuery.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            NavigationLink(destination: auraStudioDestination) {
                                AuraStudioHeroCard(
                                    title: "Aura Studio",
                                    subtitle: LaraL10n.text(
                                        en: "Dynamic Island neon, rainbow, and glow.",
                                        es: "Neón, arcoíris y brillo para Dynamic Island."
                                    ),
                                    badge: hasSeenAuraStudioBeta10
                                        ? nil
                                        : LaraL10n.text(en: "NEW", es: "NUEVO")
                                )
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(LaraL10n.text(en: "Customize one part", es: "Personalizar una parte"))
                                    .font(.headline)
                                    .padding(.horizontal, 2)
                                    .accessibilityAddTraits(.isHeader)

                                VStack(spacing: 0) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Icon Studio", es: "Icon Studio"),
                                        subtitle: LaraL10n.text(
                                            en: "Themes and custom shapes",
                                            es: "Temas y formas personalizadas"
                                        ),
                                        systemImage: "square.grid.2x2.fill",
                                        accent: Color(red: 0.18, green: 0.60, blue: 0.42),
                                        badge: LaraL10n.text(en: "SOON", es: "PRÓXIMAMENTE"),
                                        showsDisclosureIndicator: false
                                    )
                                    .opacity(0.62)
                                    .accessibilityHint(LaraL10n.text(
                                        en: "Icon Studio is coming soon",
                                        es: "Icon Studio estará disponible próximamente"
                                    ))

                                    Divider().padding(.leading, 65)

                                    NavigationLink(destination: AnimatedWallpapersView()) {
                                    LaraToolRow(
                                        title: LaraL10n.text(en: "Wallpapers", es: "Fondos"),
                                        subtitle: LaraL10n.text(en: "Explore or create", es: "Explora o crea"),
                                        systemImage: "photo.on.rectangle.angled",
                                        accent: Color(red: 0.34, green: 0.31, blue: 0.88)
                                    )
                                }

                                    Divider().padding(.leading, 65)

                                    NavigationLink(destination: PasscodeView(mgr: mgr)) {
                                        LaraToolRow(
                                            title: LaraL10n.text(en: "Passcode", es: "Código"),
                                            subtitle: LaraL10n.text(en: "Unlock key styles", es: "Números de desbloqueo"),
                                            systemImage: "circle.grid.3x3.fill",
                                            accent: Color(red: 0.56, green: 0.28, blue: 0.72)
                                        )
                                    }

                                    Divider().padding(.leading, 65)

                                    NavigationLink(destination: CardView()) {
                                        LaraToolRow(
                                            title: LaraL10n.text(en: "Cards", es: "Tarjetas"),
                                            subtitle: LaraL10n.text(en: "Wallet design", es: "Diseño de Wallet"),
                                            systemImage: "creditcard.fill",
                                            accent: Color(red: 0.08, green: 0.48, blue: 0.52)
                                        )
                                    }

                                    Divider().padding(.leading, 65)

                                    NavigationLink(destination: DockCustomizerView()) {
                                        LaraToolRow(
                                            title: "Dock",
                                            subtitle: LaraL10n.text(en: "Fit up to six apps", es: "Hasta seis apps"),
                                            systemImage: "dock.rectangle",
                                            accent: Color(red: 0.12, green: 0.46, blue: 0.86)
                                        )
                                    }

                                    Divider().padding(.leading, 65)

                                    NavigationLink(destination: homeLabelColorDestination) {
                                        LaraToolRow(
                                            title: LaraL10n.text(en: "App Name Color", es: "Color de nombres"),
                                            subtitle: LaraL10n.text(
                                                en: "Solid Home Screen text colors · Beta",
                                                es: "Colores sólidos para los textos de Inicio · Beta"
                                            ),
                                            systemImage: "textformat",
                                            accent: Color(red: 0.36, green: 0.30, blue: 0.88),
                                            badge: hasSeenHomeLabelColorBeta10
                                                ? nil
                                                : LaraL10n.text(en: "NEW", es: "NUEVO")
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(.primary.opacity(0.07), lineWidth: 1)
                                }
                            }

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
                        }
                    } else {
                        toolSearchResults
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    eagleTitle
                    Spacer(minLength: 8)
                    headerBadges
                }

                VStack(alignment: .leading, spacing: 10) {
                    eagleTitle
                    headerBadges
                }
            }

            Text(LaraL10n.text(
                en: "Customize what you actually see.",
                es: "Personaliza lo que realmente ves."
            ))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var eagleTitle: some View {
        HStack(spacing: 10) {
            Text("Eagle")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(EagleSpectrumStyle.wordmarkGradient)
                .minimumScaleFactor(0.82)
                .accessibilityAddTraits(.isHeader)

            EagleSmileyFlower(size: 40)
        }
    }

    private var headerBadges: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                languageBadge
                readinessBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                languageBadge
                readinessBadge
            }
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

    private var readinessBadge: some View {
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
                ? LaraL10n.text(en: "Eagle is ready", es: "Eagle está lista")
                : LaraL10n.text(en: "Eagle needs preparation", es: "Eagle necesita preparación")
        )
    }

    private var normalizedToolQuery: String {
        toolSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var availableToolRoutes: [LaraHomeToolRoute] {
        LaraHomeToolRoute.allCases.filter { route in
            switch route {
            case .auraStudio, .completeStyles, .wallpapers,
                    .homeLabelColor, .cards, .passcode, .icons, .dock:
                return true
            case .eagleSystem, .advancedSettings:
                return false
            }
        }
    }

    private var filteredToolRoutes: [LaraHomeToolRoute] {
        guard !normalizedToolQuery.isEmpty else { return [] }
        return availableToolRoutes.filter { route in
            let searchableText = "\(route.title) \(route.subtitle) \(route.keywords)"
            return searchableText.range(
                of: normalizedToolQuery,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ) != nil
        }
    }

    private var toolSearchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(
                LaraL10n.text(en: "Search tools", es: "Buscar herramientas"),
                text: $toolSearchQuery
            )
            .focused($isToolSearchFocused)
            .submitLabel(.search)
            .onSubmit {
                isToolSearchFocused = false
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(minHeight: 44)
            .accessibilityLabel(LaraL10n.text(
                en: "Search tools",
                es: "Buscar herramientas"
            ))
            .accessibilityHint(LaraL10n.text(
                en: "Searches every customization tool.",
                es: "Busca en todas las herramientas de personalización."
            ))

            if !toolSearchQuery.isEmpty {
                Button {
                    toolSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LaraL10n.text(
                    en: "Clear search",
                    es: "Limpiar búsqueda"
                ))
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, toolSearchQuery.isEmpty ? 14 : 4)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.07), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var toolSearchResults: some View {
        if filteredToolRoutes.isEmpty {
            VStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(LaraL10n.text(
                    en: "No matching tools",
                    es: "No hay herramientas coincidentes"
                ))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(LaraL10n.text(
                    en: "Try another customization name.",
                    es: "Prueba otro nombre de personalización."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .padding(.horizontal, 18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 0) {
                ForEach(filteredToolRoutes) { route in
                    searchResult(for: route)
                    if route != filteredToolRoutes.last {
                        Divider().padding(.leading, 65)
                    }
                }
            }
            .buttonStyle(.plain)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.primary.opacity(0.07), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func searchResult(for route: LaraHomeToolRoute) -> some View {
        if route == .icons {
            toolSearchRow(for: route)
                .opacity(0.62)
                .accessibilityHint(LaraL10n.text(
                    en: "Icon Studio is coming soon",
                    es: "Icon Studio estará disponible próximamente"
                ))
        } else {
            NavigationLink {
                toolDestination(for: route)
            } label: {
                toolSearchRow(for: route)
            }
            .accessibilityHint(LaraL10n.text(
                en: "Opens \(route.title)",
                es: "Abre \(route.title)"
            ))
        }
    }

    private func toolSearchRow(for route: LaraHomeToolRoute) -> some View {
        LaraToolRow(
            title: route.title,
            subtitle: route.subtitle,
            systemImage: route.systemImage,
            accent: route.accent,
            badge: route == .icons
                ? LaraL10n.text(en: "SOON", es: "PRÓXIMAMENTE")
                : (route == .auraStudio && !hasSeenAuraStudioBeta10
                    ? LaraL10n.text(en: "NEW", es: "NUEVO")
                    : (route == .homeLabelColor && !hasSeenHomeLabelColorBeta10
                        ? LaraL10n.text(en: "NEW", es: "NUEVO")
                        : nil)),
            showsDisclosureIndicator: route != .icons
        )
    }

    @ViewBuilder
    private func toolDestination(for route: LaraHomeToolRoute) -> some View {
        switch route {
        case .completeStyles:
            CompleteStylesView()
        case .eagleSystem:
            EagleSystemView()
        case .wallpapers:
            AnimatedWallpapersView()
        case .homeLabelColor:
            homeLabelColorDestination
        case .cards:
            CardView()
        case .passcode:
            PasscodeView(mgr: mgr)
        case .icons:
            DarkBoardView()
        case .dock:
            DockCustomizerView()
        case .advancedSettings:
            EmptyView()
        case .auraStudio:
            auraStudioDestination
        }
    }

    private var auraStudioDestination: some View {
        AuraStudioView()
            .onAppear {
                hasSeenAuraStudioBeta10 = true
            }
    }

    private var homeLabelColorDestination: some View {
        HomeLabelColorView()
            .onAppear {
                hasSeenHomeLabelColorBeta10 = true
            }
    }

}

private enum LaraHomeToolRoute: String, CaseIterable, Identifiable {
    case auraStudio
    case completeStyles
    case eagleSystem
    case wallpapers
    case homeLabelColor
    case cards
    case passcode
    case icons
    case dock
    case advancedSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completeStyles: return LaraL10n.text(en: "Styles", es: "Estilos")
        case .eagleSystem: return "Eagle System"
        case .wallpapers: return LaraL10n.text(en: "Wallpapers", es: "Fondos")
        case .homeLabelColor:
            return LaraL10n.text(en: "App Name Color", es: "Color de nombres")
        case .cards: return LaraL10n.text(en: "Cards", es: "Tarjetas")
        case .passcode: return LaraL10n.text(en: "Passcode", es: "Código")
        case .icons: return "Icon Studio"
        case .dock: return "Dock"
        case .advancedSettings:
            return LaraL10n.text(en: "Advanced system tools", es: "Herramientas avanzadas")
        case .auraStudio: return "Aura Studio"
        }
    }

    var subtitle: String {
        switch self {
        case .completeStyles:
            return LaraL10n.text(en: "Complete visual styles", es: "Estilos visuales completos")
        case .eagleSystem:
            return LaraL10n.text(en: "Guardian and recovery", es: "Guardian y recuperación")
        case .wallpapers:
            return LaraL10n.text(en: "Explore or create", es: "Explora o crea")
        case .homeLabelColor:
            return LaraL10n.text(
                en: "Solid Home Screen text colors · Beta",
                es: "Colores sólidos para los textos de Inicio · Beta"
            )
        case .cards:
            return LaraL10n.text(en: "Wallet design", es: "Diseño de Wallet")
        case .passcode:
            return LaraL10n.text(en: "Unlock key styles", es: "Números de desbloqueo")
        case .icons:
            return LaraL10n.text(en: "Themes and Android shapes", es: "Temas y formas Android")
        case .dock:
            return LaraL10n.text(en: "Fit up to six apps", es: "Hasta seis apps")
        case .advancedSettings:
            return LaraL10n.text(en: "Expert controls", es: "Controles expertos")
        case .auraStudio:
            return LaraL10n.text(en: "System neon controls", es: "Controles de neón del sistema")
        }
    }

    var systemImage: String {
        switch self {
        case .completeStyles: return "sparkles"
        case .eagleSystem: return "checkmark.shield.fill"
        case .wallpapers: return "photo.on.rectangle.angled"
        case .homeLabelColor: return "textformat"
        case .cards: return "creditcard.fill"
        case .passcode: return "circle.grid.3x3.fill"
        case .icons: return "square.grid.2x2.fill"
        case .dock: return "dock.rectangle"
        case .advancedSettings: return "wrench.and.screwdriver.fill"
        case .auraStudio: return "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .completeStyles: return Color(red: 0.33, green: 0.25, blue: 0.82)
        case .eagleSystem: return .indigo
        case .wallpapers: return Color(red: 0.34, green: 0.31, blue: 0.88)
        case .homeLabelColor: return Color(red: 0.36, green: 0.30, blue: 0.88)
        case .cards: return Color(red: 0.08, green: 0.48, blue: 0.52)
        case .passcode: return Color(red: 0.56, green: 0.28, blue: 0.72)
        case .icons: return Color(red: 0.18, green: 0.60, blue: 0.42)
        case .dock: return Color(red: 0.12, green: 0.46, blue: 0.86)
        case .advancedSettings: return .orange
        case .auraStudio: return Color(red: 0.10, green: 0.78, blue: 1.00)
        }
    }

    var keywords: String {
        switch self {
        case .completeStyles: return "style styles estilo estilos complete completo visual"
        case .eagleSystem: return "system sistema guardian recovery recuperación"
        case .wallpapers: return "wallpaper wallpapers fondo fondos creator creador gallery galería"
        case .homeLabelColor:
            return "text color label labels name names texto color nombre nombres home inicio solid sólido"
        case .cards: return "card cards tarjeta tarjetas wallet"
        case .passcode: return "passcode code código unlock desbloqueo key keys números"
        case .icons: return "icon icons icono iconos theme themes tema temas android shape formas"
        case .dock: return "dock apps icons iconos capacity capacidad"
        case .advancedSettings: return "advanced avanzado settings ajustes expert experto kernelcache"
        case .auraStudio: return "aura neon neón island isla dock glow"
        }
    }
}

private struct LaraFeatureCard: View {
    enum Artwork {
        case aura
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
    let badge: String?

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        accent: Color,
        artwork: Artwork,
        badge: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.accent = accent
        self.artwork = artwork
        self.badge = badge
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                accent.opacity(0.12)

                switch artwork {
                case .aura:
                    auraArtwork
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
            .accessibilityHidden(true)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 1)

            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

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
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(18)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .frame(minHeight: 25)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .padding(12)
                    .accessibilityLabel(LaraL10n.text(en: "New", es: "Nuevo"))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
    }

    private var auraArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.11, green: 0.05, blue: 0.24), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Capsule(style: .continuous)
                .stroke(Color.purple.opacity(0.20), lineWidth: 15)
                .frame(width: 164, height: 58)
                .blur(radius: 13)

            Capsule(style: .continuous)
                .fill(Color.black)
                .frame(width: 154, height: 49)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [.cyan, .blue, .purple, .pink, .orange, .cyan],
                                center: .center
                            ),
                            lineWidth: 3.5
                        )
                }
                .shadow(color: .cyan.opacity(0.52), radius: 11)
                .shadow(color: .pink.opacity(0.34), radius: 20)
        }
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
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.primary)
                    HStack {
                        Text("•••• 4242")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        Image(systemName: "apple.logo")
                            .foregroundStyle(.primary)
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

private struct AuraStudioHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    var badge: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            neonCapsule

            VStack(alignment: .leading, spacing: -2) {
                Text("Aura")
                Text("Studio")
            }
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(auraBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0 : 0.16),
            radius: 14, x: 0, y: 8
        )
        .overlay(alignment: .topTrailing) {
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .frame(minHeight: 25)
                    .background(Color.white.opacity(0.18), in: Capsule())
                    .padding(12)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
    }

    private var auraBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.17, green: 0.11, blue: 0.32),
                        Color(red: 0.09, green: 0.05, blue: 0.19),
                    ]
                    : [
                        Color(red: 0.44, green: 0.28, blue: 0.86),
                        Color(red: 0.27, green: 0.15, blue: 0.60),
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    (colorScheme == .dark
                        ? Color(red: 0.42, green: 0.24, blue: 0.86)
                        : Color(red: 0.70, green: 0.52, blue: 1.0))
                        .opacity(colorScheme == .dark ? 0.45 : 0.5),
                    .clear,
                ],
                center: UnitPoint(x: 0.26, y: 0.5),
                startRadius: 4,
                endRadius: 210
            )
        }
    }

    private var neonCapsule: some View {
        ZStack {
            Capsule(style: .continuous)
                .stroke(Color.purple.opacity(0.30), lineWidth: 15)
                .frame(width: 128, height: 48)
                .blur(radius: 14)

            Capsule(style: .continuous)
                .fill(Color.black)
                .frame(width: 122, height: 44)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [.cyan, .blue, .purple, .pink, .orange, .cyan],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                }
                .shadow(color: .cyan.opacity(0.5), radius: 10)
                .shadow(color: .pink.opacity(0.36), radius: 16)
        }
        .frame(width: 138, height: 96)
        .accessibilityHidden(true)
    }
}

private struct LaraToolRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    var badge: String? = nil
    var showsDisclosureIndicator = true

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(accent)
                .frame(width: 38, height: 38)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if let badge {
                Text(badge)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .frame(minHeight: 22)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .accessibilityHidden(true)
            }
            if showsDisclosureIndicator {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(
            badge == nil ? subtitle : "\(subtitle). \(badge ?? "")"
        )
    }
}
