import SwiftUI
import UIKit

private struct IslandAuraNotice: Identifiable {
    let id = UUID()
    let message: String
}

private enum IslandAuraMode: Int, CaseIterable, Identifiable {
    case glow = 1
    case pulse = 2
    case tint = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .glow: return LaraL10n.text(en: "Glow", es: "Brillo")
        case .pulse: return LaraL10n.text(en: "Pulse", es: "Pulso")
        case .tint: return LaraL10n.text(en: "Tint", es: "Color")
        }
    }

    var summary: String {
        switch self {
        case .glow:
            return LaraL10n.text(
                en: "A clean neon edge with a soft outer light.",
                es: "Un borde neón limpio con una luz exterior suave."
            )
        case .pulse:
            return LaraL10n.text(
                en: "The aura breathes gently while the Island stays black.",
                es: "El aura respira suavemente mientras la Island permanece negra."
            )
        case .tint:
            return LaraL10n.text(
                en: "Adds a dark color wash behind the neon outline.",
                es: "Añade un tono oscuro detrás del contorno neón."
            )
        }
    }
}

struct IslandAuraView: View {
    @ObservedObject private var mgr = laramgr.shared
    @AppStorage("eagle.islandAura.red") private var red = 0.10
    @AppStorage("eagle.islandAura.green") private var green = 0.78
    @AppStorage("eagle.islandAura.blue") private var blue = 1.0
    @AppStorage("eagle.islandAura.selectedMode") private var selectedModeRaw = IslandAuraMode.glow.rawValue
    @AppStorage("eagle.islandAura.activeMode") private var activeModeRaw = 0

    @State private var isApplying = false
    @State private var previewPulse = false
    @State private var notice: IslandAuraNotice?

    private var selectedMode: IslandAuraMode {
        get { IslandAuraMode(rawValue: selectedModeRaw) ?? .glow }
        nonmutating set { selectedModeRaw = newValue.rawValue }
    }

    private var auraColor: Color {
        Color(red: red, green: green, blue: blue)
    }

