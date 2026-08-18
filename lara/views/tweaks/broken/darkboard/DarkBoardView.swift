//
//  DarkBoard.swift
//  lara
//
//  Created by ruter on 24.04.26.
//  skidded from Cowabunga, credit goes to lemin and co.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

private struct DarkBoardAlert: Identifiable {
    let id = UUID()
    let message: String
}

private struct OverrideChoice: Identifiable {
    let theme: LaraIconTheme
    let image: UIImage

    var id: String { theme.name }
}

private struct PendingSingleIconImport: Identifiable {
    let id = UUID()
    let fileName: String
    let data: Data
}

private enum EagleIconThemeOrder: String, CaseIterable, Identifiable {
    case alphabetical
    case selectedFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alphabetical:
            return LaraL10n.text(en: "A–Z", es: "A–Z")
        case .selectedFirst:
            return LaraL10n.text(en: "Selected first", es: "Seleccionados primero")
        }
    }
}

private struct EagleIconShapePreviewMask: Shape {
    let style: EagleIconShape

    func path(in rect: CGRect) -> Path {
        switch style {
        case .original:
            return RoundedRectangle(
                cornerRadius: rect.width * 0.23,
                style: .continuous
            ).path(in: rect)
        case .circle:
            return Circle().path(in: rect)
        case .material:
            return RoundedRectangle(
                cornerRadius: rect.width * 0.18,
                style: .circular
            ).path(in: rect)
        }
    }
}

struct DarkBoardView: View {
    @ObservedObject private var manager = IconThemeManager.shared
    @ObservedObject private var mgr = laramgr.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showImporter = false
    @State private var showRestoreConfirmation = false
    @State private var alert: DarkBoardAlert?
    @State private var pendingImportURL: URL?
    @State private var pendingSingleIconImport: PendingSingleIconImport?
    @State private var themeSearch = ""
    @AppStorage("eagle.icons.themeOrder")
    private var themeOrder: EagleIconThemeOrder = .alphabetical

    private let previewBundleIDs = [
        "com.apple.mobilephone",
        "com.apple.mobilesafari",
        "com.apple.mobileslideshow",
        "com.apple.camera",
        "com.apple.AppStore",
        "com.apple.Preferences",
        "com.apple.Music",
        "com.apple.calculator",
    ]

