//
//  LogsView.swift
//  lara
//
//  Created by lunginspector on 5/3/26.
//

import SwiftUI

struct LogsView: View {
    @ObservedObject var logger: Logger
    @Environment(\.dismiss) private var dismiss
    @AppStorage(EaglePreferenceKeys.disableLogDividers)
    private var combinesLogEntries = true
    @State private var searchText = ""
    @State private var copied = false
    
    let logsURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("lara.log")
    }()

    private var filteredLogs: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return logger.logs }
        return logger.logs.filter {
            $0.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ) != nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredLogs.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: searchText.isEmpty ? "terminal" : "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                        Text(searchText.isEmpty
                            ? LaraL10n.text(en: "No logs yet", es: "Todavía no hay logs")
                            : LaraL10n.text(en: "No matching logs", es: "No hay logs coincidentes"))
                            .font(.headline)
                        if !searchText.isEmpty {
                            Text(LaraL10n.text(
                                en: "Try another word or clear the search.",
                                es: "Prueba otra palabra o limpia la búsqueda."
                            ))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .accessibilityElement(children: .combine)
                } else if combinesLogEntries {
                    let combined = filteredLogs.joined(separator: "\n")
                    Text(combined)
                        .font(.system(.footnote, design: .monospaced))
                        .lineSpacing(1)
                        .textSelection(.enabled)
                } else {
                    ForEach(Array(filteredLogs.enumerated()), id: \.offset) { _, log in
                        Text(log)
                            .font(.system(.footnote, design: .monospaced))
                            .lineSpacing(1)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle(LaraL10n.text(en: "Logs", es: "Registros"))
            .searchable(
                text: $searchText,
                prompt: LaraL10n.text(en: "Search logs", es: "Buscar en los logs")
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text(LaraL10n.text(en: "Close", es: "Cerrar"))
                            .foregroundStyle(EagleVisualTheme.accent)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ShareLink(item: logsURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(LaraL10n.text(en: "Share log file", es: "Compartir archivo de logs"))

                    Button {
                        copy(filteredLogs.joined(separator: "\n\n"))
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(filteredLogs.isEmpty)
                    .accessibilityLabel(copied
                        ? LaraL10n.text(en: "Copied", es: "Copiado")
                        : LaraL10n.text(en: "Copy visible logs", es: "Copiar logs visibles"))
                    
                }
            }
        }
    }

    private func copy(_ text: String) {
        guard !text.isEmpty else { return }
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }
}
