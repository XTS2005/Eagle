import SwiftUI
import UIKit

/// One identity per artwork, including every Live style that shares native mode 36.
struct IslandGalleryArtwork: Identifiable {
    let style: IslandGalleryStyle
    var liveTheme: IslandLiveTheme? = nil
    var id: String { liveTheme?.id ?? (style == .singularityLive ? "singularity-live" : "island-\(style.rawValue)") }
    var isLive: Bool { style == .singularityLive }
    var title: String { liveTheme.map { LaraL10n.text(en: $0.title, es: $0.titleES) } ?? style.title }
    var subtitle: String {
        if isLive { return LaraL10n.text(en: "Art in motion. Made for your Island.", es: "Arte en movimiento. Hecho para tu isla.") }
        return style.subtitle
    }
    var accent: Color {
        guard let rgb = liveTheme?.rgb else { return style.accent }
        return Color(red: Double(rgb.red) / 255, green: Double(rgb.green) / 255, blue: Double(rgb.blue) / 255)
    }
    var posterURL: URL? { isLive ? (liveTheme?.posterURL ?? IslandLiveMedia.posterURL) : nil }
    var motionURL: URL? { isLive ? (liveTheme?.previewURL ?? IslandLiveMedia.previewURL) : nil }
}

enum IslandGalleryFilter: String, CaseIterable, Identifiable {
    case all, live, still, favorites
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return LaraL10n.text(en: "All", es: "Todo")
        case .live: return "Live"
        case .still: return "Static"
        case .favorites: return "Saves"
        }
    }
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .live: return "play.circle"
        case .still: return "sparkles"
        case .favorites: return "heart"
        }
    }
    func includes(_ artwork: IslandGalleryArtwork, favorites: Set<String>) -> Bool {
        switch self {
        case .all: return true
        case .live: return artwork.isLive
        case .still: return !artwork.isLive
        case .favorites: return favorites.contains(artwork.id)
        }
    }
}

struct IslandGalleryView: View {
    @ObservedObject private var manager = laramgr.shared
    @AppStorage("eagle.islandGallery.selectedStyle") private var selectedRaw = IslandGalleryStyle.starlight.rawValue
    @AppStorage("eagle.islandGallery.selectedArtworkID") private var selectedID = ""
    @AppStorage("eagle.islandGallery.favoriteIDs") private var favoritesJSON = "[]"
    @AppStorage("eagle.islandGallery.shadowIntensity") private var shadowIntensity = 0.72
    @AppStorage("eagle.auraStudio.activeFlags") private var activeFlagsRaw = 0
    @AppStorage("eagle.auraStudio.activeIslandMode") private var activeIslandModeRaw = 0
    @AppStorage("eagle.islandGallery.activeLiveID") private var activeLiveID = "singularity-live"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicType
    @State private var liveThemes: [IslandLiveTheme] = []
    @State private var loading = false
    @State private var loadFailed = false
    @State private var filter: IslandGalleryFilter = .all
    @State private var search = ""
    @State private var motionPaused = false
    @State private var applying = false
    @State private var showAccess = false
    @State private var result: IslandGalleryApplyResult?
    @State private var rememberedSelections: [IslandGalleryFilter: String] = [:]

