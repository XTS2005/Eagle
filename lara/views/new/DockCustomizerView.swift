import SwiftUI

private struct EagleDockAlert: Identifiable {
    let id = UUID()
    let message: String
}

struct DockCustomizerView: View {
    @ObservedObject private var mgr = laramgr.shared
    @AppStorage("eagle.dock.capacity") private var selectedCapacity = 5

    @State private var isApplying = false
    @State private var alert: EagleDockAlert?

    private let capacities = [4, 5, 6]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                dockPreview
                capacityCard
                explanationCard
                applyButton
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Dock")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alert) { alert in
            Alert(
                title: Text("Dock"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if isApplying {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                    VStack(spacing: 12) {
                        EagleRainbowSpinner(size: 28)
                        Text(LaraL10n.text(
                            en: "Updating the Dock…",
                            es: "Actualizando el Dock…"
                        ))
                            .font(.headline)
                    }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var dockPreview: some View {
        VStack(spacing: 18) {
            VStack(spacing: 5) {
                Text(LaraL10n.text(en: "More room, same Dock", es: "Más espacio, el mismo Dock"))
                    .font(.title2.bold())
                Text(capacityDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: selectedCapacity == 6 ? 8 : 11) {
                ForEach(0..<selectedCapacity, id: \.self) { index in
                    RoundedRectangle(cornerRadius: selectedCapacity == 6 ? 10 : 12, style: .continuous)
                        .fill(previewColor(for: index).gradient)
                        .frame(
                            width: selectedCapacity == 6 ? 39 : 45,
                            height: selectedCapacity == 6 ? 39 : 45
                        )
                        .overlay {
                            Image(systemName: previewSymbol(for: index))
                                .font(.system(size: selectedCapacity == 6 ? 15 : 17, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.primary.opacity(0.10), lineWidth: 1)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var capacityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(LaraL10n.text(en: "Dock Capacity", es: "Capacidad del Dock"))
                .font(.headline)

            Picker(
                LaraL10n.text(en: "Dock Capacity", es: "Capacidad del Dock"),
                selection: $selectedCapacity
            ) {
                ForEach(capacities, id: \.self) { capacity in
                    Text("\(capacity)").tag(capacity)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text(capacityLabel)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if selectedCapacity == 4 {
                    Text(LaraL10n.text(en: "Apple default", es: "Original de Apple"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var explanationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.draw.fill")
                .foregroundStyle(.secondary)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(en: "Add apps after applying", es: "Añade apps después de aplicar"))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "Eagle creates the extra Dock spaces. Return to the Home Screen, then drag apps into them. A respring or reboot returns the standard layout.",
                    es: "Eagle crea los espacios adicionales. Vuelve a la pantalla de inicio y arrastra apps al Dock. Un respring o reinicio devuelve el diseño estándar."
                ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var applyButton: some View {
        Button(action: applySelectedCapacity) {
            HStack(spacing: 9) {
                Image(systemName: selectedCapacity == 4 ? "arrow.counterclockwise" : "checkmark.circle.fill")
                Text(selectedCapacity == 4
                     ? LaraL10n.text(en: "Restore Standard Dock", es: "Restaurar Dock estándar")
                     : LaraL10n.text(en: "Apply \(selectedCapacity)-Icon Dock", es: "Aplicar Dock de \(selectedCapacity) iconos"))
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
    }

    private var capacityLabel: String {
        switch selectedCapacity {
        case 4:
            return LaraL10n.text(en: "Standard spacing", es: "Espaciado estándar")
        case 5:
            return LaraL10n.text(en: "Balanced", es: "Equilibrado")
        default:
            return LaraL10n.text(en: "Compact", es: "Compacto")
        }
    }

    private var capacityDescription: String {
        switch selectedCapacity {
        case 4:
            return LaraL10n.text(en: "Restore the familiar four-icon layout.", es: "Restaura el diseño familiar de cuatro iconos.")
        case 5:
            return LaraL10n.text(en: "One useful extra space without feeling crowded.", es: "Un espacio adicional sin que se sienta apretado.")
        default:
            return LaraL10n.text(en: "Maximum useful space on an iPhone Dock.", es: "El máximo espacio útil en el Dock del iPhone.")
        }
    }

    private func previewColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .indigo, .orange, .purple, .pink]
        return colors[index % colors.count]
    }

    private func previewSymbol(for index: Int) -> String {
        let symbols = ["phone.fill", "safari.fill", "message.fill", "music.note", "camera.fill", "envelope.fill"]
        return symbols[index % symbols.count]
    }

    private func applySelectedCapacity() {
        guard !isApplying else { return }
        isApplying = true

        let applyWithSession = {
            guard let process = self.mgr.sbProc else {
                self.finishWithError(LaraL10n.text(
                    en: "Eagle connected to SpringBoard but did not receive a live session.",
                    es: "Eagle se conectó a SpringBoard, pero no recibió una sesión activa."
                ))
                return
            }

            let capacity = self.selectedCapacity
            DispatchQueue.global(qos: .userInitiated).async {
                let result = set_dock_icon_count(process, Int32(capacity))
                DispatchQueue.main.async {
                    self.isApplying = false
                    if result == 0 {
                        self.alert = EagleDockAlert(message: LaraL10n.text(
                            en: "The Dock now accepts \(capacity) icons. Return to the Home Screen and drag apps into the new spaces.",
                            es: "El Dock ahora acepta \(capacity) iconos. Vuelve a la pantalla de inicio y arrastra apps a los espacios nuevos."
                        ))
                    } else {
                        self.alert = EagleDockAlert(message: self.message(forResult: result))
                    }
                }
            }
        }

        if mgr.rcready, mgr.sbProc != nil {
            applyWithSession()
            return
        }

        guard mgr.dsready else {
            finishWithError(LaraL10n.text(
                en: "Complete Eagle setup before changing the Dock.",
                es: "Completa la preparación de Eagle antes de cambiar el Dock."
            ))
            return
        }

        mgr.rcinit(process: "SpringBoard") { success in
            if success || (self.mgr.rcready && self.mgr.sbProc != nil) {
                applyWithSession()
            } else {
                let detail = self.mgr.rcLastError?.trimmingCharacters(in: .whitespacesAndNewlines)
                self.finishWithError(detail?.isEmpty == false
                    ? detail!
                    : LaraL10n.text(
                        en: "Eagle could not start the live SpringBoard session.",
                        es: "Eagle no pudo iniciar la sesión en vivo con SpringBoard."
                    ))
            }
        }
    }

    private func finishWithError(_ message: String) {
        DispatchQueue.main.async {
            self.isApplying = false
            self.alert = EagleDockAlert(message: message)
        }
    }

    private func message(forResult result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose its icon controller.",
                es: "SpringBoard no mostró su controlador de iconos."
            )
        case -3:
            return LaraL10n.text(
                en: "Eagle could not find the active Dock. Unlock the iPhone, visit the Home Screen once, and try again.",
                es: "Eagle no encontró el Dock activo. Desbloquea el iPhone, visita la pantalla de inicio una vez e inténtalo de nuevo."
            )
        case -5:
            return LaraL10n.text(
                en: "SpringBoard rejected the main-thread update. No Dock changes were made.",
                es: "SpringBoard rechazó la actualización principal. No se cambió el Dock."
            )
        default:
            return LaraL10n.text(
                en: "The Dock was found, but iOS did not accept the new capacity.",
                es: "Se encontró el Dock, pero iOS no aceptó la nueva capacidad."
            )
        }
    }
}
