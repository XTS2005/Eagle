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
                    releaseHighlightsCard
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

                Text(LaraL10n.text(en: "VERSION 1.0.3", es: "VERSIÓN 1.0.3"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(EagleVisualTheme.accent, in: Capsule())

                Text(LaraL10n.text(
                    en: "Art for your Dynamic Island and Dock, calibrated halos, and a more polished customization experience.",
                    es: "Arte para tu Dynamic Island y Dock, halos calibrados y una experiencia de personalización más pulida."
                ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var releaseHighlightsCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Release highlights", es: "Lo destacado"),
                systemImage: "wand.and.stars",
                color: .pink
            )

            HStack(spacing: 10) {
                highlightMetric(
                    value: "6",
                    label: LaraL10n.text(en: "Island styles", es: "Estilos Island"),
                    icon: "capsule.fill",
                    color: .purple
                )
                highlightMetric(
                    value: "3",
                    label: LaraL10n.text(en: "Dock themes", es: "Temas Dock"),
                    icon: "dock.rectangle",
                    color: .pink
                )
                highlightMetric(
                    value: "1.0.3",
                    label: LaraL10n.text(en: "Release", es: "Versión"),
                    icon: "checkmark.seal.fill",
                    color: .cyan
                )
            }
        }
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
                icon: "capsule.fill",
                color: .purple,
                title: LaraL10n.text(en: "Island Gallery", es: "Galería Island"),
                detail: LaraL10n.text(
                    en: "Choose from six calibrated art styles. Every image keeps Starlight's verified size and position, with a strong halo sampled from its main color.",
                    es: "Elige entre seis estilos de arte calibrados. Cada imagen conserva el tamaño y la posición verificados de Starlight, con un halo intenso tomado de su color principal."
                )
            )

            welcomeRow(
                icon: "dock.rectangle",
                color: .pink,
                title: LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"),
                detail: LaraL10n.text(
                    en: "Apply Bubblegum, Springfield, or Bikini Bottom behind your Dock apps at the exact verified 382 × 106-point frame without stretching the artwork.",
                    es: "Aplica Chicle, Springfield o Fondo de Bikini detrás de las apps del Dock con el marco verificado exacto de 382 × 106 puntos, sin estirar el arte."
                )
            )

            welcomeRow(
                icon: "eye.slash.fill",
                color: .indigo,
                title: LaraL10n.text(en: "Independent system controls", es: "Controles del sistema independientes"),
                detail: LaraL10n.text(
                    en: "Hide or restore the system Island and the Dock background separately while keeping icons, artwork, and the other Aura surface untouched.",
                    es: "Oculta o restaura por separado la Island del sistema y el fondo del Dock, conservando los iconos, el arte y la otra superficie Aura."
                )
            )

            welcomeRow(
                icon: "sparkles.rectangle.stack.fill",
                color: .cyan,
                title: LaraL10n.text(en: "Living gallery cards", es: "Tarjetas de galería vivas"),
                detail: LaraL10n.text(
                    en: "Gallery presentations now use color-aware breathing light, a gentle moving sheen, clearer selection feedback, and full Reduce Motion support.",
                    es: "Las presentaciones de galería ahora usan luz respirante según el color, un barrido suave, selección más clara y compatibilidad completa con Reducir movimiento."
                )
            )

            welcomeRow(
                icon: "checkmark.shield.fill",
                color: .green,
                title: LaraL10n.text(en: "Verified state stays accurate", es: "Estado verificado más preciso"),
                detail: LaraL10n.text(
                    en: "Island and Dock galleries now stay synchronized with Aura Studio, clear expired SpringBoard sessions, and never keep an outdated active badge.",
                    es: "Las galerías Island y Dock ahora se sincronizan con Aura Studio, limpian sesiones vencidas de SpringBoard y no conservan indicadores activos desactualizados."
                )
            )

            welcomeRow(
                icon: "iphone.and.arrow.forward",
                color: .orange,
                title: LaraL10n.text(en: "TrollStore access improvement", es: "Mejora de acceso con TrollStore"),
                detail: LaraL10n.text(
                    en: "On supported TrollStore installations, Eagle now recognizes existing mobile filesystem access before attempting an unnecessary sandbox transition.",
                    es: "En instalaciones compatibles con TrollStore, Eagle ahora reconoce el acceso existente al sistema de archivos móvil antes de intentar una transición de sandbox innecesaria."
                )
            )

            welcomeRow(
                icon: "rectangle.3.group.fill",
                color: .blue,
                title: LaraL10n.text(en: "Polished customization", es: "Personalización más pulida"),
                detail: LaraL10n.text(
                    en: "Home navigation, action placement, Passcode labels, wallpaper copy, diagnostics, and adaptive light/dark surfaces have been refined throughout the app.",
                    es: "Se refinaron la navegación de Inicio, la ubicación de acciones, los textos de Código y Fondos, los diagnósticos y las superficies adaptativas claras y oscuras."
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

    private func highlightMetric(
        value: String,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 88)
        .padding(.horizontal, 6)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