    private var artworks: [IslandGalleryArtwork] {
        IslandGalleryStyle.allCases.map { style in
            IslandGalleryArtwork(style: style, liveTheme: style == .singularityLive
                ? liveThemes.first(where: { $0.id == "singularity-live" }) : nil)
        } + liveThemes.filter { $0.id != "singularity-live" }.map { IslandGalleryArtwork(style: .singularityLive, liveTheme: $0) }
    }
    private var favorites: Set<String> {
        guard let data = favoritesJSON.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(ids)
    }
    private var visibleArtworks: [IslandGalleryArtwork] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return artworks.filter { item in
            filter.includes(item, favorites: favorites) &&
                (query.isEmpty || item.title.localizedStandardContains(query) ||
                 item.subtitle.localizedStandardContains(query) || item.id.localizedStandardContains(query))
        }
    }
    private var selected: IslandGalleryArtwork? {
        visibleArtworks.first(where: { $0.id == selectedID }) ?? visibleArtworks.first
    }
    private var activeArtwork: IslandGalleryArtwork? {
        artworks.first(where: isActive)
    }
    private func isActive(_ item: IslandGalleryArtwork) -> Bool {
        (activeFlagsRaw & 1) != 0 && activeIslandModeRaw == item.style.rawValue &&
            (!item.isLive || activeLiveID == item.id)
    }
    private var selectionIndex: Int {
        visibleArtworks.firstIndex(where: { $0.id == selected?.id }) ?? 0
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    filterPicker
                    if let item = selected {
                        featuredPresentation(item)
                            .id("island-featured")
                    }
                    collectionSection(proxy: proxy)
                    if loadFailed { catalogRetry }
                    if loading {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(LaraL10n.text(en: "Loading the Live collection…", es: "Cargando la colección Live…"))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if let active = activeArtwork {
                        activeStyleSummary(active)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            actionBar
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Island Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await loadCatalog(force: true) } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(loading || applying)
                    .accessibilityLabel(LaraL10n.text(en: "Refresh collection", es: "Actualizar colección"))
                }
            }
            .sheet(isPresented: $showAccess) { accessSheet }
            .alert(
                result?.succeeded == true
                    ? LaraL10n.text(en: "Island updated", es: "Island actualizada")
                    : LaraL10n.text(en: "Could not apply", es: "No se pudo aplicar"),
                isPresented: Binding(get: { result != nil }, set: { if !$0 { result = nil } })
            ) {
                Button(LaraL10n.text(en: "Done", es: "Listo"), role: .cancel) { result = nil }
            } message: { Text(result?.message ?? "") }
            .task { await loadCatalog() }
            .onAppear { restoreSelection() }
            .onChange(of: search) { _ in synchronizeSelection() }
            .onChange(of: favoritesJSON) { _ in synchronizeSelection() }
        }
    }

    private var filterPicker: some View {
        ViewThatFits(in: .horizontal) {
            filterButtons
            ScrollView(.horizontal, showsIndicators: false) { filterButtons }
        }
    }

    private var filterButtons: some View {
        HStack(spacing: 6) {
            ForEach(IslandGalleryFilter.allCases) { option in
                Button { selectFilter(option) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: option.icon).font(.system(size: 11, weight: .semibold))
                        Text(option.title).font(.system(size: 12, weight: .semibold))
                    }
                    .fixedSize()
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(filter == option ? Color(uiColor: .systemBackground) : .primary)
                    .background(filter == option ? Color.primary : .clear, in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .disabled(applying)
                .accessibilityAddTraits(filter == option ? .isSelected : [])
                .accessibilityIdentifier("island-filter-\(option.rawValue)")
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 17))
    }

    private func featuredPresentation(_ item: IslandGalleryArtwork) -> some View {
        VStack(spacing: 16) {
            IslandGalleryStage(
                artwork: item,
                playing: !applying && !motionPaused && !reduceMotion,
                active: isActive(item),
                shadowIntensity: shadowIntensity
            )
                .id(item.id)
                .contentShape(RoundedRectangle(cornerRadius: 30))
                .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { gesture in
                    guard abs(gesture.translation.width) > abs(gesture.translation.height) else { return }
                    step(gesture.translation.width < 0 ? 1 : -1)
                })
            shadowControl
            HStack(spacing: 12) {
                navigationButton("chevron.left", direction: -1)
                VStack(spacing: 3) {
                    Text(String(format: "%02d", selectionIndex + 1) + " / " + String(format: "%02d", visibleArtworks.count))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                if item.isLive {
                    Button { motionPaused.toggle() } label: {
                        Image(systemName: motionPaused || reduceMotion ? "play.fill" : "pause.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(Color.primary.opacity(0.05), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(reduceMotion)
                    .accessibilityLabel(motionPaused
                        ? LaraL10n.text(en: "Play preview", es: "Reproducir vista previa")
                        : LaraL10n.text(en: "Pause preview", es: "Pausar vista previa"))
                }
                favoriteButton(item)
                navigationButton("chevron.right", direction: 1)
            }
        }
    }

    private var shadowControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LaraL10n.text(en: "Shadow", es: "Sombra"), systemImage: "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(shadowIntensity <= 0.005
                    ? LaraL10n.text(en: "Off", es: "Sin sombra")
                    : "\(Int((shadowIntensity * 100).rounded()))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $shadowIntensity, in: 0...1, step: 0.01)
                .tint(.primary)
                .disabled(applying)
                .accessibilityLabel(LaraL10n.text(
                    en: "Island shadow intensity",
                    es: "Intensidad de sombra de Island"
                ))
                .accessibilityValue(shadowIntensity <= 0.005
                    ? LaraL10n.text(en: "No shadow", es: "Sin sombra")
                    : "\(Int((shadowIntensity * 100).rounded()))%")
        }
        .padding(.horizontal, 2)
    }

    private func navigationButton(_ symbol: String, direction: Int) -> some View {
        Button { step(direction) } label: {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold))
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(applying || visibleArtworks.count < 2)
        .accessibilityLabel(direction < 0
            ? LaraL10n.text(en: "Previous style", es: "Estilo anterior")
            : LaraL10n.text(en: "Next style", es: "Estilo siguiente"))
        .accessibilityIdentifier(direction < 0 ? "island-previous" : "island-next")
    }

    private func collectionSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(filter == .favorites
                    ? LaraL10n.text(en: "Your collection", es: "Tu colección")
                    : LaraL10n.text(en: "Collection", es: "Colección"))
                    .font(.headline).tracking(-0.4)
                Spacer(minLength: 8)
                Text("\(visibleArtworks.count)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            searchField
            if visibleArtworks.isEmpty { emptyCollection }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicType.isAccessibilitySize ? 260 : 145), spacing: 12)],
                      spacing: 12) {
                ForEach(visibleArtworks) { item in
                    collectionTile(item) {
                        select(item)
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                            proxy.scrollTo("island-featured", anchor: .top)
                        }
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(LaraL10n.text(en: "Find a style…", es: "Busca un estilo…"), text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier("island-search")
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        .frame(width: 28, height: 36)
                }
                .accessibilityLabel(LaraL10n.text(en: "Clear search", es: "Borrar búsqueda"))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
        .disabled(applying)
    }

    private func collectionTile(_ item: IslandGalleryArtwork, action: @escaping () -> Void) -> some View {
        let isSelected = item.id == selected?.id
        return VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                ZStack {
                    Color(red: 0.045, green: 0.047, blue: 0.06)
                    RadialGradient(colors: [item.accent.opacity(0.3), .clear], center: .center,
                                   startRadius: 0, endRadius: 100)
                    IslandGalleryArtworkImage(artwork: item, animated: false, compact: true)
                        .aspectRatio(2.4, contentMode: .fit)
                        .padding(.horizontal, 10)
                        .shadow(color: item.accent.opacity(0.4), radius: 9)
                    VStack {
                        HStack(spacing: 4) {
                            Image(systemName: item.isLive ? "play.fill" : "sparkle")
                            Text(item.isLive ? "LIVE" : "STATIC")
                            Spacer()
                            if isActive(item) { Image(systemName: "checkmark.seal.fill").foregroundStyle(.mint) }
                        }
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(1).foregroundStyle(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(12)
                }
                .frame(height: 107)
                .clipShape(RoundedRectangle(cornerRadius: 19))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LaraL10n.text(en: "Preview \(item.title)", es: "Ver \(item.title)"))
            .disabled(applying)
            HStack(spacing: 2) {
                Button(action: action) {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .disabled(applying)
                Button { toggleFavorite(item) } label: {
                    Image(systemName: favorites.contains(item.id) ? "heart.fill" : "heart")
                        .font(.system(size: 12))
                        .foregroundStyle(favorites.contains(item.id) ? .pink : .secondary)
                        .frame(width: 34, height: 44)
                }
                .buttonStyle(.plain)
                .disabled(applying)
                .accessibilityLabel(favoriteLabel(item))
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .padding(.vertical, 4)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 19))
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .strokeBorder(isSelected ? item.accent.opacity(0.9) : Color.primary.opacity(0.065), lineWidth: isSelected ? 1.5 : 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("island-tile-\(item.id)")
    }

    private var emptyCollection: some View {
        VStack(spacing: 14) {
            Image(systemName: filter == .favorites ? "heart" : "sparkle.magnifyingglass")
                .font(.system(size: 32, weight: .light)).foregroundStyle(.secondary)
            Text(filter == .favorites && search.isEmpty
                ? LaraL10n.text(en: "No favorites yet", es: "Sin favoritos")
                : LaraL10n.text(en: "No matching styles.", es: "No encontramos ese estilo."))
                .font(.headline)
            Button(LaraL10n.text(en: "Explore all", es: "Explorar todo")) {
                search = ""
                selectFilter(.all)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 18)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 24))
    }

    private var catalogRetry: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").foregroundStyle(.orange)
            Text(LaraL10n.text(en: "The Live collection couldn't be refreshed.", es: "No pudimos actualizar la colección Live."))
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Button(LaraL10n.text(en: "Retry", es: "Reintentar")) { Task { await loadCatalog(force: true) } }
                .font(.caption.weight(.semibold)).disabled(loading || applying)
        }
        .padding(14)
        .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }

    private func activeStyleSummary(_ item: IslandGalleryArtwork) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(.mint)
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(LaraL10n.text(en: "ON YOUR ISLAND", es: "EN TU ISLAND"))
                    .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.4).foregroundStyle(.secondary)
                Text(item.title).font(.subheadline.weight(.semibold))
            }
            Spacer()
            Button(role: .destructive) { restore() } label: {
                Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44)
            }
            .disabled(applying)
            .accessibilityLabel(LaraL10n.text(en: "Restore original Island", es: "Restaurar Island original"))
        }
        .padding(14)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder private var actionBar: some View {
        if let item = selected {
            HStack(spacing: 10) {
                Button {
                    if !manager.dsready { showAccess = true }
                    else { apply(item) }
                } label: {
                    HStack(spacing: 8) {
                        if applying { ProgressView().tint(.white) }
                        else {
                            Image(systemName: !manager.dsready
                                ? "lock.shield.fill"
                                : (isActive(item) ? "arrow.clockwise" : "arrow.down.circle.fill"))
                        }
                        Text(!manager.dsready
                            ? LaraL10n.text(en: "Prepare to apply", es: "Preparar para aplicar")
                            : (isActive(item)
                                ? LaraL10n.text(en: "Reapply \(item.title)", es: "Reaplicar \(item.title)")
                                : LaraL10n.text(en: "Apply \(item.title)", es: "Aplicar \(item.title)")))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(!manager.dsready ? .blue : item.accent)
                .accessibilityIdentifier("island-apply")

                if isActive(item) && manager.dsready {
                    Button(role: .destructive) { restore() } label: {
                        Image(systemName: "trash.fill")
                            .font(.headline)
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .accessibilityLabel(LaraL10n.text(en: "Remove Island theme", es: "Quitar tema de Island"))
                    .accessibilityIdentifier("island-remove")
                }
            }
            .disabled(applying)
            .padding(.horizontal, 20)
            .padding(.top, 13)
            .padding(.bottom, 12)
            .background(Color(uiColor: .systemBackground))
            .overlay(alignment: .top) { Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 0.5) }
        }
    }

    private var accessSheet: some View {
        NavigationStack {
            ScrollView {
                LaraAccessView(compact: true) { showAccess = false }.padding(20)
            }
            .navigationTitle(LaraL10n.text(en: "Prepare Eagle", es: "Preparar Eagle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LaraL10n.text(en: "Done", es: "Listo")) { showAccess = false }
                }
            }
        }
    }

    private func favoriteButton(_ item: IslandGalleryArtwork) -> some View {
        Button { toggleFavorite(item) } label: {
            Image(systemName: favorites.contains(item.id) ? "heart.fill" : "heart")
                .font(.system(size: 16))
                .foregroundStyle(favorites.contains(item.id) ? Color.pink : .primary)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.05), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(applying)
        .accessibilityLabel(favoriteLabel(item))
        .accessibilityIdentifier("island-favorite")
    }

    private func favoriteLabel(_ item: IslandGalleryArtwork) -> String {
        favorites.contains(item.id)
            ? LaraL10n.text(en: "Remove \(item.title) from favorites", es: "Quitar \(item.title) de favoritos")
            : LaraL10n.text(en: "Save \(item.title) to favorites", es: "Guardar \(item.title) en favoritos")
    }

    private func toggleFavorite(_ item: IslandGalleryArtwork) {
        guard !applying else { return }
        var ids = favorites
        if !ids.insert(item.id).inserted { ids.remove(item.id) }
        if let data = try? JSONEncoder().encode(ids.sorted()), let json = String(data: data, encoding: .utf8) {
            favoritesJSON = json
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func select(_ item: IslandGalleryArtwork) {
        guard !applying else { return }
        selectedID = item.id
        selectedRaw = item.style.rawValue
        rememberedSelections[filter] = item.id
        UISelectionFeedbackGenerator().selectionChanged()
    }

    private func selectFilter(_ value: IslandGalleryFilter) {
        guard !applying else { return }
        if let selected { rememberedSelections[filter] = selected.id }
        filter = value
        if let remembered = rememberedSelections[value], visibleArtworks.contains(where: { $0.id == remembered }) {
            selectedID = remembered
        }
        synchronizeSelection()
        if let selected { selectedRaw = selected.style.rawValue }
    }

    private func synchronizeSelection() {
        guard !applying else { return }
        if !visibleArtworks.contains(where: { $0.id == selectedID }), let first = visibleArtworks.first {
            selectedID = first.id
            selectedRaw = first.style.rawValue
        }
    }

    private func restoreSelection() {
        guard selectedID.isEmpty else { return }
        if (activeFlagsRaw & 1) != 0 && activeIslandModeRaw == IslandGalleryStyle.singularityLive.rawValue {
            // Remote identity must survive before the catalog has arrived.
            selectedID = activeLiveID
        } else if let active = activeArtwork { selectedID = active.id }
        else {
            let style = IslandGalleryStyle(rawValue: selectedRaw) ?? .starlight
            selectedID = IslandGalleryArtwork(style: style).id
        }
    }

    private func step(_ delta: Int) {
        guard !applying, visibleArtworks.count > 1 else { return }
        let next = (selectionIndex + delta + visibleArtworks.count) % visibleArtworks.count
        select(visibleArtworks[next])
    }

    private func loadCatalog(force: Bool = false) async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let themes = try await IslandLiveMedia.loadCatalog(force: force)
            guard !Task.isCancelled else { return }
            liveThemes = themes
            loadFailed = false
            restoreSelection()
            synchronizeSelection()
        } catch {
            if !Task.isCancelled { loadFailed = true }
        }
    }

    private func apply(_ item: IslandGalleryArtwork) {
        guard !applying else { return }
        select(item)
        applying = true
        Task { @MainActor in
            let response: IslandGalleryApplyResult
            if let theme = item.liveTheme {
                response = await IslandGalleryExecutor.shared.applyLive(
                    theme,
                    shadowIntensity: shadowIntensity
                )
            } else {
                response = await IslandGalleryExecutor.shared.apply(
                    item.style,
                    shadowIntensity: shadowIntensity
                )
            }
            applying = false
            UINotificationFeedbackGenerator().notificationOccurred(response.succeeded ? .success : .error)
            result = response
        }
    }

    private func restore() {
        guard !applying else { return }
        applying = true
        Task { @MainActor in
            let response = await IslandGalleryExecutor.shared.restore()
            applying = false
            UINotificationFeedbackGenerator().notificationOccurred(response.succeeded ? .success : .error)
            result = response
        }
    }
}

/// Exactly one featured animation. Collection tiles request only PNG posters.
private struct IslandGalleryArtworkImage: View {
    let artwork: IslandGalleryArtwork
    let animated: Bool
    var compact = false
    var body: some View {
        Group {
            if artwork.isLive {
                LaraRemoteMediaPreview(url: animated ? artwork.motionURL : artwork.posterURL,
                                       animated: animated, contentMode: .fit,
                                       showsRetry: !compact, compactPlaceholder: compact, background: .clear)
            } else {
                Image(artwork.style.assetName).resizable().interpolation(.high).scaledToFit()
            }
        }
        .accessibilityHidden(compact)
    }
}

private struct IslandGalleryStage: View {
    let artwork: IslandGalleryArtwork
    let playing: Bool
    let active: Bool
    let shadowIntensity: Double

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(artwork.accent).frame(width: 5, height: 5)
                Text(artwork.isLive ? "LIVE" : "STATIC")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.5)
                Spacer()
                if active {
                    Label(LaraL10n.text(en: "Applied", es: "Aplicado"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(.mint)
                } else {
                    Image(systemName: "viewfinder").font(.system(size: 15, weight: .light))
                }
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.horizontal, 22)
            .padding(.top, 21)

            phoneContext
                .frame(height: 208)

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(artwork.title).font(.system(size: 25, weight: .semibold, design: .rounded))
                        .tracking(-0.6).foregroundStyle(.white).lineLimit(2)
                }
                Spacer(minLength: 0)
                HStack(spacing: -4) {
                    Circle().fill(artwork.accent.opacity(0.45))
                    Circle().fill(artwork.accent)
                    Circle().fill(.white.opacity(0.85))
                }
                .frame(width: 42, height: 16)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 23)
        }
        .background {
            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.047)
                RadialGradient(colors: [artwork.accent.opacity(0.19), .clear], center: .init(x: 0.5, y: 0.35),
                               startRadius: 2, endRadius: 230)
                LinearGradient(colors: [.white.opacity(0.025), .clear, artwork.accent.opacity(0.04)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.18), artwork.accent.opacity(0.12), .white.opacity(0.055)],
                                              startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
        .shadow(color: artwork.accent.opacity(0.12), radius: 22, y: 10)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("island-featured-stage")
    }

    private var phoneContext: some View {
        VStack(spacing: 0) {
            HStack {
                Text("9:41").font(.system(size: 10, weight: .semibold))
                Spacer()
                Image(systemName: "cellularbars")
                Image(systemName: "wifi")
                Image(systemName: "battery.100percent")
            }
            .font(.system(size: 9)).foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 21)
            .frame(height: 42)
            .overlay(alignment: .center) {
                IslandGalleryArtworkImage(artwork: artwork, animated: playing && artwork.isLive, compact: true)
                    .frame(width: 130, height: 54)
                    .shadow(
                        color: artwork.accent.opacity(0.9 * shadowIntensity),
                        radius: 12 * shadowIntensity
                    )
                    .offset(y: 3)
            }
                VStack(spacing: 0) {
                    Text(LaraL10n.text(en: "Sunday, September 6", es: "Domingo, 6 de septiembre"))
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.7))
                    Text("9:41")
                        .font(.system(size: 62, weight: .thin, design: .rounded)).tracking(-3).foregroundStyle(.white.opacity(0.9))
                }
                .padding(.top, 14)
                Spacer(minLength: 0)
        }
        .frame(width: 260, height: 193)
        .background {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.10)
                Ellipse().fill(artwork.accent.opacity(0.45)).frame(width: 230, height: 290)
                    .blur(radius: 25).rotationEffect(.degrees(-45)).offset(x: 94, y: 90)
                Ellipse().stroke(.white.opacity(0.09), lineWidth: 36)
                    .frame(width: 230, height: 330).rotationEffect(.degrees(-45)).offset(x: -55, y: 100)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 29))
        .overlay {
            RoundedRectangle(cornerRadius: 29)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.75),
                                      .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
        .padding(.top, 14)
    }
}
