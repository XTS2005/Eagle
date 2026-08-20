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
                    whatsNewCard
                    compatibilityCard
                    referenceDeviceCard
                    safetyNote
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(LaraL10n.text(en: "Welcome", es: "Bienvenido"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text(LaraL10n.text(en: "Continue to Eagle", es: "Continuar a Eagle"))
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
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [.cyan, .blue, .purple, .pink, .orange, .cyan],
                            center: .center
                        )
                    )
                    .frame(width: 86, height: 86)
                    .blur(radius: 14)
                    .opacity(0.48)

                Image(systemName: "bird.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 9)
            }
            .accessibilityHidden(true)

            VStack(spacing: 5) {
                Text(LaraL10n.text(en: "Welcome to Eagle", es: "Bienvenido a Eagle"))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple, .pink, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text(LaraL10n.text(en: "PUBLIC BETA 10", es: "BETA PÚBLICA 10"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )

                Text(LaraL10n.text(
                    en: "A safer, clearer beta focused on verified personalization.",
                    es: "Una beta más segura y clara, enfocada en personalización verificada."
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

    private var whatsNewCard: some View {
        welcomeCard {
            welcomeSectionTitle(
                LaraL10n.text(en: "New in Beta 10", es: "Novedades de Beta 10"),
                systemImage: "sparkles",
                color: .purple
            )

            welcomeRow(
                icon: "app.badge",
                color: .pink,
                title: LaraL10n.text(en: "Home Icon Neon", es: "Neón de iconos"),
                detail: LaraL10n.text(
                    en: "Choose a diffuse glow or a precise neon outline for the visible icons on the current Home page.",
                    es: "Elige una sombra difuminada o un contorno neón preciso para los iconos visibles de la página actual."
                )
            )

            welcomeRow(
                icon: "textformat",
                color: .indigo,
                title: LaraL10n.text(en: "App Name Color", es: "Color de nombres"),
                detail: LaraL10n.text(
                    en: "Apply a solid custom color to app names on the current Home page, with independent restore.",
                    es: "Aplica un color sólido personalizado a los nombres de la página actual, con restauración independiente."
                )
            )

            welcomeRow(
                icon: "capsule.fill",
                color: .cyan,
                title: LaraL10n.text(en: "Eagle visual identity", es: "Identidad visual de Eagle"),
                detail: LaraL10n.text(
                    en: "Rainbow loading feedback and a clearer Aura Studio presentation centered on Dynamic Island.",
                    es: "Carga multicolor y una presentación más clara de Aura Studio centrada en Dynamic Island."
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
                status: LaraL10n.text(en: "Experimental", es: "Experimental"),
                range: "iOS 16.x",
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
                    en: "Not supported: releases below iOS 16, iOS 18.7.2 and later iOS 18 releases, iOS 19–25, iOS 26.0.2+, and current MIE devices.",
                    es: "No compatibles: versiones anteriores a iOS 16, iOS 18.7.2 y posteriores de iOS 18, iOS 19–25, iOS 26.0.2+ y dispositivos actuales con MIE."
                ))
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }

            Label {
                Text(LaraL10n.text(
                    en: "Important: Prepare is blocked on iPhone 16 (iPhone17,3) running iOS 18.5 after field reports of full device restarts.",
                    es: "Importante: Preparar está bloqueado en iPhone 16 (iPhone17,3) con iOS 18.5 después de reportes de reinicios completos."
                ))
                .font(.footnote.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(.red)
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
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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
            return LaraL10n.text(en: "EXPERIMENTAL", es: "EXPERIMENTAL")
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