    private var auraColorBinding: Binding<Color> {
        Binding(
            get: { auraColor },
            set: { color in
                let resolved = UIColor(color)
                var nextRed: CGFloat = 0
                var nextGreen: CGFloat = 0
                var nextBlue: CGFloat = 0
                var alpha: CGFloat = 0
                guard resolved.getRed(
                    &nextRed,
                    green: &nextGreen,
                    blue: &nextBlue,
                    alpha: &alpha
                ) else { return }
                red = Double(nextRed)
                green = Double(nextGreen)
                blue = Double(nextBlue)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                preview
                controls
                realityNote

                if !mgr.dsready {
                    LaraAccessView(compact: true)
                }

                applyButton
                restoreButton
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Island Aura")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $notice) { notice in
            Alert(
                title: Text("Island Aura"),
                message: Text(notice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if isApplying {
                ZStack {
                    Color.black.opacity(0.14).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(LaraL10n.text(
                            en: "Lighting the Island…",
                            es: "Iluminando la Island…"
                        ))
                            .font(.headline)
                    }
                    .padding(22)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                previewPulse = true
            }
        }
    }

    private var preview: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(LaraL10n.text(en: "Give the Island an aura", es: "Dale un aura a la Island"))
                    .font(.title2.bold())
                Text(LaraL10n.text(
                    en: "A live SpringBoard effect, not a wallpaper trick.",
                    es: "Un efecto en vivo de SpringBoard, no un truco del fondo."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color(red: 0.055, green: 0.07, blue: 0.13),
                        auraColor.opacity(0.20),
                        Color(red: 0.04, green: 0.045, blue: 0.075),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                HStack {
                    Text("9:41")
                    Spacer()
                    HStack(spacing: 5) {
                        Image(systemName: "cellularbars")
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 18)
                .padding(.top, 12)

                islandPreview
                    .padding(.top, 7)
            }
            .frame(height: 184)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }

            HStack(spacing: 7) {
                Circle()
                    .fill(activeModeRaw == 0 ? Color.secondary.opacity(0.5) : Color.green)
                    .frame(width: 8, height: 8)
                Text(activeModeRaw == 0
                     ? LaraL10n.text(en: "No verified aura", es: "Sin aura verificada")
                     : LaraL10n.text(en: "Last apply was verified", es: "La última aplicación fue verificada"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var islandPreview: some View {
        ZStack {
            Capsule()
                .fill(selectedMode == .tint ? auraColor.opacity(0.30) : Color.black)
                .frame(width: 128, height: 37)
                .overlay {
                    Capsule()
                        .stroke(auraColor, lineWidth: 2.2)
                }
                .shadow(color: auraColor.opacity(0.95), radius: 10)
                .shadow(color: auraColor.opacity(0.52), radius: 18)
                .opacity(selectedMode == .pulse ? (previewPulse ? 1 : 0.58) : 1)

            HStack(spacing: 58) {
                Circle().fill(.black).frame(width: 8, height: 8)
                Circle().fill(.black).frame(width: 6, height: 6)
            }
            .opacity(selectedMode == .tint ? 1 : 0)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LaraL10n.text(en: "Your Aura", es: "Tu Aura"))
                .font(.headline)

            Picker(
                LaraL10n.text(en: "Effect", es: "Efecto"),
                selection: Binding(
                    get: { selectedMode },
                    set: { selectedMode = $0 }
                )
            ) {
                ForEach(IslandAuraMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(selectedMode.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ColorPicker(
                LaraL10n.text(en: "Neon color", es: "Color neón"),
                selection: auraColorBinding,
                supportsOpacity: false
            )
            .font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                ForEach(presets, id: \.name) { preset in
                    Button {
                        red = preset.red
                        green = preset.green
                        blue = preset.blue
                    } label: {
                        Circle()
                            .fill(Color(red: preset.red, green: preset.green, blue: preset.blue))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Circle().strokeBorder(.white.opacity(0.5), lineWidth: 1)
                            }
                            .shadow(
                                color: Color(red: preset.red, green: preset.green, blue: preset.blue).opacity(0.55),
                                radius: 6
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.name)
                }
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var realityNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.dotted.circle.fill")
                .foregroundStyle(auraColor)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(LaraL10n.text(en: "Designed around the hardware", es: "Diseñada alrededor del hardware"))
                    .font(.subheadline.weight(.semibold))
                Text(LaraL10n.text(
                    en: "The camera and sensor cutout is physically black. On iOS 18, Eagle connects to the live System Aperture surface through a bounded main-thread path so the aura can follow music, recording and timer layouts. If that surface is unavailable, Eagle uses a verified compact halo. The effect ends after a respring or reboot.",
                    es: "La abertura de cámara y sensores es físicamente negra. En iOS 18, Eagle se conecta a la superficie activa de System Aperture mediante una ruta limitada en el hilo principal para que el aura siga la música, la grabación y el temporizador. Si esa superficie no está disponible, Eagle usa un halo compacto verificado. El efecto termina tras un respring o reinicio."
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
    }

    private var applyButton: some View {
        Button {
            apply(mode: selectedMode.rawValue)
        } label: {
            Label(
                LaraL10n.text(en: "Light the Island", es: "Iluminar la Island"),
                systemImage: "sparkles"
            )
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(auraColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isApplying)
    }

    private var restoreButton: some View {
        Button {
            apply(mode: 0)
        } label: {
            Label(
                LaraL10n.text(en: "Restore Black Island", es: "Restaurar Island negra"),
                systemImage: "arrow.counterclockwise"
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        // Keep cleanup available even after an app update or a stale saved
        // state; an older halo may still need to be removed.
        .disabled(isApplying)
    }

    private var presets: [(name: String, red: Double, green: Double, blue: Double)] {
        [
            ("Electric", 0.10, 0.78, 1.00),
            ("Ultra Violet", 0.62, 0.25, 1.00),
            ("Hot Pink", 1.00, 0.16, 0.62),
            ("Acid", 0.42, 1.00, 0.24),
        ]
    }

    private func apply(mode: Int) {
        guard !isApplying else { return }
        guard !isdebugged() else {
            notice = IslandAuraNotice(message: LaraL10n.text(
                en: "Stop the Xcode run and open Eagle manually from the Home Screen before changing SpringBoard.",
                es: "Detén la ejecución en Xcode y abre Eagle manualmente desde la pantalla de inicio antes de modificar SpringBoard."
            ))
            return
        }
        guard mgr.dsready else {
            notice = IslandAuraNotice(message: LaraL10n.text(
                en: "Prepare Eagle access before changing the Dynamic Island.",
                es: "Prepara el acceso de Eagle antes de cambiar la Dynamic Island."
            ))
            return
        }

        isApplying = true
        let applyWithSession = {
            guard let process = self.mgr.sbProc else {
                self.finish(message: LaraL10n.text(
                    en: "Eagle connected to SpringBoard but did not receive a live session.",
                    es: "Eagle se conectó a SpringBoard, pero no recibió una sesión activa."
                ))
                return
            }

            let redValue = Int32(max(0, min(255, Int((self.red * 255).rounded()))))
            let greenValue = Int32(max(0, min(255, Int((self.green * 255).rounded()))))
            let blueValue = Int32(max(0, min(255, Int((self.blue * 255).rounded()))))
            DispatchQueue.global(qos: .userInitiated).async {
                let result = eagle_set_island_aura(
                    process,
                    redValue,
                    greenValue,
                    blueValue,
                    Int32(mode)
                )
                DispatchQueue.main.async {
                    self.isApplying = false
                    if result >= 0 {
                        self.activeModeRaw = mode
                        self.notice = IslandAuraNotice(
                            message: self.successMessage(for: result, mode: mode)
                        )
                    } else {
                        self.notice = IslandAuraNotice(message: self.message(for: result))
                    }
                }
            }
        }

        if mgr.rcready, mgr.sbProc != nil {
            applyWithSession()
        } else {
            mgr.rcinit(process: "SpringBoard") { success in
                if success || (self.mgr.rcready && self.mgr.sbProc != nil) {
                    applyWithSession()
                } else {
                    let detail = self.mgr.rcLastError?.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.finish(message: detail?.isEmpty == false
                        ? detail!
                        : LaraL10n.text(
                            en: "Eagle could not start the live SpringBoard session.",
                            es: "Eagle no pudo iniciar la sesión en vivo con SpringBoard."
                        ))
                }
            }
        }
    }

    private func finish(message: String) {
        DispatchQueue.main.async {
            self.isApplying = false
            self.notice = IslandAuraNotice(message: message)
        }
    }

    private func message(for result: Int32) -> String {
        switch result {
        case -2:
            return LaraL10n.text(
                en: "SpringBoard did not expose a Dynamic Island on this device. If it is enabled by a system tweak, open the Island once and try again.",
                es: "SpringBoard no mostró una Dynamic Island en este dispositivo. Si fue activada con una modificación, abre la Island una vez e inténtalo de nuevo."
            )
        case -3:
            return LaraL10n.text(
                en: "Eagle found the Island controller, but iOS did not expose its live background. Start a timer or play music, then try again.",
                es: "Eagle encontró el controlador de la Island, pero iOS no mostró su fondo en vivo. Inicia un temporizador o reproduce música y vuelve a intentarlo."
            )
        case -4:
            return LaraL10n.text(
                en: "The Island appeared without an editable visual layer. Nothing was changed.",
                es: "La Island apareció sin una capa visual editable. No se cambió nada."
            )
        case -6:
            return LaraL10n.text(
                en: "Eagle reached the Island but could not verify either the native surface or the safe halo. Nothing was reported as applied.",
                es: "Eagle llegó a la Island, pero no pudo verificar ni la superficie nativa ni el halo seguro. No se marcó nada como aplicado."
            )
        case -8:
            return LaraL10n.text(
                en: "No visible SpringBoard host was available for the safe halo. Return to the Home Screen once, reopen Eagle, and try again.",
                es: "No había un contenedor visible de SpringBoard para el halo seguro. Vuelve una vez a la pantalla de inicio, abre Eagle de nuevo e inténtalo otra vez."
            )
        case -9, -10, -11:
            return LaraL10n.text(
                en: "SpringBoard did not create the safe aura layer. Nothing was changed; no respring is required.",
                es: "SpringBoard no creó la capa segura del aura. No se cambió nada y no hace falta un respring."
            )
        case -12:
            return LaraL10n.text(
                en: "SpringBoard did not attach the safe halo within one second. Nothing was reported as applied.",
                es: "SpringBoard no conectó el halo seguro dentro de un segundo. No se marcó nada como aplicado."
            )
        case -13:
            return LaraL10n.text(
                en: "The SpringBoard session did not provide an isolated call thread. Eagle stopped before changing anything.",
                es: "La sesión de SpringBoard no proporcionó un hilo de llamadas aislado. Eagle se detuvo antes de cambiar nada."
            )
        default:
            return LaraL10n.text(
                en: "Eagle reached the Island, but iOS did not keep the neon layer. Nothing was reported as applied.",
                es: "Eagle llegó a la Island, pero iOS no conservó la capa neón. No se marcó como aplicada."
            )
        }
    }

    private func successMessage(for result: Int32, mode: Int) -> String {
        if mode == 0 {
            return LaraL10n.text(
                en: "The custom aura was removed and the Dynamic Island is black again.",
                es: "Se eliminó el aura personalizada y la Dynamic Island volvió a ser negra."
            )
        }

        switch result {
        case 1:
            return LaraL10n.text(
                en: "Adaptive Aura is live on SpringBoard's native surface. It follows the Island as music, screen recording and timers change its size.",
                es: "El aura adaptativa está activa en la superficie nativa de SpringBoard. Sigue a la Island cuando la música, la grabación de pantalla y los temporizadores cambian su tamaño."
            )
        case 2:
            return LaraL10n.text(
                en: "Island Aura is live through the native compatibility route. Its visual layer was read back and verified.",
                es: "Island Aura está activa mediante la ruta nativa de compatibilidad. Su capa visual fue comprobada y verificada."
            )
        case 3:
            return LaraL10n.text(
                en: "The safe compact halo is live and verified. It stays around the compact Island while Live Activities may expand independently.",
                es: "El halo compacto seguro está activo y verificado. Permanece alrededor de la Island compacta mientras las actividades en vivo pueden expandirse por separado."
            )
        default:
            return LaraL10n.text(
                en: "Island Aura was applied and verified.",
                es: "Island Aura fue aplicada y verificada."
            )
        }
    }
}
