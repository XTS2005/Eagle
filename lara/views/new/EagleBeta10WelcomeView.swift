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
                    fixesCard
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

                Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.4") · \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "80")")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(EagleVisualTheme.accent, in: Capsule())

                Text(LaraL10n.text(
                    en: "Refreshed galleries. Clearer controls. Stability improvements.",
                    es: "Galerías renovadas. Controles más claros. Mejoras de estabilidad."
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
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(LaraL10n.text(en: "This device", es: "Este dispositivo"))
                                .font(.headline)
                                .fixedSize()
                            Spacer(minLength: 8)
                            supportBadge
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LaraL10n.text(en: "This device", es: "Este dispositivo"))
                                .font(.headline)
                            supportBadge
                        }
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

    private var supportBadge: some View {
        Text(supportTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(supportColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(supportColor.opacity(0.13), in: Capsule())
            .fixedSize()
    }

    private var updatesCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "What’s new", es: "Novedades"),
                systemImage: "sparkles",
                color: .primary
            )

            welcomeRow(
                icon: "capsule.fill",
                color: .purple,
                title: LaraL10n.text(en: "Island Gallery", es: "Galería Island"),
                detail: LaraL10n.text(
                    en: "Live, Static and Saves, with adjustable shadows and a direct Apply button.",
                    es: "Live, Static y Saves, con sombra ajustable y botón para aplicar."
                )
            )

            welcomeRow(
                icon: "dock.rectangle",
                color: .pink,
                title: LaraL10n.text(en: "Dock Gallery", es: "Galería Dock"),
                detail: LaraL10n.text(
                    en: "Live and static themes, Saves, and adjustable glow.",
                    es: "Temas Live y estáticos, Saves y brillo ajustable."
                )
            )

            welcomeRow(
                icon: "eye.slash.fill",
                color: .indigo,
                title: LaraL10n.text(en: "Hide Dock + Island", es: "Hide Dock + Island"),
                detail: LaraL10n.text(
                    en: "Both controls now have their own screen. Hide Dock needs a respring and must be reapplied after a full restart.",
                    es: "Ambos controles tienen su propia pantalla. Hide Dock requiere respring y volver a activarlo tras un reinicio completo."
                )
            )

            welcomeRow(
                icon: "circle.lefthalf.filled",
                color: .primary,
                title: LaraL10n.text(en: "Cleaner navigation", es: "Navegación más limpia"),
                detail: LaraL10n.text(
                    en: "Black-and-white New badges. Aura Studio no longer shows New.",
                    es: "Etiquetas Nuevo en blanco y negro. Aura Studio ya no muestra Nuevo."
                )
            )

            welcomeRow(
                icon: "flask.fill",
                color: .blue,
                title: LaraL10n.text(en: "Laboratory access", es: "Acceso al laboratorio"),
                detail: LaraL10n.text(
                    en: "Advanced and Laboratory tools are easier to find from Customize.",
                    es: "Acceso más directo a las herramientas avanzadas y de laboratorio desde Personalizar."
                )
            )
        }
    }

    private var fixesCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "Corrections", es: "Correcciones"),
                systemImage: "checkmark.shield",
                color: .primary
            )

            welcomeRow(
                icon: "checkmark.shield.fill",
                color: .green,
                title: LaraL10n.text(en: "Applying themes", es: "Aplicar temas"),
                detail: LaraL10n.text(
                    en: "Added checks for expired sessions, repeated taps, interrupted operations and invalid saved settings.",
                    es: "Más comprobaciones ante sesiones vencidas, toques repetidos, interrupciones y ajustes guardados inválidos."
                )
            )

            welcomeRow(
                icon: "arrow.uturn.backward",
                color: .indigo,
                title: LaraL10n.text(en: "Hide Dock recovery", es: "Recuperación de Hide Dock"),
                detail: LaraL10n.text(
                    en: "Changes are checked before reporting success, with original backups and recovery if writing fails.",
                    es: "Los cambios se comprueban antes de indicar éxito, con copia de originales y recuperación si falla la escritura."
                )
            )

            welcomeRow(
                icon: "hand.tap.fill",
                color: .blue,
                title: LaraL10n.text(en: "Visible action buttons", es: "Botones accesibles"),
                detail: LaraL10n.text(
                    en: "Prepare and Apply stay above the bottom navigation bar.",
                    es: "Preparar y Aplicar quedan por encima de la barra inferior."
                )
            )

            welcomeRow(
                icon: "capsule",
                color: .purple,
                title: LaraL10n.text(en: "Island alignment and light", es: "Posición y luz de Island"),
                detail: LaraL10n.text(
                    en: "Fine-tuned alignment on iPhone 16 and 15 Pro Max, plus Glow and Pulse corrections.",
                    es: "Ajuste de posición en iPhone 16 y 15 Pro Max, y correcciones de Glow y Pulse."
                )
            )

            welcomeRow(
                icon: "paintpalette.fill",
                color: .pink,
                title: LaraL10n.text(en: "Dock colors and preview", es: "Colores y vista previa del Dock"),
                detail: LaraL10n.text(
                    en: "Corrected Pulse colors and added checks for invalid glow intensity and icon counts.",
                    es: "Colores de Pulse corregidos y comprobaciones de intensidad e iconos fuera de rango."
                )
            )

            welcomeRow(
                icon: "circle.grid.3x3.fill",
                color: .orange,
                title: LaraL10n.text(en: "Passcode and Collections", es: "Código y Colecciones"),
                detail: LaraL10n.text(
                    en: "Corrected digit matching, original backups and recovery after an incomplete change.",
                    es: "Correcciones en los dígitos, las copias originales y la recuperación de cambios incompletos."
                )
            )

            welcomeRow(
                icon: "arrow.clockwise",
                color: .cyan,
                title: LaraL10n.text(en: "Prepare and returning to Eagle", es: "Preparar y volver a Eagle"),
                detail: LaraL10n.text(
                    en: "Improved cleanup between attempts and handling of unfinished operations when switching apps.",
                    es: "Mejor limpieza entre intentos y gestión de operaciones pendientes al cambiar de app."
                )
            )

            welcomeRow(
                icon: "iphone.and.arrow.forward",
                color: .green,
                title: LaraL10n.text(en: "TrollStore access", es: "Acceso con TrollStore"),
                detail: LaraL10n.text(
                    en: "Recognizes existing file access on supported installations.",
                    es: "Reconoce el acceso a archivos ya disponible en instalaciones compatibles."
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
                LaraL10n.text(en: "Reference device", es: "Dispositivo de referencia"),
                systemImage: "iphone.gen3",
                color: .cyan
            )

            Text("iPhone 16 Pro · iOS 18.6.2 (22G100)")
                .font(.headline)

            Text(LaraL10n.text(
                en: "Physical reference for development. Results can vary by device and iOS version.",
                es: "Referencia física de desarrollo. Los resultados pueden variar según el dispositivo y la versión de iOS."
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
