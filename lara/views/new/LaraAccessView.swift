import SwiftUI

enum LaraAccessState: Equatable {
    case idle
    case preparing(String, Double?)
    case ready
    case failed(String)
}

struct LaraAccessView: View {
    @ObservedObject private var mgr = laramgr.shared
    @State private var state: LaraAccessState = .idle

    let compact: Bool
    let onReady: (() -> Void)?

    init(compact: Bool = false, onReady: (() -> Void)? = nil) {
        self.compact = compact
        self.onReady = onReady
    }

    var body: some View {
        Group {
            if mgr.sbxready {
                readyView
            } else {
                preparationView
            }
        }
        .onChange(of: mgr.dsprogress) { progress in
            if mgr.dsrunning {
                state = .preparing(LaraL10n.text(
                    en: "Preparing device",
                    es: "Preparando el dispositivo"
                ), progress)
            }
        }
    }

    private var readyView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
            Text("Eagle está lista")
                .font(.subheadline.weight(.semibold))
            Spacer()
        }
        .padding(compact ? 12 : 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var preparationView: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preparar acceso")
                        .font(.headline)
                    Text("Eagle necesita acceso temporal para realizar este cambio. Nada se aplica sin tu confirmación.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            switch state {
            case .preparing(let message, let progress):
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(message)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        ProgressView()
                    }
                    if let progress {
                        ProgressView(value: progress)
                    }
                }

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)

            default:
                EmptyView()
            }

            Button(action: prepare) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isBusy || isunsupported())

            if isunsupported() {
                Text("Este dispositivo o esta versión de iOS no es compatible con el motor actual de Eagle.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 16 : 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var isBusy: Bool {
        if case .preparing = state { return true }
        return mgr.dsrunning || mgr.sbxrunning
    }

    private var buttonTitle: String {
        if isBusy { return LaraL10n.text(en: "Preparing…", es: "Preparando…") }
        if case .failed = state { return LaraL10n.text(en: "Try again", es: "Intentar otra vez") }
        return LaraL10n.text(en: "Continue", es: "Continuar")
    }

    private func prepare() {
        guard !isBusy, !isunsupported() else { return }
        state = .preparing(LaraL10n.text(
            en: "Checking compatibility",
            es: "Comprobando compatibilidad"
        ), nil)
        offsets_init()

        if mgr.dsready {
            resolveOffsetsAndOpenSandbox()
            return
        }

        mgr.run { success in
            guard success else {
                state = .failed(LaraL10n.text(
                    en: "The device could not be prepared. You can try again.",
                    es: "No se pudo preparar el dispositivo. Puedes intentarlo de nuevo."
                ))
                return
            }
            resolveOffsetsAndOpenSandbox()
        }
    }

    private func resolveOffsetsAndOpenSandbox() {
        if mgr.hasOffsets {
            openSandbox()
            return
        }

        state = .preparing(LaraL10n.text(
            en: "Getting compatibility data for your iPhone",
            es: "Obteniendo compatibilidad para tu iPhone"
        ), nil)
        DispatchQueue.global(qos: .userInitiated).async {
            let fetched = fetchkcache()
            let loaded = fetched && dlkcache()
            DispatchQueue.main.async {
                mgr.hasOffsets = loaded
                if loaded {
                    openSandbox()
                } else {
                    state = .failed(LaraL10n.text(
                        en: "Compatibility data could not be prepared.",
                        es: "No fue posible preparar los datos de compatibilidad."
                    ))
                }
            }
        }
    }

    private func openSandbox() {
        state = .preparing(LaraL10n.text(
            en: "Opening temporary access",
            es: "Abriendo acceso temporal"
        ), nil)
        mgr.sbxescape { success in
            if success {
                state = .ready
                onReady?()
            } else {
                state = .failed(LaraL10n.text(
                    en: "Temporary access could not be started.",
                    es: "El acceso temporal no pudo iniciarse."
                ))
            }
        }
    }
}
