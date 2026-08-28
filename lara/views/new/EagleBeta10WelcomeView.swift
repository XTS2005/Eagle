import SwiftUI

struct EagleBeta10WelcomeView: View {
    let onContinue: () -> Void

    @AppStorage(LaraLanguage.storageKey) private var language = LaraLanguage.english

    private var support: EagleSupportAssessment {
        eagleSupportAssessment()
    }

    private var deviceName: String {
        EagleDeviceIdentity.displayName(for: devicemachine())
    }

    private var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return [version.majorVersion, version.minorVersion, version.patchVersion]
            .map(String.init)
            .joined(separator: ".")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    currentDeviceCard
                    updatesCard
                    compatibilityCard
                    referenceDeviceCard
                    safetyNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(LaraL10n.text(en: "Updates", es: "Actualizaciones"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text(LaraL10n.text(en: "Continue", es: "Continuar"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .interactiveDismissDisabled(true)
        .environment(\.locale, language.locale)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            EagleBrandMark(size: 86)

            VStack(spacing: 5) {
                Text(LaraL10n.text(en: "Eagle Updates", es: "Actualizaciones de Eagle"))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(EagleVisualTheme.accent)
                    .multilineTextAlignment(.center)

                Text(LaraL10n.text(en: "VERSION 1.0.2", es: "VERSIÓN 1.0.2"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(EagleVisualTheme.accent, in: Capsule())

                Text(LaraL10n.text(
                    en: "A cleaner identity, accurate Aura previews, and an independent system Island control.",
                    es: "Una identidad más limpia, previews de Aura precisas y control independiente de la Island del sistema."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var currentDeviceCard: some View {
        welcomeCard {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: supportSymbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(supportColor)
                    .frame(width: 34)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(LaraL10n.text(en: "This device", es: "Este dispositivo"))
                            .font(.headline)
                        Spacer(minLength: 8)
                        Text(supportTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(supportColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(supportColor.opacity(0.13), in: Capsule())
                    }

                    Text("\(deviceName) · iOS \(systemVersion)")
                        .font(.subheadline.weight(.medium))

                    Text(support.message(spanish: language == .spanish))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var updatesCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "What changed", es: "Qué cambió"),
                systemImage: "sparkles",
                color: .purple
            )

            welcomeRow(
                icon: "bird.fill",
                color: .indigo,
                title: LaraL10n.text(en: "Refined Eagle identity", es: "Identidad Eagle refinada"),
                detail: LaraL10n.text(
                    en: "The Eagle mark and wordmark now share a restrained spectrum reflection and adapt cleanly to light and dark mode.",
                    es: "El símbolo y nombre Eagle ahora comparten un reflejo de espectro sutil y se adaptan correctamente a los modos claro y oscuro."
                )
            )

            welcomeRow(
                icon: "waveform.path",
                color: .cyan,
                title: LaraL10n.text(en: "Accurate Aura preview", es: "Preview de Aura precisa"),
                detail: LaraL10n.text(
                    en: "Glow stays steady, Pulse breathes, and Rainbow moves only when that mode is selected. Preview animation pauses when it is not needed.",
                    es: "Glow permanece fijo, Pulse respira y Rainbow se mueve solo cuando ese modo está seleccionado. La animación se pausa cuando no hace falta."
                )
            )

            welcomeRow(
                icon: "eye.slash.fill",
                color: .purple,
                title: LaraL10n.text(en: "Independent system Island", es: "Island del sistema independiente"),
                detail: LaraL10n.text(
                    en: "Hide or restore the system Island without changing its Aura profile, then choose Respring now or later after Eagle verifies the saved setting.",
                    es: "Oculta o restaura la Island del sistema sin cambiar su perfil Aura y elige Respring ahora o después cuando Eagle verifique el ajuste guardado."
                )
            )

            welcomeRow(
                icon: "rectangle.3.group.fill",
                color: .blue,
                title: LaraL10n.text(en: "Cleaner visual system", es: "Sistema visual más limpio"),
                detail: LaraL10n.text(
                    en: "Home, Access, Aura cards, navigation, and controls now use calmer adaptive contrast and more consistent surfaces.",
                    es: "Inicio, Acceso, tarjetas de Aura, navegación y controles ahora usan contraste adaptativo más calmado y superficies coherentes."
                )
            )

            welcomeRow(
                icon: "slider.horizontal.3",
                color: .indigo,
                title: LaraL10n.text(en: "Clear release channels", es: "Canales de versión claros"),
                detail: LaraL10n.text(
                    en: "Choose Stable, Advanced, or Laboratory directly from Home. Eagle warns which features become unavailable before moving to a lower channel.",
                    es: "Elige Stable, Advanced o Laboratory directamente desde Inicio. Eagle avisa qué funciones dejarán de estar disponibles antes de bajar de canal."
                )
            )

            welcomeRow(
                icon: "photo.on.rectangle.angled",
                color: .teal,
                title: LaraL10n.text(en: "More reliable wallpapers", es: "Fondos más confiables"),
                detail: LaraL10n.text(
                    en: "Wallpaper installs now validate their result, identify iOS 26-only entries correctly, and report when the system gallery needs to be opened manually.",
                    es: "La instalación de fondos ahora valida el resultado, identifica correctamente los exclusivos de iOS 26 y avisa cuando debes abrir manualmente la galería del sistema."
                )
            )

            welcomeRow(
                icon: "checkmark.shield.fill",
                color: .green,
                title: LaraL10n.text(en: "Stable paths preserved", es: "Rutas estables preservadas"),
                detail: LaraL10n.text(
                    en: "Prepare and device compatibility, Dock and Dynamic Island application paths, and the verified iPhone 16 Pro profile were not changed.",
                    es: "Preparar y la compatibilidad de dispositivos, las rutas de aplicación del Dock y Dynamic Island, y el perfil verificado del iPhone 16 Pro no cambiaron."
                )
            )

            welcomeRow(
                icon: "person.crop.circle.badge.checkmark",
                color: .orange,
                title: LaraL10n.text(en: "Open-source credit", es: "Crédito de código abierto"),
                detail: LaraL10n.text(
                    en: "Cyanide and 0xjohnny are now credited for the OTA implementation inherited through Lara, including a notice inside the app.",
                    es: "Cyanide y 0xjohnny ahora reciben crédito por la implementación OTA heredada mediante Lara, incluido un aviso dentro de la app."
                )
            )
        }
    }

    private var compatibilityCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Compatibility", es: "Compatibilidad"),
                systemImage: "checkmark.shield.fill",
                color: .green
            )

            compatibilityRow(
                status: LaraL10n.text(en: "Limited test", es: "Prueba limitada"),
                range: "iOS 16.7.2",
                color: .orange
            )
            compatibilityRow(
                status: LaraL10n.text(en: "Supported", es: "Compatible"),
                range: "iOS 17.0 – iOS 18.7.1",
                color: .green
            )
            compatibilityRow(
                status: LaraL10n.text(en: "Supported", es: "Compatible"),
                range: "iOS 26.0 – iOS 26.0.1",
                color: .green
            )

            Divider()

            Label {
                Text(LaraL10n.text(
                    en: "Blocked for safety: unverified iOS 16 builds, releases outside the supported ranges above, and current MIE devices.",
                    es: "Bloqueados por seguridad: builds no verificados de iOS 16, versiones fuera de los rangos compatibles indicados y dispositivos actuales con MIE."
                ))
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }

            Label {
                Text(LaraL10n.text(
                    en: "Prepare access is available again on iPhone 16 (iPhone17,3) running iOS 18.5.",
                    es: "El acceso de Preparar vuelve a estar disponible en iPhone 16 (iPhone17,3) con iOS 18.5."
                ))
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var referenceDeviceCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Primary verified device", es: "Dispositivo principal verificado"),
                systemImage: "iphone.gen3",
                color: .cyan
            )

            Text("iPhone 16 Pro · iOS 18.6.2 (22G100)")
                .font(.headline)

            Text(LaraL10n.text(
                en: "This is Eagle's physical reference device. The core Prepare flow, Dynamic Island, Dock, and the new Home Screen effects were developed and verified on this configuration. Other supported combinations can still require model-specific validation.",
                es: "Este es el dispositivo físico de referencia de Eagle. El flujo principal de Preparar, Dynamic Island, Dock y los nuevos efectos de Inicio fueron desarrollados y verificados en esta configuración. Otras combinaciones compatibles todavía pueden requerir validación específica por modelo."
            ))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var safetyNote: some View {
        Label {
            Text(LaraL10n.text(
                en: "Back up important data, apply one feature at a time, and stop after any reboot, timeout, or protected-call error. You can review compatibility again from Eagle Home.",
                es: "Respalda tus datos importantes, aplica una función a la vez y detente ante cualquier reinicio, espera agotada o error de llamada protegida. Puedes volver a revisar la compatibilidad desde Inicio."
            ))
            .font(.footnote)
            .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 4)
    }

    private func welcomeCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func welcomeSectionTitle(
        _ title: String,
        systemImage: String,
        color: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(color)
            .accessibilityAddTraits(.isHeader)
    }

    private func welcomeRow(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func compatibilityRow(
        status: String,
        range: String,
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .accessibilityHidden(true)
            Text(range)
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Text(status)
                .font(.caption.weight(.bold))
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }

    private var supportTitle: String {
        switch support.status {
        case .possible:
            return LaraL10n.text(en: "LIMITED TEST", es: "PRUEBA LIMITADA")
        case .testedNeedsMoreTesting:
            return LaraL10n.text(en: "LIMITED TEST", es: "PRUEBA LIMITADA")
        case .supported:
            return LaraL10n.text(en: "SUPPORTED", es: "COMPATIBLE")
        case .unsupported:
            return LaraL10n.text(en: "BLOCKED", es: "BLOQUEADO")
        }
    }

    private var supportColor: Color {
        switch support.status {
        case .possible, .testedNeedsMoreTesting: return .orange
        case .supported: return .green
        case .unsupported: return .red
        }
    }

    private var supportSymbol: String {
        switch support.status {
        case .possible, .testedNeedsMoreTesting: return "exclamationmark.shield.fill"
        case .supported: return "checkmark.shield.fill"
        case .unsupported: return "xmark.shield.fill"
        }
    }
}

#Preview {
    EagleBeta10WelcomeView(onContinue: {})
}
