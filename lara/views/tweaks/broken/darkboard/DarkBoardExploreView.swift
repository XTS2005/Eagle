import SwiftUI

private struct DarkBoardExploreAlert: Identifiable {
    let id = UUID()
    let message: String
}

struct DarkBoardExploreView: View {
    @ObservedObject private var gallery = IconThemeGalleryManager.shared
    @ObservedObject private var themes = IconThemeManager.shared

    @State private var filter: IconThemeGalleryFilter = .random
    @State private var searchTerm = ""
    @State private var alert: DarkBoardExploreAlert?
    @State private var displayedThemes: [GalleryTheme] = []
    @State private var activeImportName: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                filterBar
                if let activeImportName {
                    importStatusCard(themeName: activeImportName)
                }
                content
            }
            .padding()
        }
        .navigationTitle(LaraL10n.text(en: "Explore Themes", es: "Explorar temas"))
        .searchable(
            text: $searchTerm,
            prompt: LaraL10n.text(en: "Search themes or authors", es: "Buscar temas o autores")
        )
        .refreshable {
            await gallery.loadThemes(forceRefresh: true)
            updateDisplayedThemes()
        }
        .task {
            if gallery.themes.isEmpty {
                await gallery.loadThemes()
            }
            updateDisplayedThemes()
        }
        .onChange(of: searchTerm)     { _ in updateDisplayedThemes() }
        .onChange(of: filter)         { _ in updateDisplayedThemes() }
        .onChange(of: gallery.themes) { _ in updateDisplayedThemes() }
        .alert(item: $alert) { a in
            Alert(
                title: Text(LaraL10n.text(en: "Theme Gallery", es: "Galería de temas")),
                message: Text(a.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func updateDisplayedThemes() {
        displayedThemes = gallery.filteredThemes(searchTerm: searchTerm, filter: filter)
    }

    private func startImport(_ theme: GalleryTheme) {
        guard activeImportName == nil else { return }

        activeImportName = theme.name
        themes.icon_logmsg("gallery button tapped: \(theme.name)")

        Task { @MainActor in
            do {
                try await gallery.downloadAndImport(theme)
                themes.refreshThemes()
                let count = themes.theme(named: theme.name)?.iconCount ?? 0
                activeImportName = nil
                alert = DarkBoardExploreAlert(message: LaraL10n.text(
                    en: "Imported \(theme.name) with \(count) icons. It is selected and ready to apply.",
                    es: "Se importó \(theme.name) con \(count) iconos. Está seleccionado y listo para aplicar."
                ))
            } catch {
                activeImportName = nil
                alert = DarkBoardExploreAlert(message: LaraL10n.text(
                    en: "Eagle could not import \(theme.name):\n\n\(error.localizedDescription)",
                    es: "Eagle no pudo importar \(theme.name):\n\n\(error.localizedDescription)"
                ))
            }
        }
    }

    private func importStatusCard(themeName: String) -> some View {
        HStack(spacing: 12) {
            ProgressView()
            VStack(alignment: .leading, spacing: 2) {
                Text(LaraL10n.text(en: "Importing Theme", es: "Importando tema"))
                    .font(.headline)
                Text(LaraL10n.text(
                    en: "Downloading and checking \(themeName)…",
                    es: "Descargando y comprobando \(themeName)…"
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var filterBar: some View {
        HStack {
            Menu {
                ForEach(IconThemeGalleryFilter.allCases) { candidate in
                    Button {
                        filter = candidate
                    } label: {
                        if filter == candidate {
                            Label(candidate.title, systemImage: "checkmark")
                        } else {
                            Text(candidate.title)
                        }
                    }
                }
            } label: {
                Label(filter.title, systemImage: "line.3.horizontal.decrease.circle")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            Spacer()
            if gallery.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let loadError = gallery.loadError, gallery.themes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(LaraL10n.text(
                    en: "The community gallery could not be loaded.",
                    es: "No se pudo cargar la galería de la comunidad."
                ))
                    .font(.headline)
                Text(loadError)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(LaraL10n.text(en: "Try Again", es: "Intentar de nuevo")) {
                    Task {
                        await gallery.loadThemes(forceRefresh: true)
                        updateDisplayedThemes()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else if displayedThemes.isEmpty && gallery.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(LaraL10n.text(en: "Loading themes…", es: "Cargando temas…"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else if displayedThemes.isEmpty {
            Text(LaraL10n.text(
                en: "No themes match your search.",
                es: "Ningún tema coincide con tu búsqueda."
            ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else {
            LazyVStack(spacing: 14) {
                ForEach(displayedThemes) { theme in
                    GalleryThemeCard(
                        theme: theme,
                        previewURL: gallery.previewURL(for: theme),
                        isImported: themes.theme(named: theme.name) != nil,
                        isDownloading: activeImportName == theme.name || gallery.isDownloading(theme),
                        isImportDisabled: activeImportName != nil
                    ) {
                        startImport(theme)
                    }
                }
            }
        }
    }
}

private struct GalleryThemeCard: View {
    let theme: GalleryTheme
    let previewURL: URL?
    let isImported: Bool
    let isDownloading: Bool
    let isImportDisabled: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let previewURL {
                AsyncImage(url: previewURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    default:
                        previewPlaceholder
                    }
                }
            } else {
                previewPlaceholder
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(.headline)
                            .lineLimit(1)
                        Text(theme.contact.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if isImported {
                        Text(LaraL10n.text(en: "Imported", es: "Importado"))
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                }
                Text(theme.description)

                Button(action: onDownload) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: isImported
                                  ? "arrow.triangle.2.circlepath"
                                  : "arrow.down.circle")
                        }

                        Text(isImported
                            ? LaraL10n.text(en: "Reimport Theme", es: "Volver a importar")
                            : LaraL10n.text(en: "Import Theme", es: "Importar tema"))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isImportDisabled)
                .opacity(isImportDisabled && !isDownloading ? 0.55 : 1)
                .accessibilityHint(LaraL10n.text(
                    en: "Downloads and adds this theme to Icon Studio.",
                    es: "Descarga y añade este tema a Iconos."
                ))
            }
            .padding()
        }
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var previewPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "app.dashed")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(height: 180).frame(maxWidth: .infinity)
    }
}
