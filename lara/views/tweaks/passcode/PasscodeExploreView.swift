//
//  PasscodeExploreView.swift
//  lara
//
//  Created by neonmodder123 on 20/05/2026.
//

import SwiftUI

struct PasscodeExploreView: View {
    @ObservedObject var mgr: laramgr
    @ObservedObject private var gallery = PasscodeGalleryManager.shared

    @State private var searchTerm = ""
    @State private var alertMessage: String?
    var onImport: ((URL) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    private func handleDownload(_ theme: PasscodeGalleryTheme) async {
        do {
            try await gallery.downloadAndImport(theme)
            let dest = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(theme.name + ".passthm")
            onImport?(dest)
            dismiss()
        } catch { alertMessage = error.localizedDescription }
    }

    private var displayed: [PasscodeGalleryTheme] {
        guard !searchTerm.isEmpty else { return gallery.themes }
        let q = searchTerm.lowercased()
        return gallery.themes.filter {
            $0.name.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            $0.authorLine.lowercased().contains(q)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if gallery.isLoading && gallery.themes.isEmpty {
                    loadingView
                } else if let error = gallery.loadError, gallery.themes.isEmpty {
                    errorView(error)
                } else if displayed.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "circle.grid.3x3")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("No encontramos estilos")
                            .font(.headline)
                        Text("Prueba con otro nombre o creador.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 50)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 12)], spacing: 12) {
                        ForEach(displayed) { theme in
                            PasscodeGalleryCard(
                                theme: theme,
                                previewURL: gallery.previewURL(for: theme),
                                isDownloading: gallery.isDownloading(theme)
                            ) { Task { await handleDownload(theme) } }
                        }
                    }
                }

                Link(
                    "Colección oficial de Nugget Wallpapers",
                    destination: URL(string: "https://github.com/SerStars/Nugget-Wallpapers")!
                )
                .font(.footnote.weight(.medium))
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Explorar estilos")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchTerm, prompt: "Buscar estilo o creador")
        .refreshable { await gallery.loadThemes(forceRefresh: true) }
        .task { if gallery.themes.isEmpty { await gallery.loadThemes() } }
        .alert("Estilos del código", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) { Button("Aceptar", role: .cancel) {} } message: { Text(alertMessage ?? "") }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView().controlSize(.large)
            Text("Cargando estilos…")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No se pudieron cargar los estilos")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Intentar de nuevo") { Task { await gallery.loadThemes(forceRefresh: true) } }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct PasscodeGalleryCard: View {
    let theme: PasscodeGalleryTheme
    let previewURL: URL?
    let isDownloading: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LaraRemoteMediaPreview(
                url: previewURL,
                animated: false,
                contentMode: .fit,
                showsRetry: false
            )
            .frame(maxWidth: .infinity)
            .frame(height: 190)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(theme.name).font(.headline).lineLimit(1)
                        Text(theme.authorLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }

                if !theme.description.isEmpty {
                    Text(theme.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: onDownload) {
                    HStack {
                        if isDownloading { ProgressView().controlSize(.small).tint(.white) } else { Image(systemName: "arrow.down.circle") }
                        Text("Usar estilo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading)
            }
            .padding()
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
        }
    }

}
