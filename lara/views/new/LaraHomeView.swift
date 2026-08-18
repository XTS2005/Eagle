import SwiftUI

struct LaraHomeView: View {
    @ObservedObject private var mgr = laramgr.shared
    @ObservedObject private var sceneManager = EagleSceneManager.shared
    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english
    @AppStorage(EagleInterfaceMode.storageKey) private var interfaceMode = EagleInterfaceMode.simple
    @AppStorage(EagleReleaseChannel.storageKey)
    private var channelRaw = EagleReleaseChannel.stable.rawValue
    @State private var showingAdvancedSystemTools = false
    @State private var toolSearchQuery = ""

    private var channel: EagleReleaseChannel {
        EagleFeaturePolicy.channel(from: channelRaw)
    }

    private func allows(_ feature: EagleProductFeature) -> Bool {
        EagleFeaturePolicy.allows(feature, channel: channel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    if interfaceMode == .advanced &&
                        allows(.scenes) &&
                        sceneManager.hasPendingShortcut {
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

                    interfaceModeControl
                    compatibilityLink
                    toolSearchField

                    if normalizedToolQuery.isEmpty {
                        if interfaceMode == .advanced {
                            EaglePrepareCrashReportCard()
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

                        if interfaceMode == .advanced {
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
                                            en: allows(.scenes)
                                                ? "Guardian, Scenes, and safe sharing"
                                                : "Verified recovery for every change",
                                            es: allows(.scenes)
                                                ? "Guardian, Escenas y uso compartido seguro"
                                                : "Recuperación verificada para cada cambio"
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
                        }

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

                                if interfaceMode == .advanced {
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

                                    if allows(.advancedSystemTools) {
                                        Divider().padding(.leading, 62)

                                        Button {
                                            showingAdvancedSystemTools = true
                                        } label: {
                                            LaraToolRow(
                                                title: LaraL10n.text(
                                                    en: "Advanced system tools",
                                                    es: "Herramientas avanzadas del sistema"
                                                ),
                                                subtitle: LaraL10n.text(
                                                    en: "Kernelcache, RemoteCall, and expert controls",
                                                    es: "Kernelcache, RemoteCall y controles expertos"
                                                ),
                                                systemImage: "wrench.and.screwdriver.fill",
                                                accent: .orange
                                            )
                                        }
                                        .accessibilityHint(LaraL10n.text(
                                            en: "Opens Experimental system settings",
                                            es: "Abre los ajustes experimentales del sistema"
                                        ))
                                    }
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
                    } else {
                        toolSearchResults
                    }

                    trustNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
            .scrollDismissesKeyboard(.interactively)
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
        .sheet(isPresented: $showingAdvancedSystemTools) {
            SettingsView()
                .environmentObject(mgr)
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
        Text("Eagle")
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.82)
    }

    private var headerBadges: some View {
        HStack(spacing: 8) {
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
                .frame(minHeight: 34)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .overlay {
                    Capsule().strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                }
            }
            .accessibilityLabel(LaraL10n.text(en: "Language", es: "Idioma"))
            .accessibilityValue(language.displayName)

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
    }

    private var interfaceModeControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: interfaceMode == .simple
                      ? "rectangle.grid.1x2.fill"
                      : "slider.horizontal.3")
                    .foregroundStyle(interfaceMode == .simple ? .blue : .orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LaraL10n.text(en: "Interface mode", es: "Modo de interfaz"))
                        .font(.subheadline.weight(.semibold))
                    Text(interfaceMode.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            Picker(
                LaraL10n.text(en: "Interface mode", es: "Modo de interfaz"),
                selection: $interfaceMode
            ) {
                ForEach(EagleInterfaceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(LaraL10n.text(en: "Interface mode", es: "Modo de interfaz"))
            .accessibilityValue(interfaceMode.title)
            .accessibilityHint(LaraL10n.text(
                en: "Simple shows the essential destinations. Advanced reveals the tools allowed by your feature channel.",
                es: "Simple muestra los destinos esenciales. Avanzado revela las herramientas permitidas por tu canal de funciones."
            ))
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private var compatibilityLink: some View {
        NavigationLink(destination: EagleCompatibilityCenterView()) {
            HStack(spacing: 13) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 42, height: 42)
                    .background(Color.blue.opacity(0.11), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(LaraL10n.text(en: "Compatibility", es: "Compatibilidad"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(LaraL10n.text(
                        en: "\(channel.title) channel · Device support and reports",
                        es: "Canal \(channel.title) · Compatibilidad y reportes"
                    ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(LaraL10n.text(en: "Compatibility", es: "Compatibilidad"))
        .accessibilityValue(channel.title)
        .accessibilityHint(LaraL10n.text(
            en: "Shows device support, feature channels, and Prepare reports",
            es: "Muestra compatibilidad, canales de funciones y reportes de Preparar"
        ))
    }

    private var normalizedToolQuery: String {
        toolSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var availableToolRoutes: [LaraHomeToolRoute] {
        LaraHomeToolRoute.allCases.filter { route in
            switch route {
            case .completeStyles:
                return allows(.completeStyles)
            case .wallpapers:
                return allows(.wallpapers)
            case .auraStudio:
                return allows(.islandGlow) || allows(.dockGlow)
            case .eagleSystem, .cards, .passcode, .icons, .dock:
                return interfaceMode == .advanced
            case .advancedSettings:
                return interfaceMode == .advanced && allows(.advancedSystemTools)
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
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .frame(minHeight: 44)
            .accessibilityLabel(LaraL10n.text(
                en: "Search tools",
                es: "Buscar herramientas"
            ))
            .accessibilityHint(LaraL10n.text(
                en: "Results follow the current interface mode and feature channel.",
                es: "Los resultados respetan el modo de interfaz y el canal actuales."
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
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
                Text(LaraL10n.text(
                    en: "Available results follow \(interfaceMode.title) · \(channel.title).",
                    es: "Los resultados disponibles respetan \(interfaceMode.title) · \(channel.title)."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .padding(.horizontal, 18)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityElement(children: .combine)
        } else {
            VStack(spacing: 0) {
                ForEach(filteredToolRoutes) { route in
                    searchResult(for: route)
                    if route != filteredToolRoutes.last {
                        Divider().padding(.leading, 62)
                    }
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

    @ViewBuilder
    private func searchResult(for route: LaraHomeToolRoute) -> some View {
        if route == .advancedSettings {
            Button {
                showingAdvancedSystemTools = true
            } label: {
                toolSearchRow(for: route)
            }
            .accessibilityHint(LaraL10n.text(
                en: "Opens advanced settings",
                es: "Abre los ajustes avanzados"
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
            accent: route.accent
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(route.title)
        .accessibilityValue(route.subtitle)
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
            AuraStudioView()
        }
    }

    private var homeAccessCard: some View {
        LaraAccessView(compact: false)
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
                    en: "Preparation starts only when you press Prepare iPhone. If the device restarts, reopen Eagle and try again; a report can be created only when you request it.",
                    es: "La preparación comienza solo cuando pulsas Preparar iPhone. Si el dispositivo se reinicia, vuelve a abrir Eagle e inténtalo otra vez; el reporte se crea solo cuando tú lo solicitas."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

private enum LaraHomeToolRoute: String, CaseIterable, Identifiable {
    case completeStyles
    case eagleSystem
    case wallpapers
    case cards
    case passcode
    case icons
    case dock
    case advancedSettings
    case auraStudio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .completeStyles: return LaraL10n.text(en: "Styles", es: "Estilos")
        case .eagleSystem: return "Eagle System"
        case .wallpapers: return LaraL10n.text(en: "Wallpapers", es: "Fondos")
        case .cards: return LaraL10n.text(en: "Cards", es: "Tarjetas")
        case .passcode: return LaraL10n.text(en: "Passcode", es: "Código")
        case .icons: return LaraL10n.text(en: "Icons", es: "Iconos")
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
            .accessibilityHidden(true)

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
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
                    .fixedSize(horizontal: false, vertical: true)
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