    private var grid: [GridItem] {
        dynamicTypeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 160), spacing: 12)]
    }

    private var displayedThemes: [LaraIconTheme] {
        let query = themeSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        var themes = manager.themes
        if !query.isEmpty {
            themes = themes.filter {
                $0.name.range(
                    of: query,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    locale: .current
                ) != nil
            }
        }

        guard themeOrder == .selectedFirst else {
            return themes.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        }

        var selectedPositions: [String: Int] = [:]
        for (index, name) in manager.selectedThemeNames.enumerated()
            where selectedPositions[name] == nil {
            selectedPositions[name] = index
        }

        return themes.sorted { lhs, rhs in
            let lhsPosition = selectedPositions[lhs.name]
            let rhsPosition = selectedPositions[rhs.name]
            switch (lhsPosition, rhsPosition) {
            case let (.some(left), .some(right)):
                return left < right
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    helperCards
                    shapePicker
                    if !manager.themes.isEmpty {
                        themeBrowserControls
                    }
                    themeGrid
                }
                .padding()
                .padding(.bottom, 90)
            }

            if !manager.themes.isEmpty || manager.selectedIconShape != .original {
                Button {
                    applyThemes()
                } label: {
                    Text(LaraL10n.text(en: "Apply Icons", es: "Aplicar iconos"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            !hasChosenArtwork && manager.selectedIconShape == .original
                                ? Color.secondary.opacity(0.25)
                                : Color.accentColor
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding()
                }
                .disabled(
                    (!hasChosenArtwork && manager.selectedIconShape == .original) ||
                    manager.isApplying
                )
            }
        }
        .navigationTitle(LaraL10n.text(en: "Icon Studio", es: "Iconos"))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .destructive) {
                    showRestoreConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel(LaraL10n.text(en: "Restore original icons", es: "Restaurar iconos originales"))
                .disabled(manager.isApplying)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel(LaraL10n.text(en: "Import icons", es: "Importar iconos"))
                .disabled(manager.isApplying)
            }
        }
        .sheet(isPresented: $showImporter) {
            ThemeImportPicker(selectedURL: $pendingImportURL)
        }
        .sheet(item: $pendingSingleIconImport) { pendingIcon in
            SingleIconAppPicker(
                fileName: pendingIcon.fileName,
                apps: manager.installedApps.filter { !$0.hiddenFromSpringboard },
                onSelect: { app in
                    do {
                        _ = try manager.importSingleIcon(
                            data: pendingIcon.data,
                            for: app.bundleIdentifier
                        )
                        pendingSingleIconImport = nil
                        alert = DarkBoardAlert(message: LaraL10n.text(
                            en: "Custom icon assigned to \(app.name). Tap Apply Icons to put it on the Home Screen.",
                            es: "Icono personalizado asignado a \(app.name). Toca Aplicar iconos para verlo en la pantalla de inicio."
                        ))
                    } catch {
                        pendingSingleIconImport = nil
                        alert = DarkBoardAlert(message: error.localizedDescription)
                    }
                },
                onCancel: {
                    pendingSingleIconImport = nil
                }
            )
            .interactiveDismissDisabled()
        }
        .confirmationDialog(
            LaraL10n.text(en: "Restore Original Icons?", es: "¿Restaurar los iconos originales?"),
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                LaraL10n.text(en: "Restore Original Icons", es: "Restaurar iconos originales"),
                role: .destructive
            ) {
                manager.selectedIconShape = .original
                manager.clearSelectionsForFullReset()
                applyThemes()
            }
            Button(LaraL10n.text(en: "Cancel", es: "Cancelar"), role: .cancel) {}
        } message: {
            Text(LaraL10n.text(
                en: "Eagle will remove theme choices and return supported apps to their original icons.",
                es: "Eagle quitará los temas seleccionados y devolverá las apps compatibles a sus iconos originales."
            ))
        }
        .alert(item: $alert) { alert in
            Alert(
                title: Text(LaraL10n.text(en: "Icon Studio", es: "Iconos")),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if manager.isApplying {
                progressOverlay(
                    title: LaraL10n.text(en: "Applying Icons", es: "Aplicando iconos"),
                    message: manager.applyMessage,
                    progress: manager.applyProgress
                )
            }
        }
        .onAppear {
            manager.refreshThemes()
            try? manager.refreshApps()
            manager.startPendingFixupIfPossible()
        }
        .onChange(of: pendingImportURL) { url in
            guard let url else { return }
            handleImport(url)
            pendingImportURL = nil
        }
    }

    private var helperCards: some View {
        VStack(spacing: 12) {
            if !mgr.dsready {
                Text(LaraL10n.text(
                    en: "Complete Eagle setup before applying icons. Theme imports are saved privately and do not require SBX.",
                    es: "Completa la preparación de Eagle antes de aplicar iconos. Los temas se guardan de forma privada y no requieren SBX."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LaraL10n.text(en: "Themes", es: "Temas"))
                        .font(.headline)
                    Text(LaraL10n.text(
                        en: "\(manager.themes.count) imported",
                        es: "\(manager.themes.count) importados"
                    ))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                Spacer()
                NavigationLink(LaraL10n.text(en: "Explore", es: "Explorar")) {
                    DarkBoardExploreView()
                }
                .buttonStyle(.bordered)
                NavigationLink(LaraL10n.text(en: "Apps", es: "Apps")) {
                    IconOverridesView()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if manager.themes.isEmpty {
                Text(LaraL10n.text(
                    en: "Explore community themes, import a `.theme`, `.zip`, or folder, or assign one PNG to an app.",
                    es: "Explora temas, importa un `.theme`, `.zip` o carpeta, o asigna un PNG a una app."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var shapePicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(en: "Icon Shape", es: "Forma del icono"))
                    .font(.headline)
                Text(LaraL10n.text(
                    en: "Choose one shape for every supported Home Screen icon.",
                    es: "Elige una forma para cada icono compatible de la pantalla de inicio."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 9) {
                ForEach(EagleIconShape.allCases) { shape in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            manager.selectedIconShape = shape
                        }
                    } label: {
                        VStack(spacing: 9) {
                            ZStack {
                                LinearGradient(
                                    colors: [Color.indigo, Color.cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: "sparkles")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(EagleIconShapePreviewMask(style: shape))

                            Text(shape.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            manager.selectedIconShape == shape
                                ? Color.accentColor.opacity(0.12)
                                : Color(uiColor: .tertiarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    manager.selectedIconShape == shape
                                        ? Color.accentColor
                                        : Color.primary.opacity(0.06),
                                    lineWidth: manager.selectedIconShape == shape ? 1.5 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(shape.title)
                    .accessibilityValue(
                        manager.selectedIconShape == shape
                            ? LaraL10n.text(en: "Selected", es: "Seleccionado")
                            : ""
                    )
                }
            }

            Label(manager.selectedIconShape.summary, systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private var themeGrid: some View {
        Group {
            if displayedThemes.isEmpty && !themeSearch.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(LaraL10n.text(en: "No matching themes", es: "No hay temas coincidentes"))
                        .font(.headline)
                    Button(LaraL10n.text(en: "Clear Search", es: "Limpiar búsqueda")) {
                        themeSearch = ""
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
            } else {
                LazyVGrid(columns: grid, spacing: 12) {
                    ForEach(displayedThemes) { theme in
                        ThemeCardView(
                            theme: theme,
                            previews: manager.icons(forAppIDs: previewBundleIDs, from: theme),
                            shape: manager.selectedIconShape,
                            selectionIndex: manager.selectedThemeNames.firstIndex(of: theme.name),
                            onToggle: { manager.toggleThemeSelection(theme) },
                            onDelete: { removeTheme(theme) }
                        )
                    }
                }
            }
        }
    }

    private var themeBrowserControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField(
                    LaraL10n.text(en: "Search themes", es: "Buscar temas"),
                    text: $themeSearch
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

                if !themeSearch.isEmpty {
                    Button {
                        themeSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LaraL10n.text(en: "Clear search", es: "Limpiar búsqueda"))
                }
            }
            .padding(.leading, 13)
            .padding(.trailing, themeSearch.isEmpty ? 13 : 2)
            .background(
                Color(uiColor: .tertiarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )

            ViewThatFits(in: .horizontal) {
                HStack {
                    themeCountLabel
                    Spacer()
                    themeOrderMenu
                }

                VStack(alignment: .leading, spacing: 8) {
                    themeCountLabel
                    themeOrderMenu
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }

    private var themeCountLabel: some View {
        Text(LaraL10n.text(
            en: "\(displayedThemes.count) of \(manager.themes.count) themes",
            es: "\(displayedThemes.count) de \(manager.themes.count) temas"
        ))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var themeOrderMenu: some View {
        Menu {
            Picker(
                LaraL10n.text(en: "Theme order", es: "Orden de temas"),
                selection: $themeOrder
            ) {
                ForEach(EagleIconThemeOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
        } label: {
            Label(themeOrder.title, systemImage: "arrow.up.arrow.down")
                .font(.caption.weight(.semibold))
        }
    }

    private func applyThemes() {
        manager.applyLiveIcons { liveResult in
            switch liveResult {
            case .success(let live):
                var message = LaraL10n.text(
                    en: "Applied to \(live.shapedIconCount) Home Screen icons.",
                    es: "Aplicado a \(live.shapedIconCount) iconos de la pantalla de inicio."
                )
                if live.themedIconCount > 0 {
                    message += LaraL10n.text(
                        en: " Custom artwork is live on \(live.themedIconCount) icons.",
                        es: " El diseño personalizado está activo en \(live.themedIconCount) iconos."
                    )
                } else if hasChosenArtwork {
                    message += LaraL10n.text(
                        en: " None of the loaded apps matched this theme's bundle identifiers.",
                        es: " Ninguna app cargada coincidió con los identificadores de este tema."
                    )
                }
                message += LaraL10n.text(
                    en: " Changes are immediate and safely reset after a respring or reboot.",
                    es: " Los cambios son inmediatos y se restablecen de forma segura tras un respring o reinicio."
                )
                alert = DarkBoardAlert(message: message)

            case .failure(let error):
                alert = DarkBoardAlert(message: error.localizedDescription)
            }
        }
    }

    private func handleImport(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            if url.pathExtension.lowercased() == "png" {
                let data = try Data(contentsOf: url)
                guard UIImage(data: data) != nil else {
                    throw NSError(
                        domain: "IconThemer",
                        code: 11,
                        userInfo: [NSLocalizedDescriptionKey: LaraL10n.text(
                            en: "This PNG could not be read as an image.",
                            es: "Este PNG no se pudo leer como imagen."
                        )]
                    )
                }
                if manager.installedApps.isEmpty {
                    try manager.refreshApps()
                }
                let pendingIcon = PendingSingleIconImport(
                    fileName: url.lastPathComponent,
                    data: data
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    pendingSingleIconImport = pendingIcon
                }
            } else {
                try manager.importTheme(from: url)
                alert = DarkBoardAlert(message: LaraL10n.text(
                    en: "Theme imported and selected. Tap Apply Icons.",
                    es: "Tema importado y seleccionado. Toca Aplicar iconos."
                ))
            }
        } catch {
            alert = DarkBoardAlert(message: error.localizedDescription)
        }
    }

    private var hasChosenArtwork: Bool {
        !manager.selectedThemeNames.isEmpty || !manager.iconOverrides.isEmpty
    }

    private func removeTheme(_ theme: LaraIconTheme) {
        do {
            try manager.removeTheme(theme)
        } catch {
            alert = DarkBoardAlert(message: error.localizedDescription)
        }
    }

    @ViewBuilder
    private func progressOverlay(title: String, message: String, progress: Double) -> some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView(value: progress, total: 1.0)
                Text(title).font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct ThemeCardView: View {
    let theme: LaraIconTheme
    let previews: [UIImage?]
    let shape: EagleIconShape
    let selectionIndex: Int?
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 94)

                if previews.compactMap({ $0 }).count >= 4 {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { idx in
                                previewCell(previews[safe: idx] ?? nil)
                            }
                        }
                        HStack(spacing: 4) {
                            ForEach(4..<8, id: \.self) { idx in
                                previewCell(previews[safe: idx] ?? nil)
                            }
                        }
                    }
                } else {
                    Text(LaraL10n.text(en: "Preview unavailable", es: "Vista no disponible"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text(theme.name)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text("\(theme.iconCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onToggle) {
                Text(selectionIndex == nil
                    ? LaraL10n.text(en: "Select", es: "Seleccionar")
                    : LaraL10n.text(en: "Selected: \(selectionIndex! + 1)", es: "Seleccionado: \(selectionIndex! + 1)"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectionIndex == nil ? Color.secondary.opacity(0.2) : Color.accentColor)
                    .foregroundStyle(selectionIndex == nil ? Color.primary : Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button(role: .destructive, action: onDelete) {
                Text(LaraL10n.text(en: "Remove", es: "Eliminar"))
                    .font(.caption)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func previewCell(_ image: UIImage?) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(EagleIconShapePreviewMask(style: shape))
        } else {
            EagleIconShapePreviewMask(style: shape)
                .fill(Color.clear)
                .frame(width: 28, height: 28)
        }
    }
}

struct IconOverridesView: View {
    @ObservedObject private var manager = IconThemeManager.shared

    @State private var search = ""

    var body: some View {
        List {
            ForEach(filteredApps, id: \.id) { app in
                NavigationLink {
                    OverrideSelectionView(app: app)
                } label: {
                    HStack(spacing: 12) {
                        if let icon = app.loadPreviewIcon() {
                            Image(uiImage: icon)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(EagleIconShapePreviewMask(style: manager.selectedIconShape))
                        } else {
                            Image("unknown")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(EagleIconShapePreviewMask(style: manager.selectedIconShape))
                        }
                        VStack(alignment: .leading) {
                            Text(app.name)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if manager.iconOverrides[app.bundleIdentifier] != nil {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
        }
        .navigationTitle(LaraL10n.text(en: "Choose by App", es: "Elegir por app"))
        .searchable(
            text: $search,
            prompt: LaraL10n.text(en: "Search apps", es: "Buscar apps")
        )
        .onAppear {
            try? manager.refreshApps()
        }
    }

    private var filteredApps: [LaraThemedApp] {
        let visibleApps = manager.installedApps.filter { !$0.hiddenFromSpringboard }
        guard !search.isEmpty else { return visibleApps }
        return visibleApps.filter {
            $0.name.localizedCaseInsensitiveContains(search) || $0.bundleIdentifier.localizedCaseInsensitiveContains(search)
        }
    }
}

private struct OverrideSelectionView: View {
    @ObservedObject private var manager = IconThemeManager.shared

    let app: LaraThemedApp

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if manager.iconOverrides[app.bundleIdentifier] != nil {
                Button(role: .destructive) {
                    manager.removeOverride(for: app.bundleIdentifier)
                    dismiss()
                } label: {
                    Text(LaraL10n.text(en: "Use Theme Default", es: "Usar el tema predeterminado"))
                }
            }

            ForEach(choices) { choice in
                Button {
                    manager.setOverride(bundleID: app.bundleIdentifier, themeName: choice.theme.name)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(uiImage: choice.image)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(EagleIconShapePreviewMask(style: manager.selectedIconShape))
                        VStack(alignment: .leading) {
                            Text(choice.theme.name)
                            Text(choice.theme.name == manager.iconOverrides[app.bundleIdentifier]
                                ? LaraL10n.text(en: "Current choice", es: "Selección actual")
                                : LaraL10n.text(en: "Tap to choose", es: "Toca para elegir"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var choices: [OverrideChoice] {
        manager.availableOverrideChoices(for: app.bundleIdentifier).map { OverrideChoice(theme: $0.theme, image: $0.image) }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct SingleIconAppPicker: View {
    let fileName: String
    let apps: [LaraThemedApp]
    let onSelect: (LaraThemedApp) -> Void
    let onCancel: () -> Void

    @State private var search = ""

    var body: some View {
        NavigationStack {
            List(filteredApps) { app in
                Button {
                    onSelect(app)
                } label: {
                    HStack(spacing: 12) {
                        Group {
                            if let image = app.loadPreviewIcon() {
                                Image(uiImage: image)
                                    .resizable()
                            } else {
                                Image("unknown")
                                    .resizable()
                            }
                        }
                        .frame(width: 42, height: 42)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.name)
                                .foregroundStyle(.primary)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .navigationTitle(LaraL10n.text(en: "Choose an App", es: "Elige una app"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $search,
                prompt: LaraL10n.text(en: "Search apps", es: "Buscar apps")
            )
            .safeAreaInset(edge: .top) {
                Text(LaraL10n.text(
                    en: "Where should Eagle use \(fileName)?",
                    es: "¿Dónde debe usar Eagle \(fileName)?"
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LaraL10n.text(en: "Cancel", es: "Cancelar")) {
                        onCancel()
                    }
                }
            }
        }
    }

    private var filteredApps: [LaraThemedApp] {
        guard !search.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(search)
        }
    }
}

private struct ThemeImportPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedURL: $selectedURL, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        var documentTypes: [UTType] = [.folder, .zip, .png]
        if let themeType = UTType(filenameExtension: "theme") {
            documentTypes.append(themeType)
        }

        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: documentTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        @Binding var selectedURL: URL?
        let dismissAction: DismissAction

        init(selectedURL: Binding<URL?>, dismiss: DismissAction) {
            self._selectedURL = selectedURL
            self.dismissAction = dismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            selectedURL = urls.first
            dismissAction()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            dismissAction()
        }
    }
}
